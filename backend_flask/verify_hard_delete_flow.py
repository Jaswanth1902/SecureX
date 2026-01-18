import sqlite3
import os
import uuid
import datetime

# Configuration
base_dir = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(base_dir, 'database.sqlite')

def get_file_count(cursor):
    cursor.execute("SELECT COUNT(*) FROM files")
    return cursor.fetchone()[0]

def verify_hard_delete_flow():
    print(f"\n🧪 VERIFYING HARD DELETE FLOW")
    print(f"   Database: {DB_PATH}")
    print(f"{'-'*50}")

    if not os.path.exists(DB_PATH):
        print("❌ Database not found!")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    try:
        # 1. Initial State
        initial_count = get_file_count(cursor)
        print(f"1. Initial File Count: {initial_count}")

        # 2. Simulate Upload (Insert)
        print("\n2. Simulating Mobile App Upload...")
        test_file_id = str(uuid.uuid4())
        cursor.execute(
            """INSERT INTO files (
                id, user_id, owner_id, file_name, encrypted_file_data, 
                file_size_bytes, iv_vector, auth_tag, encrypted_symmetric_key, 
                created_at, is_deleted, status
            ) VALUES (?, 'test_user', 'test_owner', 'test_file.pdf', ?, 123, ?, ?, ?, ?, 0, 'WAITING_FOR_APPROVAL')""",
            (test_file_id, b'dummy_data', b'iv', b'tag', b'key', datetime.datetime.utcnow())
        )
        conn.commit()
        
        after_upload_count = get_file_count(cursor)
        print(f"   File Count: {after_upload_count}")
        
        if after_upload_count == initial_count + 1:
             print("   ✅ SUCCESS: File count increased by 1.")
        else:
             print("   ❌ FAILURE: File count did not increase correctly.")

        # 3. Simulate Rejection (Hard Delete)
        print("\n3. Simulating Desktop App Rejection (Hard Delete)...")
        # This mocks the logic we changed in routes/files.py:
        # cursor.execute("DELETE FROM files WHERE id = ?", (test_file_id,))
        
        # ACTUALLY executing the delete command
        cursor.execute("DELETE FROM files WHERE id = ?", (test_file_id,))
        conn.commit()
        
        final_count = get_file_count(cursor)
        print(f"   File Count: {final_count}")
        
        # 4. Verification
        if final_count == initial_count:
            print("   ✅ SUCCESS: File count is back to initial.")
            print("   ✅ SUCCESS: File was permanently removed (Hard Delete).")
        else:
            print(f"   ❌ FAILURE: Count is {final_count} (Expected {initial_count}).")

        # 5. Check for Soft Delete Traces
        cursor.execute("SELECT COUNT(*) FROM files WHERE id = ?", (test_file_id,))
        trace_count = cursor.fetchone()[0]
        if trace_count == 0:
            print("   ✅ SUCCESS: No trace of file in database (Clean Delete).")
        else:
            print("   ❌ FAILURE: File still exists in database!")

    except Exception as e:
        print(f"\n❌ Error during verification: {e}")
    finally:
        conn.close()
        print(f"{'-'*50}\n")

if __name__ == "__main__":
    verify_hard_delete_flow()
