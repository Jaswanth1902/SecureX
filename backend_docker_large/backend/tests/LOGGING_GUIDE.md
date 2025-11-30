# Test Logging Guide

This guide explains how to use the `run_and_log.js` utility to execute the database audit tests and capture their output for review.

## Purpose

Running tests manually and watching the console is fine for quick checks, but for record-keeping and debugging, it's better to save the output. This utility:
1.  Runs all defined audit scripts.
2.  Captures standard output (`stdout`) and error output (`stderr`).
3.  Saves a history of runs to `.log` files.
4.  Generates a readable `.md` report for the latest run.

## Usage

Navigate to the `backend/tests` directory and run the script using Node.js:

```bash
cd backend/tests
node run_and_log.js
```

## Output Structure

The script creates a `logs/` directory within `backend/tests/`.

```text
backend/tests/
├── logs/
│   ├── audit_users.log        # Appended history of all runs
│   ├── audit_users_output.md  # Formatted report of the LAST run
│   ├── audit_files.log
│   ├── audit_files_output.md
│   ├── ...
├── run_and_log.js
└── ...
```

### Log Files (`.log`)
These files are **appended** to. They contain a chronological history of every time you ran the test. Each entry is timestamped.

Example:
```text
--- Test Run: 2023-10-27T10:00:00.000Z ---
STATUS: SUCCESS

--- STDOUT ---
... logs ...
```

### Markdown Reports (`.md`)
These files are **overwritten** on each run. They provide a clean, formatted view of the most recent execution, suitable for viewing in a Markdown previewer or sharing with the team.

Example:
```markdown
# Test Output: audit_users
**Date**: 2023-10-27T10:00:00.000Z
**Status**: ✅ SUCCESS

## Output Log
...
```

## Adding New Tests

To add a new test script to the runner, open `run_and_log.js` and add an entry to the `tests` array:

```javascript
const tests = [
  // ... existing tests
  { name: 'my_new_test', script: 'my_new_test.js' },
];
```
