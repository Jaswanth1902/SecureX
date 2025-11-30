"""
Create owner account with the email the app expects
"""
import requests
import json
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend

# Generate RSA key pair
print("Generating RSA-2048 key pair for test-owner-001@example.com...")
private_key = rsa.generate_private_key(
    public_exponent=65537,
    key_size=2048,
    backend=default_backend()
)

public_key = private_key.public_key()

private_pem = private_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption()
).decode('utf-8')

public_pem = public_key.public_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PublicFormat.SubjectPublicKeyInfo
).decode('utf-8')

# Save keys
with open('test_owner_001_private_key.pem', 'w') as f:
    f.write(private_pem)

with open('test_owner_001_public_key.pem', 'w') as f:
    f.write(public_pem)

# Owner account details - matching what the app expects
owner_data = {
    "email": "test-owner-001@example.com",
    "password": "owner123",
    "full_name": "Test Owner 001",
    "public_key": public_pem
}

# Register
try:
    response = requests.post(
        'http://localhost:5000/api/owners/register',
        json=owner_data,
        headers={'Content-Type': 'application/json'}
    )
    
    if response.status_code == 201:
        result = response.json()
        print("\nOwner account created successfully!")
        print(f"Email: test-owner-001@example.com")
        print(f"Owner ID: {result['owner']['id']}")
        
        with open('test_owner_001_info.txt', 'w') as f:
            f.write("OWNER: test-owner-001@example.com\n")
            f.write("="*60 + "\n")
            f.write(f"Owner ID: {result['owner']['id']}\n")
            f.write(f"Email: test-owner-001@example.com\n")
            f.write(f"Password: owner123\n")
        
        print("\nThis email matches what your mobile app expects!")
        
    else:
        print(f"Failed: {response.status_code} - {response.text}")
        
except Exception as e:
    print(f"Error: {e}")

print("\n" + "="*60)
print("Now the mobile app can use:")
print("Owner ID: test-owner-001@example.com")
print("="*60)
