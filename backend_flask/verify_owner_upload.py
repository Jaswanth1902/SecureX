import sqlite3

DB_PATH = 'database.sqlite'

def check_specific_owner():
    try:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        print("\n" + "="*60)
        print("SEARCHING FOR owner@test FILES")
        print("="*60)
        
        cursor.execute("""
            SELECT id, file_name, file_size_bytes, owner_id, created_at 
            FROM files 
            WHERE owner_id LIKE 'owner@test%'
            ORDER BY created_at DESC
        """)
        
        rows = cursor.fetchall()
        
        if not rows:
            print("No files found for owner@test")
        else:
            print(f"Found {len(rows)} files for owner@test:\n")
            for row in rows:
                print(f"File: {row['file_name']}")
                print(f"   Owner: {row['owner_id']}")
                print(f"   Time: {row['created_at']}")
                print("-" * 40)
                
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    check_specific_owner()
