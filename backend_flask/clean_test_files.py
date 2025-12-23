"""
Clear old test files and prepare database for authenticated uploads
Run this on the SERVER LAPTOP
"""
import sqlite3

conn = sqlite3.connect('database.sqlite')
cursor = conn.cursor()

print("\n" + "="*60)
print("CLEARING OLD TEST FILES")
print("="*60)

# Check current files
cursor.execute("SELECT COUNT(*) FROM files WHERE user_id = 'test-user-id-for-development'")
test_file_count = cursor.fetchone()[0]

cursor.execute("SELECT COUNT(*) FROM files")
total_files = cursor.fetchone()[0]

print(f"\nCurrent database state:")
print(f"  Total files: {total_files}")
print(f"  Test files (old): {test_file_count}")
print(f"  Real user files: {total_files - test_file_count}")

if test_file_count > 0:
    print(f"\n⚠️  Found {test_file_count} files with hardcoded test user_id")
    print("   These won't appear in mobile app job history.")
    print("\n   Options:")
    print("   1. Delete them (recommended)")
    print("   2. Keep them for reference")
    
    response = input("\n   Delete old test files? (yes/no): ").strip().lower()
    
    if response == 'yes':
        cursor.execute("DELETE FROM files WHERE user_id = 'test-user-id-for-development'")
        conn.commit()
        deleted = cursor.rowcount
        print(f"\n   ✅ Deleted {deleted} test files")
        print("\n   Database is now clean!")
    else:
        print("\n   ⏭️  Keeping old files (they won't appear in mobile app)")
else:
    print("\n✅ No test files found - database is clean!")

conn.close()

print("\n" + "="*60)
print("NEXT STEPS")
print("="*60)
print("1. Restart Flask server with updated code")
print("2. Upload a file from mobile app")
print("3. File should appear in job history immediately")
print("="*60 + "\n")
