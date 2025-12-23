"""
Diagnose login issue on database.sqlite
"""
import sqlite3
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))
from auth_utils import check_password

# Credentials to test
phone = "7013944675"
password = "password123"

print("[DIAGNOSIS] Starting login diagnosis...")
print(f"   Target Database: database.sqlite")
print(f"   Phone: {phone}")

conn = sqlite3.connect('database.sqlite')
cursor = conn.cursor()

try:
    # 1. Check if user exists
    cursor.execute("SELECT id, phone, password_hash, full_name FROM users WHERE phone = ?", (phone,))
    user = cursor.fetchone()
    
    if not user:
        print(f"❌ User NOT FOUND in database!")
        print("   Action: Run create_user_sqlite.py to create the account.")
    else:
        print(f"✅ User FOUND:")
        print(f"   ID: {user[0]}")
        print(f"   Name: {user[3]}")
        
        # 2. Check password
        stored_hash = user[2]
        print(f"   Stored Hash: {stored_hash[:20]}...")
        
        if check_password(password, stored_hash):
            print(f"✅ Password verification SUCCESSFUL!")
            print("   Login should work. If it fails, check token generation or server time.")
        else:
            print(f"❌ Password verification FAILED!")
            print("   Action: Consider resetting the password.")
            
except Exception as e:
    print(f"❌ Error: {e}")
finally:
    cursor.close()
    conn.close()
