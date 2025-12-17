# Disable BitLocker / Device Encryption – Windows 11 (Physical PC & VM)

This repository provides a **safe, reproducible and permanent** way to disable:

- BitLocker
- Device Encryption
- Automatic key regeneration

It is designed for:
- Windows 11 (Home / Pro / Enterprise)
- Physical PCs
- Virtual Machines (any hypervisor)

TPM **can remain enabled**, keeping Windows 11 fully compliant.

---

## Why this exists

Windows 11 may automatically enable disk encryption when it detects:
- TPM
- Secure Boot
- Modern hardware or VM migration

This can cause:
- Recovery key prompts
- Boot interruptions
- Problems after hardware changes or VM migrations

This script **permanently disables** that behavior.

---

## What the script does

✔ Turns off active encryption (non-destructive)  
✔ Removes all BitLocker protectors  
✔ Blocks automatic Device Encryption via registry  
✔ Prevents key regeneration on hardware change  
✔ Disables BitLocker-related services  
✔ Removes BitLocker Windows feature if available  
✔ Works on **PCs and VMs**  

---

## What it does NOT do

✖ Does NOT remove TPM  
✖ Does NOT break Windows 11 requirements  
✖ Does NOT delete data  
✖ Does NOT affect Windows updates  

---

## Requirements

- Windows 10 or 11
- PowerShell
- Administrator privileges

---

## Usage

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

After reboot:

```powershell
manage-bde -status
```

Expected result:
- Percentage Encrypted: `0%`
- Protection Status: `Off`
- No key protectors present

---

## Notes for Windows 11

- TPM **can remain enabled**
- Secure Boot is optional
- Works on Windows Home (Device Encryption) and Pro/Enterprise

---

## Disclaimer

This script disables disk encryption.
If you require encryption for compliance or security reasons, do not use it.

---

## License

MIT
