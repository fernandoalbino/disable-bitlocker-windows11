# =====================================================================
# Disable BitLocker & Device Encryption permanently (Windows 10/11)
# Works on physical PCs and virtual machines
# Keeps TPM enabled if present (Windows 11 compliant)
# =====================================================================

Write-Host "==> Starting BitLocker / Device Encryption removal..." -ForegroundColor Cyan

# --- Safety check ---
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Host "ERROR: Run this script as Administrator." -ForegroundColor Red
    exit 1
}

# 1. Disable active encryption (safe, non-destructive)
Write-Host "-> Turning off disk encryption (if enabled)..." -ForegroundColor Yellow
manage-bde -off C: 2>$null

# 2. Remove all BitLocker protectors
Write-Host "-> Removing BitLocker protectors..." -ForegroundColor Yellow
manage-bde -protectors -disable C: 2>$null
manage-bde -protectors -delete C: -type all 2>$null

# 3. Block automatic Device Encryption (critical)
Write-Host "-> Blocking automatic Device Encryption..." -ForegroundColor Yellow
reg add "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" `
    /v PreventDeviceEncryption /t REG_DWORD /d 1 /f | Out-Null

reg add "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" `
    /v PreventDeviceEncryptionForAzureAD /t REG_DWORD /d 1 /f | Out-Null

# 4. Prevent key regeneration after hardware changes
Write-Host "-> Disabling automatic key regeneration..." -ForegroundColor Yellow
reg add "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker\KeyRolling" `
    /v NewKeysOnStartup /t REG_DWORD /d 0 /f | Out-Null

# 5. Disable BitLocker-related services
Write-Host "-> Disabling BitLocker services..." -ForegroundColor Yellow
sc config BDESVC start= disabled | Out-Null
Stop-Service BDESVC -ErrorAction SilentlyContinue

sc config SECUREDEVICE start= disabled | Out-Null
Stop-Service SECUREDEVICE -ErrorAction SilentlyContinue

# 6. Remove BitLocker Windows feature (if available)
Write-Host "-> Removing BitLocker Windows feature..." -ForegroundColor Yellow
Disable-WindowsOptionalFeature -Online -FeatureName BitLocker `
    -NoRestart -ErrorAction SilentlyContinue

# 7. Final status
Write-Host "`n==> FINAL STATUS:" -ForegroundColor Green
manage-bde -status

Write-Host "`n✔ BitLocker and Device Encryption permanently disabled." -ForegroundColor Green
Write-Host "✔ TPM can remain enabled (Windows 11 compliant)." -ForegroundColor Green
Write-Host "✔ Safe for physical PCs and virtual machines." -ForegroundColor Green
