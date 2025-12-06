@echo off
REM Run the Flutter desktop app from repo root
REM Usage: run_desktop.bat
cd /d %~dp0\desktop_app
echo Starting Flutter desktop app in %CD%
flutter run -d windows
