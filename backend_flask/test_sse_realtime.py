import requests
import json
import threading
import time
import base64
import os
import sys

# Fix Windows console encoding
if sys.platform == 'win32':
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')
    sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'strict')

BASE_URL = "http://localhost:5000"
event_received = threading.Event()
received_data = {}

def sse_listener(token):
    print("Listener: Connecting to SSE stream...")
    headers = {'Authorization': f'Bearer {token}', 'Accept': 'text/event-stream'}
    try:
        with requests.get(f"{BASE_URL}/api/events/stream", headers=headers, stream=True) as response:
            print(f"Listener: Connected! Status code: {response.status_code}")
            if response.status_code != 200:
                print(f"Listener failed: {response.text}")
                return

            for line in response.iter_lines():
                if line:
                    decoded_line = line.decode('utf-8')
                    # print(f"🎧 Stream: {decoded_line}")
                    
                    if decoded_line.startswith('event: new_file'):
                        print("Listener: Received 'new_file' event!")
                    elif decoded_line.startswith('data: '):
                        data_str = decoded_line[6:]
                        try:
                            data = json.loads(data_str)
                            if 'file_name' in data:
                                print(f"Listener: File details received: {data['file_name']}")
                                global received_data
                                received_data = data
                                event_received.set()
                                return # Exit after receiving the event
                        except:
                            pass
    except Exception as e:
        print(f"Listener error: {e}")

def run_test():
    print("\n" + "="*60)
    print("TESTING REAL-TIME NOTIFICATIONS (SSE)")
    print("="*60 + "\n")

    # 1. Login
    print("[1/3] Logging in...")
    login_resp = requests.post(f"{BASE_URL}/api/owners/login", json={
        "email": "test-owner-new@example.com",
        "password": "test123"
    })
    
    if login_resp.status_code != 200:
        print("Login failed")
        return
        
    token = login_resp.json()['accessToken']
    owner_id = login_resp.json()['owner']['id']
    print("Login successful")

    # 2. Start Listener Thread
    print("[2/3] Starting SSE listener thread...")
    t = threading.Thread(target=sse_listener, args=(token,))
    t.daemon = True
    t.start()
    
    time.sleep(2) # Give it time to connect

    # 3. Upload File
    print("[3/3] Uploading file to trigger notification...")
    iv = base64.b64encode(os.urandom(16)).decode('utf-8')
    auth_tag = base64.b64encode(os.urandom(16)).decode('utf-8')
    encrypted_key = base64.b64encode(os.urandom(32)).decode('utf-8')
    
    files = {'file': ('sse_test.pdf', b'SSE Test Content', 'application/pdf')}
    data = {
        'file_name': 'sse_test.pdf',
        'iv_vector': iv,
        'auth_tag': auth_tag,
        'encrypted_symmetric_key': encrypted_key,
        'owner_id': owner_id
    }
    
    requests.post(f"{BASE_URL}/api/upload", files=files, data=data)
    
    # 4. Wait for event
    print("Waiting for notification...")
    if event_received.wait(timeout=5):
        print("\n" + "="*60)
        print("SUCCESS! Real-time notification received.")
        print(f"File: {received_data.get('file_name')}")
        print(f"Size: {received_data.get('file_size_bytes')} bytes")
        print("="*60 + "\n")
    else:
        print("\n" + "="*60)
        print("FAILED: Notification timed out.")
        print("="*60 + "\n")

if __name__ == "__main__":
    run_test()
