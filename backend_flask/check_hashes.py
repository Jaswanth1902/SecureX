import sqlite3
import os

DB_PATH = 'database.sqlite'

def check_hashes():
    if not os.path.exists(DB_PATH):
        print(f"Database not found at {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    print("Checking Users...")
    try:
        cursor.execute("SELECT id, phone, password_hash FROM users")
        users = cursor.fetchall()
        for u in users:
            uid, phone, pwd_hash = u
            if pwd_hash.startswith('$2b$'):
                 print(f"[PASS] User {phone}: Hash starts with $2b$")
            else:
                 print(f"[FAIL] User {phone}: Hash DOES NOT start with $2b$. Hash: {pwd_hash[:10]}...")
    except Exception as e:
        print(f"Error checking users: {e}")

    print("\nChecking Owners...")
    try:
        cursor.execute("SELECT id, email, password_hash FROM owners")
        owners = cursor.fetchall()
        for o in owners:
            oid, email, pwd_hash = o
            # Skip owners with empty password (e.g. Google Auth only)
            if not pwd_hash:
                print(f"[INFO] Owner {email}: No password set (likely OAuth)")
                continue

            if pwd_hash.startswith('$2b$'):
                 print(f"[PASS] Owner {email}: Hash starts with $2b$")
            else:
                 print(f"[FAIL] Owner {email}: Hash DOES NOT start with $2b$. Hash: {pwd_hash[:10]}...")
    except Exception as e:
        print(f"Error checking owners: {e}")

    conn.close()

if __name__ == "__main__":
    check_hashes()
