import sqlite3
import os

DB_FILE = 'database.sqlite'

def clear_database():
    print("Clearing all data from database...")
    if not os.path.exists(DB_FILE):
        print(f"Database file not found: {DB_FILE}")
        return

    try:
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        
        # Disable foreign key constraints to allow deletion in any order
        cursor.execute("PRAGMA foreign_keys = OFF;")
        
        tables = ['files', 'sessions', 'owners', 'users']
        
        for table in tables:
            try:
                cursor.execute(f"DELETE FROM {table}")
                print(f"Cleared table: {table}")
            except sqlite3.OperationalError as e:
                print(f"Error clearing table {table} (might not exist): {e}")
        
        conn.commit()
        # Re-enable foreign key constraints
        cursor.execute("PRAGMA foreign_keys = ON;")
        conn.close()
        print("Database cleared successfully.")
    except Exception as e:
        print(f"Error clearing database: {e}")

if __name__ == "__main__":
    clear_database()
