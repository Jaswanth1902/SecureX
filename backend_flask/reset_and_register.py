import sqlite3
import requests
import os
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend

DB_FILE = 'database.sqlite'
API_URL = 'http://localhost:5000/api/owners/register'

def clean_database():
    print("Cleaning owners table...")
    if not os.path.exists(DB_FILE):
        print(f"Database file not found: {DB_FILE}")
        return

    try:
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        
        # Delete dependent data first to avoid FK constraint errors
        cursor.execute("DELETE FROM files")
        cursor.execute("DELETE FROM sessions")
        cursor.execute("DELETE FROM owners")
        
        conn.commit()
        conn.close()
        print("Owners table cleaned (and related files/sessions).")
    except Exception as e:
        print(f"Error cleaning database: {e}")

def register_new_owner():
    print("Generating keys and registering new owner...")
    
    # Generate keys
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
        backend=default_backend()
    )
    public_key = private_key.public_key()
    
    public_pem = public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    ).decode('utf-8')
    
    payload = {
        "email": "surya@gmail.com",
        "password": "satthi123",
        "full_name": "Sathi Surya",
        "public_key": public_pem
    }
    
    try:
        resp = requests.post(API_URL, json=payload)
        if resp.status_code == 201:
            print("Owner 'Sathi Surya' registered successfully.")
        else:
            print(f"Registration failed: {resp.status_code} - {resp.text}")
    except Exception as e:
        print(f"Error calling API: {e}")
        print("Ensure the server is running!")

if __name__ == "__main__":
    clean_database()
    register_new_owner()
