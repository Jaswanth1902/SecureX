from flask import Blueprint, request, jsonify, g
from db import get_db_connection, release_db_connection
from auth_utils import token_required
from sse_manager import sse_manager
import uuid
import base64
import datetime

files_bp = Blueprint('files', __name__)

@files_bp.route('/upload', methods=['POST'])
# @token_required  <-- Disabled for testing
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
        file_data = file.read()
        file_size = len(file_data)
        file_mime = file.content_type or 'application/octet-stream'
    except Exception as e:
        return jsonify({'error': f'Invalid encoding: {str(e)}'}), 400

    file_id = str(uuid.uuid4())
    # user_id = g.user['sub'] <-- Disabled for testing
    user_id = 'test-user-id-for-development' # Hardcoded for testing

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
        cursor.execute(
            """INSERT INTO files (
                id, user_id, owner_id, file_name, encrypted_file_data, 
                file_size_bytes, file_mime_type, iv_vector, auth_tag, 
                encrypted_symmetric_key, created_at, is_deleted
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)""",
            (
                file_id, user_id, real_owner_id, file_name, file_data,
                file_size, file_mime, iv_vector, auth_tag, encrypted_key, created_at
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
            'message': 'File uploaded successfully'
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
    user_id = g.user['sub']
    role = g.user['role']

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        if role == 'user':
            query = """SELECT id, file_name, file_size_bytes, created_at, is_printed, printed_at 
                       FROM files WHERE is_deleted = 0 AND user_id = ? ORDER BY created_at DESC LIMIT 100"""
            cursor.execute(query, (user_id,))
        elif role == 'owner':
            query = """SELECT id, file_name, file_size_bytes, created_at, is_printed, printed_at 
                       FROM files WHERE is_deleted = 0 AND owner_id = ? ORDER BY created_at DESC LIMIT 100"""
            cursor.execute(query, (user_id,))
        else:
            return jsonify({'error': 'Invalid role'}), 403

        files = []
        for row in cursor.fetchall():
            files.append({
                'file_id': row[0],
                'file_name': row[1],
                'file_size_bytes': row[2],
                'uploaded_at': row[3],
                'is_printed': row[4],
                'printed_at': row[5],
                'status': 'PRINTED_AND_DELETED' if row[4] else 'WAITING_TO_PRINT'
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
    if g.user['role'] != 'owner':
        return jsonify({'error': 'Forbidden'}), 403

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Verify ownership
        cursor.execute("SELECT owner_id, is_deleted FROM files WHERE id = ?", (file_id,))
        row = cursor.fetchone()
        if not row:
             return jsonify({'error': 'File not found'}), 404
        
        if str(row[0]) != g.user['sub']:
             return jsonify({'error': 'Forbidden'}), 403
        
        if row[1]:
             return jsonify({'error': 'File already deleted'}), 400

        # Mark as deleted
        deleted_at = datetime.datetime.utcnow().isoformat()
        cursor.execute("""
            UPDATE files 
            SET is_deleted = 1, deleted_at = ?, is_printed = 1, printed_at = ?
            WHERE id = ?
        """, (deleted_at, deleted_at, file_id))
        
        cursor.execute("SELECT id, file_name FROM files WHERE id = ?", (file_id,))
        deleted = cursor.fetchone()
        conn.commit()

        return jsonify({
            'success': True,
            'file_id': deleted[0],
            'file_name': deleted[1],
            'status': 'DELETED',
            'deleted_at': deleted_at,
            'message': 'File deleted'
        })

    except Exception as e:
        conn.rollback()
        print(f"Delete error: {e}")
        return jsonify({'error': True, 'message': 'Delete failed'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)
