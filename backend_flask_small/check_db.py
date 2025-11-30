import sqlite3
import os
from dotenv import load_dotenv

load_dotenv()

# SQLite Database Configuration
DB_FILE = os.getenv('DB_FILE', 'database.sqlite')
DB_PATH = os.path.join(os.path.dirname(__file__), DB_FILE)

def check_sqlite_db():
    """Check if SQLite database exists and is accessible"""
    try:
        if not os.path.exists(DB_PATH):
            print(f"Database file not found: {DB_PATH}")
            return False
        
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        # Check if required tables exist
        cursor.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='table' 
            ORDER BY name
        """)
        
        tables = [row[0] for row in cursor.fetchall()]
        
        if not tables:
            print(f"Database exists but has no tables: {DB_PATH}")
            return False
        
        print(f"Database connected successfully: {DB_PATH}")
        print(f"\nAvailable tables ({len(tables)}):")
        for table in tables:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            print(f"   - {table}: {count} rows")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"Error connecting to database: {e}")
        return False

def get_db_stats():
    """Get detailed database statistics"""
    try:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        print(f"\n{'='*60}")
        print("DATABASE STATISTICS")
        print(f"{'='*60}\n")
        
        # File info
        file_size = os.path.getsize(DB_PATH) / 1024 / 1024  # MB
        print(f"Database file: {DB_PATH}")
        print(f"File size: {file_size:.2f} MB\n")
        
        # Table details
        expected_tables = ['users', 'owners', 'files', 'sessions']
        
        for table in expected_tables:
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {table}")
                count = cursor.fetchone()[0]
                print(f"{table.upper()}: {count} records")
            except sqlite3.OperationalError:
                print(f"{table.upper()}: Table not found")
        
        conn.close()
        
    except Exception as e:
        print(f"Error getting stats: {e}")

if __name__ == "__main__":
    print("\n" + "="*60)
    print("SQLITE DATABASE CHECK")
    print("="*60 + "\n")
    
    if check_sqlite_db():
        get_db_stats()
    else:
        print("\nDatabase check failed!")
        print("Run 'python db.py' to initialize the database.")
