"""
Direct test of registration endpoint
"""
import requests
import json

# Test registration
url = "http://127.0.0.1:5000/api/auth/register"
payload = {
    "phone": "9876543210",
    "password": "testpass123",
    "full_name": "Test User"
}

print("=" * 60)
print("Testing Registration Endpoint")
print("=" * 60)
print(f"URL: {url}")
print(f"Payload: {json.dumps(payload, indent=2)}")
print()

try:
    response = requests.post(url, json=payload, timeout=10)
    print(f"Status Code: {response.status_code}")
    print(f"Response Headers: {dict(response.headers)}")
    print(f"Response Body: {response.text}")
    
    if response.status_code in [200, 201]:
        print("\n✅ Registration successful!")
        data = response.json()
        print(f"Access Token: {data.get('accessToken', 'N/A')[:20]}...")
        print(f"User ID: {data.get('user', {}).get('id', 'N/A')}")
    else:
        print("\n❌ Registration failed!")
        try:
            print(f"Error Response: {response.json()}")
        except:
            print(f"Raw Response: {response.text}")
            
except requests.exceptions.ConnectionError:
    print("❌ Connection error: Cannot connect to backend")
    print("   Is the Flask server running on http://127.0.0.1:5000?")
except Exception as e:
    print(f"❌ Error: {e}")
