"""
Connectivity Test - Run this to diagnose if device can reach backend
"""
import socket
import subprocess

def test_firewall_rule():
    """Test if we can open port 5000"""
    try:
        # Try to create a socket listener on 0.0.0.0:5000
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind(('0.0.0.0', 5000))
        sock.listen(1)
        print("✅ Port 5000 is open and listening")
        sock.close()
        return True
    except OSError as e:
        print(f"❌ Port 5000 issue: {e}")
        return False

def get_firewall_status():
    """Check Windows Firewall status"""
    try:
        result = subprocess.run(
            ['netsh', 'advfirewall', 'show', 'allprofiles'],
            capture_output=True,
            text=True
        )
        print("Windows Firewall Status:")
        for line in result.stdout.split('\n')[:5]:
            print(f"  {line}")
        return True
    except Exception as e:
        print(f"Could not check firewall: {e}")
        return False

print("=" * 60)
print("Network Connectivity Diagnostic")
print("=" * 60)
print()

# Test 1: Port listening
print("1. Checking if port 5000 is listening...")
test_firewall_rule()
print()

# Test 2: Firewall
print("2. Windows Firewall status...")
get_firewall_status()
print()

print("3. Your WiFi IP Address: 192.168.0.103")
print("   Your Ethernet IP Address: 192.168.56.1")
print()

print("=" * 60)
print("SOLUTION: Add Firewall Exception")
print("=" * 60)
print()
print("Run this in PowerShell as ADMINISTRATOR:")
print()
print('netsh advfirewall firewall add rule name="Flask Backend" ^')
print('  dir=in action=allow protocol=tcp localport=5000 ^')
print('  remoteip=192.168.0.0/24')
print()
print("OR manually:")
print("1. Windows Security > Firewall & network protection")
print("2. Allow an app through firewall")
print("3. Allow Python through firewall")
print()
