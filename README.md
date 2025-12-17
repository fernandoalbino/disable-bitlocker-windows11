# BitLocker Control – Disable & Enable (Windows 10 / 11)

This repository provides **two complementary PowerShell scripts** to explicitly **disable** or **enable** BitLocker / Device Encryption.

It is suitable for:
- Windows 10 and Windows 11
- Physical PCs
- Virtual Machines (any hypervisor)

TPM **can remain enabled**, keeping Windows 11 fully compliant.

---

## Scripts overview

| Script | Purpose |
|------|--------|
| `disable-bitlocker-windows11.ps1` | Permanently disables BitLocker and Device Encryption |
| `enable-bitlocker-windows11.ps1` | Restores BitLocker and enables disk encryption |

---

## ENABLE – BitLocker with automatic Recovery Key export

### What happens when you enable BitLocker

When the enable script is executed:

- BitLocker is activated on drive `C:`
- Encryption starts **in background**
- A **new Recovery Key is generated**
- The Recovery Key is **automatically exported to disk**
- TPM is used automatically when available

### Automatic Recovery Key export

For safety and auditability, the script automatically saves the recovery key to:

```
C:\ProgramData\BitLocker-Recovery\recovery-key-YYYY-MM-DD_HH-MM-SS.txt
```

This file contains:
- Volume information
- Key ID (GUID)
- Numerical Recovery Password

⚠️ **Important**:
- Copy this file to a secure location
- Do NOT rely solely on the VM disk
- Treat this file as a sensitive secret

### Quick run

Run **PowerShell as Administrator**:

```powershell
irm https://raw.githubusercontent.com/fernandoalbino/enable-bitlocker-windows11/main/enable-bitlocker-windows11.ps1 | iex
```

---

## DISABLE – BitLocker / Device Encryption

### What the disable script does

✔ Turns off active disk encryption  
✔ Removes all BitLocker protectors  
✔ Blocks automatic Device Encryption  
✔ Prevents reactivation after hardware changes  

### Quick run

```powershell
irm https://raw.githubusercontent.com/fernandoalbino/disable-bitlocker-windows11/main/disable-bitlocker-windows11.ps1 | iex
```

---

## Verification

Check BitLocker status at any time:

```powershell
manage-bde -status
```

---

## Test-safe workflow (recommended)

For lab or VM testing:

```powershell
# Enable (generates + exports key)
enable-bitlocker-windows11.ps1

# Disable immediately (no reboot)
disable-bitlocker-windows11.ps1
```

No system lockout will occur if no reboot happens between steps.

---

## Security considerations

- Enabling BitLocker protects data at rest
- Disabling BitLocker removes that protection
- Always store Recovery Keys securely

---

## Disclaimer

This software is provided "as is", without warranty of any kind.
Use at your own risk.

---

## License

MIT
