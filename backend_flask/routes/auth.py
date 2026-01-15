from flask import Blueprint, request, jsonify, g
from db import get_db_connection, release_db_connection
from auth_utils import hash_password, check_password, generate_tokens, hash_token, token_required
import datetime
import uuid

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    phone = data.get('phone')
    password = data.get('password')
    full_name = data.get('full_name')

    if not phone or not password:
        return jsonify({'error': 'phone and password required'}), 400

    hashed_password = hash_password(password)
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Check if user exists
        cursor.execute("SELECT id FROM users WHERE phone = ?", (phone,))
        if cursor.fetchone():
            return jsonify({
                "success": False,
                "message": "Account already exists. Please log in."
            }), 409

        # Generate UUID for user
        user_id = str(uuid.uuid4())

        # Insert user
        cursor.execute(
            "INSERT INTO users (id, phone, password_hash, full_name) VALUES (?, ?, ?, ?)",
            (user_id, phone, hashed_password, full_name)
        )
        
        # Fetch the inserted user
        cursor.execute("SELECT id, phone, full_name FROM users WHERE id = ?", (user_id,))
        user = cursor.fetchone()
        user_phone = user[1]
        user_name = user[2]

        # Generate tokens
        access_token, refresh_token = generate_tokens(user_id, user_phone, 'user')

        # Store session
        session_id = str(uuid.uuid4())
        hashed_refresh = hash_token(refresh_token)
        hashed_access = hash_token(access_token)
        expires_at = datetime.datetime.utcnow() + datetime.timedelta(days=7)
        
        cursor.execute(
            """INSERT INTO sessions (id, user_id, token_hash, refresh_token_hash, expires_at, refresh_expires_at, is_valid)
               VALUES (?, ?, ?, ?, ?, ?, 1)""",
            (session_id, user_id, hashed_access, hashed_refresh, expires_at, expires_at)
        )
        
        conn.commit()

        return jsonify({
            'success': True,
            'accessToken': access_token,
            'refreshToken': refresh_token,
            'user': {'id': user_id, 'phone': user_phone, 'full_name': user_name}
        }), 201

    except Exception as e:
        conn.rollback()
        print(f"Register error: {e}")
        return jsonify({'error': True, 'message': 'Registration failed'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    phone = data.get('phone')
    password = data.get('password')
    
    # DEBUG LOG
    print(f"DEBUG (Auth): Login attempt for phone: '{phone}'")

    if not phone or not password:
        return jsonify({'error': 'phone and password required'}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("SELECT id, phone, password_hash, full_name FROM users WHERE phone = ?", (phone,))
        user = cursor.fetchone()

        if not user or not check_password(password, user[2]):
            return jsonify({'error': 'Invalid credentials'}), 401

        user_id = user[0]
        user_phone = user[1]
        user_name = user[3]

        access_token, refresh_token = generate_tokens(user_id, user_phone, 'user')

        session_id = str(uuid.uuid4())
        hashed_refresh = hash_token(refresh_token)
        hashed_access = hash_token(access_token)
        expires_at = datetime.datetime.utcnow() + datetime.timedelta(days=7)

        cursor.execute(
            """INSERT INTO sessions (id, user_id, token_hash, refresh_token_hash, expires_at, refresh_expires_at, is_valid)
               VALUES (?, ?, ?, ?, ?, ?, 1)""",
            (session_id, user_id, hashed_access, hashed_refresh, expires_at, expires_at)
        )
        conn.commit()

        return jsonify({
            'success': True,
            'accessToken': access_token,
            'refreshToken': refresh_token,
            'user': {'id': user_id, 'phone': user_phone, 'full_name': user_name}
        })

    except Exception as e:
        conn.rollback()
        print(f"Login error: {e}")
        return jsonify({'error': True, 'message': 'Login failed'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

@auth_bp.route('/change-password', methods=['POST'])
@token_required
def change_password():
    data = request.get_json()
    current_password = data.get('current_password')
    new_password = data.get('new_password')
    
    if not current_password or not new_password:
        return jsonify({'error': 'Current and new password required'}), 400
        
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        user_id = g.user['sub']
        
        # Verify current password
        cursor.execute("SELECT password_hash FROM users WHERE id = ?", (user_id,))
        result = cursor.fetchone()
        if not result or not check_password(current_password, result[0]):
            return jsonify({'error': 'Invalid current password'}), 401
            
        # Update with new password
        new_hash = hash_password(new_password)
        cursor.execute("UPDATE users SET password_hash = ? WHERE id = ?", (new_hash, user_id))
        conn.commit()
        
        return jsonify({'success': True, 'message': 'Password updated successfully'})
    except Exception as e:
        conn.rollback()
        print(f"Change Password Error: {e}")
        return jsonify({'error': True, 'message': 'Update failed'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

