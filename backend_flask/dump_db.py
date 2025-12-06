import sqlite3
import os

DB_FILE = 'database.sqlite'
OUTPUT_FILE = 'DATABASE_DUMP.md'

def dump_database_md():
    if not os.path.exists(DB_FILE):
        print(f"❌ Database file not found: {DB_FILE}")
        return

    try:
        conn = sqlite3.connect(DB_FILE)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        # Get all tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
        tables = [row[0] for row in cursor.fetchall()]

        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            f.write(f"# Database Dump: {DB_FILE}\n\n")
            
            for table in tables:
                f.write(f"## Table: `{table}`\n\n")
                
                # Get columns
                cursor.execute(f"PRAGMA table_info({table})")
                columns = [col[1] for col in cursor.fetchall()]
                
                # Get rows
                cursor.execute(f"SELECT * FROM {table}")
                rows = cursor.fetchall()
                
                if not rows:
                    f.write("*(No data)*\n\n")
                    continue
                
                # Write Markdown Table Header
                f.write("| " + " | ".join(columns) + " |\n")
                f.write("| " + " | ".join(["---"] * len(columns)) + " |\n")
                
                # Write Rows
                for row in rows:
                    # Convert values to string and escape pipes
                    values = [str(val).replace('|', '\|').replace('\n', '<br>') for val in row]
                    f.write("| " + " | ".join(values) + " |\n")
                
                f.write("\n")

        conn.close()
        print(f"Database dump written to {OUTPUT_FILE}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    dump_database_md()
