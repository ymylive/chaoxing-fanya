# User Authentication Specification

## 1. Overview

### 1.1 Purpose
Define the authentication system for Chaoxing Learning Assistant GUI, providing secure login, session management, and user credential handling.

### 1.2 Scope
- User login/logout flows
- Session persistence and management
- Captcha handling
- Credential storage and security
- Error handling and user feedback

### 1.3 Stakeholders
- End Users: Students using Chaoxing platform
- Developers: Maintaining authentication system
- Security: Ensuring credential protection

## 2. System Context

### 2.1 Dependencies
- `api.base.Chaoxing` - Core authentication API
- `api.cookies` - Session persistence
- `api.captcha` - CAPTCHA handling (optional, Python < 3.13)
- `api.exceptions` - Error types
- `keyring` - Secure credential storage (Windows Credential Manager)

### 2.2 Integration Points
- GUI LoginWorker (QThread)
- Main application workflow
- Configuration system
- Logging system

## 3. Functional Requirements

### 3.1 Authentication Flow

#### FR-001: User Login
**Priority:** Critical
**Description:** User can authenticate using phone number and password

**Acceptance Criteria:**
- User enters valid phone number and password
- System validates input format
- System calls `Chaoxing.login()` API
- On success, user is authenticated and courses are accessible
- On failure, appropriate error message is displayed

#### FR-002: Session Persistence
**Priority:** High
**Description:** User sessions persist across application restarts

**Acceptance Criteria:**
- Successful login saves session cookies to `cookies.txt`
- Application startup attempts cookie-based authentication
- Invalid cookies trigger credential-based login
- Session refresh on successful re-authentication

#### FR-003: Captcha Challenge
**Priority:** Medium
**Description:** Handle CAPTCHA challenges during login

**Acceptance Criteria:**
- CAPTCHA modal appears when required by server
- OCR auto-fill when available (Python < 3.13)
- Manual input always available
- Retry mechanism after CAPTCHA resolution

#### FR-004: Credential Management
**Priority:** Medium
**Description:** Secure storage and retrieval of user credentials

**Acceptance Criteria:**
- "Remember Me" option stores credentials securely
- Auto-fill credentials on application restart
- No automatic login without user consent
- Option to clear stored credentials

### 3.2 Session Management

#### FR-005: Logout
**Priority:** Medium
**Description:** User can terminate session and clear data

**Acceptance Criteria:**
- Logout clears in-memory session data
- Option to delete cookies and stored credentials
- User returns to login state
- All authenticated operations become unavailable

#### FR-006: Auto-refresh
**Priority:** Low
**Description:** Automatic session refresh when possible

**Acceptance Criteria:**
- Detect session expiration
- Attempt automatic re-authentication with stored credentials
- Fallback to login prompt on failure

## 4. Non-Functional Requirements

### 4.1 Security Requirements

#### NFR-001: Credential Protection
- Passwords never logged or stored in plaintext
- Phone numbers masked in logs (138****0000)
- Use Windows Credential Manager for secure storage
- Fallback to DPAPI-protected local storage
- Clear sensitive data from memory after use

#### NFR-002: Session Security
- Restrict `cookies.txt` to current user permissions
- Session cookies encrypted in transit
- No sensitive data in application logs

### 4.2 Performance Requirements

#### NFR-003: Response Time
- Login attempt completes within 30 seconds
- UI remains responsive during authentication
- Background thread for network operations

#### NFR-004: Reliability
- Retry mechanism for transient failures (max 3 attempts)
- Exponential backoff (1s, 2s, 4s)
- Rate limiting: minimum 1s between attempts

### 4.3 Usability Requirements

#### NFR-005: User Experience
- Clear visual feedback for all states
- Intuitive error messages with actionable guidance
- Accessibility support (keyboard navigation, screen readers)
- Consistent with platform UI guidelines

## 5. User Interface Specifications

### 5.1 Login Panel
```
┌─────────────────────────────────┐
│ 账号登录                          │
├─────────────────────────────────┤
│ 手机号                           │
│ [___________________]           │
│ 密码                            │
│ [___________________] [👁]      │
│ □ 记住我                         │
│                                 │
│ [     登录并获取课程     ]        │
└─────────────────────────────────┘
```

### 5.2 CAPTCHA Modal
```
┌─────────────────────────────────┐
│ 验证码验证                        │
├─────────────────────────────────┤
│ [CAPTCHA IMAGE]                 │
│                                 │
│ 验证码                           │
│ [___________________]           │
│                                 │
│ [取消]              [确认]       │
└─────────────────────────────────┘
```

### 5.3 Authentication Status
```
Header: "已登录: 138****0000" | [登出]
```

## 6. Error Handling

### 6.1 Error Types

| Error Code | Description | User Message | Action |
|------------|-------------|--------------|--------|
| AUTH_001 | Invalid credentials | 用户名或密码错误 | Show retry option |
| AUTH_002 | Network timeout | 网络超时，请重试 | Show retry button |
| AUTH_003 | CAPTCHA required | 需要验证码验证 | Show CAPTCHA modal |
| AUTH_004 | CAPTCHA failed | 验证码错误，请重试 | Allow re-entry |
| AUTH_005 | Account locked | 账号异常，请联系客服 | Show support info |
| AUTH_006 | Server error | 服务器异常，请稍后重试 | Show retry option |

### 6.2 Error Recovery
- Transient errors: automatic retry with backoff
- Credential errors: require user input
- Network errors: offline detection and retry mechanism
- Unknown errors: log details, show generic message

## 7. State Management

### 7.1 Authentication States
```
┌─────────────────┐
│ Unauthenticated │
└─────────┬───────┘
          │ login()
          ▼
┌─────────────────┐    CAPTCHA    ┌──────────────────┐
│ Authenticating  │◄──────────────┤ ChallengeRequired│
└─────────┬───────┘               └──────────────────┘
          │ success
          ▼
┌─────────────────┐
│ Authenticated   │
└─────────┬───────┘
          │ logout()
          ▼
┌─────────────────┐
│ LoggingOut      │
└─────────────────┘
```

### 7.2 State Transitions
- `Unauthenticated` → `Authenticating`: User clicks login
- `Authenticating` → `Authenticated`: Login success
- `Authenticating` → `ChallengeRequired`: CAPTCHA needed
- `ChallengeRequired` → `Authenticating`: CAPTCHA submitted
- `Authenticated` → `LoggingOut`: User clicks logout
- `LoggingOut` → `Unauthenticated`: Logout complete
- Any state → `Unauthenticated`: Error or session expired

## 8. Configuration

### 8.1 Configuration Options
```ini
[auth]
# Enable credential storage
remember = true

# Auto-login on startup (requires remember=true)
autologin = false

# Credential storage backend: keyring|dpapi|none
store_backend = keyring

# Login timeout in seconds
timeout = 30

[network]
# HTTP proxy for authentication (optional)
proxy = http://127.0.0.1:7890

# Retry configuration
max_retries = 3
retry_delay = 1
```

## 9. Logging and Monitoring

### 9.1 Log Levels
- **INFO**: Authentication state changes, retry counts
- **DEBUG**: HTTP status codes (no sensitive data)
- **ERROR**: Authentication failures, network errors
- **TRACE**: Disabled by default for security

### 9.2 Log Examples
```
INFO: Authentication state: Unauthenticated → Authenticating
INFO: Login successful for user 138****0000
DEBUG: HTTP 200 - Authentication API response
ERROR: Login failed - Invalid credentials (AUTH_001)
INFO: Session restored from cookies for user 138****0000
```

## 10. Testing Strategy

### 10.1 Unit Tests
- Credential validation logic
- State machine transitions
- Error handling paths
- Secure storage operations

### 10.2 Integration Tests
- Login flow with mock API
- CAPTCHA handling workflow
- Session persistence across restarts
- Configuration loading and validation

### 10.3 Security Tests
- Credential masking in logs
- Secure storage encryption
- Session cookie protection
- Memory cleanup validation

## 11. Implementation Notes

### 11.1 Thread Safety
- All network operations in background threads
- Thread-safe state updates using Qt signals
- Atomic operations for credential storage

### 11.2 Cross-Platform Considerations
- Windows: Use Credential Manager via `keyring`
- Fallback: DPAPI-protected file storage
- File permissions: user-only access

### 11.3 Future Enhancements
- Two-factor authentication support
- Single Sign-On (SSO) integration
- Biometric authentication
- Multi-account management

## 12. Acceptance Criteria Summary

### 12.1 Must Have
- ✅ User can login with phone/password
- ✅ Session persists across app restarts
- ✅ Clear error messages for all failure cases
- ✅ Secure credential storage (Windows)
- ✅ CAPTCHA handling when required

### 12.2 Should Have
- ✅ Auto-fill credentials with "Remember Me"
- ✅ Logout with option to clear data
- ✅ Network proxy support
- ✅ Retry mechanism with backoff

### 12.3 Could Have
- Auto-refresh expired sessions
- Multiple account profiles
- Advanced security options
- Detailed authentication logs

---

**Document Version:** 1.0  
**Last Updated:** 2024-01-20  
**Status:** Draft  
**Approved By:** [Pending]


