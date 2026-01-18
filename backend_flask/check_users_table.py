"""
Check database schema and verify users table
"""
import sqlite3
import os

db_path = os.path.join(os.path.dirname(__file__), 'database.sqlite')

try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    print("=" * 60)
    print("Checking Database Schema")
    print("=" * 60)
    
    # Get table info
    cursor.execute("PRAGMA table_info(users);")
    columns = cursor.fetchall()
    
    print("\n✅ Users table columns:")
    for col in columns:
        print(f"   - {col[1]} ({col[2]})")
    
    # Count users
    cursor.execute("SELECT COUNT(*) FROM users;")
    count = cursor.fetchone()[0]
    print(f"\n📊 Total users in database: {count}")
    
    # List all users
    if count > 0:
        print("\n📋 All users:")
        cursor.execute("SELECT id, phone, full_name, created_at FROM users;")
        users = cursor.fetchall()
        for user in users:
            print(f"   - {user[1]} ({user[2]}) - Created: {user[3]}")
    
    conn.close()
    print("\n✅ Database check complete!")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
