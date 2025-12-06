import sqlite3
import os

def show_all_files():
    db_path = 'database.sqlite'
    
    if not os.path.exists(db_path):
        print(f"Database not found at {db_path}")
        return
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Get all files
        cursor.execute("""
            SELECT id, file_name, file_size_bytes, created_at, deleted_at,
                   is_deleted, is_printed, status, owner_id
            FROM files 
            ORDER BY created_at DESC
        """)
        
        files = cursor.fetchall()
        
        print(f"\n{'='*100}")
        print(f"Total files in database: {len(files)}")
        print(f"{'='*100}\n")
        
        if len(files) == 0:
            print("No files found in database.")
            return
        
        for idx, row in enumerate(files, 1):
            file_id, name, size, created, deleted, is_del, is_print, status, owner = row
            
            print(f"{idx}. {name}")
            print(f"   ID: {file_id}")
            print(f"   Size: {size:,} bytes ({size/1024:.1f} KB)")
            print(f"   Status: {status}")
            print(f"   Deleted: {'Yes' if is_del else 'No'}")
            print(f"   Printed: {'Yes' if is_print else 'No'}")
            print(f"   Created: {created}")
            if deleted:
                print(f"   Deleted at: {deleted}")
            print(f"   Owner: {owner}")
            print()
        
        # Summary
        active_files = sum(1 for f in files if not f[5])  # is_deleted = 0
        deleted_files = sum(1 for f in files if f[5])     # is_deleted = 1
        
        print(f"{'='*100}")
        print(f"Summary:")
        print(f"  Active files: {active_files}")
        print(f"  Deleted files (history): {deleted_files}")
        print(f"{'='*100}")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    show_all_files()
