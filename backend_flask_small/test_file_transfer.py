#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test End-to-End File Transfer
Tests mobile->server->desktop file transfer workflow
"""

import requests
import json
import base64
import os
from pathlib import Path

BASE_URL = "http://localhost:5000"

def test_file_transfer_workflow():
    """Test complete file upload and download workflow"""
    
    print("\n" + "="*60)
    print("END-TO-END FILE TRANSFER TEST")
    print("="*60 + "\n")
    
    # Step 1: Login as owner
    print("[1/5] Logging in as owner...")
    login_response = requests.post(f"{BASE_URL}/api/owners/login", json={
        "email": "test-owner-new@example.com",
        "password": "test123"
    })
    
    if login_response.status_code != 200:
        print(f"[ERROR] Login failed: {login_response.status_code}")
        return False
    
    owner_data = login_response.json()
    owner_id = owner_data['owner']['id']
    access_token = owner_data['accessToken']
    print(f"[OK] Logged in as: {owner_data['owner']['email']}")
    print(f"     Owner ID: {owner_id}\n")
    
    # Step 2: Upload a test file (simulating mobile upload)
    print("[2/5] Uploading test file...")
    test_content = b"This is a test PDF document for SafeCopy printing system"
    
    # Generate mock encryption data
    iv = base64.b64encode(os.urandom(16)).decode('utf-8')
    auth_tag = base64.b64encode(os.urandom(16)).decode('utf-8')
    encrypted_key = base64.b64encode(os.urandom(32)).decode('utf-8')
    
    files = {
        'file': ('test_document.pdf', test_content, 'application/pdf')
    }
    
    data = {
        'file_name': 'test_document.pdf',
        'iv_vector': iv,
        'auth_tag': auth_tag,
        'encrypted_symmetric_key': encrypted_key,
        'owner_id': owner_id
    }
    
    upload_response = requests.post(f"{BASE_URL}/api/upload", files=files, data=data)
    
    if upload_response.status_code != 201:
        print(f"[ERROR] Upload failed: {upload_response.status_code}")
        print(f"Response: {upload_response.text}")
        return False
    
    upload_data = upload_response.json()
    file_id = upload_data['file_id']
    print(f"[OK] File uploaded successfully")
    print(f"     File ID: {file_id}")
    print(f"     File Name: {upload_data['file_name']}")
    print(f"     File Size: {upload_data['file_size_bytes']} bytes\n")
    
    # Step 3: List files (simulating desktop checking for new files)
    print("[3/5] Listing files (desktop app polling)...")
    list_response = requests.get(
        f"{BASE_URL}/api/files",
        headers={'Authorization': f'Bearer {access_token}'}
    )
    
    if list_response.status_code != 200:
        print(f"[ERROR] List files failed: {list_response.status_code}")
        return False
    
    list_data = list_response.json()
    print(f"[OK] Found {list_data['count']} files")
    
    # Find our uploaded file
    our_file = None
    for f in list_data['files']:
        if f['file_id'] == file_id:
            our_file = f
            break
    
    if our_file:
        print(f"     - {our_file['file_name']} (Status: {our_file['status']})\n")
    else:
        print(f"[ERROR] Uploaded file not found in list!\n")
        return False
    
    # Step 4: Download file for printing (simulating desktop downloading)
    print("[4/5] Downloading file for printing...")
    download_response = requests.get(
        f"{BASE_URL}/api/print/{file_id}",
        headers={'Authorization': f'Bearer {access_token}'}
    )
    
    if download_response.status_code != 200:
        print(f"[ERROR] Download failed: {download_response.status_code}")
        print(f"Response: {download_response.text}")
        return False
    
    download_data = download_response.json()
    print(f"[OK] File downloaded successfully")
    print(f"     File Name: {download_data['file_name']}")
    print(f"     Encrypted Data Size: {len(download_data['encrypted_file_data'])} chars (base64)")
    print(f"     Has IV: {bool(download_data['iv_vector'])}")
    print(f"     Has Auth Tag: {bool(download_data['auth_tag'])}")
    print(f"     Has Encrypted Key: {bool(download_data['encrypted_symmetric_key'])}\n")
    
    # Step 5: Delete file (mark as printed)
    print("[5/5] Deleting file (marking as printed)...")
    delete_response = requests.post(
        f"{BASE_URL}/api/delete/{file_id}",
        headers={'Authorization': f'Bearer {access_token}'}
    )
    
    if delete_response.status_code != 200:
        print(f"[ERROR] Delete failed: {delete_response.status_code}")
        return False
    
    delete_data = delete_response.json()
    print(f"[OK] File deleted/printed successfully")
    print(f"     Status: {delete_data['status']}\n")
    
    # Summary
    print("="*60)
    print("TRANSFER TEST SUMMARY")
    print("="*60)
    print("[OK] 1. Owner Login:           SUCCESS")
    print("[OK] 2. File Upload (Mobile):  SUCCESS")
    print("[OK] 3. List Files (Desktop):  SUCCESS")
    print("[OK] 4. Download File:         SUCCESS")
    print("[OK] 5. Delete File:           SUCCESS")
    print("\n[INFO] File transfer is WORKING")
    print("\n[WARNING] NO APPROVAL MECHANISM FOUND!")
    print("         Files are immediately available without owner confirmation")
    print("="*60 + "\n")
    
    return True

if __name__ == "__main__":
    try:
        test_file_transfer_workflow()
    except Exception as e:
        print(f"\n[ERROR] Test failed with exception: {e}\n")
