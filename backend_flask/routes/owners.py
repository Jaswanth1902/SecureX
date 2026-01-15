from auth_utils import hash_password, check_password, generate_tokens, hash_token, token_required
from flask import Blueprint, request, jsonify, g
from db import get_db_connection, release_db_connection
import datetime
import uuid
import requests
import os
import json
import base64
import time
from urllib.parse import urlencode

owners_bp = Blueprint('owners', __name__)

# Base URL for redirects (Google OAuth callback)
BASE_URL = os.getenv("PUBLIC_BASE_URL", "http://127.0.0.1:5000")
GOOGLE_REDIRECT_URI = os.getenv(
    "GOOGLE_REDIRECT_URI",
    f"{BASE_URL}/api/owners/google/callback"
)

# Google OAuth Configuration
GOOGLE_CLIENT_ID = os.getenv('GOOGLE_CLIENT_ID')
GOOGLE_CLIENT_SECRET = os.getenv('GOOGLE_CLIENT_SECRET')

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
            return jsonify({
                "success": False,
                "message": "Account already exists. Please log in."
            }), 409

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
@token_required
def get_profile():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        owner_id = g.user['sub']
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


@owners_bp.route('/me', methods=['GET'])
def get_me():
    """Get current user from session - used by desktop app after OAuth"""
    # Check for token in Authorization header
    auth_header = request.headers.get('Authorization')
    if auth_header and auth_header.startswith('Bearer '):
        token = auth_header.split(' ')[1]
        
        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            token_hash = hash_token(token)
            cursor.execute("SELECT user_id FROM sessions WHERE token_hash = ? AND is_valid = 1", (token_hash,))
            session = cursor.fetchone()
            if not session:
                return jsonify({'authenticated': False}), 401
                
            owner_id = session[0]
            cursor.execute("SELECT email, full_name FROM owners WHERE id = ?", (owner_id,))
            owner = cursor.fetchone()
            
            if not owner:
                return jsonify({'authenticated': False}), 404
                 
            return jsonify({
                'authenticated': True,
                'owner': {
                    'id': owner_id,
                    'email': owner[0],
                    'full_name': owner[1]
                }
            })
        except Exception as e:
            print(f"Get Me Error: {e}")
            return jsonify({'authenticated': False, 'error': str(e)}), 500
        finally:
            cursor.close()
            release_db_connection(conn)
    
    return jsonify({'authenticated': False}), 401

@owners_bp.route('/update-profile', methods=['POST'])
@token_required
def update_profile():
    data = request.get_json()
    new_name = data.get('full_name')
    if not new_name:
        return jsonify({'error': 'full_name is required'}), 400
        
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        owner_id = g.user['sub']
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

@owners_bp.route('/public-key', methods=['GET'])
@token_required
def get_my_public_key_simple():
    """Return the currently logged in owner's public key (for mobile compatibility)"""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        owner_id = g.user['sub']
        cursor.execute("SELECT public_key FROM owners WHERE id = ?", (owner_id,))
        result = cursor.fetchone()
        if not result or not result[0]:
            return jsonify({'error': 'Public key not set'}), 404
        
        return jsonify({'success': True, 'publicKey': result[0]})
        
    except Exception as e:
        print(f"Get My Public Key Error: {e}")
        return jsonify({'error': True, 'message': 'Internal error'}), 500
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
@token_required
def change_password():
    print("\n--- DEBUG START: change_password ---")
    try:
        data = request.get_json(silent=True)
        if not data:
            print("ERROR: No JSON data")
            return jsonify({'error': 'Invalid JSON'}), 400
            
        current_password = data.get('current_password')
        new_password = data.get('new_password')
        
        user_id = g.user.get('sub')
        role = g.user.get('role', 'owner')
        table = 'users' if role == 'user' else 'owners'
        
        print(f"DEBUG: User ID from JWT: {user_id}")
        print(f"DEBUG: Role from JWT: {role}")
        print(f"DEBUG: Initial target table: {table}")
        print(f"DEBUG: Payload keys: {list(data.keys())}")

        if not current_password or not new_password:
            print("ERROR: Missing fields")
            return jsonify({'error': 'Current and new password required'}), 400
            
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # 1. Search in primary table
        print(f"DEBUG: Querying {table} for id={user_id}")
        cursor.execute(f"SELECT password_hash FROM {table} WHERE id = ?", (user_id,))
        result = cursor.fetchone()
        
        # 2. Diagnostics if not found
        if not result:
            print(f"WARNING: User {user_id} NOT found in {table} table.")
            # Fallback search for debugging
            other_table = 'owners' if table == 'users' else 'users'
            print(f"DEBUG: Checking fallback table {other_table}...")
            cursor.execute(f"SELECT password_hash FROM {other_table} WHERE id = ?", (user_id,))
            fallback = cursor.fetchone()
            if fallback:
                print(f"CRITICAL: User found in WRONG table ({other_table})! Role mismatch.")
                result = fallback
                table = other_table
            else:
                print(f"ERROR: User {user_id} not found in EITHER table.")
                return jsonify({'error': 'User record not found'}), 401

        # 3. Verify Password
        if not check_password(current_password, result[0]):
            print(f"ERROR: Password comparison failed for {user_id} in {table}")
            return jsonify({'error': 'Invalid current password'}), 401
            
        # 4. Update
        print(f"DEBUG: Updating password for {user_id} in {table}")
        new_hash = hash_password(new_password)
        cursor.execute(f"UPDATE {table} SET password_hash = ? WHERE id = ?", (new_hash, user_id))
        conn.commit()
        
        print("DEBUG: Password updated successfully.")
        print("--- DEBUG END: change_password ---\n")
        return jsonify({'success': True, 'message': 'Password updated successfully'})
    except Exception as e:
        import traceback
        print(f"CRITICAL ERROR in change_password: {e}")
        print(traceback.format_exc())
        return jsonify({'error': True, 'message': f'Internal error: {str(e)}'}), 500
    finally:
        if 'conn' in locals():
            cursor.close()
            release_db_connection(conn)

@owners_bp.route('/feedback', methods=['POST'])
@token_required
def send_feedback():
    """Submit user feedback (authenticated)"""
    data = request.get_json()
    message = data.get('message')
    owner_id = g.user['sub']
    
    print(f"DEBUG: Feedback request received for owner {owner_id}")
    
    if not message:
        return jsonify({'error': 'Message required'}), 400
        
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
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
        
        print(f"DEBUG: Feedback {feedback_id} stored successfully for owner {owner_id}")
        return jsonify({'success': True, 'message': 'Feedback sent'})
    except Exception as e:
        conn.rollback()
        print(f"DEBUG: Feedback Error for owner {owner_id}: {e}")
        return jsonify({'error': True, 'message': 'Failed to send feedback'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

@owners_bp.route('/me/public-key', methods=['GET'])
@token_required
def get_my_public_key():
    """Check if the current owner has a public key and return it if it exists"""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        owner_id = g.user['sub']
        cursor.execute("SELECT public_key FROM owners WHERE id = ?", (owner_id,))
        result = cursor.fetchone()
        if result and result[0]:
            return jsonify({'exists': True, 'public_key': result[0]})
        return jsonify({'exists': False})
    except Exception as e:
        print(f"DEBUG: Get My Public Key Error: {e}")
        return jsonify({'error': True, 'message': 'Internal error'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

@owners_bp.route('/sync-key', methods=['POST'])
@token_required
def sync_key():
    """Synchronize RSA public key from desktop app (Write-Once)"""
    data = request.get_json()
    public_key = data.get('public_key')
    
    if not public_key:
        return jsonify({'error': 'public_key is required'}), 400
        
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        owner_id = g.user['sub']
        
        # Check if key already exists (Write-Once policy)
        cursor.execute("SELECT public_key FROM owners WHERE id = ?", (owner_id,))
        existing = cursor.fetchone()
        if existing and existing[0]:
            print(f"DEBUG: Public key already exists for owner {owner_id}. Skipping update.")
            return jsonify({'success': True, 'message': 'Public key already set (Write-Once)'})

        cursor.execute("UPDATE owners SET public_key = ? WHERE id = ?", (public_key, owner_id))
        conn.commit()
        print(f"DEBUG: Synchronized new public key for owner {owner_id}")
        return jsonify({'success': True, 'message': 'Public key synchronized'})
    except Exception as e:
        conn.rollback()
        print(f"DEBUG: Sync Key Error: {e}")
        return jsonify({'error': True, 'message': 'Sync failed'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

# ============================================
# Browser-based Google OAuth Routes
# ============================================

# In-memory storage for pending desktop auth sessions
# Format: {session_id: {'status': 'pending'|'success', 'jwt': ..., 'user': ..., 'created_at': ...}}
oauth_sessions = {}

def _cleanup_oauth_sessions():
    """Remove expired sessions (older than 5 minutes)"""
    now = time.time()
    expired = [sid for sid, data in oauth_sessions.items() 
               if now - data.get('created_at', 0) > 300]
    for sid in expired:
        del oauth_sessions[sid]

@owners_bp.route('/google/login', methods=['GET'])
def google_login():
    print("🔥 BASE_URL USED FOR GOOGLE LOGIN =", BASE_URL)
    """Redirect user to Google OAuth consent page"""
    _cleanup_oauth_sessions()
    
    if not GOOGLE_CLIENT_ID or not GOOGLE_CLIENT_SECRET:
        return jsonify({'error': 'GOOGLE_CLIENT_ID/SECRET not configured'}), 500
    
    # Get session ID from query param
    session_id = request.args.get('session_id')
    if not session_id:
        # Fallback to desktop_session or generate new one
        session_id = request.args.get('desktop_session', str(uuid.uuid4()))
    
    # Store pending session
    oauth_sessions[session_id] = {
        'status': 'pending',
        'created_at': time.time()
    }
    print(f"DEBUG: Initialized OAuth session {session_id}")
    
    # Encode state: {session_id, nonce, timestamp}
    state_data = {
        'session_id': session_id,
        'nonce': str(uuid.uuid4()),
        'timestamp': time.time()
    }
    state = base64.urlsafe_b64encode(json.dumps(state_data).encode()).decode().rstrip('=')
    
    # Construct Google OAuth URL using urlencode for reliability
    params = {
        'client_id': GOOGLE_CLIENT_ID,
        'redirect_uri': GOOGLE_REDIRECT_URI,
        'response_type': 'code',
        'scope': 'openid email profile',
        'access_type': 'offline',
        'prompt': 'consent',
        'state': state
    }
    google_auth_url = f"https://accounts.google.com/o/oauth2/v2/auth?{urlencode(params)}"
    
    from flask import redirect
    return redirect(google_auth_url)


@owners_bp.route('/google/status', methods=['GET'])
def google_status():
    """Poll for desktop OAuth completion"""
    _cleanup_oauth_sessions()
    
    session_id = request.args.get('session_id', '').strip()
    print(f"DEBUG: Status check for [{session_id}]")
    
    if not session_id or session_id not in oauth_sessions:
        print(f"DEBUG: Session [{session_id}] not found. Active: {list(oauth_sessions.keys())}")
        return jsonify({'status': 'pending'})
    
    session_data = oauth_sessions[session_id]
    print(f"DEBUG: Session [{session_id}] data: status={session_data.get('status')}")
    
    if session_data.get('status') == 'success':
        print(f"DEBUG: Returning success for [{session_id}]")
        # Return auth data and clean up
        user_data = session_data.get('user', {})
        result = {
            'status': 'success',
            'jwt': session_data.get('jwt'),
            'email': user_data.get('email'),
            'name': user_data.get('name') or user_data.get('full_name')
        }
        del oauth_sessions[session_id]
        return jsonify(result)
    
    return jsonify({'status': 'pending'})


@owners_bp.route('/google/config', methods=['GET'])
def google_config():
    """Expose whether Google OAuth is configured (no secrets)."""
    return jsonify({
        'configured': bool(GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET),
        'redirect_uri': GOOGLE_REDIRECT_URI
    })


@owners_bp.route('/google/callback', methods=['GET'])
def google_callback():
    """Handle Google OAuth callback"""
    code = request.args.get('code')
    error = request.args.get('error')
    state_raw = request.args.get('state', '')
    
    if error:
        return f"Authentication failed: {error}", 400
    
    if not code:
        return "No authorization code received", 400
    
    # Decode and validate state (with robust padding)
    try:
        print(f"DEBUG: Callback received. Raw state: {state_raw}")
        # Base64 padding normalization
        state_encoded = state_raw
        missing_padding = len(state_encoded) % 4
        if missing_padding:
            state_encoded += '=' * (4 - missing_padding)
            
        decoded_bytes = base64.urlsafe_b64decode(state_encoded.encode())
        state_data = json.loads(decoded_bytes.decode())
        session_id = state_data.get('session_id', '').strip()
        print(f"DEBUG: Extracted session_id: [{session_id}]")
    except Exception as e:
        print(f"DEBUG: State decode failed: {e}")
        return f"Invalid session state: {str(e)}", 400
        
    if not session_id or session_id not in oauth_sessions:
        print(f"DEBUG: Session [{session_id}] not found in callback. Active: {list(oauth_sessions.keys())}")
        return "Session expired or invalid. Please try again from the app.", 400
    
    if not GOOGLE_CLIENT_ID or not GOOGLE_CLIENT_SECRET:
        return "Google OAuth not configured on server", 500
    
    try:
        # Exchange code for tokens
        token_response = requests.post(
            'https://oauth2.googleapis.com/token',
            data={
                'code': code,
                'client_id': GOOGLE_CLIENT_ID,
                'client_secret': GOOGLE_CLIENT_SECRET,
                'redirect_uri': GOOGLE_REDIRECT_URI,
                'grant_type': 'authorization_code'
            }
        )
        
        if token_response.status_code != 200:
            return "Failed to exchange code with Google", 400
        
        tokens = token_response.json()
        id_token = tokens.get('id_token')
        
        # Verify and decode ID token
        verify_url = f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}"
        verify_response = requests.get(verify_url)
        
        if verify_response.status_code != 200:
            return "Invalid token from Google", 401
        
        token_info = verify_response.json()
        email = token_info.get('email')
        name = token_info.get('name', email.split('@')[0] if email else 'User')
        
        # Database operations
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("SELECT id, full_name FROM owners WHERE email = ?", (email,))
        owner = cursor.fetchone()
        
        if not owner:
            owner_id = str(uuid.uuid4())
            cursor.execute(
                "INSERT INTO owners (id, email, password_hash, full_name, public_key, private_key_encrypted) VALUES (?, ?, ?, ?, ?, ?)",
                (owner_id, email, '', name, '', '')
            )
            owner_name = name
            conn.commit()
        else:
            owner_id = owner[0]
            owner_name = owner[1]
        
        # Create JWT session
        access_token, refresh_token = generate_tokens(owner_id, email, 'owner')
        
        # Store in shared storage for polling
        oauth_sessions[session_id] = {
            'status': 'success',
            'jwt': access_token,
            'user': {'id': owner_id, 'email': email, 'full_name': owner_name, 'name': owner_name},
            'created_at': time.time()
        }
        print(f"DEBUG: Updated session {session_id} to success")
        
        # Return minimal success HTML
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Login Successful</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; text-align: center; padding: 50px; background: #f9f9f9; }
                .card { background: white; padding: 40px; border-radius: 12px; max-width: 400px; margin: auto; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
                h1 { color: #28a745; margin-bottom: 10px; }
                p { color: #666; font-size: 16px; }
            </style>
        </head>
        <body>
            <div class="card">
                <h1>✓ Success!</h1>
                <p>Login successful. You may close this window and return to the application.</p>
            </div>
        </body>
        </html>
        """, 200
        
    except Exception as e:
        print(f"DEBUG: Google Callback Error: {e}")
        return f"Authentication failed: {str(e)}", 500
    finally:
        if 'conn' in locals():
            cursor.close()
            release_db_connection(conn)


@owners_bp.route('/google', methods=['POST'])
def google_auth():
    data = request.get_json()
    id_token = data.get('id_token')
    
    if not id_token:
        return jsonify({'error': 'id_token required'}), 400
        
    try:
        # Verify token with Google
        verify_url = f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}"
        response = requests.get(verify_url)
        
        if response.status_code != 200:
            return jsonify({'error': 'Invalid token'}), 401
            
        token_info = response.json()
        
        # Verify Audience
        if token_info.get('aud') != GOOGLE_CLIENT_ID:
            return jsonify({'error': 'Invalid token audience'}), 401
            
        # Extract Email
        email = token_info.get('email')
        if not email:
            return jsonify({'error': 'Token does not contain email'}), 400
            
        # Check if Owner exists
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("SELECT id, full_name FROM owners WHERE email = ?", (email,))
        owner = cursor.fetchone()
        
        if not owner:
            return jsonify({'error': 'User not found'}), 404
            
        owner_id = owner[0]
        owner_name = owner[1]
        
        # Create Session (Login)
        access_token, refresh_token = generate_tokens(owner_id, email, 'owner')
        
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
            'owner': {'id': owner_id, 'email': email, 'full_name': owner_name}
        })
        
    except Exception as e:
        print(f"Google Auth Error: {e}")
        return jsonify({'error': True, 'message': 'Authentication failed'}), 500
    finally:
        if 'conn' in locals():
            cursor.close()
            release_db_connection(conn)
