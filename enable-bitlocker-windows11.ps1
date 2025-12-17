# =====================================================================
# Re-enable BitLocker / Device Encryption (Windows 10/11)
# Physical PC and Virtual Machine compatible
# =====================================================================

Write-Host "==> Restoring BitLocker / Device Encryption..." -ForegroundColor Cyan

# --- Safety check ---
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Host "ERROR: Run this script as Administrator." -ForegroundColor Red
    exit 1
}

# 1. Re-enable BitLocker services
Write-Host "-> Enabling BitLocker services..." -ForegroundColor Yellow
sc config BDESVC start= auto | Out-Null
Start-Service BDESVC -ErrorAction SilentlyContinue

sc config SECUREDEVICE start= auto | Out-Null
Start-Service SECUREDEVICE -ErrorAction SilentlyContinue

# 2. Remove registry blocks for Device Encryption
Write-Host "-> Removing registry blocks..." -ForegroundColor Yellow
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v PreventDeviceEncryption /f 2>$null
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v PreventDeviceEncryptionForAzureAD /f 2>$null
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker\KeyRolling" /v NewKeysOnStartup /f 2>$null

# 3. Reinstall BitLocker Windows feature
Write-Host "-> Reinstalling BitLocker feature..." -ForegroundColor Yellow
Enable-WindowsOptionalFeature -Online -FeatureName BitLocker -NoRestart -ErrorAction SilentlyContinue

# 4. Enable BitLocker on system drive
Write-Host "-> Enabling BitLocker on drive C:..." -ForegroundColor Yellow
manage-bde -on C: -RecoveryPassword

# 5. Final status
Write-Host "`n==> FINAL STATUS:" -ForegroundColor Green
manage-bde -status

Write-Host "`n✔ BitLocker / Device Encryption restoration initiated." -ForegroundColor Green
Write-Host "✔ Encryption will continue in background." -ForegroundColor Green
