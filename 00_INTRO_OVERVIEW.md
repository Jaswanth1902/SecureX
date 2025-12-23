# SafeCopy — Introduction & Project Overview

## Idea
SafeCopy (Secure File Printing System) is a privacy-first solution that lets users securely upload documents from mobile devices, stores those documents encrypted on a server, and allows an owner to decrypt and print the document on a desktop machine in memory only. After printing, the encrypted copy is removed so plaintext never persists on owner hardware.

## Problem Definition
- Users need to share sensitive documents (IDs, signed contracts, medical forms, etc.) but do not want the receiving party (owner/printer) to retain a copy. Typical workflows leave decrypted copies on the receiver's device or shared cloud storage.
- Existing print workflows either rely on trusting the receiver with plaintext or require complex, manual secure handling.
- Goal: create an end-to-end flow where the upload is encrypted client-side, the server stores only ciphertext, and the owner can decrypt only in RAM for printing — with enforced automatic deletion and auditability.

## Core Objectives
- Privacy by design: files encrypted on the client before transmission.
- Zero-knowledge server: server cannot decrypt stored files.
- Safe printing: decryption occurs only in volatile memory, no plaintext on disk.
- Controlled lifecycle: automatic deletion after print and tamper-evident audit logs.
- Practical UX: provide mobile and desktop apps with a clear upload/print user flow and robust error handling.

## Methodology
- Cryptography: authenticated symmetric encryption (AES-256-GCM) for file payloads, with asymmetric encryption (RSA-2048 or similar) for protecting keys in transit when needed. File hashing (SHA-256) for integrity checks.
- Architecture: small Express.js backend that stores encrypted files and metadata, a Flutter-based mobile app to encrypt & upload, and a Flutter desktop app (Windows) to download, decrypt in memory, print, and then request deletion.
- Security controls: JWT-based authentication for APIs, rate limiting, secure configuration via environment variables, and audit logging for uploads/prints/deletes. Memory shredding and in-memory-only plaintext handling for owner-side decryption.
- Testing & validation: unit tests, integration tests for end-to-end flows (upload → download → print → delete), security tests (auth, tamper, replay), and performance tests for large files and concurrency.
- Documentation-first: maintain clear docs (API guide, architecture, setup, runbook) so deployments and audits are reproducible.

## Proposed Outcomes
- A reproducible, documented system enabling secure uploads and memory-only printing.
- Production-ready backend with encryption and auth services.
- Mobile (Flutter) uploader app that encrypts and uploads files with progress and error handling.
- Desktop (Flutter) owner app that lists files, downloads ciphertext, decrypts in memory, prints, and triggers deletion.
- Audit trail for compliance and troubleshooting.
- CI tests and a basic deployment recipe for staging/production.

## Timeline (4 Phases)
Each phase includes deliverables, verification criteria, and an estimated duration. Durations are estimates and may be adjusted based on team size and risk discovered during work.

- Phase 1 — Foundation & Backend (Weeks 1–4)
  - Deliverables: Architecture, database schema, backend scaffold, encryption & auth services, core API endpoints (`/api/upload`, `/api/files`, `/api/print/:id`, `/api/delete/:id`), `.env.example`, and backend documentation.
  - Verification: API health check, unit tests for core services, successful encrypted file storage in DB.
  - Estimated duration: 1–4 weeks (foundation files and core services already present in repository; adjust to complete any gaps).

- Phase 2 — Mobile Upload Client (Weeks 5–8)
  - Deliverables: Flutter mobile app with file picker, client-side AES-256-GCM encryption, upload flow, progress UI, and basic auth integration.
  - Verification: End-to-end uploads from device with ciphertext stored on server, correct metadata and hash verification.
  - Estimated duration: 1–4 weeks.

- Phase 3 — Desktop Owner Client & Print Flow (Weeks 9–12)
  - Deliverables: Flutter desktop app (Windows) to list available files, download ciphertext, decrypt in memory, integrate with local printing APIs, and trigger server-side deletion after successful print.
  - Verification: Owner can download, decrypt in RAM, print, and confirm deletion; no plaintext files written to disk; memory shredding behavior tested.
  - Estimated duration: 1–4 weeks.

- Phase 4 — Integration, Testing & Deployment (Weeks 13–16+)
  - Deliverables: Full integration tests, security audit (OWASP / penetration checks), performance testing for large file sizes and concurrent usage, CI pipeline (tests + lint), and deployment script for staging/production.
  - Verification: 10+ successful end-to-end runs without leakage, passing security checks, and CI gating on tests.
  - Estimated duration: 2–6 weeks depending on audit depth and deployment target.

Total estimated time: 8–18 weeks depending on team size and required audit depth. Many repository documents indicate a realistic 16–20 week roadmap for a full-featured release with CI and deployment automation.

## Acceptance Criteria (MVP)
- Client-side encryption: AES-256-GCM implemented and used by mobile uploader.
- Server stores only ciphertext; owner cannot access plaintext from server data.
- Owner-side decryption occurs in memory with controlled printing and automatic deletion.
- End-to-end automated tests for at least the basic flows.
- Documentation describing setup, run, and verification steps.

## Next Steps / Suggested Immediate Tasks
- Review and confirm encryption parameters and key exchange approach (RSA-2048 vs hybrid KEM).
- Run end-to-end test: encrypt+upload from mobile → download+decrypt+print on desktop → verify deletion and audit logs.
- Add/verify CI tasks: `lint`, `test`, and optional `build` steps for Flutter apps.
- If you want, I can create the file structure for a release README and a short checklist to hand to a tester.

---

Maintainer: Jaswanth
Repository root file: `00_INTRO_OVERVIEW.md`

_Document generated automatically from repository docs on 2025-11-24._
