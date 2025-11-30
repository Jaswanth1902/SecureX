import sqlite3
import os

DB_PATH = 'database.sqlite'

def fix_owner_ids():
    if not os.path.exists(DB_PATH):
        print(f"Database not found at {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    print("Fixing owner IDs in 'files' table...")

    # Get all owners
    cursor.execute("SELECT id, email FROM owners")
    owners = cursor.fetchall()

    updated_count = 0

    for owner_id, email in owners:
        print(f"Checking for files owned by email '{email}' (should be '{owner_id}')...")
        
        # Update files where owner_id matches the email
        cursor.execute("UPDATE files SET owner_id = ? WHERE owner_id = ?", (owner_id, email))
        if cursor.rowcount > 0:
            print(f"  -> Updated {cursor.rowcount} files.")
            updated_count += cursor.rowcount

    conn.commit()
    conn.close()
    print(f"\nDone. Total files updated: {updated_count}")

if __name__ == "__main__":
    fix_owner_ids()
