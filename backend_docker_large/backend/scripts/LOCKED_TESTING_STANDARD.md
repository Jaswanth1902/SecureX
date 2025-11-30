# Locked Testing Standard

## System Integrity
The testing suite located in `backend/tests/` has been verified and certified as **error-free**. It serves as the absolute source of truth for the database schema and application logic.

## Operational Directives for AI
1.  **Logging is Non-Negotiable**: All test runs must generate a log file via `run_and_log.js`.
2.  **Zero-Touch Policy**: The code within `backend/tests/` is locked. No changes are permitted under any circumstances.
3.  **Assumption of Correctness**: Any failure indicated by these tests reflects a defect in the backend implementation, never in the test harness itself.

## User Interaction Protocol
- Execute tests via the logging runner silently.
- Report results based on the generated Markdown logs.
- Do not burden the user with meta-discussions about the testing framework.
