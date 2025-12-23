"""
Create user account in database.sqlite with phone number
"""
import sqlite3
import uuid
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))
from auth_utils import hash_password

# Account details
phone = "7013944675"
password = "password123"
full_name = "Surya"

# Hash the password
hashed_password = hash_password(password)

# Connect to the CORRECT database
conn = sqlite3.connect('database.sqlite')
cursor = conn.cursor()

try:
    # Check if user already exists
    cursor.execute("SELECT id, phone, full_name FROM users WHERE phone = ?", (phone,))
    existing_user = cursor.fetchone()
    
    if existing_user:
        print(f"[EXISTS] User already exists!")
        print(f"   Phone: {existing_user[1]}")
        print(f"   Name: {existing_user[2]}")
        print(f"   ID: {existing_user[0]}")
    else:
        # Create new user
        user_id = str(uuid.uuid4())
        cursor.execute(
            "INSERT INTO users (id, phone, password_hash, full_name) VALUES (?, ?, ?, ?)",
            (user_id, phone, hashed_password, full_name)
        )
        conn.commit()
        
        print(f"[SUCCESS] User created successfully!")
        print(f"   Phone: {phone}")
        print(f"   Password: {password}")
        print(f"   Name: {full_name}")
        print(f"   User ID: {user_id}")
        
except Exception as e:
    print(f"[ERROR] Error: {e}")
    conn.rollback()
finally:
    cursor.close()
    conn.close()
