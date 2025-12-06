import sqlite3
import time
import datetime
import sys

DB_PATH = 'database.sqlite'
OWNERS = ['surya@gmail.com']
SEEN_IDS = set()

def monitor():
    print("\n" + "="*60)
    print("MONITORING FOR NEW UPLOADS...")
    print(f"Checking for owners: {', '.join(OWNERS)}")
    print("Press Ctrl+C to stop")
    print("="*60 + "\n")

    # Pre-load existing IDs so we only show NEW ones
    try:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        # Show last 3 recent files on startup
        print("RECENT FILES:")
        cursor.execute("""
            SELECT id, file_name, file_size_bytes, owner_id, created_at 
            FROM files 
            ORDER BY created_at DESC 
            LIMIT 3
        """)
        for row in cursor.fetchall():
            print(f"   - {row['created_at']} | {row['file_name']} ({row['owner_id']})")
            SEEN_IDS.add(row['id'])
            
        # Load all other IDs to avoid duplicates
        cursor.execute("SELECT id FROM files")
        for row in cursor.fetchall():
            SEEN_IDS.add(row[0])
            
        conn.close()
        print("-" * 60)
        sys.stdout.flush()
    except Exception as e:
        print(f"Error loading initial state: {e}")

    while True:
        try:
            conn = sqlite3.connect(DB_PATH)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            # Check for both owners (using partial match for flexibility)
            placeholders = ','.join(['?'] * len(OWNERS))
            
            cursor.execute("""
                SELECT id, file_name, file_size_bytes, owner_id, created_at 
                FROM files 
                ORDER BY created_at ASC
            """)
            
            rows = cursor.fetchall()
            
            for row in rows:
                file_id = row['id']
                owner = row['owner_id']
                
                # Check if it's one of our target owners (or close match)
                is_target = any(o in owner for o in ['surya@gmail.com'])
                
                if file_id not in SEEN_IDS and is_target:
                    print(f"\nNEW FILE RECEIVED!")
                    print(f"   Time:  {row['created_at']}")
                    print(f"   File:  {row['file_name']}")
                    print(f"   Size:  {row['file_size_bytes']} bytes")
                    print(f"   Owner: {owner}")
                    print("-" * 40)
                    sys.stdout.flush() # Force print
                    SEEN_IDS.add(file_id)
            
            conn.close()
            time.sleep(2)
            
        except KeyboardInterrupt:
            print("\nStopping monitor...")
            break
        except Exception as e:
            print(f"Error: {e}")
            time.sleep(2)

if __name__ == "__main__":
    monitor()
