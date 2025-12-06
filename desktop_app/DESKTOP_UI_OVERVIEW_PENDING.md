**Desktop UI — Pending Features & Implementation Checklist**

This document lists features that are not yet implemented in the desktop UI and provides a recommended implementation checklist and testing notes.

Not yet implemented (high-priority)
- Google account authentication (desktop OAuth flow)
  - Desired: Allow owners to link a Google account for SSO and easier account recovery.
  - Implementation notes: Use an OAuth desktop flow (installed app) or open a browser-based flow with a loopback redirect. Implement server-side endpoints to accept Google tokens and map them to owner accounts.

- Delete account (UI + API)
  - Desired: Allow owner to delete their account and all associated data.
  - Backend: Add endpoint `DELETE /api/owners` or `POST /api/owners/delete` that validates token and removes owner, sessions, and owned files.
  - UI: Add a settings screen action with confirmation and secondary confirmation (type "DELETE"), inform user about irreversible removal.

- Password change flow (UI + API)
  - Desired: Owner can change password while logged in (verify current password or token).
  - Backend: Add `POST /api/owners/change-password` with `current_password`, `new_password` logic and bcrypt hashing.
  - UI: Provide form in Profile/Settings; show success and re-login (optionally) after password change.

- Notifications improvements
  - Desired: Reliable SSE or WebSocket-based notifications, with UI to show toasts and a notification center.
  - Implementation: Strengthen `NotificationService`, allow background reconnects, show actionable toasts (e.g., view file, open history).

Lower priority / nice-to-have
- Persist tokens securely (encrypted local storage)
- Improve key storage by encrypting private key with a passphrase or using OS key store
- Add UI for account recovery and linking multiple keys

Implementation checklist (practical)
1. Add backend endpoints for delete-account and change-password and write unit tests.
2. Implement frontend dialogs and confirm flows for delete and password change.
3. Implement Google OAuth integration (server + client pieces). Test with a test Google project.
4. Improve NotificationService: robust reconnection, exponential backoff, and toast UI.
5. Move private key storage to encrypted form or integrate OS key store.

Testing notes
- End-to-end tests should include: register (keygen), login (with stored key), print flow (decrypt symmetric key), delete account cleanup, password change, and notification handling.
- Use the `test_all_endpoints.py` in `backend_flask` (if present) to verify server-side endpoints before UI integration.

Quick checklist for developers
- [ ] Backend `DELETE /api/owners` (or similar) implemented
- [ ] Backend `POST /api/owners/change-password` implemented
- [ ] Desktop UI: Password-change form added
- [ ] Desktop UI: Delete account action with confirmation added
- [ ] Google OAuth flow designed and implemented (server + client)
- [ ] Notification UI and background handling improved

If you want, I can start implementing any one of the above in the repo — tell me which item to begin with and I will scaffold the backend and/or UI changes and run tests.
