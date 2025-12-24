"""
Create owner account for Sathi Surya
Email: surya@gmail.com
Password: sathi123
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

# Serialize to PEM format (PKCS#8 for compatibility with desktop app)
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
import os
with open('surya_private_key.pem', 'w') as f:
    f.write(private_pem)
# Restrict private key file permissions to user-only
try:
    os.chmod('surya_private_key.pem', 0o600)
except Exception:
    # Some platforms (e.g., Windows) may not support chmod exactly as POSIX; warn but continue
    print('Warning: could not set strict file permissions on surya_private_key.pem; ensure this file is protected.')
print("\nPrivate key saved to: surya_private_key.pem (permissions set to user-only where supported)")

with open('surya_public_key.pem', 'w') as f:
    f.write(public_pem)
print("Public key saved to: surya_public_key.pem")

# Owner account details
import getpass
import secrets

owner_email = "surya@gmail.com"
owner_full_name = "Sathi surya"

# Prompt for password (do NOT store plaintext passwords on disk)
password = getpass.getpass("Enter password for new owner (leave blank to generate a secure password): ")
if not password:
    # Generate a strong random password but DO NOT print or persist it.
    # The plaintext password is never written to disk or logs; it is transmitted to the server
    # where it will be hashed and stored as a password hash only.
    password = secrets.token_urlsafe(16)

owner_data = {
    "email": owner_email,
    "password": password,
    "full_name": owner_full_name,
    "public_key": public_pem,
    "must_reset_password_on_first_login": True
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
        print("\nOwner account created successfully.")
        print(f"Owner ID: {result['owner']['id']}")
        print(f"Email: {result['owner']['email']}")
        # Do not display tokens or passwords

        # Save only non-sensitive account metadata
        with open('surya_account_info.txt', 'w') as f:
            f.write("OWNER ACCOUNT INFO - REDACTED FOR SECURITY\n")
            f.write("="*60 + "\n\n")
            f.write(f"Owner ID: {result['owner']['id']}\n")
            f.write(f"Email: {result['owner']['email']}\n")
            f.write(f"Name: {result['owner']['full_name']}\n\n")
            f.write("Access Token: REDACTED\n")
            f.write("Refresh Token: REDACTED\n")
            f.write("must_reset_password_on_first_login: true\n")
            f.write("\nPlease remove this file and any key files from version control and store private keys securely.\n")
        print("Account metadata saved to: surya_account_info.txt (REDACTED)")

        # Desktop app info (non-sensitive guidance)
        print("\nDESKTOP APP KEY SETUP")
        print("="*60)
        print("The public key was registered; private key file created locally at surya_private_key.pem (keep it secure).")
        
    else:
        print(f"\nRegistration failed: {response.status_code}")
        print(f"Response: {response.text}")
        
except Exception as e:
    print(f"\nError: {e}")
    print("\nNote: Make sure Flask server is running on http://localhost:5000")

print("\n" + "="*60)
print("SUMMARY FOR MOBILE APP")
print("="*60)
print("\nWhen uploading files from mobile app, use:")
print(f"Owner Email: surya@gmail.com")
print("\nThe public key has been registered in the database.")
print("The mobile app will fetch it automatically when you enter this email.")
print("="*60)
