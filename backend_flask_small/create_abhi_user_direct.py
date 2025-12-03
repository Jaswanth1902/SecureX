"""
Create a new user directly in the database: abhi@gmail.com / test123
"""
import sqlite3
import bcrypt
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend
import os
import uuid

# Database path
DB_PATH = os.path.join(os.path.dirname(__file__), 'database.sqlite')

print("="*60)
print("Creating User: abhi@gmail.com / test123")
print("="*60)

# Generate RSA key pair
print("\n1. Generating RSA-2048 key pair...")
private_key = rsa.generate_private_key(
    public_exponent=65537,
    key_size=2048,
    backend=default_backend()
)

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

print("   ✓ RSA keys generated")

# Save keys
with open('abhi_private_key.pem', 'w') as f:
    f.write(private_pem)
with open('abhi_public_key.pem', 'w') as f:
    f.write(public_pem)
print("   ✓ Keys saved to: abhi_private_key.pem and abhi_public_key.pem")

# Hash password
password = "test123"
hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
print("\n2. Password hashed with bcrypt")

# Connect to database and insert user
print("\n3. Inserting into database...")
try:
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Generate unique owner ID
    owner_id = str(uuid.uuid4())
    
    # Insert into owners table (owners requires: id, email, password_hash, full_name, public_key, private_key_encrypted)
    cursor.execute("""
        INSERT INTO owners (id, email, password_hash, full_name, public_key, private_key_encrypted, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    """, (owner_id, 'abhi@gmail.com', hashed_password, 'Abhi User', public_pem, private_pem))
    
    conn.commit()
    conn.close()
    
    print(f"   ✓ User created successfully!")
    print(f"\n   Owner ID: {owner_id}")
    print(f"   Email: abhi@gmail.com")
    print(f"   Name: Abhi User")
    
    # Save credentials
    with open('abhi_account_info.txt', 'w') as f:
        f.write("USER ACCOUNT CREDENTIALS\n")
        f.write("="*60 + "\n\n")
        f.write(f"Owner ID: {owner_id}\n")
        f.write(f"Email: abhi@gmail.com\n")
        f.write(f"Password: test123\n")
        f.write(f"Name: Abhi User\n\n")
        f.write("Private Key: abhi_private_key.pem\n")
        f.write("Public Key: abhi_public_key.pem\n")
    
    print("\n✓ Account info saved to: abhi_account_info.txt")
    
except Exception as e:
    print(f"   ✗ Error: {e}")
    exit(1)

print("\n" + "="*60)
print("LOGIN CREDENTIALS")
print("="*60)
print("\nEmail: abhi@gmail.com")
print("Password: test123")
print("\nPrivate Key File: abhi_private_key.pem")
print("="*60)
print("\n✅ User created successfully!")
print("\nYou can now log in with:")
print("  Email: abhi@gmail.com")
print("  Password: test123")
