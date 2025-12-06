"""
Database Migration: Add Status Tracking to Files Table

This script adds status tracking fields to existing databases.
Safe to run multiple times (uses ALTER TABLE IF NOT EXISTS where possible).
"""

import sqlite3
import os
from datetime import datetime

# Database path
DB_FILE = os.getenv('DB_FILE', 'database.sqlite')
DB_PATH = os.path.join(os.path.dirname(__file__), DB_FILE)

def migrate_database():
    """Add status tracking fields to files table"""
    
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found at: {DB_PATH}")
        print("   Run the server first to create the database, then run this migration.")
        return
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        # Check if status column already exists
        cursor.execute("PRAGMA table_info(files)")
        columns = [col[1] for col in cursor.fetchall()]
        
        if 'status' in columns:
            print("✅ Status columns already exist. Skipping migration.")
            return
        
        print("📝 Adding status tracking columns...")
        
        # Add status column with default value
        cursor.execute("""
            ALTER TABLE files 
            ADD COLUMN status TEXT DEFAULT 'WAITING_FOR_APPROVAL'
        """)
        
        # Add status_updated_at column
        cursor.execute("""
            ALTER TABLE files 
            ADD COLUMN status_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        """)
        
        # Add rejection_reason column
        cursor.execute("""
            ALTER TABLE files 
            ADD COLUMN rejection_reason TEXT
        """)
        
        print("📝 Creating index on status field...")
        
        # Create index on status
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_files_status ON files(status)
        """)
        
        print("📝 Migrating existing data...")
        
        # Update existing records based on is_printed flag
        # If printed, set status to PRINT_COMPLETED
        cursor.execute("""
            UPDATE files 
            SET status = 'PRINT_COMPLETED', 
                status_updated_at = printed_at 
            WHERE is_printed = 1
        """)
        
        # If deleted but not printed, set to CANCELLED
        cursor.execute("""
            UPDATE files 
            SET status = 'CANCELLED', 
                status_updated_at = deleted_at 
            WHERE is_deleted = 1 AND is_printed = 0
        """)
        
        # If not printed and not deleted, set to WAITING_FOR_APPROVAL
        cursor.execute("""
            UPDATE files 
            SET status = 'WAITING_FOR_APPROVAL',
                status_updated_at = created_at
            WHERE is_printed = 0 AND is_deleted = 0
        """)
        
        rows_affected = cursor.rowcount
        
        conn.commit()
        
        print(f"✅ Migration completed successfully!")
        print(f"   - Added 3 new columns: status, status_updated_at, rejection_reason")
        print(f"   - Created index on status field")
        print(f"   - Migrated {rows_affected} existing records")
        
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e).lower():
            print("✅ Columns already exist. No migration needed.")
        else:
            print(f"❌ Migration failed: {e}")
            conn.rollback()
            raise
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    print("=" * 60)
    print("STATUS TRACKING MIGRATION")
    print("=" * 60)
    print(f"Database: {DB_PATH}")
    print()
    
    migrate_database()
    
    print()
    print("=" * 60)
