#!/usr/bin/env python3
"""
Script to clear all owner accounts from the database.
This will delete all records from the owners table.
"""

import sqlite3
import os

DB_FILE = 'database.sqlite'

def clear_owners():
    """Delete all owner accounts from the database."""
    if not os.path.exists(DB_FILE):
        print(f"Error: Database file '{DB_FILE}' not found!")
        return False
    
    try:
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        
        # Count owners before deletion
        cursor.execute("SELECT COUNT(*) FROM owners")
        count_before = cursor.fetchone()[0]
        print(f"Found {count_before} owner account(s) in the database.")
        
        if count_before == 0:
            print("No owners to delete.")
            conn.close()
            return True
        
        # Delete all owners
        cursor.execute("DELETE FROM owners")
        conn.commit()
        
        # Verify deletion
        cursor.execute("SELECT COUNT(*) FROM owners")
        count_after = cursor.fetchone()[0]
        
        print(f"\nDeleted {count_before - count_after} owner account(s).")
        print(f"Remaining owners: {count_after}")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"Error clearing owners: {e}")
        return False

if __name__ == "__main__":
    print("=" * 50)
    print("CLEAR ALL OWNER ACCOUNTS")
    print("=" * 50)
    print("\nThis will delete ALL owner accounts from the database.")
    
    confirm = input("Are you sure you want to continue? (yes/no): ")
    
    if confirm.lower() == 'yes':
        success = clear_owners()
        if success:
            print("\nOwner accounts cleared successfully!")
        else:
            print("\nFailed to clear owner accounts.")
    else:
        print("\nOperation cancelled.")
