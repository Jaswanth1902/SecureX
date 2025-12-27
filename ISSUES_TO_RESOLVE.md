# Desktop App Testing - Bugs Found
**Project:** SecureX - Desktop Application (Owner Side)  
**Tested By:** Nandini  
**Developer:** Abhi  
**Date:** December 7, 2025

## Table of Contents
1. [🔴 Critical Bug - Blocks Release](#-critical-bug---blocks-release)
   - [Bug #1: Session Expires After 15 Minutes](#bug-1-session-expires-after-15-minutes-without-warning)
2. [🟡 Medium Bugs](#-medium-bugs)
   - [Bug #2: Error Messages Are Too Technical](#bug-2-error-messages-are-too-technical)
3. [� Low Priority - Cosmetic](#-low-priority---cosmetic)
   - [Bug #3: VS Code Shows False C++ Errors](#bug-3-vs-code-shows-false-c-errors)
4. [Summary](#summary)
5. [What Works Correctly](#what-works-correctly-)


---

## �🔴 CRITICAL BUG - BLOCKS RELEASE

### Bug #1: Session Expires After 15 Minutes Without Warning

**What Happens:**
After 15 minutes, users cannot accept or reject files. The app shows no error message or warning.

**How to Reproduce:**
1. Login to Desktop App
2. Wait 15 minutes
3. Try to click "Accept" on any file
4. **BUG:** Nothing happens, console shows "401 Unauthorized"

**Expected Behavior:**
When session expires, show error message: "Your session has expired. Please login again."

**Actual Behavior:**
Silent failure. No error message shown to user.

**Root Cause:**
- JWT token expires after 15 minutes (`backend_flask/auth_utils.py` line 23)
- Desktop app doesn't detect 401 errors or show logout message

**Files to Fix:**
- `desktop_app/lib/services/api_service.dart` - Detect 401 errors and show logout message

**Priority:** � **CRITICAL** - Users are confused and think the app is broken

---

## 🟡 MEDIUM BUGS

### Bug #2: Error Messages Are Too Technical

**What Happens:**
When a corrupted file exists in database, users see:
```
CRITICAL ERROR: Failed to decode encryptedFileData
invalid argument/decoding error
```

**Expected Behavior:**
Show user-friendly error: "This file appears corrupted. Please re-upload or contact support."

**Actual Behavior:**
Shows technical error that normal users don't understand.

**Where to Fix:**
- File: `desktop_app/lib/screens/print_preview_screen.dart`
- Function: `_fetchAndDecrypt()`
- Lines: Around 150-180

**Priority:** 🟡 **MEDIUM** - Confusing for end users

---

## 🟢 LOW PRIORITY - COSMETIC

### Bug #3: VS Code Shows False C++ Errors

**What Happens:**
Red errors appear in `generated_plugin_registrant.cc` file in VS Code.

**Is This Actually Broken?**
**NO.** App compiles and runs perfectly. This is just VS Code IntelliSense being confused.

**Priority:** 🟢 **LOW** - Cosmetic only, no functional impact

---

## Summary

| Bug | Severity | User Impact | Must Fix? |
|-----|----------|-------------|-----------|
| #1: Session timeout | 🔴 Critical | App feels broken after 15 min | ✅ YES |
| #2: Technical errors | 🟡 Medium | Users confused by error messages | Recommended |
| #3: IDE warnings | 🟢 Low | None (cosmetic) | Optional |

---

## What Works Correctly ✅

**Verified working features:**

1. **Login/Logout** - Tested successfully with `surya@gmail.com`
2. **File List Display** - Shows uploaded files with name, size, date
3. **Accept File** - Opens print preview (works when session is valid)
4. **Reject File** - Deletes file with confirmation dialog (works when session is valid)
5. **Auto-Refresh** - Dashboard reloads file list every 10 seconds (confirmed in code: `dashboard_screen.dart` line 36)
6. **Animations** - Smooth transitions on buttons and cards (confirmed: `AnimatedContainer` in `file_card.dart`)
7. **Window Resizing** - Layout adapts when window is resized (tested from small to large windows)

**Overall:** App works well when session is valid. Main issue is Bug #1 (session timeout).

**Overall Quality:** 9/10

---

## Testing Details

- **OS:** Windows 11
- **Test Duration:** 2.5 hours
- **Test User:** surya@gmail.com
- **Backend:** Flask on localhost:5000

---

**Status:** Ready for Abhi to fix Bug #1 before release
