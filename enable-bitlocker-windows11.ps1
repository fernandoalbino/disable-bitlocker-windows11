# =====================================================================
# Enable / Restore BitLocker with automatic Recovery Key export
# Windows 10 / 11 - Physical PC & VM
# =====================================================================

Write-Host "==> Enabling BitLocker and exporting Recovery Key..." -ForegroundColor Cyan

# --- Safety check ---
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Host "ERROR: Run this script as Administrator." -ForegroundColor Red
    exit 1
}

# Timestamp
$Date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ExportDir = "$env:ProgramData\BitLocker-Recovery"
$ExportFile = "$ExportDir\recovery-key-$Date.txt"

# Create export directory
New-Item -ItemType Directory -Path $ExportDir -Force | Out-Null

# 1. Re-enable services
Write-Host "-> Enabling BitLocker services..." -ForegroundColor Yellow
sc config BDESVC start= auto | Out-Null
Start-Service BDESVC -ErrorAction SilentlyContinue

sc config SECUREDEVICE start= auto | Out-Null
Start-Service SECUREDEVICE -ErrorAction SilentlyContinue

# 2. Remove registry blocks
Write-Host "-> Removing registry blocks..." -ForegroundColor Yellow
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v PreventDeviceEncryption /f 2>$null
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v PreventDeviceEncryptionForAzureAD /f 2>$null
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker\KeyRolling" /v NewKeysOnStartup /f 2>$null

# 3. Reinstall BitLocker feature
Write-Host "-> Reinstalling BitLocker feature..." -ForegroundColor Yellow
Enable-WindowsOptionalFeature -Online -FeatureName BitLocker -NoRestart -ErrorAction SilentlyContinue

# 4. Enable BitLocker
Write-Host "-> Enabling BitLocker on C:..." -ForegroundColor Yellow
manage-bde -on C: -RecoveryPassword

# 5. Export recovery key automatically
Write-Host "-> Exporting Recovery Key to $ExportFile" -ForegroundColor Yellow
manage-bde -protectors -get C: > $ExportFile

# 6. Final status
Write-Host "`n==> FINAL STATUS:" -ForegroundColor Green
manage-bde -status

Write-Host "`n✔ BitLocker enabled." -ForegroundColor Green
Write-Host "✔ Recovery key exported automatically." -ForegroundColor Green
Write-Host "✔ Location: $ExportFile" -ForegroundColor Green
