"""
Migrate database.sqlite from email to phone
"""
import sqlite3
import shutil
from datetime import datetime

# Backup the old database first
backup_name = f'database.sqlite.backup_{datetime.now().strftime("%Y%m%d_%H%M%S")}'
shutil.copy('database.sqlite', backup_name)
print(f'[BACKUP] Created backup: {backup_name}')

# Connect to database
conn = sqlite3.connect('database.sqlite')
cursor = conn.cursor()

try:
    # Check current schema
    cursor.execute("PRAGMA table_info(users)")
    columns = [col[1] for col in cursor.fetchall()]
    print(f'[INFO] Current users columns: {columns}')
    
    if 'email' in columns and 'phone' not in columns:
        print('[MIGRATE] Renaming email column to phone...')
        
        # SQLite doesn't support ALTER COLUMN, so we need to recreate the table
        # 1. Create new users table with phone column
        cursor.execute("""
            CREATE TABLE users_new (
                id TEXT PRIMARY KEY,
                phone TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                full_name TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # 2. Copy data from old table to new table
        cursor.execute("""
            INSERT INTO users_new (id, phone, password_hash, full_name, created_at, updated_at)
            SELECT id, email, password_hash, full_name, created_at, updated_at
            FROM users
        """)
        
        # 3. Drop old table
        cursor.execute("DROP TABLE users")
        
        # 4. Rename new table to users
        cursor.execute("ALTER TABLE users_new RENAME TO users")
        
        # 5. Recreate index
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone)")
        
        conn.commit()
        print('[SUCCESS] Migration complete!')
        print('[INFO] Column "email" has been renamed to "phone"')
        
    elif 'phone' in columns:
        print('[INFO] Database already has "phone" column - no migration needed')
    else:
        print('[ERROR] Unexpected schema - manual intervention required')
        
except Exception as e:
    conn.rollback()
    print(f'[ERROR] Migration failed: {e}')
    import traceback
    traceback.print_exc()
finally:
    cursor.close()
    conn.close()

print('\n[DONE] You can now restart the Flask server')
