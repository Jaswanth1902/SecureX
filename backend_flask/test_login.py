"""
Test login directly using the auth.py route logic
"""
import sqlite3
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))
from auth_utils import check_password

# Test credentials
phone = "7013944675"
password = "password123"

conn = sqlite3.connect('database.db')
cursor = conn.cursor()

try:
    # Query user from database
    cursor.execute("SELECT id, phone, password_hash, full_name FROM users WHERE phone = ?", (phone,))
    user = cursor.fetchone()
    
    if not user:
        print(f"[ERROR] User not found with phone: {phone}")
    else:
        print(f"[INFO] User found:")
        print(f"   Phone: {user[1]}")
        print(f"   Name: {user[3]}")
        print(f"   ID: {user[0]}")
        
        # Check password
        password_hash = user[2]
        print(f"\n[INFO] Testing password...")
        print(f"   Provided password: {password}")
        print(f"   Stored hash (first 20 chars): {password_hash[:20]}...")
        
        if check_password(password, password_hash):
            print(f"\n[SUCCESS] Password is correct!")
            print(f"   Login should work!")
        else:
            print(f"\n[ERROR] Password is INCORRECT!")
            print(f"   The password in the database does not match '{password}'")
            print(f"   You may need to reset the password.")
            
except Exception as e:
    print(f"[ERROR] Exception: {e}")
    import traceback
    traceback.print_exc()
finally:
    cursor.close()
    conn.close()
