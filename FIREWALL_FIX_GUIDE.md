# Connection Timeout Fix - Firewall Issue

## The Problem
Your Android device **cannot reach** the backend server at `192.168.0.103:5000` because **Windows Firewall is blocking** the incoming connection on port 5000.

Error you saw:
```
Socket exception: connection timed out
address=192.168.0.103, port=5000
```

## The Solution (Pick ONE)

### ✅ SOLUTION 1: Manual Firewall Rule (Recommended - No Admin Needed for Python)

1. **Open Windows Security**
   - Press `Win + I` or search for "Windows Security"
   - Click on it

2. **Go to Firewall Settings**
   - Click **Firewall & network protection**
   - On the right, click **Allow an app through firewall**
   
3. **Add Python Exception**
   - Click **Change settings** button (top right)
   - Click **Allow another app...**
   - Click **Browse**
   - Navigate to: `C:\Users\Sushmitha M\AppData\Local\Programs\Python`
   - Find and select `python.exe`
   - Click **Add**
   - Make sure it's checked for **Private** networks ✓

4. **Restart Backend**
   - Stop the Flask backend (Ctrl+C)
   - Start it again: `python app.py`

5. **Try Registration Again**
   - Rebuild app: `flutter run`
   - Try registering with a new phone number
   - Should work now!

---

### ✅ SOLUTION 2: Quick Fix Using Command Prompt

If you have admin access, run **Command Prompt as Administrator**:

```cmd
netsh advfirewall firewall add rule name="Flask Backend" dir=in action=allow protocol=tcp localport=5000
```

---

### ✅ SOLUTION 3: Temporary - Disable Firewall (Testing Only)

**⚠️ SECURITY WARNING: Only for testing!**

```cmd
netsh advfirewall set allprofiles state off
```

After testing, re-enable:
```cmd
netsh advfirewall set allprofiles state on
```

---

## Verification: Test the Connection

After applying the firewall fix, verify from your Android device:

1. Open browser on your phone
2. Go to: `http://192.168.0.103:5000/health`
3. Should see: `{"status":"OK","environment":"development"}`

If you see this, the firewall is fixed!

---

## If Still Having Issues

Possible alternate causes:

### Different Network
If device is on a **different WiFi network**:
- Check if your PC's network is `192.168.0.X`
- Check if device is on same network
- If not, connect both to same WiFi network

### If Device is on Ethernet Network Instead
If your device can reach `192.168.56.1` instead:
- Edit `mobile_app/lib/services/api_service.dart`
- Change: `static const String BACKEND_IP = WIFI_IP;`
- To: `static const String BACKEND_IP = ETHERNET_IP;`
- Rebuild: `flutter run`

### Test Directly from Device
1. On your Android phone, open browser
2. Try: `http://192.168.0.103:5000/health`
3. If it doesn't load, firewall is still blocking

---

## Current Mobile App Configuration

✅ Backend IP options now configurable at top of `api_service.dart`:
- `WIFI_IP = '192.168.0.103'` (currently active)
- `ETHERNET_IP = '192.168.56.1'` (alternative)
- `EMULATOR_IP = '10.0.2.2'` (for emulator)

You can easily switch by changing one line!

