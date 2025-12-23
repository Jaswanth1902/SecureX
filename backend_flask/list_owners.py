import sqlite3
import os

DB_FILE = 'database.sqlite'

def list_owners():
    if not os.path.exists(DB_FILE):
        print(f"Database file not found: {DB_FILE}")
        return

    try:
        conn = sqlite3.connect(DB_FILE)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        cursor.execute("SELECT id, email, full_name, created_at FROM owners")
        owners = cursor.fetchall()

        if not owners:
            print("No owners found.")
        else:
            print(f"Found {len(owners)} owner(s):")
            print("-" * 60)
            print(f"{'Name':<25} | {'Email':<30} | {'ID'}")
            print("-" * 60)
            for owner in owners:
                print(f"{owner['full_name']:<25} | {owner['email']:<30} | {owner['id']}")
            print("-" * 60)

        conn.close()

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    list_owners()
