#!/bin/bash

# ============================================
# Secure File Print System - Client Build Script
# ============================================
# This script builds all Flutter client applications:
# - Mobile App (Android APK)
# - Desktop App (Windows/Linux)
# - Owner App (Target platform)
#
# Requirements:
# - Flutter SDK installed and in PATH
# - Dart SDK (comes with Flutter)
# - Android SDK (for mobile builds)
# - Platform-specific tools (for desktop builds)
# ============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Build output directory
BUILD_DIR="builds"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# ============================================
# Helper Functions
# ============================================

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ============================================
# Pre-flight Checks (moved to main())
# ============================================

run_preflight_checks() {
    print_header "Pre-flight Checks"
    
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        print_info "Please install Flutter from: https://flutter.dev/docs/get-started/install"
        exit 1
    fi
    
    print_success "Flutter SDK found: $(flutter --version | head -n 1)"
    
    # Check Flutter doctor (non-fatal - warnings shouldn't stop the build)
    print_info "Running Flutter doctor..."
    flutter doctor || true  # Ignore exit status - warnings are informational
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    print_success "Build directory created: $BUILD_DIR"
    echo ""
}

# ============================================
# Mobile App Build (Android APK)
# ============================================

build_mobile_app() {
    print_header "Building Mobile App (Android APK)"
    
    if [ ! -d "mobile_app" ]; then
        print_warning "mobile_app directory not found, skipping..."
        return
    fi
    
    # Navigate to mobile app directory with error handling
    cd mobile_app || {
        print_error "Failed to cd to mobile_app in build_mobile_app()"
        exit 1
    }
    
    print_info "Cleaning previous builds..."
    flutter clean
    
    print_info "Getting dependencies..."
    flutter pub get
    
    print_info "Building APK..."
    flutter build apk --release
    
    # Copy APK to build directory
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        cp build/app/outputs/flutter-apk/app-release.apk "../$BUILD_DIR/mobile_app_${TIMESTAMP}.apk"
        print_success "Mobile app built successfully!"
        print_info "APK location: $BUILD_DIR/mobile_app_${TIMESTAMP}.apk"
    else
        print_error "APK file not found at build/app/outputs/flutter-apk/app-release.apk"
        cd ..
        return 1
    fi
    
    cd .. || {
        print_error "Failed to return to parent directory from mobile_app"
        exit 1
    }
}

# ============================================
# Flutter Desktop App Builder (Generic Helper)
# ============================================

build_flutter_app() {
    local app_dir="$1"
    local output_basename="$2"
    
    # Verify directory exists
    if [ ! -d "$app_dir" ]; then
        print_warning "$app_dir directory not found, skipping..."
        return 1
    fi
    
    # Navigate to app directory with error handling
    cd "$app_dir" || {
        print_error "Failed to cd to $app_dir in build_flutter_app()"
        exit 1
    }
    
    # Clean and prepare
    print_info "Cleaning previous builds..."
    flutter clean
    
    print_info "Getting dependencies..."
    flutter pub get
    
    # Detect platform and build accordingly
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        print_info "Building for Windows..."
        flutter build windows --release
        
        local source_path="build/windows/runner/Release"
        local dest_path="../$BUILD_DIR/${output_basename}_windows_${TIMESTAMP}"
        
        if [ -d "$source_path" ]; then
            mkdir -p "$dest_path"
            cp -r "$source_path"/* "$dest_path/"
            print_success "$(basename "$app_dir") (Windows) built successfully!"
            print_info "Build location: $BUILD_DIR/${output_basename}_windows_${TIMESTAMP}/"
        else
            print_error "Build output not found at $source_path"
            cd .. || {
                print_error "Failed to return to parent directory from $app_dir"
                exit 1
            }
            return 1
        fi
        
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_info "Building for Linux..."
        flutter build linux --release
        
        local source_path="build/linux/x64/release/bundle"
        local dest_path="../$BUILD_DIR/${output_basename}_linux_${TIMESTAMP}"
        
        if [ -d "$source_path" ]; then
            mkdir -p "$dest_path"
            cp -r "$source_path"/* "$dest_path/"
            print_success "$(basename "$app_dir") (Linux) built successfully!"
            print_info "Build location: $BUILD_DIR/${output_basename}_linux_${TIMESTAMP}/"
        else
            print_error "Build output not found at $source_path"
            cd .. || {
                print_error "Failed to return to parent directory from $app_dir"
                exit 1
            }
            return 1
        fi
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_info "Building for macOS..."
        flutter build macos --release
        
        local source_path="build/macos/Build/Products/Release"
        local dest_path="../$BUILD_DIR/${output_basename}_macos_${TIMESTAMP}"
        
        if [ -d "$source_path" ]; then
            mkdir -p "$dest_path"
            cp -r "$source_path"/* "$dest_path/"
            print_success "$(basename "$app_dir") (macOS) built successfully!"
            print_info "Build location: $BUILD_DIR/${output_basename}_macos_${TIMESTAMP}/"
        else
            print_error "Build output not found at $source_path"
            cd .. || {
                print_error "Failed to return to parent directory from $app_dir"
                exit 1
            }
            return 1
        fi
        
    else
        print_warning "Unsupported platform: $OSTYPE"
        cd .. || {
            print_error "Failed to return to parent directory from $app_dir"
            exit 1
        }
        return 1
    fi
    
    # Return to parent directory with error handling
    cd .. || {
        print_error "Failed to return to parent directory from $app_dir"
        exit 1
    }
    return 0
}

# ============================================
# Desktop App Build
# ============================================

build_desktop_app() {
    print_header "Building Desktop App"
    build_flutter_app "desktop_app" "desktop_app"
}

# ============================================
# Owner App Build
# ============================================

build_owner_app() {
    print_header "Building Owner App"
    build_flutter_app "owner_app" "owner_app"
}

# ============================================
# Main Build Process
# ============================================

main() {
    # Run pre-flight checks first (moved from top-level to avoid parse-time exits)
    run_preflight_checks
    
    print_header "Secure File Print System - Client Build Script"
    echo ""
    
    # Track start time
    START_TIME=$(date +%s)
    
    # Build all apps
    build_mobile_app
    echo ""
    
    build_desktop_app
    echo ""
    
    build_owner_app
    echo ""
    
    # Calculate build time
    END_TIME=$(date +%s)
    BUILD_TIME=$((END_TIME - START_TIME))
    
    # Summary
    print_header "Build Summary"
    print_success "All builds completed!"
    print_info "Total build time: ${BUILD_TIME} seconds"
    print_info "Build artifacts location: $BUILD_DIR/"
    
    # List build artifacts
    echo ""
    print_info "Build artifacts:"
    ls -lh "$BUILD_DIR/" | tail -n +2
}

# Run main function
main
