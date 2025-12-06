import sqlite3
import datetime

DB_PATH = 'database.sqlite'

def check_uploads():
    try:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        print("\n" + "="*60)
        print("CHECKING RECENT FILE UPLOADS")
        print("="*60)
        
        cursor.execute("""
            SELECT id, file_name, file_size_bytes, owner_id, created_at 
            FROM files 
            ORDER BY created_at DESC 
            LIMIT 5
        """)
        
        rows = cursor.fetchall()
        
        if not rows:
            print("No files found in database!")
        else:
            print(f"Found {len(rows)} recent files:\n")
            for row in rows:
                print(f"File: {row['file_name']}")
                print(f"   ID: {row['id']}")
                print(f"   Size: {row['file_size_bytes']} bytes")
                print(f"   Owner: {row['owner_id']}")
                print(f"   Time: {row['created_at']}")
                print("-" * 40)
                
    except Exception as e:
        print(f"Error reading database: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    check_uploads()
