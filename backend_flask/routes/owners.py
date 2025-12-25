from flask import Blueprint, request, jsonify
from db import get_db_connection, release_db_connection
from auth_utils import hash_password, check_password, generate_tokens, hash_token
import datetime
import uuid

owners_bp = Blueprint('owners', __name__)

@owners_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    full_name = data.get('full_name')
    public_key = data.get('public_key')

    if not email or not password:
        return jsonify({'error': 'email and password required'}), 400
    
    if not public_key:
        return jsonify({'error': 'public_key is required'}), 400

    hashed_password = hash_password(password)
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("SELECT id FROM owners WHERE email = ?", (email,))
        if cursor.fetchone():
            return jsonify({'error': 'Owner already exists'}), 409

        owner_id = str(uuid.uuid4())
        cursor.execute(
            "INSERT INTO owners (id, email, password_hash, full_name, public_key, private_key_encrypted) VALUES (?, ?, ?, ?, ?, ?)",
            (owner_id, email, hashed_password, full_name, public_key, '')
        )
        
        cursor.execute("SELECT id, email, full_name FROM owners WHERE id = ?", (owner_id,))
        owner = cursor.fetchone()
        owner_email = owner[1]
        owner_name = owner[2]

        access_token, refresh_token = generate_tokens(owner_id, owner_email, 'owner')

        session_id = str(uuid.uuid4())
        hashed_refresh = hash_token(refresh_token)
        hashed_access = hash_token(access_token)
        expires_at = datetime.datetime.utcnow() + datetime.timedelta(days=7)
        
        cursor.execute(
            """INSERT INTO sessions (id, user_id, token_hash, refresh_token_hash, expires_at, refresh_expires_at, is_valid)
               VALUES (?, ?, ?, ?, ?, ?, 1)""",
            (session_id, owner_id, hashed_access, hashed_refresh, expires_at, expires_at)
        )
        
        conn.commit()

        return jsonify({
            'success': True,
            'accessToken': access_token,
            'refreshToken': refresh_token,
            'owner': {'id': owner_id, 'email': owner_email, 'full_name': owner_name}
        }), 201

    except Exception as e:
        conn.rollback()
        print(f"Owner Register error: {e}")
        return jsonify({'error': True, 'message': 'Registration failed'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

@owners_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    public_key = data.get('public_key')  # Optional - sync if provided

    if not email or not password:
        return jsonify({'error': 'email and password required'}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("SELECT id, email, password_hash, full_name FROM owners WHERE email = ?", (email,))
        owner = cursor.fetchone()

        if not owner or not check_password(password, owner[2]):
            return jsonify({'error': 'Invalid credentials'}), 401

        owner_id = owner[0]
        owner_email = owner[1]
        owner_name = owner[3]

        # Update public key if provided (for key sync)
        if public_key:
            cursor.execute("UPDATE owners SET public_key = ? WHERE id = ?", (public_key, owner_id))
            print(f"Updated public key for owner {owner_email}")

        access_token, refresh_token = generate_tokens(owner_id, owner_email, 'owner')

        session_id = str(uuid.uuid4())
        hashed_refresh = hash_token(refresh_token)
        hashed_access = hash_token(access_token)
        expires_at = datetime.datetime.utcnow() + datetime.timedelta(days=7)

        cursor.execute(
            """INSERT INTO sessions (id, user_id, token_hash, refresh_token_hash, expires_at, refresh_expires_at, is_valid)
               VALUES (?, ?, ?, ?, ?, ?, 1)""",
            (session_id, owner_id, hashed_access, hashed_refresh, expires_at, expires_at)
        )
        conn.commit()

        return jsonify({
            'success': True,
            'accessToken': access_token,
            'refreshToken': refresh_token,
            'owner': {'id': owner_id, 'email': owner_email, 'full_name': owner_name}
        })

    except Exception as e:
        conn.rollback()
        print(f"Owner Login error: {e}")
        return jsonify({'error': True, 'message': 'Login failed'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

@owners_bp.route('/profile', methods=['GET'])
def get_profile():
    # Helper to extract token from header
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Missing token'}), 401
    token = auth_header.split(' ')[1]
    
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Validate token via sessions table (simplified check)
        # In a full middleware we'd decode JWT, but here we can check if token hash exists in valid session
        # For simplicity in this codebase context, assuming we trust the JWT if we had a decode function handy.
        # But wait, we don't have a decode function imported.
        # Let's rely on the token provided. Actually, best practice is to decode.
        # Given potential complexity, I'll use a direct look up if possible or just rely on the user_id passed if we demand it?
        # Standard: Decode JWT.
        # Alternative: We don't have decode imported here. `check_password` etc allow hash check.
        # Let's import decode_token if available or just assume for now we need to query based on something.
        # Ah, we don't have middleware. Let's look at how other routes do it.
        # Wait, other routes don't seem to have auth protection visible here!
        # Status/files routes usually check headers.
        # Let's just implement it assuming we pass owner_id for now as query param? No that's insecure.
        # Let's implement a quick token lookup hash check if possible.
        
        # ACTUALLY: The existing code uses `generate_tokens`. We need to verify them.
        # Let's use `auth_utils` if it has verification.
        # Checking `auth_utils` imports... `hash_password`, `check_password`, `generate_tokens`, `hash_token`.
        # We can hash the token and look it up in sessions!
        
        token_hash = hash_token(token)
        cursor.execute("SELECT user_id FROM sessions WHERE token_hash = ? AND is_valid = 1", (token_hash,))
        session = cursor.fetchone()
        if not session:
            return jsonify({'error': 'Invalid or expired token'}), 401
            
        owner_id = session[0]
        cursor.execute("SELECT email, full_name FROM owners WHERE id = ?", (owner_id,))
        owner = cursor.fetchone()
        
        if not owner:
             return jsonify({'error': 'Owner not found'}), 404
             
        return jsonify({
            'success': True,
            'owner': {
                'id': owner_id,
                'email': owner[0],
                'full_name': owner[1]
            }
        })
    except Exception as e:
        print(f"Get Profile Error: {e}")
        return jsonify({'error': True, 'message': 'Internal error'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

@owners_bp.route('/update-profile', methods=['POST'])
def update_profile():
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Missing token'}), 401
    token = auth_header.split(' ')[1]
    
    data = request.get_json()
    new_name = data.get('full_name')
    if not new_name:
        return jsonify({'error': 'full_name is required'}), 400
        
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        token_hash = hash_token(token)
        cursor.execute("SELECT user_id FROM sessions WHERE token_hash = ? AND is_valid = 1", (token_hash,))
        session = cursor.fetchone()
        if not session:
            return jsonify({'error': 'Invalid token'}), 401
            
        owner_id = session[0]
        cursor.execute("UPDATE owners SET full_name = ? WHERE id = ?", (new_name, owner_id))
        conn.commit()
        
        return jsonify({'success': True, 'message': 'Profile updated'})
    except Exception as e:
        conn.rollback()
        print(f"Update Profile Error: {e}")
        return jsonify({'error': True, 'message': 'Update failed'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

@owners_bp.route('/public-key/<identifier>', methods=['GET'])
def get_public_key(identifier):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Check if identifier looks like an email
        if '@' in identifier:
            cursor.execute("SELECT public_key FROM owners WHERE email = ?", (identifier,))
        else:
            # Assume UUID
            cursor.execute("SELECT public_key FROM owners WHERE id = ?", (identifier,))
            
        result = cursor.fetchone()
        if not result:
            return jsonify({'error': 'Owner not found'}), 404
        
        return jsonify({'success': True, 'publicKey': result[0]})
        
    except Exception as e:
        print(f"Get Public Key error: {e}")
        return jsonify({'error': True, 'message': 'Failed to fetch key'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

@owners_bp.route('/change-password', methods=['POST'])
def change_password():
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Missing token'}), 401
    token = auth_header.split(' ')[1]
    
    data = request.get_json()
    current_password = data.get('current_password')
    new_password = data.get('new_password')
    
    if not current_password or not new_password:
        return jsonify({'error': 'Current and new password required'}), 400
        
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        token_hash = hash_token(token)
        cursor.execute("SELECT user_id FROM sessions WHERE token_hash = ? AND is_valid = 1", (token_hash,))
        session = cursor.fetchone()
        if not session:
            return jsonify({'error': 'Invalid token'}), 401
            
        owner_id = session[0]
        
        # Verify current password
        cursor.execute("SELECT password_hash FROM owners WHERE id = ?", (owner_id,))
        result = cursor.fetchone()
        if not result or not check_password(current_password, result[0]):
            return jsonify({'error': 'Invalid current password'}), 401
            
        # Update with new password
        new_hash = hash_password(new_password)
        cursor.execute("UPDATE owners SET password_hash = ? WHERE id = ?", (new_hash, owner_id))
        conn.commit()
        
        return jsonify({'success': True, 'message': 'Password updated successfully'})
    except Exception as e:
        conn.rollback()
        print(f"Change Password Error: {e}")
        return jsonify({'error': True, 'message': 'Update failed'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

@owners_bp.route('/feedback', methods=['POST'])
def send_feedback():
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Missing token'}), 401
    token = auth_header.split(' ')[1]
    
    data = request.get_json()
    message = data.get('message')
    
    if not message:
        return jsonify({'error': 'Message required'}), 400
        
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Validate token
        token_hash = hash_token(token)
        cursor.execute("SELECT user_id FROM sessions WHERE token_hash = ? AND is_valid = 1", (token_hash,))
        session = cursor.fetchone()
        if not session:
            return jsonify({'error': 'Invalid token'}), 401
            
        owner_id = session[0]
        
        # Ensure table exists (minimal schema)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS feedback (
                id TEXT PRIMARY KEY,
                user_id TEXT,
                message TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Insert feedback
        feedback_id = str(uuid.uuid4())
        cursor.execute(
            "INSERT INTO feedback (id, user_id, message) VALUES (?, ?, ?)",
            (feedback_id, owner_id, message)
        )
        conn.commit()
        
        return jsonify({'success': True, 'message': 'Feedback sent'})
    except Exception as e:
        conn.rollback()
        print(f"Feedback Error: {e}")
        return jsonify({'error': True, 'message': 'Failed to send feedback'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)
