#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Comprehensive Backend API Test Script
Tests all server-to-desktop endpoints after database migration
"""

import requests
import json
import os
import sys
from pathlib import Path

# Fix Windows console encoding
if sys.platform == 'win32':
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')
    sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'strict')

BASE_URL = "http://localhost:5000"

# ANSI color codes for pretty output
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'

def print_header(text):
    print(f"\n{BLUE}{'=' * 60}")
    print(f"{text}")
    print(f"{'=' * 60}{RESET}\n")

def print_success(text):
    print(f"{GREEN}[OK] {text}{RESET}")

def print_error(text):
    print(f"{RED}[ERROR] {text}{RESET}")

def print_info(text):
    print(f"{YELLOW}[INFO] {text}{RESET}")

# Test 1: Health Check
def test_health_check():
    print_header("TEST 1: Health Check Endpoint")
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            data = response.json()
            print_success(f"Health check passed: {data}")
            return True
        else:
            print_error(f"Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Health check error: {e}")
        return False

# Test 2: Owner Registration
def test_owner_registration():
    print_header("TEST 2: Owner Registration")
    
    # Read test owner's public key
    try:
        with open('test_owner_001_public_key.pem', 'r') as f:
            public_key = f.read()
    except FileNotFoundError:
        print_error("Test owner public key file not found")
        return False, None
    
    payload = {
        "email": "test-owner-new@example.com",
        "password": "test123",
        "full_name": "Test Owner New",
        "public_key": public_key
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/owners/register", json=payload)
        
        if response.status_code == 201:
            data = response.json()
            print_success("Owner registration successful")
            print_info(f"Owner ID: {data.get('owner', {}).get('id')}")
            print_info(f"Access Token: {data.get('accessToken', '')[:20]}...")
            return True, data
        elif response.status_code == 409:
            print_info("Owner already exists (expected if re-running tests)")
            return True, None
        else:
            print_error(f"Registration failed: {response.status_code} - {response.text}")
            return False, None
    except Exception as e:
        print_error(f"Registration error: {e}")
        return False, None

# Test 3: Owner Login
def test_owner_login():
    print_header("TEST 3: Owner Login")
    
    payload = {
        "email": "test-owner-new@example.com",
        "password": "test123"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/owners/login", json=payload)
        
        if response.status_code == 200:
            data = response.json()
            print_success("Owner login successful")
            print_info(f"Owner ID: {data.get('owner', {}).get('id')}")
            print_info(f"Access Token: {data.get('accessToken', '')[:20]}...")
            return True, data
        else:
            print_error(f"Login failed: {response.status_code} - {response.text}")
            return False, None
    except Exception as e:
        print_error(f"Login error: {e}")
        return False, None

# Test 4: Get Public Key
def test_get_public_key():
    print_header("TEST 4: Get Owner Public Key")
    
    email = "test-owner-new@example.com"
    
    try:
        response = requests.get(f"{BASE_URL}/api/owners/public-key/{email}")
        
        if response.status_code == 200:
            data = response.json()
            print_success("Public key retrieved successfully")
            print_info(f"Public Key (first 50 chars): {data.get('publicKey', '')[:50]}...")
            return True, data
        else:
            print_error(f"Get public key failed: {response.status_code} - {response.text}")
            return False, None
    except Exception as e:
        print_error(f"Get public key error: {e}")
        return False, None

# Test 5: File Upload (No auth - disabled for testing)
def test_file_upload(owner_id):
    print_header("TEST 5: File Upload Endpoint")
    
    if not owner_id:
        print_error("No owner ID provided - skipping file upload test")
        return False, None
    
    # Create a test file
    test_file_content = b"This is a test encrypted file content for SafeCopy"
    
    # Simulated encryption metadata (base64 encoded)
    import base64
    iv = base64.b64encode(os.urandom(16)).decode('utf-8')
    auth_tag = base64.b64encode(os.urandom(16)).decode('utf-8')
    encrypted_key = base64.b64encode(os.urandom(32)).decode('utf-8')
    
    files = {
        'file': ('test_document.pdf', test_file_content, 'application/pdf')
    }
    
    data = {
        'file_name': 'test_document.pdf',
        'iv_vector': iv,
        'auth_tag': auth_tag,
        'encrypted_symmetric_key': encrypted_key,
        'owner_id': owner_id
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/upload", files=files, data=data)
        
        if response.status_code == 201:
            result = response.json()
            print_success("File uploaded successfully")
            print_info(f"File ID: {result.get('file_id')}")
            print_info(f"File Name: {result.get('file_name')}")
            print_info(f"File Size: {result.get('file_size_bytes')} bytes")
            return True, result
        else:
            print_error(f"File upload failed: {response.status_code} - {response.text}")
            return False, None
    except Exception as e:
        print_error(f"File upload error: {e}")
        return False, None

# Test 6: List Files (Requires auth token)
def test_list_files(access_token):
    print_header("TEST 6: List Files Endpoint")
    
    if not access_token:
        print_error("No access token provided - skipping list files test")
        return False
    
    headers = {
        'Authorization': f'Bearer {access_token}'
    }
    
    try:
        response = requests.get(f"{BASE_URL}/api/files", headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            print_success(f"Files listed successfully: {data.get('count', 0)} files found")
            for file in data.get('files', [])[:3]:  # Show first 3 files
                print_info(f"  - {file.get('file_name')} ({file.get('status')})")
            return True
        else:
            print_error(f"List files failed: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print_error(f"List files error: {e}")
        return False

# Test 7: Get File for Print (Requires auth token)
def test_get_file_for_print(access_token, file_id):
    print_header("TEST 7: Get File for Printing Endpoint")
    
    if not access_token or not file_id:
        print_error("Missing access token or file ID - skipping get file test")
        return False
    
    headers = {
        'Authorization': f'Bearer {access_token}'
    }
    
    try:
        response = requests.get(f"{BASE_URL}/api/print/{file_id}", headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            print_success("File retrieved for printing successfully")
            print_info(f"File Name: {data.get('file_name')}")
            print_info(f"File Size: {data.get('file_size_bytes')} bytes")
            print_info(f"Has encrypted data: {bool(data.get('encrypted_file_data'))}")
            return True
        else:
            print_error(f"Get file for print failed: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print_error(f"Get file for print error: {e}")
        return False

# Test 8: Delete File (Requires auth token)
def test_delete_file(access_token, file_id):
    print_header("TEST 8: Delete File Endpoint")
    
    if not access_token or not file_id:
        print_error("Missing access token or file ID - skipping delete file test")
        return False
    
    headers = {
        'Authorization': f'Bearer {access_token}'
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/delete/{file_id}", headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            print_success("File deleted successfully")
            print_info(f"Deleted File: {data.get('file_name')}")
            print_info(f"Status: {data.get('status')}")
            return True
        else:
            print_error(f"Delete file failed: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print_error(f"Delete file error: {e}")
        return False

# Main Test Runner
def run_all_tests():
    print_header("SAFE COPY - BACKEND ENDPOINT TESTS")
    print_info("Testing all server-to-desktop endpoints after database migration\n")
    
    results = []
    
    # Test 1: Health Check
    results.append(("Health Check", test_health_check()))
    
    # Test 2: Owner Registration
    success, reg_data = test_owner_registration()
    results.append(("Owner Registration", success))
    
    # Test 3: Owner Login
    success, login_data = test_owner_login()
    results.append(("Owner Login", success))
    
    access_token = login_data.get('accessToken') if login_data else None
    owner_id = login_data.get('owner', {}).get('id') if login_data else None
    
    # Test 4: Get Public Key
    success, _ = test_get_public_key()
    results.append(("Get Public Key", success))
    
    # Test 5: File Upload
    success, upload_data = test_file_upload(owner_id)
    results.append(("File Upload", success))
    
    file_id = upload_data.get('file_id') if upload_data else None
    
    # Test 6: List Files
    results.append(("List Files", test_list_files(access_token)))
    
    # Test 7: Get File for Print
    results.append(("Get File for Print", test_get_file_for_print(access_token, file_id)))
    
    # Test 8: Delete File
    results.append(("Delete File", test_delete_file(access_token, file_id)))
    
    # Print Summary
    print_header("TEST SUMMARY")
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "[PASS]" if result else "[FAIL]"
        print(f"{status} - {test_name}")
    
    print(f"\n{BLUE}Total: {passed}/{total} tests passed{RESET}")
    
    if passed == total:
        print_success("\nAll tests passed! Server is working correctly.")
    else:
        print_error(f"\n{total - passed} test(s) failed. Please review.")

if __name__ == "__main__":
    run_all_tests()
