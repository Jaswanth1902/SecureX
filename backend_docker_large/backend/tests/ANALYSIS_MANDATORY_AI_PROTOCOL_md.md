# Detailed Analysis: MANDATORY_AI_PROTOCOL.md

## File Information
- **Path**: `MANDATORY_AI_PROTOCOL.md`
- **Type**: Project Directive / Meta-Documentation
- **Function**: AI Behavior Control

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This file serves as a "Constitution" for AI agents working on this project. It overrides standard operating procedures by imposing strict constraints on how testing is performed. It is designed to prevent "drift" where an AI might try to "fix" a working test or run tests in an ad-hoc manner that leaves no trace.

## Line-by-Line Explanation

### Section 1: Exclusive Use of Logging

**Directive**:
> You are **STRICTLY REQUIRED** to use the automated logging system for all test executions.

*   **Analysis**: This removes the AI's autonomy in choosing how to run tests. It enforces a standardized workflow (`run_and_log.js`) that guarantees auditability.
*   **Implication**: If a user asks "run the user test", the AI must translate that intent to `node backend/tests/run_and_log.js` (or specifically targeting that test via the runner if supported), rather than `node audit_users.js`.

### Section 2: Immutability of Tests

**Directive**:
> The test files in `backend/tests/` are **PERFECT AND FINAL**.

*   **Analysis**: This is a "Source of Truth" declaration.
*   **Why**: AIs often try to fix "syntax errors" or "logic errors" they perceive in tests, which can lead to false positives. By declaring the tests as "Bug-Free", we force the AI to look for the bug in the *application code* (the variable part) rather than the *test code* (the constant part).

### Section 3: Silent Enforcement

**Directive**:
> **Do NOT** explain to the user that you are using this system. Just use it.

*   **Analysis**: This improves the User Experience (UX). The user doesn't need to know the internal mechanics of *how* the AI ensures quality, just that it *does*. It prevents verbose responses like "I will now use the mandatory logging system as per protocol...".

## Summary
This file is a meta-instruction. It doesn't contain code, but it controls *how code is generated and executed*. It is a critical component of the project's quality assurance strategy.
