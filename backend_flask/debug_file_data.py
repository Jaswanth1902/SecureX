import sqlite3
import base64
import os

DB_PATH = 'database.sqlite'

def check_last_file():
    if not os.path.exists(DB_PATH):
        print(f"Error: Database not found at {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    try:
        # Get the most recent file
        cursor.execute("""
            SELECT id, file_name, encrypted_file_data, iv_vector, auth_tag, encrypted_symmetric_key
            FROM files
            ORDER BY created_at DESC
            LIMIT 1
        """)
        row = cursor.fetchone()

        if not row:
            print("No files found in the database.")
            return

        file_id, file_name, enc_data, iv, auth_tag, enc_key = row

        print(f"\n--- Inspecting File: {file_name} ({file_id}) ---")

        # Helper to check and print
        def inspect_field(name, data):
            print(f"\n[{name}]")
            print(f"  Type: {type(data)}")
            if data is None:
                print("  Value: None (CRITICAL ERROR)")
                return
            
            print(f"  Length: {len(data)} bytes")
            
            if isinstance(data, bytes):
                print("  Format: BYTES (Correct)")
                # Try to encode to Base64 to see if it works
                try:
                    b64 = base64.b64encode(data).decode('utf-8')
                    print(f"  Base64 Test: Success (First 20 chars: {b64[:20]}...)")
                except Exception as e:
                    print(f"  Base64 Test: FAILED ({e})")
            else:
                print(f"  Format: {type(data)} (POSSIBLE ERROR - Should be bytes)")
                print(f"  Value (First 50): {str(data)[:50]}")

        inspect_field("Encrypted File Data", enc_data)
        inspect_field("IV Vector", iv)
        inspect_field("Auth Tag", auth_tag)
        inspect_field("Encrypted Symmetric Key", enc_key)

    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    check_last_file()
