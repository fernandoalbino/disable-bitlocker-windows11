# BitLocker Control – Disable & Enable (Windows 10 / 11)

This repository provides **two complementary PowerShell scripts** to **disable** or **re-enable** BitLocker / Device Encryption in a **controlled, predictable and documented way**.

It is suitable for:
- Windows 10 and Windows 11
- Physical PCs
- Virtual Machines (any hypervisor)

TPM **can remain enabled**, keeping Windows 11 fully compliant.

---

## Overview

| Script | Purpose |
|------|--------|
| `disable-bitlocker-windows11.ps1` | Permanently disables BitLocker and Device Encryption |
| `enable-bitlocker-windows11.ps1` | Restores BitLocker and re-enables disk encryption |

Both scripts are:
- Idempotent (safe to run more than once)
- Designed for administrative use
- Explicit about what they change

---

## Why this project exists

Windows may automatically enable disk encryption when it detects:
- TPM
- Secure Boot
- Modern hardware
- VM migration or hardware changes

This behavior can cause:
- Unexpected recovery key prompts
- Boot interruptions
- Problems after VM migration
- Operational friction in labs, homelabs and testing environments

This project gives **explicit control** over BitLocker behavior.

---

## DISABLE BitLocker / Device Encryption

### What the disable script does

✔ Turns off active disk encryption (non-destructive)  
✔ Removes all BitLocker protectors  
✔ Blocks automatic Device Encryption via registry  
✔ Prevents key regeneration after hardware changes  
✔ Disables BitLocker-related services  
✔ Removes the BitLocker Windows feature (when available)  

### What it does NOT do

✖ Does NOT remove or disable TPM  
✖ Does NOT break Windows 11 requirements  
✖ Does NOT delete data  

### Quick run (recommended)

Run **PowerShell as Administrator**:

```powershell
irm https://raw.githubusercontent.com/fernandoalbino/disable-bitlocker-windows11/main/disable-bitlocker-windows11.ps1 | iex
```

### When to use

- Lab or homelab environments
- Virtual machines that migrate between hosts
- Systems where disk encryption is not required
- Testing, benchmarking or automation scenarios

---

## ENABLE / RESTORE BitLocker

### What the enable script does

✔ Re-enables BitLocker services  
✔ Removes registry blocks created by the disable script  
✔ Reinstalls the BitLocker Windows feature  
✔ Enables BitLocker on system drive (C:)  
✔ Uses TPM automatically if available  

### Important notes

- Encryption happens **in background**
- A **new recovery key will be generated**
- Backup the recovery key securely

### Quick run (recommended)

Run **PowerShell as Administrator**:

```powershell
irm https://raw.githubusercontent.com/fernandoalbino/enable-bitlocker-windows11/main/enable-bitlocker-windows11.ps1 | iex
```

### When to use

- Restore security after testing
- Compliance or data-at-rest requirements
- Preparing a system for production use
- Re-enabling encryption on physical laptops

---

## Verification (both cases)

After reboot, verify BitLocker status:

```powershell
manage-bde -status
```

Expected states:

- **Disabled**:
  - Percentage Encrypted: `0%`
  - Protection Status: `Off`
  - No key protectors

- **Enabled**:
  - Percentage Encrypted: progressing to `100%`
  - Protection Status: `On`

---

## Windows 11 notes

- TPM **can remain enabled**
- Secure Boot is optional
- Works on Windows Home (Device Encryption) and Pro / Enterprise
- Safe for VM migration scenarios

---

## Security considerations

Disabling BitLocker removes data-at-rest protection.

If your environment requires:
- Regulatory compliance
- Protection against device loss or theft
- Strong security guarantees

**Do not use the disable script.**

---

## Disclaimer

This software is provided "as is", without warranty of any kind.
Use at your own risk.

---

## License

MIT
