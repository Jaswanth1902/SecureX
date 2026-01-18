"""
Test network connectivity from the device perspective
"""
import socket

def test_connection(host, port):
    """Test if we can connect to the host:port"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except Exception as e:
        print(f"Error: {e}")
        return False

# Test backend connectivity
print("=" * 60)
print("Testing Network Connectivity to Backend")
print("=" * 60)

# Try different IPs
ips_to_test = [
    ("192.168.0.103", 5000),
    ("192.168.56.1", 5000),
    ("127.0.0.1", 5000),
    ("localhost", 5000),
]

for host, port in ips_to_test:
    print(f"\n🔍 Testing {host}:{port}...")
    if test_connection(host, port):
        print(f"   ✅ CONNECTED!")
    else:
        print(f"   ❌ Connection failed")

# Also test with curl-like command
print("\n" + "=" * 60)
print("Making HTTP Request to Backend")
print("=" * 60)

import requests

url = "http://192.168.0.103:5000/health"
print(f"\n🔄 Testing: {url}")
try:
    response = requests.get(url, timeout=5)
    print(f"✅ Status: {response.status_code}")
    print(f"   Response: {response.json()}")
except requests.exceptions.ConnectionError:
    print(f"❌ Connection Error - Backend not reachable")
except Exception as e:
    print(f"❌ Error: {e}")
