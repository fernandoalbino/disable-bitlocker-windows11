# Enable / Restore BitLocker – Windows 10 & 11

This repository provides a **safe and controlled** way to **restore**:

- BitLocker
- Device Encryption
- TPM-based key protection

It is intended to **undo** the effects of the
[`disable-bitlocker-windows11`](https://github.com/fernandoalbino/disable-bitlocker-windows11) project.

---

## When should you use this

Use this script if you want to:

- Re-enable disk encryption
- Restore compliance or security requirements
- Protect data at rest again
- Re-enable BitLocker after testing or VM migration

---

## What the script does

✔ Re-enables BitLocker services  
✔ Removes registry blocks that prevented encryption  
✔ Reinstalls BitLocker Windows feature  
✔ Enables BitLocker on system drive (C:)  
✔ Uses TPM automatically if available  

---

## Requirements

- Windows 10 or Windows 11
- Administrator privileges
- TPM recommended (required for silent unlock)

---

## Quick run (PowerShell)

Run **PowerShell as Administrator**:

```powershell
irm https://raw.githubusercontent.com/fernandoalbino/enable-bitlocker-windows11/main/enable-bitlocker-windows11.ps1 | iex
```

---

## Manual usage

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\enable-bitlocker-windows11.ps1
```

Reboot may be required.

---

## Verification

```powershell
manage-bde -status
```

Expected:
- Percentage Encrypted: progressing to 100%
- Protection Status: On

---

## Notes

- Encryption happens in background
- Recovery key will be generated
- Backup your recovery key securely

---

## Disclaimer

This script **enables disk encryption**.
Use only if you understand the implications.

---

## License

MIT
