from flask import Blueprint, request, jsonify, g
from db import get_db_connection, release_db_connection
from auth_utils import token_required
from sse_manager import sse_manager
import datetime

status_bp = Blueprint('status', __name__)

# Valid status transitions
VALID_TRANSITIONS = {
    'UPLOADED': ['WAITING_FOR_APPROVAL', 'CANCELLED', 'REJECTED', 'BEING_PRINTED'],
    'WAITING_FOR_APPROVAL': ['APPROVED', 'REJECTED', 'CANCELLED'],
    'APPROVED': ['BEING_PRINTED', 'CANCELLED'],
    'BEING_PRINTED': ['PRINT_COMPLETED', 'APPROVED', 'REJECTED'],  # Can be rejected if print fails
    'PRINT_COMPLETED': [],  # Terminal state
    'REJECTED': [],  # Terminal state
    'CANCELLED': []  # Terminal state
}

@status_bp.route('/update/<file_id>', methods=['POST'])
@token_required
def update_file_status(file_id):
    """
    Update the status of a file (owner only)
    Request body: { "status": "APPROVED", "rejection_reason": "optional" }
    """
    if g.user['role'] != 'owner':
        return jsonify({'error': 'Only owners can update file status'}), 403
    
    data = request.get_json()
    new_status = data.get('status')
    rejection_reason = data.get('rejection_reason', None)
    
    # Validate status
    valid_statuses = ['UPLOADED', 'WAITING_FOR_APPROVAL', 'APPROVED', 'BEING_PRINTED', 
                      'PRINT_COMPLETED', 'REJECTED', 'CANCELLED']
    if new_status not in valid_statuses:
        return jsonify({'error': f'Invalid status. Must be one of: {", ".join(valid_statuses)}'}), 400
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get current file info
        cursor.execute("""
            SELECT owner_id, file_name, status, user_id 
            FROM files 
            WHERE id = ? AND is_deleted = 0
        """, (file_id,))
        
        file_row = cursor.fetchone()
        if not file_row:
            return jsonify({'error': 'File not found'}), 404
        
        # Verify ownership
        if str(file_row[0]) != g.user['sub']:
            return jsonify({'error': 'Forbidden: Not your file'}), 403
        
        current_status = file_row[2]
        file_name = file_row[1]
        user_id = file_row[3]
        
        # Validate transition
        if new_status == current_status:
            return jsonify({'message': 'Status unchanged', 'status': current_status}), 200
        
        if new_status not in VALID_TRANSITIONS.get(current_status, []):
            return jsonify({
                'error': f'Invalid status transition from {current_status} to {new_status}'
            }), 400
        
        # Update status
        status_updated_at = datetime.datetime.utcnow().isoformat()
        
        # Update is_printed flag if status is PRINT_COMPLETED
        if new_status == 'PRINT_COMPLETED':
            cursor.execute("""
                UPDATE files 
                SET status = ?, status_updated_at = ?, rejection_reason = ?, 
                    is_printed = 1, printed_at = ?
                WHERE id = ?
            """, (new_status, status_updated_at, rejection_reason, status_updated_at, file_id))
        else:
            cursor.execute("""
                UPDATE files 
                SET status = ?, status_updated_at = ?, rejection_reason = ?
                WHERE id = ?
            """, (new_status, status_updated_at, rejection_reason, file_id))
        
        conn.commit()
        
        print(f"✅ Status updated for file {file_id}: {current_status} → {new_status}")
        
        # Notify desktop owner (if applicable)
        sse_manager.publish(str(file_row[0]), "status_update", {
            "file_id": file_id,
            "file_name": file_name,
            "status": new_status,
            "updated_at": status_updated_at,
            "rejection_reason": rejection_reason
        })
        
        # Also notify the uploader (user) about status changes, especially rejections
        if user_id:
            sse_manager.publish(str(user_id), "file_status_changed", {
                "file_id": file_id,
                "file_name": file_name,
                "status": new_status,
                "updated_at": status_updated_at,
                "rejection_reason": rejection_reason
            })
        
        return jsonify({
            'success': True,
            'file_id': file_id,
            'file_name': file_name,
            'old_status': current_status,
            'new_status': new_status,
            'status_updated_at': status_updated_at,
            'rejection_reason': rejection_reason,
            'message': f'Status updated to {new_status}'
        }), 200
        
    except Exception as e:
        conn.rollback()
        print(f"Status update error: {e}")
        return jsonify({'error': True, 'message': str(e)}), 500
    finally:
        cursor.close()
        release_db_connection(conn)


@status_bp.route('/history/<file_id>', methods=['GET'])
@token_required
def get_file_status(file_id):
    """
    Get the current status of a file (user or owner)
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get file info
        cursor.execute("""
            SELECT id, file_name, status, status_updated_at, rejection_reason, 
                   created_at, user_id, owner_id
            FROM files 
            WHERE id = ?
        """, (file_id,))
        
        file_row = cursor.fetchone()
        if not file_row:
            return jsonify({'error': 'File not found'}), 404
        
        user_role = g.user['role']
        user_sub = g.user['sub']
        
        # Verify access (user can see their own files, owner can see their files)
        if user_role == 'user' and str(file_row[6]) != user_sub:
            return jsonify({'error': 'Forbidden'}), 403
        elif user_role == 'owner' and str(file_row[7]) != user_sub:
            return jsonify({'error': 'Forbidden'}), 403
        
        return jsonify({
            'success': True,
            'file_id': file_row[0],
            'file_name': file_row[1],
            'status': file_row[2],
            'status_updated_at': file_row[3],
            'rejection_reason': file_row[4],
            'uploaded_at': file_row[5]
        }), 200
        
    except Exception as e:
        print(f"Get status error: {e}")
        return jsonify({'error': True, 'message': str(e)}), 500
    finally:
        cursor.close()
        release_db_connection(conn)
