<div align="center">

# 🔒 SecureX
### Zero-Trust Ephemeral Document Sanitization & Secure Print Vault

[![Security: Zero-Trust](https://img.shields.io/badge/Security-Zero--Trust-red?style=flat-square)](https://github.com/Jaswanth1902/SecureX)
[![Storage: RAM--Only](https://img.shields.io/badge/Storage-Ephemeral%20RAM-success?style=flat-square)]()
[![Metadata: Shredded](https://img.shields.io/badge/Metadata-Cryptographically%20Zeroized-blue?style=flat-square)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

**Stop confidential documents from persisting in printer spools and disk caches.**  
SecureX delivers an in-memory document sanitization pipeline that strips hidden metadata, decrypts in volatile RAM, and guarantees physical zeroization post-print.

[🛡️ Threat Model](#threat-model) • [🚀 Quickstart](#quickstart) • [📐 Architecture](#architecture)

</div>

---

### 🛡️ Threat Model & Defense
Standard operating systems and enterprise printer queues write raw unencrypted PDF/DOCX buffers to `%WINDIR%\System32\spool\PRINTERS`. These unencrypted artifacts frequently persist across system reboots, creating an invisible data exfiltration vector.

**SecureX eliminates this attack vector**:
1. **Volatile RAM Ingestion**: Documents are decrypted strictly in volatile RAM buffers.
2. **Metadata Sanitization**: Strips EXIF, author tags, revision histories, and steganographic watermarks.
3. **Hardware-Level Zeroization**: Buffer memory is overwritten with cryptographic entropy barriers post-job.

---

### 🚀 Quickstart

```bash
git clone https://github.com/Jaswanth1902/SecureX.git
cd SecureX
pip install -r requirements.txt
python securex_vault.py --ephemeral
```
