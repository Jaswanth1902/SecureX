import sqlite3
import os

db_path = 'database.sqlite'

if not os.path.exists(db_path):
    print(f"Database not found at {db_path}")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Get all tables
cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
tables = cursor.fetchall()

for table in tables:
    table_name = table[0]
    print(f"\n--- Table: {table_name} ---")
    
    # Get columns
    cursor.execute(f"PRAGMA table_info({table_name})")
    columns = [info[1] for info in cursor.fetchall()]
    print(f"Columns: {', '.join(columns)}")
    
    # Get data
    cursor.execute(f"SELECT * FROM {table_name}")
    rows = cursor.fetchall()
    
    if not rows:
        print("v No data found in this table.")
    else:
        for row in rows:
            print(row)

conn.close()
