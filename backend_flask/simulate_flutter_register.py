"""
Simulate what the Flutter app does when calling register endpoint
Mimics the exact code flow from api_service.dart
"""
import requests
import json
from requests.exceptions import ConnectionError, Timeout

def test_register():
    base_url = 'http://192.168.0.103:5000'
    phone = '7013944675'
    password = 'test123'
    full_name = 'Test User'
    
    # Build URL and request
    url = f'{base_url}/api/auth/register'
    headers = {'Content-Type': 'application/json'}
    body = {
        'phone': phone,
        'password': password,
        'full_name': full_name,
    }
    
    print("=" * 60)
    print("Simulating Flutter App Registration Request")
    print("=" * 60)
    print(f"URL: {url}")
    print(f"Headers: {headers}")
    print(f"Body: {json.dumps(body, indent=2)}")
    print()
    
    try:
        print("🔄 Sending POST request...")
        response = requests.post(
            url,
            headers=headers,
            json=body,
            timeout=10
        )
        
        print(f"📨 Response Status Code: {response.status_code}")
        print(f"📨 Response Headers: {dict(response.headers)}")
        print(f"📨 Response Body: {response.text}")
        print()
        
        # Check if it's what we expect
        if response.status_code == 201:
            try:
                data = response.json()
                print("✅ Registration successful!")
                print(f"   Access Token: {data.get('accessToken', 'N/A')[:30]}...")
                print(f"   User ID: {data.get('user', {}).get('id', 'N/A')}")
                print(f"   Phone: {data.get('user', {}).get('phone', 'N/A')}")
            except json.JSONDecodeError as e:
                print(f"❌ Failed to parse successful response: {e}")
        else:
            try:
                data = response.json()
                print(f"❌ Registration failed with status {response.status_code}")
                print(f"   Error: {data}")
            except json.JSONDecodeError:
                print(f"❌ Failed to parse error response")
                print(f"   Raw response: {response.text}")
        
    except ConnectionError:
        print("❌ Connection Error: Cannot reach the backend")
        print("   Check that:")
        print("   1. Backend is running on port 5000")
        print("   2. IP address 192.168.0.103 is correct")
        print("   3. Device/app can route to that IP")
    except Timeout:
        print("❌ Timeout: Backend took too long to respond")
    except Exception as e:
        print(f"❌ Unexpected error: {type(e).__name__}: {e}")

if __name__ == '__main__':
    test_register()
