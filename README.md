# BitLocker Control (Unified) – CLI/TUI + GUI (Windows 10 / 11)

This repository provides **explicit and reversible control** over **BitLocker / Device Encryption**, designed for both **virtual machines (migration-safe)** and **physical PCs**.

It includes:
- **Unified CLI/TUI script** (interactive terminal menu + automation mode)
- **Real GUI (WinForms)** in a pragmatic “Titus-style” control panel
- **Automatic system drive detection**
- **File-based logging**
- **Safety confirmations**
- **Automatic Recovery Key export when enabling BitLocker**

TPM **can remain enabled**, keeping Windows 11 fully compliant.

---

## Files

- `bitlocker-control.ps1`  
  Unified script with:
  - Interactive menu (colors + ASCII icons)
  - CLI automation mode (`-Mode`)
  - Logging and confirmations

- `bitlocker-control-gui.ps1`  
  Real WinForms GUI with:
  - Enable / Disable / Test / Status buttons
  - Embedded log console
  - Background execution (non-blocking UI)

---

## Requirements

- Windows 10 or Windows 11
- PowerShell
- Must be run as **Administrator**
- `manage-bde` available (default on Windows)

---

## Run without downloading (recommended)

### CLI/TUI (interactive menu) – one-liner

Run **PowerShell as Administrator**:

```powershell
irm https://raw.githubusercontent.com/fernandoalbino/bitlocker-control/main/bitlocker-control.ps1 | iex
```

### GUI (WinForms) – one-liner

Run **PowerShell as Administrator**:

```powershell
irm https://raw.githubusercontent.com/fernandoalbino/bitlocker-control/main/bitlocker-control-gui.ps1 | iex
```

> Note: these one-liners execute the scripts directly in memory (no files written to disk).

### If your environment blocks script execution

If you get an ExecutionPolicy-related error, use a temporary bypass in the current session:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
irm https://raw.githubusercontent.com/fernandoalbino/bitlocker-control/main/bitlocker-control.ps1 | iex
```

---

## Quick start – local CLI / TUI

Open **PowerShell as Administrator** and run:

```powershell
.\bitlocker-control.ps1
```

This opens the interactive terminal menu.

### Automation mode (no menu)

```powershell
.\bitlocker-control.ps1 -Mode status
.\bitlocker-control.ps1 -Mode enable
.\bitlocker-control.ps1 -Mode disable
.\bitlocker-control.ps1 -Mode test
```

### Force mode (skip confirmations)

For automation / CI / remote execution:

```powershell
.\bitlocker-control.ps1 -Mode disable -Force
```

---

## GUI usage (local WinForms)

Run **PowerShell as Administrator**:

```powershell
.\bitlocker-control-gui.ps1
```

The GUI provides:
- **Enable (Export Key)**
- **Disable (Prevent Auto-Encryption)**
- **Test (Enable → Disable)**
- **Status**
- **Open Logs**

All actions run asynchronously and write both to the GUI console and log files.

---

## Automatic system drive detection

The scripts automatically detect the OS drive using:

1. `Win32_OperatingSystem.SystemDrive` (preferred)
2. `$env:SystemDrive`
3. Fallback to `C:`

No manual drive selection is required.

---

## Logging

Each execution generates a dedicated log file:

```
C:\ProgramData\BitLocker-Control\logs\
```

Examples:
- `bitlocker-control-YYYY-MM-DD_HH-MM-SS.log`
- `bitlocker-control-gui-YYYY-MM-DD_HH-MM-SS.log`

---

## Recovery Key handling

### What happens when enabling BitLocker

When **Enable** is executed:

- BitLocker is enabled on the system drive
- Encryption starts **in background**
- A **new Recovery Key** is generated
- The Recovery Key is **automatically exported to disk**
- TPM is used automatically when available

### Automatic export location

```
C:\ProgramData\BitLocker-Recovery\recovery-key-YYYY-MM-DD_HH-MM-SS.txt
```

This file contains:
- Volume information
- Key ID (GUID)
- Numerical Recovery Password

### Best practices

- Treat the recovery key file as a **sensitive secret**
- Copy it to a secure external location (vault / password manager)
- In VMs, **do not rely solely on the VM disk**

---

## Safe testing workflow (VMs)

If you want to test without risking lockout:

- Use **Test (Enable → Disable)**
- **Do NOT reboot** between enable and disable

CLI example:

```powershell
.\bitlocker-control.ps1 -Mode test
```

This validates the full workflow without leaving the VM encrypted.

---

## Status verification

At any time:

```powershell
manage-bde -status
```

Expected states:

- **Disabled**
  - Protection Status: `Off`
  - Encryption returning to `0%`

- **Enabled**
  - Protection Status: `On`
  - Encryption progressing to `100%`

---

## Security considerations

- **Enable** provides data-at-rest protection (recommended for laptops and production systems)
- **Disable** removes data-at-rest protection (appropriate for labs, test VMs, and environments where encryption interferes with operations)

If you require regulatory compliance or strong security guarantees, **do not use the disable functionality**.

---

## Disclaimer

This software is provided **as is**, without warranty of any kind.
Use at your own risk.

---

## License

MIT
