import requests
import json

BASE_URL = 'http://127.0.0.1:5000'

def test_feedback():
    print("\n--- Testing Feedback ---")
    
    # 1. Register/Login a User
    phone = "9998887777"
    password = "password123"
    
    # Try login first
    print("Logging in...")
    response = requests.post(f"{BASE_URL}/api/auth/login", json={
        "phone": phone,
        "password": password
    })
    
    token = None
    if response.status_code == 200:
        token = response.json().get('accessToken')
    else:
        # Register if login fails
        print("Login failed, registering...")
        requests.post(f"{BASE_URL}/api/auth/register", json={
            "phone": phone,
            "password": password,
            "full_name": "Feedback Tester"
        })
        # Login again
        response = requests.post(f"{BASE_URL}/api/auth/login", json={
             "phone": phone,
             "password": password
        })
        token = response.json().get('accessToken')

    if not token:
        print("❌ Failed to get token")
        return

    # 2. Send Feedback
    print("Sending feedback...")
    feedback_msg = "This is a test feedback from script."
    response = requests.post(
        f"{BASE_URL}/api/auth/feedback",
        headers={"Authorization": f"Bearer {token}"},
        json={"message": feedback_msg}
    )
    
    if response.status_code == 200:
        print("[PASS] Feedback sent successfully")
    else:
        print(f"[FAIL] Failed to send feedback: {response.text}")

if __name__ == "__main__":
    test_feedback()
