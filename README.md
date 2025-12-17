# Disable BitLocker / Device Encryption – Windows 11 (Physical PC & VM)

This repository provides a **safe, reproducible and permanent** way to disable:

- BitLocker
- Device Encryption
- Automatic key regeneration

It is designed for:
- Windows 11 (Home / Pro / Enterprise)
- Windows 10
- Physical PCs
- Virtual Machines (any hypervisor)

TPM **can remain enabled**, keeping Windows 11 fully compliant.

---

## Why this exists

Windows may automatically enable disk encryption when it detects:
- TPM
- Secure Boot
- Modern hardware or VM migration

This behavior can cause:
- Unexpected recovery key prompts
- Boot interruptions
- Problems after hardware changes or VM migrations
- Operational issues in labs, homelabs and enterprise environments

This script **permanently disables** that behavior while keeping the system stable.

---

## What the script does

✔ Turns off active disk encryption (non-destructive)  
✔ Removes all BitLocker protectors  
✔ Blocks automatic Device Encryption via registry  
✔ Prevents key regeneration after hardware changes  
✔ Disables BitLocker-related services  
✔ Removes the BitLocker Windows feature (when available)  
✔ Works on **physical PCs and virtual machines**  

---

## What the script does NOT do

✖ Does NOT remove or disable TPM  
✖ Does NOT break Windows 11 requirements  
✖ Does NOT delete data  
✖ Does NOT affect Windows Update  
✖ Does NOT weaken system integrity beyond disabling disk encryption  

---

## Requirements

- Windows 10 or Windows 11
- PowerShell
- Administrator privileges

---

## Quick run (recommended)

Run **PowerShell as Administrator** and execute:

```powershell
irm https://raw.githubusercontent.com/fernandoalbino/disable-bitlocker-windows11/main/disable-bitlocker-windows11.ps1 | iex
```

> The script is executed directly in memory.  
> No files are written to disk.

---

## Manual usage

1. Download the script:
   ```powershell
   disable-bitlocker-windows11.ps1
   ```

2. Open **PowerShell as Administrator**

3. Allow execution (temporary):
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

4. Run:
   ```powershell
   .\disable-bitlocker-windows11.ps1
   ```

5. Reboot the system

---

## Verification

After reboot, confirm BitLocker is fully disabled:

```powershell
manage-bde -status
```

Expected output:
- Percentage Encrypted: `0%`
- Protection Status: `Off`
- No key protectors present

---

## Windows 11 notes

- TPM **can remain enabled**
- Secure Boot is optional
- Works on Windows Home (Device Encryption) and Pro/Enterprise editions
- Safe for VM migration scenarios

---

## Security considerations

This project intentionally disables disk encryption.

If your environment requires:
- Data-at-rest protection
- Regulatory compliance
- Lost-device threat mitigation

**Do not use this script.**

---

## Disclaimer

This software is provided "as is", without warranty of any kind.
Use at your own risk.

---

## License

MIT
