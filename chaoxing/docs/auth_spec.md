## User Authentication Spec

### Goal
Provide a secure, reliable, and user-friendly authentication flow to Chaoxing, integrated with the existing core (`api.base.Chaoxing`) and the PySide6 GUI.

### Assumptions
- Remote auth uses `api.base.Chaoxing.login()` and persists session via `api.cookies.save_cookies`/`use_cookies` to `cookies.txt`.
- Optional captcha via `api.captcha.CxCaptcha` with DdddOcr (< Python 3.13). Fallback to manual.

### UX Requirements
- Login panel: phone, password; show/hide password; Remember me; Login/Cancel; disabled controls + busy indicator while authenticating.
- Status: header shows “Signed in as 138****0000”; Sign out action.
- Captcha modal: shows image; input field; auto-fill if OCR available; retry.
- Logout: clears in-memory session; optionally clear saved credentials and cookies.

### Functional Requirements
- FR-1 Validate input (non-empty; trim; basic phone format).
- FR-2 Login: call `Chaoxing.login()`. On success, save cookies (session reuse).
- FR-3 Cookie reuse: at startup, try cookie-only session; fallback to credential login on failure.
- FR-4 Captcha: when required, present modal; support OCR auto-fill if available; retry login after success.
- FR-5 Session persistence: use `cookies.txt` path from `GlobalConst.COOKIES_PATH`; refresh after successful login.
- FR-6 Logout: invalidate in-memory session; optionally delete cookies and saved credentials.
- FR-7 Remember me: securely store credentials; auto-fill on next launch; no auto-login unless enabled.
- FR-8 Retry/backoff: transient errors retry up to 3 times (1s/2s/4s); abort on credential errors.
- FR-9 Rate limit: minimum 1s spacing between repeated login attempts.
- FR-10 Offline detection: show dedicated message; provide retry.
- FR-11 Proxy support: optional HTTP proxy for login only.
- FR-12 No telemetry.

### Security Requirements
- SR-1 Never log secrets (passwords, tokens). Mask phone (e.g., 138****0000).
- SR-2 Secure storage: prefer Windows Credential Manager via `keyring`; fallback to DPAPI-protected file; else disable Remember me.
- SR-3 Limit password lifetime in memory; clear buffers after use.
- SR-4 Restrict `cookies.txt` permissions to current user; offer purge on logout.
- SR-5 Do not persist captcha images; keep in-memory only.

### Error Handling
- Wrong credentials: banner “用户名或密码错误”。
- Captcha fail: show image + input; allow retry; fall back to manual.
- Network/timeout: message + Retry.
- 403/locked: stop and show clear guidance.
- Unknown: show short typed message; encourage viewing log file.

### Logging
- INFO: auth state transitions, retries (counts only).
- DEBUG (optional): HTTP status codes only; never secrets.
- TRACE: off by default.

### Configuration
Optional `config.ini` keys:
- [auth]
  - remember = true|false
  - autologin = false (default)
  - store_backend = keyring|dpapi|none
- [network]
  - proxy = http://host:port (login only)

### State Machine
- Unauthenticated → Authenticating → Authenticated
- Authenticating → ChallengeRequired (Captcha) → Authenticating → Authenticated | Error
- Any → Error → Unauthenticated
- Authenticated → LoggingOut → Unauthenticated

### Acceptance Criteria
- AC-1 Valid cookies → auto Authenticated without password prompt.
- AC-2 Invalid cookies → prompt; success stores new cookies.
- AC-3 Wrong password → visible error, no more than one auto-retry.
- AC-4 Captcha required → modal; manual and OCR both can pass; session established.
- AC-5 Remember me → secure storage + auto-fill; no auto-submit unless autologin.
- AC-6 Logout removes session and optionally cookies + saved credentials.
- AC-7 Logs contain no secrets; masked identifiers.

### Integration Points
- Core: `api.base.Chaoxing`, `api.cookies`, `api.captcha` (optional), `api.exceptions`.
- GUI: `LoginWorker` (QThread) to avoid blocking; toast + busy indicators; proxy field.

### Risks & Mitigations
- DdddOcr unavailable on Python 3.13 → manual captcha entry.
- Backend changes → surface raw messages; keep flow resilient; centralize error mapping.
- Misconfigured proxy → detect and fall back to direct; show warning.


