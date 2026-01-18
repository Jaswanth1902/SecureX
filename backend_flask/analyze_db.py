import sqlite3
import os
import sys

# Database Configuration
# We use the standard location
base_dir = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(base_dir, 'database.sqlite')

def analyze_database():
    print(f"\nAnalyzing Database: {DB_PATH}")
    
    if not os.path.exists(DB_PATH):
        print("X Database file not found!")
        return

    # 1. Physical File Size
    size_bytes = os.path.getsize(DB_PATH)
    size_mb = size_bytes / (1024 * 1024)
    print(f"Physical File Size: {size_mb:.2f} MB")

    try:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        # 2. Total Counts
        cursor.execute("SELECT COUNT(*) FROM files")
        total_files = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM files WHERE is_deleted = 0")
        active_files = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM files WHERE is_deleted = 1")
        soft_deleted = cursor.fetchone()[0]

        print(f"\nSUMMARY COUNTS:")
        print(f"   Total Records: {total_files}")
        print(f"   Active Files:  {active_files}")
        print(f"   Soft Deleted:  {soft_deleted}")

        # 3. Status Breakdown
        print(f"\nDETAILED STATUS BREAKDOWN (Active Files Only):")
        print(f"---------------------------------------------")
        
        cursor.execute("""
            SELECT status, COUNT(*) 
            FROM files 
            WHERE is_deleted = 0 
            GROUP BY status
            ORDER BY COUNT(*) DESC
        """)
        
        rows = cursor.fetchall()
        if not rows:
            print("   (No active files found)")
        
        for row in rows:
            print(f"   - {row[0]}: {row[1]}")

        # 4. Soft Deleted Breakdown
        if soft_deleted > 0:
            print(f"\nSOFT DELETED STATUS BREAKDOWN (Taking up space):")
            print(f"---------------------------------------------")
            cursor.execute("""
                SELECT status, COUNT(*) 
                FROM files 
                WHERE is_deleted = 1 
                GROUP BY status
                ORDER BY COUNT(*) DESC
            """)
            for row in cursor.fetchall():
                print(f"   - {row[0]}: {row[1]}")

        print(f"\n------------------------------------------------------------")
        print("EXPLANATION:")
        print("1. 'Soft Deleted' files are marked hidden but NOT removed from disk.")
        print("2. This is why the database size (81.61 MB) remains constant.")
        print("3. To recover space, you must implement a 'Hard Delete' or run 'VACUUM'.")
        print(f"------------------------------------------------------------\n")

    except Exception as e:
        print(f"Error analyzing database: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    analyze_database()
