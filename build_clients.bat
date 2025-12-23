@echo off
REM ============================================
REM Secure File Print System - Client Build Script
REM Windows Batch Version
REM ============================================
REM This script builds all Flutter client applications:
REM - Mobile App (Android APK)
REM - Desktop App (Windows)
REM - Owner App (Windows)
REM
REM Requirements:
REM - Flutter SDK installed and in PATH
REM - Dart SDK (comes with Flutter)
REM - Android SDK (for mobile builds)
REM ============================================

setlocal enabledelayedexpansion

REM Build output directory
set BUILD_DIR=builds
set TIMESTAMP=%date:~-4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%

REM ============================================
REM Pre-flight Checks
REM ============================================

echo ========================================
echo Pre-flight Checks
echo ========================================

REM Check if Flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter is not installed or not in PATH
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install
    exit /b 1
)

echo [OK] Flutter SDK found
flutter --version | findstr /C:"Flutter"

REM Create build directory
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
echo [OK] Build directory created: %BUILD_DIR%

REM ============================================
REM Mobile App Build (Android APK)
REM ============================================

:build_mobile_app
echo.
echo ========================================
echo Building Mobile App (Android APK)
echo ========================================

if not exist "mobile_app" (
    echo [WARNING] mobile_app directory not found, skipping...
    goto build_desktop_app
)

cd mobile_app || (
    echo [ERROR] Failed to change to mobile_app directory
    exit /b 1
)

echo [INFO] Cleaning previous builds...
call flutter clean || (
    echo [ERROR] Flutter clean failed
    cd ..
    exit /b 1
)

echo [INFO] Getting dependencies...
call flutter pub get || (
    echo [ERROR] Flutter pub get failed
    cd ..
    exit /b 1
)

echo [INFO] Building APK...
call flutter build apk --release || (
    echo [ERROR] Flutter build failed
    cd ..
    exit /b 1
)
REM Copy APK to build directory
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy "build\app\outputs\flutter-apk\app-release.apk" "..\%BUILD_DIR%\mobile_app_%TIMESTAMP%.apk"
    echo [OK] Mobile app built successfully!
    echo [INFO] APK location: %BUILD_DIR%\mobile_app_%TIMESTAMP%.apk
) else (
    echo [ERROR] APK file not found
    cd ..
    exit /b 1
)

cd ..

REM ============================================
REM Desktop App Build (Windows)
REM ============================================

:build_desktop_app
echo.
echo ========================================
echo Building Desktop App (Windows)
echo ========================================

if not exist "desktop_app" (
    echo [WARNING] desktop_app directory not found, skipping...
    goto build_owner_app
)

cd desktop_app || (
    echo [ERROR] Failed to change to desktop_app directory
    exit /b 1
)

echo [INFO] Cleaning previous builds...
call flutter clean || (
    echo [ERROR] Flutter clean failed
    cd ..
    exit /b 1
)

echo [INFO] Getting dependencies...
call flutter pub get || (
    echo [ERROR] Flutter pub get failed
    cd ..
    exit /b 1
)

echo [INFO] Building for Windows...
call flutter build windows --release || (
    echo [ERROR] Flutter build failed
    cd ..
    exit /b 1
)

if exist "build\windows\runner\Release\" (
    if not exist "..\%BUILD_DIR%\desktop_app_windows_%TIMESTAMP%" mkdir "..\%BUILD_DIR%\desktop_app_windows_%TIMESTAMP%"
    xcopy /E /I /Y "build\windows\runner\Release\*" "..\%BUILD_DIR%\desktop_app_windows_%TIMESTAMP%\" || (
        echo [ERROR] Failed to copy build artifacts
        cd ..
        exit /b 1
    )
    echo [OK] Desktop app (Windows) built successfully!
    echo [INFO] Build location: %BUILD_DIR%\desktop_app_windows_%TIMESTAMP%\
) else (
    echo [ERROR] Build output not found
    cd ..
    exit /b 1
)

cd ..

REM ============================================
REM Owner App Build (Windows)
REM ============================================

:build_owner_app
echo.
echo ========================================
echo Building Owner App (Windows)
echo ========================================

if not exist "owner_app" (
    echo [WARNING] owner_app directory not found, skipping...
    goto build_summary
)

cd owner_app || (
    echo [ERROR] Failed to change to owner_app directory
    exit /b 1
)

echo [INFO] Cleaning previous builds...
call flutter clean || (
    echo [ERROR] Flutter clean failed
    cd ..
    exit /b 1
)

echo [INFO] Getting dependencies...
call flutter pub get || (
    echo [ERROR] Flutter pub get failed
    cd ..
    exit /b 1
)

echo [INFO] Building for Windows...
call flutter build windows --release || (
    echo [ERROR] Flutter build failed
    cd ..
    exit /b 1
)

if exist "build\windows\runner\Release\" (
    if not exist "..\%BUILD_DIR%\owner_app_windows_%TIMESTAMP%" mkdir "..\%BUILD_DIR%\owner_app_windows_%TIMESTAMP%"
    xcopy /E /I /Y "build\windows\runner\Release\*" "..\%BUILD_DIR%\owner_app_windows_%TIMESTAMP%\" || (
        echo [ERROR] Failed to copy build artifacts
        cd ..
        exit /b 1
    )
    echo [OK] Owner app (Windows) built successfully!
    echo [INFO] Build location: %BUILD_DIR%\owner_app_windows_%TIMESTAMP%\
) else (
    echo [ERROR] Build output not found
    cd ..
    exit /b 1
)

cd ..

REM ============================================
REM Build Summary
REM ============================================

:build_summary
echo.
echo ========================================
echo Build Summary
echo ========================================
echo [OK] All builds completed!
echo [INFO] Build artifacts location: %BUILD_DIR%\
echo.
echo [INFO] Build artifacts:
dir /B "%BUILD_DIR%"

endlocal
pause
