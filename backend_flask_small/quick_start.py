import subprocess
import time
import sys
import os
import threading
import sqlite3

def stream_output(process, prefix):
    """Stream output from a process to stdout with a prefix"""
    for line in iter(process.stdout.readline, ''):
        if line:
            print(f"[{prefix}] {line.strip()}")

def check_owner(email):
    """Check if an owner exists in the database"""
    print(f"Checking for owner: {email}...")
    db_path = os.path.join(os.getcwd(), 'database.sqlite')
    
    if not os.path.exists(db_path):
        print(f"❌ Database not found at {db_path}")
        return False
        
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT id, full_name FROM owners WHERE email = ?", (email,))
        row = cursor.fetchone()
        conn.close()
        
        if row:
            print(f"Owner found: {row[1]} (ID: {row[0]})")
            return True
        else:
            print(f"Owner '{email}' NOT found in database.")
            print("   Please register this account using the Desktop App or create_owner script.")
            return False
    except Exception as e:
        print(f"Error checking database: {e}")
        return False

def start_server():
    print("Starting Flask Server...")
    # Run app.py
    server_process = subprocess.Popen(
        [sys.executable, 'app.py'],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        cwd=os.getcwd()
    )
    
    # Start a thread to print server output
    t = threading.Thread(target=stream_output, args=(server_process, "SERVER"))
    t.daemon = True
    t.start()
    
    return server_process

def start_monitor():
    print("Starting File Monitor...")
    # Run monitor_uploads.py
    monitor_process = subprocess.Popen(
        [sys.executable, 'monitor_uploads.py'],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        cwd=os.getcwd()
    )
    
    # Start a thread to print monitor output
    t = threading.Thread(target=stream_output, args=(monitor_process, "MONITOR"))
    t.daemon = True
    t.start()
    
    return monitor_process

def main():
    print("="*60)
    print("SAFECOPY QUICK START SERVER")
    print("="*60)
    
    # Check for specific owner
    check_owner("surya@gmail.com")
    print("-" * 60)
    
    print("Starting backend and file monitor...\n")
    
    try:
        server = start_server()
        # Wait a bit for server to initialize
        time.sleep(2)
        monitor = start_monitor()
        
        print("\nSystem is RUNNING!")
        print("   - Server: http://localhost:5000")
        print("   - Monitor: Watching for new files")
        print("\nPress Ctrl+C to stop everything.\n")
        
        # Keep main thread alive
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\n\n🛑 Stopping services...")
        if 'server' in locals():
            server.terminate()
        if 'monitor' in locals():
            monitor.terminate()
        print("Goodbye!")
        sys.exit(0)

if __name__ == "__main__":
    main()
