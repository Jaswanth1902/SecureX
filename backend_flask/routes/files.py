from flask import Blueprint, request, jsonify, g
from db import get_db_connection, release_db_connection
from auth_utils import token_required
from sse_manager import sse_manager
import uuid
import base64
import datetime
import os

files_bp = Blueprint('files', __name__)

@files_bp.route('/upload', methods=['POST'])
@token_required  # Authentication enabled - use real user_id from JWT
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400
    
    file = request.files['file']
    file_name = request.form.get('file_name')
    iv_vector_b64 = request.form.get('iv_vector')
    auth_tag_b64 = request.form.get('auth_tag')
    encrypted_key_b64 = request.form.get('encrypted_symmetric_key')
    owner_id = request.form.get('owner_id')

    if not all([file_name, iv_vector_b64, auth_tag_b64, encrypted_key_b64, owner_id]):
        return jsonify({'error': 'Missing required fields'}), 400

    # Convert Base64 to Bytes for DB storage
    try:
        iv_vector = base64.b64decode(iv_vector_b64)
        auth_tag = base64.b64decode(auth_tag_b64)
        encrypted_key = base64.b64decode(encrypted_key_b64)
        
        # Check file size (50MB limit)
        file.seek(0, os.SEEK_END)
        file_length = file.tell()
        file.seek(0)
        
        if file_length > 50 * 1024 * 1024: # 50MB
            return jsonify({'error': 'File too large (max 50MB)'}), 413
            
        file_data = file.read()
        file_size = len(file_data)
        file_mime = file.content_type or 'application/octet-stream'
        
        # Sanitize filename (basic)
        import re
        file_name = re.sub(r'[^a-zA-Z0-9_.-]', '_', file_name)

        # Validate file extension (Security Fix #22)
        # Must match mobile app allowed list: pdf, doc, docx
        allowed_extensions = {'pdf', 'doc', 'docx'}
        ext = file_name.rsplit('.', 1)[1].lower() if '.' in file_name else ''
        if ext not in allowed_extensions:
            return jsonify({'error': 'Invalid file type. Only PDF and DOCX allowed.'}), 400
        
    except Exception as e:
        return jsonify({'error': f'Invalid encoding: {str(e)}'}), 400

    file_id = str(uuid.uuid4())
    user_id = g.user['sub']  # Use real user ID from JWT token

    conn = get_db_connection()
    cursor = conn.cursor()

    # Resolve Owner ID (Mobile app sends Email, we need UUID)
    real_owner_id = owner_id
    try:
        cursor.execute("SELECT id FROM owners WHERE email = ?", (owner_id,))
        row = cursor.fetchone()
        if row:
            real_owner_id = row[0]
            print(f"Resolved owner email '{owner_id}' to UUID '{real_owner_id}'")
        else:
            # Check if it's already a UUID
            cursor.execute("SELECT id FROM owners WHERE id = ?", (owner_id,))
            if cursor.fetchone():
                real_owner_id = owner_id
            else:
                print(f"Warning: Owner '{owner_id}' not found in DB. Using as-is.")
    except Exception as e:
        print(f"Error resolving owner: {e}")

    try:
        created_at = datetime.datetime.utcnow().isoformat()
        status_updated_at = created_at
        cursor.execute(
            """INSERT INTO files (
                id, user_id, owner_id, file_name, encrypted_file_data, 
                file_size_bytes, file_mime_type, iv_vector, auth_tag, 
                encrypted_symmetric_key, created_at, is_deleted, status, status_updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 'WAITING_FOR_APPROVAL', ?)""",
            (
                file_id, user_id, real_owner_id, file_name, file_data,
                file_size, file_mime, iv_vector, auth_tag, encrypted_key, created_at, status_updated_at
            )
        )
        conn.commit()

        print(f"File uploaded: {file_id} ({file_size} bytes)")

        # Notify desktop client via SSE
        sse_manager.publish(owner_id, "new_file", {
            "file_id": file_id,
            "file_name": file_name,
            "file_size_bytes": file_size,
            "uploaded_at": created_at
        })

        return jsonify({
            'success': True,
            'file_id': file_id,
            'file_name': file_name,
            'file_size_bytes': file_size,
            'uploaded_at': created_at,
            'status': 'WAITING_FOR_APPROVAL',
            'status_updated_at': status_updated_at,
            'message': 'File uploaded successfully. Waiting for owner approval.'
        }), 201

    except Exception as e:
        conn.rollback()
        print(f"Upload error: {e}")
        return jsonify({'error': True, 'message': 'Upload failed'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

@files_bp.route('/files', methods=['GET'])
@token_required
def list_files():
    # Get user info from token (set by @token_required decorator)
    user_id = g.user['sub']
    role = g.user.get('role', 'user')  # Default to 'user' if role not specified

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        if role == 'user':
            # Include REJECTED files even if deleted, so mobile app can show rejection status
            query = """SELECT f.id, f.file_name, f.file_size_bytes, f.created_at, f.is_printed, f.printed_at, f.status, f.status_updated_at, f.rejection_reason, u.phone
                       FROM files f
                       LEFT JOIN users u ON f.user_id = u.id
                       WHERE (f.is_deleted = 0 OR f.status = 'REJECTED') AND f.user_id = ? ORDER BY f.created_at DESC LIMIT 100"""
            cursor.execute(query, (user_id,))
        elif role == 'owner':
            # Include REJECTED files even if deleted, so desktop app can show rejection status
            query = """SELECT f.id, f.file_name, f.file_size_bytes, f.created_at, f.is_printed, f.printed_at, f.status, f.status_updated_at, f.rejection_reason, u.phone
                       FROM files f
                       LEFT JOIN users u ON f.user_id = u.id
                       WHERE (f.is_deleted = 0 OR f.status = 'REJECTED') AND f.owner_id = ? ORDER BY f.created_at DESC LIMIT 100"""
            cursor.execute(query, (user_id,))
        else:
            return jsonify({'error': 'Invalid role'}), 403

        files = []
        for row in cursor.fetchall():
            phone = row[9]
            masked_phone = None
            if phone:
                phone_str = str(phone)
                if len(phone_str) > 4:
                    masked_phone = 'x' * (len(phone_str) - 4) + phone_str[-4:]
                else:
                    masked_phone = phone_str # Too short to mask
            
            files.append({
                'file_id': row[0],
                'file_name': row[1],
                'file_size_bytes': row[2],
                'uploaded_at': row[3],
                'is_printed': row[4],
                'printed_at': row[5],
                'status': row[6],
                'status_updated_at': row[7],
                'rejection_reason': row[8],
                'sender_phone': masked_phone 
            })

        return jsonify({
            'success': True,
            'count': len(files),
            'files': files
        })

    except Exception as e:
        print(f"List files error: {e}")
        return jsonify({'error': True, 'message': 'Failed to list files'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

@files_bp.route('/print/<file_id>', methods=['GET'])
@token_required
def get_file_for_print(file_id):
    if g.user['role'] != 'owner':
        return jsonify({'error': 'Forbidden'}), 403

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""
            SELECT id, file_name, encrypted_file_data, file_size_bytes, 
                   iv_vector, auth_tag, encrypted_symmetric_key, created_at, 
                   is_printed, owner_id
            FROM files WHERE id = ? AND is_deleted = 0
        """, (file_id,))
        
        row = cursor.fetchone()
        if not row:
            return jsonify({'error': 'File not found'}), 404

        if str(row[9]) != g.user['sub']:
             return jsonify({'error': 'Forbidden: Not your file'}), 403

        # Convert bytes to Base64 strings for JSON response
        def to_b64(data):
            if isinstance(data, memoryview):
                data = data.tobytes()
            return base64.b64encode(data).decode('utf-8')

        response = {
            'success': True,
            'file_id': row[0],
            'file_name': row[1],
            'encrypted_file_data': to_b64(row[2]),
            'file_size_bytes': row[3],
            'iv_vector': to_b64(row[4]),
            'auth_tag': to_b64(row[5]),
            'encrypted_symmetric_key': to_b64(row[6]),
            'uploaded_at': row[7],
            'is_printed': row[8],
            'message': 'Decrypt this file on your PC before printing'
        }
        return jsonify(response)

    except Exception as e:
        print(f"Print download error: {e}")
        return jsonify({'error': True, 'message': 'Failed to download'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

@files_bp.route('/delete/<file_id>', methods=['POST'])
@token_required
def delete_file(file_id):
    user_id = g.user['sub']
    role = g.user.get('role', 'user')

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Verify ownership - either owner OR the user who uploaded it
        cursor.execute("SELECT user_id, owner_id, is_deleted, status, file_name FROM files WHERE id = ?", (file_id,))
        row = cursor.fetchone()
        if not row:
             return jsonify({'error': 'File not found'}), 404
        
        file_user_id = str(row[0])
        file_owner_id = str(row[1])
        
        # Check if user is either the uploader or the owner
        if role == 'owner':
            if file_owner_id != user_id:
                return jsonify({'error': 'Forbidden: Not your file'}), 403
        elif role == 'user':
            if file_user_id != user_id:
                return jsonify({'error': 'Forbidden: Not your file'}), 403
        else:
            return jsonify({'error': 'Invalid role'}), 403
        
        if row[2]:
             return jsonify({'error': 'File already deleted'}), 400

        current_status = row[3]
        file_name = row[4]

        # Mark as deleted
        deleted_at = datetime.datetime.utcnow().isoformat()
        
        if current_status == 'PRINT_COMPLETED':
            # Mark as printed and deleted
            cursor.execute("""
                UPDATE files 
                SET is_deleted = 1, deleted_at = ?, is_printed = 1, printed_at = ?
                WHERE id = ?
            """, (deleted_at, deleted_at, file_id))
            final_status = current_status
            print(f"File deleted, preserving status: {current_status}")

        elif current_status in ['APPROVED', 'REJECTED']:
            # Delete but DO NOT mark as printed (unless it was already printed? but APPROVED/REJECTED implies not yet printed in new flow)
            # Actually if it was REJECTED, it definitely wasn't printed.
            # If it was APPROVED, in new flow it transitions to BEING_PRINTED then PRINT_COMPLETED. 
            # So APPROVED means it wasn't printed yet.
            cursor.execute("""
                UPDATE files 
                SET is_deleted = 1, deleted_at = ?
                WHERE id = ?
            """, (deleted_at, file_id))
            final_status = current_status
            print(f"File deleted, preserving status: {current_status}")
        else:
            # Set to CANCELLED for other statuses
            cursor.execute("""
                UPDATE files 
                SET is_deleted = 1, deleted_at = ?, is_printed = 1, printed_at = ?, status = 'CANCELLED', status_updated_at = ?
                WHERE id = ?
            """, (deleted_at, deleted_at, deleted_at, file_id))
            final_status = 'CANCELLED'
            print(f"File deleted, status changed from {current_status} to CANCELLED")
        
        conn.commit()

        # Notify via SSE (notify the owner, not the user)
        try:
            sse_manager.publish(file_owner_id, "status_update", {
                "file_id": file_id,
                "file_name": file_name,
                "status": final_status,
                "updated_at": deleted_at,
                "message": f"File deleted with status: {final_status}"
            })
        except Exception as sse_error:
            print(f"Warning: Failed to send SSE notification: {sse_error}")

        return jsonify({
            'success': True,
            'file_id': file_id,
            'file_name': file_name,
            'status': final_status,
            'deleted_at': deleted_at,
            'message': 'File deleted successfully'
        })

    except Exception as e:
        conn.rollback()
        print(f"Delete error: {e}")
        return jsonify({'error': True, 'message': 'Delete failed'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

@files_bp.route('/history', methods=['GET'])
@token_required
def get_print_history():
    if g.user['role'] != 'owner':
        return jsonify({'error': 'Forbidden'}), 403

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Get all deleted files for this owner
        cursor.execute("""
            SELECT id, file_name, file_size_bytes, created_at, deleted_at, 
                   status, status_updated_at, rejection_reason, is_printed
            FROM files 
            WHERE is_deleted = 1 AND owner_id = ? 
            ORDER BY deleted_at DESC 
            LIMIT 100
        """, (g.user['sub'],))

        history = []
        for row in cursor.fetchall():
            history.append({
                'file_id': row[0],
                'file_name': row[1],
                'file_size_bytes': row[2],
                'uploaded_at': row[3],
                'deleted_at': row[4],
                'status': row[5],
                'status_updated_at': row[6],
                'rejection_reason': row[7],
                'is_printed': row[8]
            })

        return jsonify({
            'success': True,
            'count': len(history),
            'history': history
        })

    except Exception as e:
        print(f"History error: {e}")
        return jsonify({'error': True, 'message': 'Failed to fetch history'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

@files_bp.route('/clear-history', methods=['POST'])
@token_required
def clear_history():
    if g.user['role'] != 'owner':
        return jsonify({'error': 'Forbidden'}), 403

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Permanently delete all deleted files for this owner
        cursor.execute("""
            DELETE FROM files 
            WHERE is_deleted = 1 AND owner_id = ?
        """, (g.user['sub'],))
        
        deleted_count = cursor.rowcount
        conn.commit()
        
        print(f"Permanently deleted {deleted_count} history records for owner {g.user['sub']}")

        return jsonify({
            'success': True,
            'deleted_count': deleted_count,
            'message': f'Deleted {deleted_count} history records'
        })

    except Exception as e:
        conn.rollback()
        print(f"Clear history error: {e}")
        return jsonify({'error': True, 'message': 'Failed to clear history'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)
