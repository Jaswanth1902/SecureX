"""
Simulate the exact JSON parsing the Flutter app does
"""
import json

# This is the exact response from the backend
backend_response = """{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJiZTliZjYzYS1lZTlmLTQ1ZDktYWNiMi0wNGM0YzZiZjE0YTEiLCJwaG9uZSI6IjcwMTM5NDQ2NzUiLCJyb2xlIjoidXNlciIsImlhdCI6MTc2ODU4OTU3MSwiZXhwIjoxNzcxMTgxNTcxfQ.ok2JzgP3pfPQIYkSjgG_XJkOn9uxln7-FBAa2e1cN7Y",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJiZTliZjYzYS1lZTlmLTQ1ZDktYWNiMi0wNGM0YzZiZjE0YTEiLCJwaG9uZSI6IjcwMTM5NDQ2NzUiLCJyb2xlIjoidXNlciIsImlhdCI6MTc2ODU4OTU3MSwiZXhwIjoxNzY5MTk0MzcxfQ.Mklks0iKCR5r_7C5gtHjorM2Bfsw1ssyEcRyo15j4Sk",
  "success": true,
  "user": {
    "full_name": "Test User",
    "id": "be9bf63a-ee9f-45d9-acb2-04c4c6bf14a1",
    "phone": "7013944675"
  }
}"""

print("=" * 60)
print("Testing JSON Parsing (Simulating Dart)")
print("=" * 60)

try:
    data = json.loads(backend_response)
    print("✅ JSON parsed successfully!")
    print()
    
    # Test accessing fields as the Dart code would
    print("Testing field access:")
    print(f"  success: {data.get('success')} (type: {type(data.get('success')).__name__})")
    print(f"  accessToken exists: {bool(data.get('accessToken'))}")
    print(f"  refreshToken exists: {bool(data.get('refreshToken'))}")
    print(f"  user.id: {data.get('user', {}).get('id')}")
    print(f"  user.phone: {data.get('user', {}).get('phone')}")
    print(f"  user.full_name: {data.get('user', {}).get('full_name')}")
    
    # Check for required fields
    required_fields = ['success', 'accessToken', 'refreshToken', 'user']
    missing = [f for f in required_fields if f not in data]
    
    if missing:
        print(f"\n❌ Missing fields: {missing}")
    else:
        print(f"\n✅ All required fields present!")
        
except json.JSONDecodeError as e:
    print(f"❌ JSON parsing failed: {e}")
except Exception as e:
    print(f"❌ Error: {e}")
