import sqlite3

def check_schema():
    try:
        conn = sqlite3.connect('database.sqlite')
        cursor = conn.cursor()
        
        # Get list of tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        
        print("Tables found:")
        for table in tables:
            table_name = table[0]
            print(f"\n--- Table: {table_name} ---")
            
            # Get columns for each table
            cursor.execute(f"PRAGMA table_info({table_name})")
            columns = cursor.fetchall()
            for col in columns:
                # cid, name, type, notnull, dflt_value, pk
                print(f"  {col[1]} ({col[2]})")
                if 'permission' in col[1].lower():
                    print(f"  !!! FOUND PERMISSION FIELD: {col[1]} !!!")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    check_schema()
