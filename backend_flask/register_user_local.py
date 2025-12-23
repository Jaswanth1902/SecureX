"""
Direct user registration via localhost
"""
import requests
import json

url = "http://127.0.0.1:5000/api/auth/register"
payload = {
    "phone": "7013944675",
    "password": "jas123",
    "full_name": "Test User"
}

print("Registering user locally...")
print(f"URL: {url}")
print(f"Phone: {payload['phone']}")

try:
    response = requests.post(url, json=payload, timeout=5)
    print(f"\nStatus: {response.status_code}")
    print(f"Response: {response.text}")
    
    if response.status_code == 201:
        print("\n✅ User created successfully!")
    elif response.status_code == 409:
        print("\n⚠️  User already exists!")
    else:
        print(f"\n❌ Failed: {response.status_code}")
except Exception as e:
    print(f"\n❌ Error: {e}")
