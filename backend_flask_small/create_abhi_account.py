"""
Create a new owner account: abhi@gmail.com / test123
"""
import requests
import json
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend

# Generate RSA key pair
print("Generating RSA-2048 key pair...")
private_key = rsa.generate_private_key(
    public_exponent=65537,
    key_size=2048,
    backend=default_backend()
)

# Get public key
public_key = private_key.public_key()

# Serialize to PEM format
private_pem = private_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption()
).decode('utf-8')

public_pem = public_key.public_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PublicFormat.SubjectPublicKeyInfo
).decode('utf-8')

print("\n" + "="*60)
print("RSA KEY PAIR GENERATED")
print("="*60)

# Save keys to files
with open('abhi_private_key.pem', 'w') as f:
    f.write(private_pem)
print("\nPrivate key saved to: abhi_private_key.pem")

with open('abhi_public_key.pem', 'w') as f:
    f.write(public_pem)
print("Public key saved to: abhi_public_key.pem")

# Owner account details
owner_data = {
    "email": "abhi@gmail.com",
    "password": "test123",
    "full_name": "Abhi User",
    "public_key": public_pem
}

# Register owner account
print("\n" + "="*60)
print("REGISTERING OWNER ACCOUNT")
print("="*60)

try:
    response = requests.post(
        'http://localhost:5000/api/owners/register',
        json=owner_data,
        headers={'Content-Type': 'application/json'}
    )
    
    if response.status_code == 201:
        result = response.json()
        print("\n✅ Owner account created successfully!")
        print(f"\nOwner ID: {result['owner']['id']}")
        print(f"Email: {result['owner']['email']}")
        print(f"Name: {result['owner']['full_name']}")
        print(f"\nAccess Token: {result['accessToken'][:50]}...")
        
        # Save account info
        with open('abhi_account_info.txt', 'w') as f:
            f.write("OWNER ACCOUNT CREDENTIALS\n")
            f.write("="*60 + "\n\n")
            f.write(f"Owner ID: {result['owner']['id']}\n")
            f.write(f"Email: {owner_data['email']}\n")
            f.write(f"Password: {owner_data['password']}\n")
            f.write(f"Name: {owner_data['full_name']}\n\n")
            f.write("Access Token:\n")
            f.write(f"{result['accessToken']}\n\n")
            f.write("Refresh Token:\n")
            f.write(f"{result['refreshToken']}\n")
        
        print("\n✅ Account info saved to: abhi_account_info.txt")
        
    else:
        print(f"\n❌ Registration failed: {response.status_code}")
        print(f"Response: {response.text}")
        
except Exception as e:
    print(f"\n❌ Error: {e}")
    print("\nNote: Make sure Flask server is running on http://localhost:5000")

print("\n" + "="*60)
print("LOGIN CREDENTIALS")
print("="*60)
print("\nEmail: abhi@gmail.com")
print("Password: test123")
print("\nPrivate Key File: abhi_private_key.pem")
print("="*60)
