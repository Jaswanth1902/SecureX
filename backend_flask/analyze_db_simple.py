import sqlite3
import os
import sys

# Hardcoded for debugging
DB_PATH = r"C:\Users\jaswa\Downloads\SafeCopy\backend_flask\database.sqlite"

print(f"Checking: {DB_PATH}")

if not os.path.exists(DB_PATH):
    print("Does not exist")
    sys.exit(1)

size = os.path.getsize(DB_PATH) / (1024*1024)
print(f"Size: {size:.2f} MB")

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

cursor.execute("SELECT COUNT(*) FROM files")
total = cursor.fetchone()[0]
print(f"Total: {total}")

cursor.execute("SELECT COUNT(*) FROM files WHERE is_deleted=0")
active = cursor.fetchone()[0]
print(f"Active: {active}")

cursor.execute("SELECT COUNT(*) FROM files WHERE is_deleted=1")
soft = cursor.fetchone()[0]
print(f"SoftDel: {soft}")

print("--- Status (Active) ---")
cursor.execute("SELECT status, COUNT(*) FROM files WHERE is_deleted=0 GROUP BY status")
for row in cursor.fetchall():
    print(f"{row[0]}: {row[1]}")

print("--- Status (SoftDel) ---")
cursor.execute("SELECT status, COUNT(*) FROM files WHERE is_deleted=1 GROUP BY status")
for row in cursor.fetchall():
    print(f"{row[0]}: {row[1]}")

conn.close()
