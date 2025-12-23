import requests
import json
import sys

BASE_URL = "http://localhost:5000/api"

def run_verification():
    print("Starting verification...")
    
    # 1. Health Check
    try:
        resp = requests.get("http://localhost:5000/health")
        print(f"Health Check: {resp.status_code}")
        if resp.status_code != 200:
            print("Health check failed")
            return
    except Exception as e:
        print(f"Health check error: {e}")
        return

    # 2. Register Owner
    email = "test_owner_verify@example.com"
    password = "password123"
    payload = {
        "email": email,
        "password": password,
        "full_name": "Test Owner Verify",
        "public_key": "dummy_public_key_123"
    }
    
    print(f"Registering {email}...")
    resp = requests.post(f"{BASE_URL}/owners/register", json=payload)
    print(f"Register Status: {resp.status_code}")
    
    token = None
    if resp.status_code == 201:
        data = resp.json()
        token = data.get('accessToken')
        print("Registration successful")
    elif resp.status_code == 409:
        print("User already exists, logging in...")
        # Login
        resp = requests.post(f"{BASE_URL}/owners/login", json={
            "email": email,
            "password": password
        })
        print(f"Login Status: {resp.status_code}")
        if resp.status_code == 200:
            data = resp.json()
            token = data.get('accessToken')
            print("Login successful")
        else:
            print(f"Login failed: {resp.text}")
            return
    else:
        print(f"Registration failed: {resp.text}")
        return

    if not token:
        print("No token obtained")
        return

    # 3. List Files
    print("Listing files...")
    headers = {"Authorization": f"Bearer {token}"}
    resp = requests.get(f"{BASE_URL}/files", headers=headers)
    print(f"List Files Status: {resp.status_code}")
    if resp.status_code == 200:
        data = resp.json()
        print(f"Files found: {len(data.get('files', []))}")
        print(json.dumps(data, indent=2))
    else:
        print(f"List files failed: {resp.text}")

if __name__ == "__main__":
    run_verification()
