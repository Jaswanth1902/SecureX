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
