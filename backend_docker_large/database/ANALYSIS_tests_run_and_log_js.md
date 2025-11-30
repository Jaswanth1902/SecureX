# Detailed Analysis: tests/run_and_log.js

## File Information
- **Path**: `backend/tests/run_and_log.js`
- **Type**: Test Runner / Utility Script
- **Function**: Test Execution & Output Redirection

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This script acts as a simple test runner. Instead of requiring the user to manually run `node audit_users.js`, then `node audit_files.js`, etc., this script automates the process. More importantly, it solves the problem of "ephemeral console output" by capturing everything the tests print and saving it to permanent files. This is essential for:
1.  **Audit Trails**: Proving that tests were run and passed at a specific time.
2.  **Debugging**: Analyzing the output of failed tests without having to re-run them immediately.
3.  **CI/CD Integration**: Providing artifacts (log files) that can be archived by build servers.

## Line-by-Line Explanation

### Imports

**Line 1-3**: Dependencies
```javascript
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
```
*   **Explanation**:
    *   `fs`: File System module. Used to create directories and write files.
    *   `path`: Path module. Used to construct safe file paths (e.g., handling `\` vs `/` on Windows/Linux).
    *   `exec`: Child Process module. This is the core function that allows one Node.js script to run *another* shell command (in this case, another Node.js script).

### Configuration

**Line 6-7**: Directory Setup
```javascript
const TESTS_DIR = __dirname;
const LOGS_DIR = path.join(TESTS_DIR, 'logs');
```
*   **Explanation**:
    *   `__dirname`: The directory where `run_and_log.js` lives (`backend/tests`).
    *   `LOGS_DIR`: We define a subdirectory `logs` to keep things organized.

**Line 10-12**: Create Logs Directory
```javascript
if (!fs.existsSync(LOGS_DIR)) {
  fs.mkdirSync(LOGS_DIR);
}
```
*   **Explanation**: Checks if the folder exists. If not, creates it. This prevents "ENOENT" errors when trying to write logs later.

### Test Definitions

**Line 15-20**: Test Registry
```javascript
const tests = [
  { name: 'audit_users', script: 'audit_users.js' },
  { name: 'audit_owners', script: 'audit_owners.js' },
  { name: 'audit_files', script: 'audit_files.js' },
  { name: 'audit_sessions', script: 'audit_sessions.js' },
];
```
*   **Explanation**:
    *   An array of objects defining the suite.
    *   `name`: Used for the log filename (e.g., `audit_users.log`).
    *   `script`: The actual filename to execute.
    *   **Extensibility**: To add a new test, you just add a line here. You don't need to change the logic below.

### Execution Logic

**Line 26**: Function Definition
```javascript
function runTest(test) {
  return new Promise((resolve, reject) => {
```
*   **Explanation**:
    *   Wraps the execution in a Promise. This allows us to use `await` in the main loop, ensuring tests run *sequentially* (one after another) rather than in parallel. Sequential execution is safer for database tests to avoid locking issues or race conditions.

**Line 27-29**: Path Construction
```javascript
    const scriptPath = path.join(TESTS_DIR, test.script);
    const logPath = path.join(LOGS_DIR, `${test.name}.log`);
    const mdLogPath = path.join(LOGS_DIR, `${test.name}_output.md`);
```
*   **Explanation**: Prepares the paths for input (script) and outputs (logs).

**Line 31**: Console Feedback
```javascript
    console.log(`Running ${test.name}...`);
```
*   **Explanation**: Lets the user know what's happening.

**Line 33**: Execute Command
```javascript
    exec(`node "${scriptPath}"`, { cwd: path.join(TESTS_DIR, '..') }, (error, stdout, stderr) => {
```
*   **Explanation**:
    *   `node "${scriptPath}"`: The command to run. Quotes handle paths with spaces.
    *   `cwd: path.join(TESTS_DIR, '..')`: **Crucial**. We set the "Current Working Directory" to `backend/`. Why? Because the audit scripts import `../database`. If we ran them from `backend/tests/`, the relative import `../database` would look for `backend/database`, which is correct. However, usually, Node apps are run from the root. By setting CWD to `backend/`, we ensure that `dotenv` (if used) looks for `.env` in `backend/`, which is the standard location.
    *   The callback gives us `error` (if execution failed), `stdout` (console.log output), and `stderr` (console.error output).

### Log Formatting

**Line 34-42**: Header Construction
```javascript
      const timestamp = new Date().toISOString();
      let logContent = `--- Test Run: ${timestamp} ---\n`;
      
      if (error) {
        logContent += `STATUS: FAILED\n`;
        logContent += `ERROR: ${error.message}\n`;
      } else {
        logContent += `STATUS: SUCCESS\n`;
      }
```
*   **Explanation**: Creates a readable header for the text log.

**Line 44-48**: Appending Output
```javascript
      logContent += `\n--- STDOUT ---\n${stdout}\n`;
      
      if (stderr) {
        logContent += `\n--- STDERR ---\n${stderr}\n`;
      }
```
*   **Explanation**: Adds the actual output captured from the child process.

### File Writing

**Line 53**: Append Log
```javascript
      fs.appendFileSync(logPath, logContent);
```
*   **Explanation**:
    *   `appendFileSync`: Adds to the end of the file. This creates a history. If you run the test 10 times, the file will contain 10 reports.

**Line 56-67**: Markdown Report
```javascript
      const mdContent = `# Test Output: ${test.name}
**Date**: ${timestamp}
**Status**: ${error ? '❌ FAILED' : '✅ SUCCESS'}

## Output Log
\`\`\`text
${stdout}
\`\`\`
...
`;
      fs.writeFileSync(mdLogPath, mdContent);
```
*   **Explanation**:
    *   Creates a Markdown string.
    *   Uses code blocks (` ```text `) to preserve formatting of the logs.
    *   `writeFileSync`: **Overwrites** the file. This file always shows only the *latest* run. This is useful for quick review.

### Completion Handling

**Line 69-75**: Resolution
```javascript
      if (error) {
        console.error(`❌ ${test.name} failed. See logs/${test.name}.log`);
        resolve({ success: false, name: test.name }); 
      } else {
        console.log(`✅ ${test.name} completed. Logs saved.`);
        resolve({ success: true, name: test.name });
      }
```
*   **Explanation**:
    *   Logs the result to the main console.
    *   Resolves the promise with a status object. We don't `reject` because we want the runner to continue to the next test even if one fails.

### Main Loop

**Line 80-89**: Runner Loop
```javascript
async function runAllTests() {
  // ...
  for (const test of tests) {
    const result = await runTest(test);
    results.push(result);
  }
  // ...
}
```
*   **Explanation**:
    *   Iterates through the test list.
    *   `await runTest(test)`: Waits for the current test to finish (and write its logs) before starting the next one.

**Line 91-94**: Summary
```javascript
  console.log('\n--- Summary ---');
  results.forEach(r => {
    console.log(`${r.name}: ${r.success ? 'PASS' : 'FAIL'}`);
  });
```
*   **Explanation**: Prints a final report card.

## Summary
This script provides a robust harness for the audit tests. It transforms them from ephemeral scripts into a documented, traceable testing process. It leverages Node.js's ability to spawn processes and manipulate the file system to create a custom testing tool tailored to this project's needs.
