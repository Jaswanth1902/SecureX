@echo off
REM Run this script as Administrator to allow Flask backend on port 5000

echo Adding Windows Firewall rule for Flask Backend (port 5000)...
netsh advfirewall firewall add rule name="Flask Backend 5000" dir=in action=allow protocol=tcp localport=5000 remoteip=192.168.0.0/16 enable=yes

echo.
echo Firewall rule added successfully!
echo You should now be able to connect from mobile hotspot.
echo.
echo Checking if port 5000 is listening...
netstat -ano | findstr :5000

pause
