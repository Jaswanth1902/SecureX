import os
import sqlite3
from dotenv import load_dotenv

load_dotenv()

# Database Configuration
DB_FILE = os.getenv('DB_FILE', 'database.sqlite')
DB_PATH = os.path.join(os.path.dirname(__file__), DB_FILE)

def init_database():
    """Initialize SQLite database and create tables"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # Return rows as dictionaries
    
    # Read and execute schema
    schema_path = os.path.join(os.path.dirname(__file__), 'schema_sqlite.sql')
    with open(schema_path, 'r') as f:
        schema = f.read()
    
    conn.executescript(schema)
    conn.commit()
    print(f"✅ SQLite database initialized at: {DB_PATH}")
    return conn

def get_db_connection():
    """Get a database connection"""
    try:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        raise e

def release_db_connection(conn):
    """Release a database connection"""
    if conn:
        try:
            conn.close()
        except Exception as e:
            print(f"Error closing connection: {e}")

def close_db_pool():
    """Placeholder for compatibility with PostgreSQL version"""
    pass

# Initialize database on import
if not os.path.exists(DB_PATH):
    print(f"Creating new SQLite database at: {DB_PATH}")
    init_database()
else:
    print(f"Using existing SQLite database at: {DB_PATH}")
