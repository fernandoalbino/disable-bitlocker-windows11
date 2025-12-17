# =====================================================================
# BitLocker Control - Unified Script (Enable / Disable / Test / Status)
# Windows 10/11 | Physical PC & VM
#
# Features:
# - Interactive TUI menu with colors + ASCII icons
# - CLI mode: -Mode enable|disable|status|test
# - Automatic system drive detection
# - File logging (ProgramData)
# - Safety confirmations (Type YES) + -Force override
# - Automatic Recovery Key export on Enable
# =====================================================================

[CmdletBinding()]
param(
    [ValidateSet("enable","disable","status","test")]
    [string]$Mode,
    [switch]$Force
)

# ---------------------------
# Admin check
# ---------------------------
function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "[!] ERROR: Run this script as Administrator." -ForegroundColor Red
        exit 1
    }
}

# ---------------------------
# Paths / Logging
# ---------------------------
$Global:BaseDir  = Join-Path $env:ProgramData "BitLocker-Control"
$Global:LogDir   = Join-Path $Global:BaseDir "logs"
$null = New-Item -ItemType Directory -Path $Global:LogDir -Force -ErrorAction SilentlyContinue

$Global:RunStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$Global:LogFile  = Join-Path $Global:LogDir "bitlocker-control-$Global:RunStamp.log"

function Write-Log {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("INFO","WARN","ERROR","OK")][string]$Level="INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts][$Level] $Message"
    Add-Content -Path $Global:LogFile -Value $line -Encoding UTF8

    switch ($Level) {
        "OK"    { Write-Host "[+]" -NoNewline -ForegroundColor Green;  Write-Host " $Message" }
        "WARN"  { Write-Host "[!]" -NoNewline -ForegroundColor Yellow; Write-Host " $Message" }
        "ERROR" { Write-Host "[x]" -NoNewline -ForegroundColor Red;    Write-Host " $Message" }
        default { Write-Host "[i]" -NoNewline -ForegroundColor Cyan;   Write-Host " $Message" }
    }
}

# ---------------------------
# Helpers
# ---------------------------
function Get-SystemDriveLetter {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        if ($os.SystemDrive) { return $os.SystemDrive }
    } catch { }
    if ($env:SystemDrive) { return $env:SystemDrive }
    return "C:"
}

function Confirm-OrExit {
    param(
        [Parameter(Mandatory=$true)][string]$ActionText,
        [switch]$Skip
    )
    if ($Skip -or $Force) {
        Write-Log "Confirmation bypassed (-Force)." "WARN"
        return
    }
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "[!] SAFETY CONFIRMATION" -ForegroundColor Yellow
    Write-Host "Action: $ActionText" -ForegroundColor Yellow
    Write-Host "Type YES to continue:" -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow
    $ans = Read-Host ">"
    if ($ans -ne "YES") {
        Write-Log "User aborted. (Expected YES, got '$ans')" "WARN"
        exit 2
    }
}

function Pause-Key {
    Write-Host ""
    Read-Host "Press ENTER to continue"
}

function Header {
    Clear-Host
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "      BitLocker Control - Unified Manager" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Log file: $Global:LogFile" -ForegroundColor DarkGray
}

# ---------------------------
# Core actions
# ---------------------------
function Show-Status {
    param([string]$Drive)
    Write-Log "Showing BitLocker status for $Drive" "INFO"
    manage-bde -status $Drive
}

function Disable-BitLocker {
    param([string]$Drive)

    Confirm-OrExit -ActionText "DISABLE BitLocker / Device Encryption on $Drive (will decrypt if needed)." 
    Write-Log "Disabling BitLocker / Device Encryption on $Drive" "INFO"

    # 1) Turn off encryption (safe)
    manage-bde -off $Drive 2>$null | Out-Null
    Write-Log "Issued: manage-bde -off $Drive" "OK"

    # 2) Remove protectors
    manage-bde -protectors -disable $Drive 2>$null | Out-Null
    manage-bde -protectors -delete $Drive -type all 2>$null | Out-Null
    Write-Log "Removed protectors for $Drive" "OK"

    # 3) Block automatic Device Encryption
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v PreventDeviceEncryption /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v PreventDeviceEncryptionForAzureAD /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker\KeyRolling" /v NewKeysOnStartup /t REG_DWORD /d 0 /f | Out-Null
    Write-Log "Applied registry blocks to prevent auto-encryption" "OK"

    # 4) Disable services (best-effort; varies by edition/build)
    sc config BDESVC start= disabled | Out-Null
    Stop-Service BDESVC -ErrorAction SilentlyContinue
    sc config SECUREDEVICE start= disabled | Out-Null
    Stop-Service SECUREDEVICE -ErrorAction SilentlyContinue
    Write-Log "Disabled BitLocker-related services (best-effort)" "OK"

    # 5) Remove feature if available
    Disable-WindowsOptionalFeature -Online -FeatureName BitLocker -NoRestart -ErrorAction SilentlyContinue | Out-Null
    Write-Log "Disabled BitLocker Windows feature (if applicable)" "OK"

    Write-Log "Disable routine completed for $Drive" "OK"
}

function Enable-BitLocker {
    param([string]$Drive)

    Confirm-OrExit -ActionText "ENABLE BitLocker on $Drive (will generate a NEW Recovery Key)."
    Write-Log "Enabling BitLocker on $Drive" "INFO"

    $date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $recoveryDir  = Join-Path $env:ProgramData "BitLocker-Recovery"
    $recoveryFile = Join-Path $recoveryDir "recovery-key-$date.txt"
    $null = New-Item -ItemType Directory -Path $recoveryDir -Force -ErrorAction SilentlyContinue

    # 1) Enable services
    sc config BDESVC start= auto | Out-Null
    Start-Service BDESVC -ErrorAction SilentlyContinue
    sc config SECUREDEVICE start= auto | Out-Null
    Start-Service SECUREDEVICE -ErrorAction SilentlyContinue
    Write-Log "Enabled BitLocker services (best-effort)" "OK"

    # 2) Remove registry blocks
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v PreventDeviceEncryption /f 2>$null | Out-Null
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v PreventDeviceEncryptionForAzureAD /f 2>$null | Out-Null
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker\KeyRolling" /v NewKeysOnStartup /f 2>$null | Out-Null
    Write-Log "Removed registry blocks (if present)" "OK"

    # 3) Install feature if available
    Enable-WindowsOptionalFeature -Online -FeatureName BitLocker -NoRestart -ErrorAction SilentlyContinue | Out-Null
    Write-Log "Enabled BitLocker Windows feature (if applicable)" "OK"

    # 4) Enable BitLocker + generate recovery password
    manage-bde -on $Drive -RecoveryPassword 2>$null | Out-Null
    Write-Log "Issued: manage-bde -on $Drive -RecoveryPassword" "OK"

    # 5) Export recovery key
    manage-bde -protectors -get $Drive > $recoveryFile
    Write-Log "Recovery key exported to: $recoveryFile" "OK"

    Write-Log "Enable routine initiated for $Drive (encryption continues in background)" "OK"
}

function Test-Workflow {
    param([string]$Drive)

    Confirm-OrExit -ActionText "TEST MODE: Enable then Disable on $Drive (no reboot)."
    Write-Log "TEST MODE started on $Drive" "WARN"
    Enable-BitLocker -Drive $Drive
    Write-Log "Waiting 5 seconds before disable..." "INFO"
    Start-Sleep -Seconds 5
    Disable-BitLocker -Drive $Drive
    Write-Log "TEST MODE completed safely (avoid reboot between steps if you are only testing)." "OK"
}

# ---------------------------
# Menu
# ---------------------------
function Show-Menu {
    param([string]$Drive)
    Header
    Write-Host "System drive detected: $Drive" -ForegroundColor Green
    Write-Host ""
    Write-Host "Choose an option:" -ForegroundColor White
    Write-Host ""
    Write-Host " 1) [ + ] Enable BitLocker (export Recovery Key)" -ForegroundColor Cyan
    Write-Host " 2) [ - ] Disable BitLocker / Device Encryption" -ForegroundColor Cyan
    Write-Host " 3) [ * ] Test mode (Enable then Disable)" -ForegroundColor Cyan
    Write-Host " 4) [ i ] Show BitLocker status" -ForegroundColor Cyan
    Write-Host " 5) [ > ] Open log folder" -ForegroundColor Cyan
    Write-Host " 0) [ x ] Exit" -ForegroundColor Cyan
    Write-Host ""
}

function Open-LogFolder {
    Write-Log "Opening log folder: $Global:LogDir" "INFO"
    Start-Process explorer.exe $Global:LogDir
}

# ---------------------------
# Entry
# ---------------------------
Assert-Admin
$drive = Get-SystemDriveLetter
Write-Log "Started. Detected system drive: $drive" "INFO"

if ($Mode) {
    switch ($Mode) {
        "enable"  { Enable-BitLocker -Drive $drive; Show-Status -Drive $drive; exit 0 }
        "disable" { Disable-BitLocker -Drive $drive; Show-Status -Drive $drive; exit 0 }
        "status"  { Show-Status -Drive $drive; exit 0 }
        "test"    { Test-Workflow -Drive $drive; Show-Status -Drive $drive; exit 0 }
    }
}

do {
    Show-Menu -Drive $drive
    $choice = Read-Host "Enter choice"

    switch ($choice) {
        "1" { Enable-BitLocker -Drive $drive; Show-Status -Drive $drive; Pause-Key }
        "2" { Disable-BitLocker -Drive $drive; Show-Status -Drive $drive; Pause-Key }
        "3" { Test-Workflow -Drive $drive; Show-Status -Drive $drive; Pause-Key }
        "4" { Show-Status -Drive $drive; Pause-Key }
        "5" { Open-LogFolder; Pause-Key }
        "0" { break }
        default { Write-Log "Invalid option: $choice" "WARN"; Pause-Key }
    }
} while ($true)

Write-Log "Exited by user." "INFO"
