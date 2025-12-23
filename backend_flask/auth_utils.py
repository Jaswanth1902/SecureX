import jwt
import bcrypt
import hashlib
import os
import datetime
from functools import wraps
from flask import request, jsonify, g

JWT_SECRET = os.getenv('JWT_SECRET')
if not JWT_SECRET:
    # Fallback for dev only, but print warning
    print("WARNING: Using default insecure JWT_SECRET. Set JWT_SECRET env var in production!")
    JWT_SECRET = 'default_secret_key_must_be_long'

def hash_password(password):
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def check_password(password, hashed):
    return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))

def generate_tokens(user_id, phone, role):
    payload = {
        'sub': str(user_id),
        'phone': phone,
        'role': role,
        'iat': datetime.datetime.utcnow(),
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=30) # Access token 30 days (extended for dev)
    }
    access_token = jwt.encode(payload, JWT_SECRET, algorithm='HS256')
    
    refresh_payload = {
        'sub': str(user_id),
        'phone': phone,
        'role': role,
        'iat': datetime.datetime.utcnow(),
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=7) # Refresh token 7 days
    }
    refresh_token = jwt.encode(refresh_payload, JWT_SECRET, algorithm='HS256')
    
    return access_token, refresh_token

def hash_token(token):
    return hashlib.sha256(token.encode('utf-8')).hexdigest()

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            if auth_header.startswith('Bearer '):
                token = auth_header.split(" ")[1]
        
        if not token:
            return jsonify({'error': True, 'message': 'Token is missing'}), 401
        
        try:
            data = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
            g.user = data
        except jwt.ExpiredSignatureError:
            return jsonify({'error': True, 'message': 'Token has expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': True, 'message': 'Invalid token'}), 401
        
        return f(*args, **kwargs)
    return decorated
