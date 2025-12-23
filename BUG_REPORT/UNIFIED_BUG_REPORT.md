# SafeCopy - Unified Bug Report

**Report Generated:** December 8, 2025, 22:49 IST  
**Total Issues Identified:** 45  
**Issues Fixed:** 26 (58%)  
**Issues Remaining:** 19 (42%)

---

## 📊 Executive Summary

This unified report consolidates all bug reports from the SafeCopy project's BUG_REPORT folder:
- [BUG_REPORT.md](file:///c:/Users/jaswa/Downloads/SafeCopy/BUG_REPORT/BUG_REPORT.md) - Original 30 issues
- [SUPPLEMENTAL_BUG_REPORT.md](file:///c:/Users/jaswa/Downloads/SafeCopy/BUG_REPORT/SUPPLEMENTAL_BUG_REPORT.md) - 15 additional issues
- [FIXED_ISSUES_REPORT.md](file:///c:/Users/jaswa/Downloads/SafeCopy/BUG_REPORT/FIXED_ISSUES_REPORT.md) - Documentation of fixes
- [REMAINING_BUGS_REPORT.md](file:///c:/Users/jaswa/Downloads/SafeCopy/BUG_REPORT/REMAINING_BUGS_REPORT.md) - Verification report

### Overall Status by Severity

| Severity | Total Issues | Fixed | Remaining | % Complete |
|----------|--------------|-------|-----------|------------|
| 🔴 **Critical** | 14 | 7 | **7** | 50% |
| 🟠 **High** | 14 | 10 | **4** | 71% |
| 🟡 **Medium** | 12 | 9 | **3** | 75% |
| 🟢 **Low** | 5 | 0 | **5** | 0% |
| **TOTAL** | **45** | **26** | **19** | **58%** |

---

## ✅ FIXED ISSUES (26 Total)

### 🔴 Critical Security Fixes (7 Fixed)

| ID | Issue | Component | Fix Summary |
|:---|:---|:---|:---|
| **#1** | Authentication Bypass in File Upload | Backend | Enabled `@token_required` decorator on `/upload` endpoint |
| **#2** | Weak JWT Secret | Backend | Changed to use `os.getenv('JWT_SECRET')` without fallback |
| **#4** | Debug Mode Enabled | Backend | Set `debug=False` in production |
| **#32** | Dummy Token Bypass | Mobile App | Removed fallback to "dummy-token", now throws auth error |
| **#33** | AES Key Exposed in Memory | Mobile App | Removed 'key' from return value, implemented 3-pass secure shredding |
| **#34** | No Login/Registration | Mobile App | Login and registration screens already implemented |
| **#31** | Hardcoded IP Address | Mobile App | Updated to network IP (still needs configuration UI) |

### 🟠 High Priority Fixes (10 Fixed)

| ID | Issue | Component | Fix Summary |
|:---|:---|:---|:---|
| **#6** | Hardcoded API URL in Desktop App | Desktop App | Now uses `config.json` for API URL configuration |
| **#10** | Missing Input Validation | Backend | Added filename sanitization using regex |
| **#11** | Private Keys Stored in Plain Text | Desktop App | Implemented AES-256 encryption for private keys |
| **#15** | No File Size Limits | Backend | Implemented 50MB file size limit |
| **#22** | No File Type Validation on Backend | Backend | Enforces `['pdf', 'doc', 'docx']` allowlist |
| **#35** | RAM Security (Decrypted File) | Desktop App | Explicitly clears `_decryptedBytes` after printing |
| **#36** | Incorrect Status Workflow | Desktop App | Changed to `PRINT_COMPLETED` status after print |
| **#37** | SSE Memory Leak | Backend | Added `timeout=20` to SSE queue listener |
| **#40** | Public Key Without Validation | Mobile App | Implemented Trust-On-First-Use (TOFU) with fingerprint validation |
| **#42** | No Operation Timeouts | Mobile App | Added configurable timeouts and cancellation tokens |
| **#43** | Provider Services Not Disposed | Desktop App | Implemented `dispose` logic for `NotificationService` |

### 🟡 Medium Priority Fixes (9 Fixed)

| ID | Issue | Component | Fix Summary |
|:---|:---|:---|:---|
| **#3** | CORS Wildcard | Backend | Now uses configurable `CORS_ORIGINS` environment variable |
| **#13** | File History Sync | Mobile App | Fixed logic to prevent false "REJECTED" status |
| **#23** | UTC Timestamp Display | Desktop App | Appends 'Z' to timestamps for proper timezone conversion |
| **#44** | Debug Logging Sensitive Data | Mobile App | Created `SecureLogger` with data sanitization |
| **#45** | No Network Connectivity Check | Mobile App | Created `ConnectivityService` for pre-operation checks |
| **#18** | Auto-Reject Logic Silent Failures | Desktop App | Added error logging and user notification |
| **#19** | Timer Not Cancelled on SSE Failure | Desktop App | Implemented adaptive polling with exponential backoff |
| **#21** | Decryption Errors Crash Print Preview | Desktop App | Added safe decryption handling and retry UI |

### 🟢 Low Priority Fixes (0 Fixed)

*No low priority issues have been fixed yet.*

---

## 🚨 REMAINING ISSUES (19 Total)

> [!CAUTION]
> **7 CRITICAL issues** and **5 HIGH severity issues** remain unresolved. The application is **NOT production-ready** until these are addressed.

### 🔴 Critical Issues Remaining (7)

| ID | Issue | Component | Impact |
|:---|:---|:---|:---|
| **#5** | No Database Migration on Schema Changes | Backend | **DATA LOSS RISK** - Updates will wipe user data |
| **#7** | Unhandled JWT Token Expiration | Desktop App | Users logged out every 15 minutes, no refresh mechanism |
| **#12** | No SSL/TLS Certificate Validation | Desktop/Mobile | **MITM ATTACKS** possible, credentials sent over HTTP |

> [!WARNING]
> **SSL/TLS Implementation Required**: Both desktop and mobile apps currently use `http://` connections. Production deployment MUST implement HTTPS with proper certificate validation.

### 🟠 High Priority Issues Remaining (4)

| ID | Issue | Component | Impact |
|:---|:---|:---|:---|
| **#8** | SQL Injection in Token Validation | Backend | Potential database compromise if token hashing fails |
| **#9** | No Rate Limiting on Auth Endpoints | Backend | **BRUTE FORCE ATTACKS** possible, DDoS vulnerability |
| **#13** | Unencrypted Database File | Backend | All user data readable if server compromised |
| **#14** | Error Messages Expose Internal Details | Backend | Helps attackers craft exploits |
| **#39** | No Certificate Pinning | Mobile/Desktop | Vulnerable to SSL stripping attacks |
| **#41** | File Extension Validation Only on Client | Backend | Malicious apps can bypass restrictions |

### 🟡 Medium Priority Issues Remaining (3)

| ID | Issue | Component | Impact |
|:---|:---|:---|:---|
| **#16** | Session Management Issues | Backend | Database fills with stale sessions |
| **#17** | Owner Email/ID Resolution Inefficiency | Backend | Unnecessary database queries slow uploads |
| **#20** | No Pagination for File Lists | Backend | Users lose access to files beyond 100 |
| **#24** | SSE Connection Not Authenticated | Backend | Unauthorized access to notifications |
| **#38** | Multiple Service Instances Created | Mobile App | Memory overhead, inefficient resource usage |

### 🟢 Low Priority Issues Remaining (5)

| ID | Issue | Component | Impact |
|:---|:---|:---|:---|
| **#25** | Inconsistent Error Response Formats | Backend | Developer confusion, harder maintenance |
| **#26** | Unused Imports and Dead Code | All | Code bloat, slower development |
| **#27** | No Logging/Monitoring | Backend | Hard to debug production issues |
| **#28** | Hardcoded UI Strings | Desktop/Mobile | No internationalization support |
| **#29** | No Database Backup Mechanism | Backend | Complete data loss possible during failures |
| **#30** | Missing API Versioning | Backend | Breaking changes affect all clients |

---

## 🎯 Recommended Action Plan

### Phase 1: CRITICAL FIXES (Must Fix Before ANY Deployment)

**Backend:**
1. ✅ ~~Enable authentication on `/upload` endpoint~~ - **FIXED**
2. ✅ ~~Replace hardcoded JWT secret~~ - **FIXED**
3. ✅ ~~Restrict CORS to specific domains~~ - **FIXED** (configurable)
4. ✅ ~~Disable debug mode~~ - **FIXED**
5. ❌ **Implement database migrations** - **REMAINING**
6. ❌ **Implement JWT token refresh mechanism** - **REMAINING**
7. ❌ **Enable HTTPS/SSL with certificate validation** - **REMAINING**

**Desktop App:**
8. ✅ ~~Make API URL configurable~~ - **FIXED**
9. ✅ ~~Encrypt private keys at rest~~ - **FIXED**
10. ❌ **Implement JWT refresh mechanism** - **REMAINING**
11. ✅ ~~Fix status workflow (use PRINT_COMPLETED)~~ - **FIXED**

**Mobile App:**
12. ⚠️ **Make API URL fully configurable** - **PARTIAL** (needs UI)
13. ✅ ~~Remove dummy token fallbacks~~ - **FIXED**
14. ✅ ~~Implement login/registration~~ - **FIXED**
15. ✅ ~~Remove AES key from memory~~ - **FIXED**

### Phase 2: HIGH PRIORITY SECURITY (Fix Before Beta)

16. ❌ Add rate limiting to auth endpoints (#9)
17. ❌ Implement proper input validation and sanitization (#8)
18. ❌ Encrypt database at rest (#13)
19. ❌ Implement certificate pinning (#39)
20. ✅ ~~Backend file type validation~~ - **FIXED** (#22)

### Phase 3: MEDIUM PRIORITY UX IMPROVEMENTS

21. ❌ Add pagination for file lists (#20)
22. ❌ Fix session management (#16)
23. ✅ ~~Improve error handling (#18, #21)~~ - **FIXED**
24. ❌ Optimize database queries (#17)

### Phase 4: LOW PRIORITY POLISH

25. ❌ Database backups (#29)
26. ❌ API versioning (#30)
27. ❌ Code cleanup (#26)
28. ❌ Internationalization (#28)

---

## 🛠️ New Security Features Implemented

### Mobile App Security Enhancements (December 8, 2025)

#### 1. Trust-On-First-Use (TOFU) Public Key Validation
- **File:** `mobile_app/lib/services/public_key_trust_service.dart`
- **Feature:** SHA256 fingerprint validation with MITM detection
- **Impact:** Prevents attackers from substituting malicious RSA keys

#### 2. Operation Timeout Protection
- **File:** `mobile_app/lib/utils/operation_timeout.dart`
- **Feature:** Configurable timeouts (5min encryption, 30s API, 15s key fetch)
- **Impact:** Prevents app hangs on large files or poor connections

#### 3. Secure Logging System
- **File:** `mobile_app/lib/utils/secure_logger.dart`
- **Feature:** Data sanitization for sensitive information in logs
- **Impact:** Prevents token/key leakage to device logs

#### 4. Network Connectivity Service
- **File:** `mobile_app/lib/services/connectivity_service.dart`
- **Feature:** Pre-operation internet checks with user-friendly messages
- **Impact:** Better UX instead of cryptic network errors

---

## 📈 Progress Timeline

### December 8, 2025 - Major Security Update
- ✅ Fixed 7 critical mobile app security issues
- ✅ Implemented TOFU key validation
- ✅ Added operation timeouts
- ✅ Secured debug logging
- ✅ Added connectivity checks

### Previous Fixes (Earlier)
- ✅ Backend authentication and input validation
- ✅ Desktop app key encryption and status fixes
- ✅ File size limits and type validation
- ✅ SSE memory leak prevention
- ✅ Desktop stability improvements (Auto-reject, Backoff, Crash prevention)

---

## 🔒 Current Security Posture

### ✅ SECURED
- Authentication bypass vulnerabilities
- Secret key exposure in code
- AES key memory exposure
- MITM detection (TOFU)
- Input validation on critical endpoints
- File upload protections

### ⚠️ PARTIALLY SECURED
- Configuration management (needs UI)
- SSL/TLS (infrastructure needed)
- Database security (no migrations yet)

### ❌ UNSECURED
- Token refresh mechanism (15min expiration)
- Rate limiting on auth endpoints
- Database encryption at rest
- Certificate pinning
- Production-grade logging/monitoring

---

## 📝 Testing Coverage

### ✅ Recommended Tests Passed
- End-to-end upload → decrypt → print flow
- TOFU fingerprint validation
- Timeout protection on large files
- Connectivity error handling
- Memory security (AES key wiping)

### ❌ Tests Still Needed
- Penetration testing (OWASP ZAP)
- Load testing (file size limits)
- Token expiration and refresh
- Database migration scenarios
- SSL certificate validation

---

## 💡 Key Takeaways

### What's Working Well
1. **Core Security:** Authentication, encryption, and key management are now solid
2. **Mobile App:** Major security overhaul completed with TOFU, timeouts, and secure logging
3. **Desktop App:** Private key encryption and proper status workflows implemented
4. **Backend:** Input validation, file limits, and SSE improvements in place

### What Needs Attention
1. **🔴 CRITICAL:** SSL/TLS implementation for production
2. **🔴 CRITICAL:** Database migration system to prevent data loss
3. **🔴 CRITICAL:** JWT token refresh to avoid 15-minute logouts
4. **🟠 HIGH:** Rate limiting to prevent brute force attacks
5. **🟠 HIGH:** Database encryption at rest

### Deployment Readiness
- **Development Environment:** ✅ Safe to use
- **Internal Testing:** ✅ Ready with caveats
- **Beta Release:** ⚠️ Fix Phase 2 issues first
- **Production Release:** ❌ BLOCKED - Fix all Critical issues

---

## 📞 Support and Resources

### Documentation References
- [Original Bug Report](file:///c:/Users/jaswa/Downloads/SafeCopy/BUG_REPORT/BUG_REPORT.md)
- [Supplemental Report](file:///c:/Users/jaswa/Downloads/SafeCopy/BUG_REPORT/SUPPLEMENTAL_BUG_REPORT.md)
- [Fixed Issues Report](file:///c:/Users/jaswa/Downloads/SafeCopy/BUG_REPORT/FIXED_ISSUES_REPORT.md)
- [Remaining Bugs Verification](file:///c:/Users/jaswa/Downloads/SafeCopy/BUG_REPORT/REMAINING_BUGS_REPORT.md)

---

> [!IMPORTANT]
> **Next Immediate Actions:**
> 1. Implement HTTPS/SSL for all API communication
> 2. Add database migration system (use Alembic for Flask)
> 3. Implement token refresh mechanism (both desktop and mobile)
> 4. Add rate limiting middleware to backend
> 5. Conduct third-party security audit before production release

**Estimated Time to Production-Ready:** 2-3 weeks of full-time development

---

## 📋 Complete List of Pending Issues (23 Total)

> [!WARNING]
> This section lists ALL remaining issues in priority order. **7 Critical** and **5 High** severity issues must be resolved before production deployment.

---

### 🔴 CRITICAL PRIORITY (7 Issues)

#### Issue #5: No Database Migration on Schema Changes
- **Component:** Backend (`db.py`)
- **Location:** [db.py:L48-54](file:///c:/Users/jaswa/Downloads/SafeCopy/backend_flask/db.py#L48-54)
- **Problem:** Database only initialized if it doesn't exist; no migration system for schema updates
- **Impact:** Any application update requiring database changes will wipe all user data
- **Risk:** **DATA LOSS** - All files, users, and history destroyed on updates
- **Fix Required:** Implement Alembic or Flask-Migrate for database version control

#### Issue #7: Unhandled JWT Token Expiration
- **Component:** Desktop App + Backend
- **Location:** [auth_utils.py:L23](file:///c:/Users/jaswa/Downloads/SafeCopy/backend_flask/auth_utils.py#L23)
- **Problem:** Tokens expire after 15 minutes with no refresh mechanism
- **Impact:** Users must log in every 15 minutes during active sessions
- **Risk:** **POOR UX** - Interrupts workflow, frustrates users
- **Fix Required:** Implement refresh token rotation on both backend and desktop client

#### Issue #12: No SSL/TLS Certificate Validation
- **Component:** Desktop App + Mobile App + Backend
- **Location:** All API services using `http://`
- **Problem:** All communication over unencrypted HTTP, no certificate validation
- **Impact:** **MITM ATTACKS** - Credentials, tokens, and encrypted files intercepted
- **Risk:** **CRITICAL SECURITY** - Complete communication compromise
- **Fix Required:** 
  - Deploy backend with HTTPS (Let's Encrypt or commercial cert)
  - Update mobile/desktop apps to use `https://` URLs
  - Implement certificate validation in HTTP clients

---

### 🟠 HIGH PRIORITY (5 Issues)

#### Issue #8: SQL Injection Vulnerability in Token Validation
- **Component:** Backend
- **Location:** [routes/owners.py:L163](file:///c:/Users/jaswa/Downloads/SafeCopy/backend_flask/routes/owners.py#L163)
- **Problem:** Inconsistent parameterization; potential SQL injection if token hashing fails
- **Impact:** Attackers could execute arbitrary SQL queries
- **Risk:** Database compromise, data theft
- **Fix Required:** Audit all SQL queries for consistent parameterization

#### Issue #9: No Rate Limiting on Auth Endpoints
- **Component:** Backend
- **Location:** All routes in `routes/auth.py`
- **Problem:** No throttling or rate limiting on login/register endpoints
- **Impact:** Brute force attacks, account enumeration, DDoS vulnerability
- **Risk:** User accounts vulnerable to password cracking
- **Fix Required:** Implement Flask-Limiter with per-IP rate limits (e.g., 5 login attempts per minute)

#### Issue #13: Unencrypted Database File
- **Component:** Backend
- **Location:** [db.py:L9](file:///c:/Users/jaswa/Downloads/SafeCopy/backend_flask/db.py#L9)
- **Problem:** SQLite database stored as plain file without encryption
- **Impact:** All user data readable if server is compromised
- **Risk:** Complete data breach if attacker gains server access
- **Fix Required:** Use SQLCipher for encrypted SQLite or migrate to PostgreSQL with encryption at rest

#### Issue #14: Error Messages Expose Internal Details
- **Component:** Backend
- **Location:** Multiple files (e.g., [routes/files.py:L102](file:///c:/Users/jaswa/Downloads/SafeCopy/backend_flask/routes/files.py#L102))
- **Problem:** Stack traces and internal errors logged/exposed in debug mode
- **Impact:** Helps attackers understand system internals and craft exploits
- **Risk:** Information disclosure aids targeted attacks
- **Fix Required:** Implement structured logging with sanitized error messages

#### Issue #39: No Certificate Pinning for API Calls
- **Component:** Mobile App + Desktop App
- **Location:** All HTTP clients
- **Problem:** No SSL certificate pinning implemented
- **Impact:** Vulnerable to SSL stripping and sophisticated MITM attacks
- **Risk:** Even with HTTPS, attackers can intercept with rogue certificates
- **Fix Required:** Implement certificate pinning with backup pins in both mobile and desktop apps

#### Issue #41: File Extension Validation Only on Client Side
- **Component:** Backend (partial - now fixed on backend too per FIXED_ISSUES_REPORT)
- **Location:** Backend validation vs. client-side validation consistency
- **Problem:** Malicious apps can bypass mobile UI restrictions with direct API calls
- **Impact:** Invalid file types stored in database, can't be printed
- **Risk:** User confusion, storage waste
- **Fix Required:** **Already partially fixed** - Verify backend enforcement is complete

#### Issue #43: Provider Services Not Properly Disposed
- **Component:** Desktop App
- **Location:** [main.dart:L39-46](file:///c:/Users/jaswa/Downloads/SafeCopy/desktop_app/lib/main.dart#L39-46)
- **Problem:** Services created without dispose logic
- **Impact:** Unclosed file handles, network connections persist after app exit
- **Risk:** Resource leaks, file locking issues on Windows
- **Fix Required:** Implement dispose methods for all Provider services

---

### 🟡 MEDIUM PRIORITY (6 Issues)

#### Issue #16: Session Management Issues
- **Component:** Backend
- **Location:** [routes/auth.py:L51](file:///c:/Users/jaswa/Downloads/SafeCopy/backend_flask/routes/auth.py#L51)
- **Problem:** Duplicate sessions created on each login; old sessions never invalidated
- **Impact:** Database fills with stale sessions; stolen devices can't be logged out remotely
- **Fix Required:** Add session cleanup on login + logout endpoint

#### Issue #17: Owner Email/ID Resolution Inefficiency
- **Component:** Backend
- **Location:** [routes/files.py:L45-61](file:///c:/Users/jaswa/Downloads/SafeCopy/backend_flask/routes/files.py#L45-61)
- **Problem:** Two database queries to resolve owner (by email, then by ID)
- **Impact:** Slower upload times, unnecessary database load
- **Fix Required:** Optimize to single query or cache owner lookups

#### Issue #18: Auto-Reject Logic Silent Failures
- **Component:** Desktop App
- **Location:** [screens/dashboard_screen.dart:L158-165](file:///c:/Users/jaswa/Downloads/SafeCopy/desktop_app/lib/screens/dashboard_screen.dart#L158-165)
- **Problem:** Status update failures caught with empty catch block
- **Impact:** Files deleted without proper status updates; broken audit trail
- **Fix Required:** Log errors and show user notification on failure

#### Issue #19: Timer Not Cancelled on SSE Failure
- **Component:** Desktop App
- **Location:** [screens/dashboard_screen.dart:L36](file:///c:/Users/jaswa/Downloads/SafeCopy/desktop_app/lib/screens/dashboard_screen.dart#L36)
- **Problem:** Polling timer continues even if API is down
- **Impact:** Battery drain, network spam, wasted resources
- **Fix Required:** Cancel timer on consecutive API failures

#### Issue #20: No Pagination for File Lists
- **Component:** Backend
- **Location:** [routes/files.py:L122](file:///c:/Users/jaswa/Downloads/SafeCopy/backend_flask/routes/files.py#L122)
- **Problem:** Hardcoded LIMIT 100 with no pagination support
- **Impact:** Users with >100 files can't access older uploads
- **Fix Required:** Implement offset/limit pagination in API

#### Issue #21: Decryption Errors Crash Print Preview
- **Component:** Desktop App
- **Location:** [services/encryption_service.dart:L25-27](file:///c:/Users/jaswa/Downloads/SafeCopy/desktop_app/lib/services/encryption_service.dart#L25-27)
- **Problem:** Decryption failures throw unhandled exceptions
- **Impact:** One corrupted file makes entire print preview unusable
- **Fix Required:** Graceful error handling with skip option for corrupted files

#### Issue #24: SSE Connection Not Authenticated
- **Component:** Backend
- **Location:** `routes/events.py`
- **Problem:** Verify if SSE endpoint properly validates tokens
- **Impact:** Potential unauthorized access to real-time notifications
- **Fix Required:** Audit and ensure SSE endpoint has `@token_required` decorator

#### Issue #38: Multiple Service Instances Created Per Screen
- **Component:** Mobile App
- **Location:** [main.dart:L127-128](file:///c:/Users/jaswa/Downloads/SafeCopy/mobile_app/lib/main.dart#L127-128)
- **Problem:** New service instances on every screen build instead of singletons
- **Impact:** Memory overhead, inefficient resource usage
- **Fix Required:** Convert services to GetIt or Provider singletons

---

### 🟢 LOW PRIORITY (5 Issues)

#### Issue #25: Inconsistent Error Response Formats
- **Component:** Backend
- **Location:** Various API routes
- **Problem:** Some routes return `{'error': True}`, others `{'error': 'message'}`
- **Impact:** Client code must handle multiple formats
- **Fix Required:** Standardize on single error response schema

#### Issue #26: Unused Imports and Dead Code
- **Component:** All (Backend, Desktop, Mobile)
- **Location:** Multiple files
- **Problem:** Commented-out code and unused imports throughout codebase
- **Impact:** Code bloat, developer confusion
- **Fix Required:** Run linters and cleanup unused code

#### Issue #27: No Logging/Monitoring
- **Component:** Backend
- **Location:** Entire application
- **Problem:** Only print statements; no structured logging
- **Impact:** Hard to debug production issues, no audit trail
- **Fix Required:** Implement Python logging with log levels and rotation

#### Issue #28: Hardcoded UI Strings
- **Component:** Desktop App + Mobile App
- **Location:** All Flutter screens
- **Problem:** No internationalization (i18n) support
- **Impact:** App only in English; can't support other languages
- **Fix Required:** Implement Flutter i18n with ARB files

#### Issue #29: No Database Backup Mechanism
- **Component:** Backend
- **Location:** Database setup
- **Problem:** No automated backups configured
- **Impact:** Complete data loss possible during server failures
- **Fix Required:** Setup automated SQLite backups or migrate to managed database with backups

#### Issue #30: Missing API Versioning
- **Component:** Backend
- **Location:** [app.py](file:///c:/Users/jaswa/Downloads/SafeCopy/backend_flask/app.py)
- **Problem:** Routes like `/api/upload` have no version (should be `/api/v1/upload`)
- **Impact:** Breaking changes affect all clients; no migration path
- **Fix Required:** Implement API versioning strategy (URL-based or header-based)

---

## 🎯 Quick Reference: Issues by Component

### Backend Issues (13 remaining)

| # | Issue Name | Severity |
|---|---|---|
| #5 | No Database Migration on Schema Changes | 🔴 Critical |
| #7 | Unhandled JWT Token Expiration | 🔴 Critical |
| #8 | SQL Injection Vulnerability in Token Validation | 🟠 High |
| #9 | No Rate Limiting on Auth Endpoints | 🟠 High |
| #13 | Unencrypted Database File | 🟠 High |
| #14 | Error Messages Expose Internal Details | 🟠 High |
| #16 | Session Management Issues | 🟡 Medium |
| #17 | Owner Email/ID Resolution Inefficiency | 🟡 Medium |
| #20 | No Pagination for File Lists | 🟡 Medium |
| #24 | SSE Connection Not Authenticated | 🟡 Medium |
| #25 | Inconsistent Error Response Formats | 🟢 Low |
| #27 | No Logging/Monitoring | 🟢 Low |
| #29 | No Database Backup Mechanism | 🟢 Low |
| #30 | Missing API Versioning | 🟢 Low |

### Desktop App Issues (2 remaining)

| # | Issue Name | Severity |
|---|---|---|
| #7 | Unhandled JWT Token Expiration | 🔴 Critical |
| #12 | No SSL/TLS Certificate Validation | 🔴 Critical |

### Mobile App Issues (2 remaining)

| # | Issue Name | Severity |
|---|---|---|
| #12 | No SSL/TLS Certificate Validation | 🔴 Critical |
| #38 | Multiple Service Instances Created Per Screen | 🟡 Medium |

### Cross-Platform/Infrastructure Issues (2 remaining)

| # | Issue Name | Severity | Components |
|---|---|---|---|
| #39 | No Certificate Pinning for API Calls | 🟠 High | Mobile + Desktop |
| #41 | File Extension Validation Only on Client Side | 🟠 High | Backend + Mobile |

---

*Report compiled from 4 source documents totaling 45 unique issues across backend, desktop, and mobile components.*
