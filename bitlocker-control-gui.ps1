# =====================================================================
# BitLocker Control - GUI (WinForms) - "Titus-style" pragmatic panel
# Windows 10/11 | Physical PC & VM
#
# Features:
# - Real GUI (WinForms) with buttons + status panel + log console
# - Automatic system drive detection
# - File logging (ProgramData)
# - Safety confirmations
# - Automatic Recovery Key export on Enable
# =====================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------------------
# Admin check
# ---------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    [System.Windows.Forms.MessageBox]::Show(
        "Run this script as Administrator.",
        "BitLocker Control",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

# ---------------------------
# Paths / Logging
# ---------------------------
$BaseDir  = Join-Path $env:ProgramData "BitLocker-Control"
$LogDir   = Join-Path $BaseDir "logs"
New-Item -ItemType Directory -Path $LogDir -Force -ErrorAction SilentlyContinue | Out-Null

$RunStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile  = Join-Path $LogDir "bitlocker-control-gui-$RunStamp.log"

function Log-Line {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR","OK")][string]$Level="INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts][$Level] $Message"
    Add-Content -Path $LogFile -Value $line -Encoding UTF8

    $prefix = switch ($Level) {
        "OK"    { "[+]" }
        "WARN"  { "[!]" }
        "ERROR" { "[x]" }
        default { "[i]" }
    }
    $global:txtLog.AppendText("$prefix $Message`r`n")
    $global:txtLog.SelectionStart = $global:txtLog.TextLength
    $global:txtLog.ScrollToCaret()
}

function Get-SystemDriveLetter {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        if ($os.SystemDrive) { return $os.SystemDrive }
    } catch { }
    if ($env:SystemDrive) { return $env:SystemDrive }
    return "C:"
}

$SystemDrive = Get-SystemDriveLetter
Log-Line "Started. System drive detected: $SystemDrive" "INFO"

function Confirm-Action {
    param([string]$ActionText)

    $msg = "Action: $ActionText`r`n`r`nDo you want to continue?"
    $res = [System.Windows.Forms.MessageBox]::Show(
        $msg, "Confirm",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    return ($res -eq [System.Windows.Forms.DialogResult]::Yes)
}

# ---------------------------
# Actions (run in background)
# ---------------------------
function Do-Status {
    Log-Line "Getting BitLocker status for $SystemDrive..." "INFO"
    $out = & manage-bde -status $SystemDrive 2>&1
    Log-Line ($out -join "`r`n") "INFO"
}

function Do-Disable {
    if (-not (Confirm-Action "DISABLE BitLocker / Device Encryption on $SystemDrive (decrypt if needed)")) {
        Log-Line "User cancelled." "WARN"
        return
    }

    Log-Line "Disabling BitLocker / Device Encryption on $SystemDrive..." "WARN"

    & manage-bde -off $SystemDrive 2>&1 | Out-Null
    Log-Line "Issued: manage-bde -off $SystemDrive" "OK"

    & manage-bde -protectors -disable $SystemDrive 2>&1 | Out-Null
    & manage-bde -protectors -delete $SystemDrive -type all 2>&1 | Out-Null
    Log-Line "Removed protectors" "OK"

    & reg add "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v PreventDeviceEncryption /t REG_DWORD /d 1 /f | Out-Null
    & reg add "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v PreventDeviceEncryptionForAzureAD /t REG_DWORD /d 1 /f | Out-Null
    & reg add "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker\KeyRolling" /v NewKeysOnStartup /t REG_DWORD /d 0 /f | Out-Null
    Log-Line "Applied registry blocks to prevent auto-encryption" "OK"

    & sc config BDESVC start= disabled | Out-Null
    Stop-Service BDESVC -ErrorAction SilentlyContinue
    & sc config SECUREDEVICE start= disabled | Out-Null
    Stop-Service SECUREDEVICE -ErrorAction SilentlyContinue
    Log-Line "Disabled BitLocker-related services (best-effort)" "OK"

    Disable-WindowsOptionalFeature -Online -FeatureName BitLocker -NoRestart -ErrorAction SilentlyContinue | Out-Null
    Log-Line "Disabled BitLocker feature (if applicable)" "OK"

    Log-Line "Disable completed." "OK"
}

function Do-Enable {
    if (-not (Confirm-Action "ENABLE BitLocker on $SystemDrive (new Recovery Key will be generated)")) {
        Log-Line "User cancelled." "WARN"
        return
    }

    Log-Line "Enabling BitLocker on $SystemDrive..." "WARN"

    $date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $recoveryDir  = Join-Path $env:ProgramData "BitLocker-Recovery"
    $recoveryFile = Join-Path $recoveryDir "recovery-key-$date.txt"
    New-Item -ItemType Directory -Path $recoveryDir -Force -ErrorAction SilentlyContinue | Out-Null

    & sc config BDESVC start= auto | Out-Null
    Start-Service BDESVC -ErrorAction SilentlyContinue
    & sc config SECUREDEVICE start= auto | Out-Null
    Start-Service SECUREDEVICE -ErrorAction SilentlyContinue
    Log-Line "Enabled services (best-effort)" "OK"

    & reg delete "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v PreventDeviceEncryption /f 2>$null | Out-Null
    & reg delete "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v PreventDeviceEncryptionForAzureAD /f 2>$null | Out-Null
    & reg delete "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker\KeyRolling" /v NewKeysOnStartup /f 2>$null | Out-Null
    Log-Line "Removed registry blocks (if present)" "OK"

    Enable-WindowsOptionalFeature -Online -FeatureName BitLocker -NoRestart -ErrorAction SilentlyContinue | Out-Null
    Log-Line "Enabled BitLocker feature (if applicable)" "OK"

    & manage-bde -on $SystemDrive -RecoveryPassword 2>&1 | Out-Null
    Log-Line "Issued: manage-bde -on $SystemDrive -RecoveryPassword" "OK"

    & manage-bde -protectors -get $SystemDrive > $recoveryFile
    Log-Line "Recovery key exported to: $recoveryFile" "OK"

    Log-Line "Enable initiated (encryption continues in background)." "OK"
}

function Do-Test {
    if (-not (Confirm-Action "TEST MODE: Enable then Disable (NO reboot).")) {
        Log-Line "User cancelled." "WARN"
        return
    }
    Log-Line "TEST MODE started." "WARN"
    Do-Enable
    Start-Sleep -Seconds 3
    Do-Disable
    Log-Line "TEST MODE completed (avoid reboot between steps if you are only testing)." "OK"
}

function Run-Async {
    param([scriptblock]$Work)

    $global:btnEnable.Enabled  = $false
    $global:btnDisable.Enabled = $false
    $global:btnTest.Enabled    = $false
    $global:btnStatus.Enabled  = $false

    $bw = New-Object System.ComponentModel.BackgroundWorker
    $bw.DoWork += { param($s,$e) & $Work }
    $bw.RunWorkerCompleted += {
        $global:btnEnable.Enabled  = $true
        $global:btnDisable.Enabled = $true
        $global:btnTest.Enabled    = $true
        $global:btnStatus.Enabled  = $true
        Log-Line "Ready." "INFO"
    }
    $bw.RunWorkerAsync()
}

# ---------------------------
# GUI Layout
# ---------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "BitLocker Control"
$form.Size = New-Object System.Drawing.Size(920, 620)
$form.StartPosition = "CenterScreen"

$fontHeader = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$fontBody   = New-Object System.Drawing.Font("Segoe UI", 10)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "BitLocker Control"
$lblTitle.Font = $fontHeader
$lblTitle.AutoSize = $true
$lblTitle.Location = New-Object System.Drawing.Point(18, 14)
$form.Controls.Add($lblTitle)

$lblDrive = New-Object System.Windows.Forms.Label
$lblDrive.Text = "System drive: $SystemDrive"
$lblDrive.Font = $fontBody
$lblDrive.AutoSize = $true
$lblDrive.Location = New-Object System.Drawing.Point(20, 48)
$form.Controls.Add($lblDrive)

$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Log file: $LogFile"
$lblLog.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblLog.AutoSize = $true
$lblLog.Location = New-Object System.Drawing.Point(20, 74)
$form.Controls.Add($lblLog)

$panelButtons = New-Object System.Windows.Forms.Panel
$panelButtons.Location = New-Object System.Drawing.Point(18, 110)
$panelButtons.Size = New-Object System.Drawing.Size(870, 80)
$form.Controls.Add($panelButtons)

$global:btnEnable = New-Object System.Windows.Forms.Button
$btnEnable.Text = "Enable (Export Key)"
$btnEnable.Font = $fontBody
$btnEnable.Size = New-Object System.Drawing.Size(190, 44)
$btnEnable.Location = New-Object System.Drawing.Point(0, 10)
$btnEnable.Add_Click({ Run-Async { Do-Enable } })
$panelButtons.Controls.Add($btnEnable)

$global:btnDisable = New-Object System.Windows.Forms.Button
$btnDisable.Text = "Disable (Prevent Auto)"
$btnDisable.Font = $fontBody
$btnDisable.Size = New-Object System.Drawing.Size(210, 44)
$btnDisable.Location = New-Object System.Drawing.Point(200, 10)
$btnDisable.Add_Click({ Run-Async { Do-Disable } })
$panelButtons.Controls.Add($btnDisable)

$global:btnTest = New-Object System.Windows.Forms.Button
$btnTest.Text = "Test (Enable -> Disable)"
$btnTest.Font = $fontBody
$btnTest.Size = New-Object System.Drawing.Size(220, 44)
$btnTest.Location = New-Object System.Drawing.Point(420, 10)
$btnTest.Add_Click({ Run-Async { Do-Test } })
$panelButtons.Controls.Add($btnTest)

$global:btnStatus = New-Object System.Windows.Forms.Button
$btnStatus.Text = "Status"
$btnStatus.Font = $fontBody
$btnStatus.Size = New-Object System.Drawing.Size(110, 44)
$btnStatus.Location = New-Object System.Drawing.Point(650, 10)
$btnStatus.Add_Click({ Run-Async { Do-Status } })
$panelButtons.Controls.Add($btnStatus)

$btnOpenLogs = New-Object System.Windows.Forms.Button
$btnOpenLogs.Text = "Open Logs"
$btnOpenLogs.Font = $fontBody
$btnOpenLogs.Size = New-Object System.Drawing.Size(110, 44)
$btnOpenLogs.Location = New-Object System.Drawing.Point(770, 10)
$btnOpenLogs.Add_Click({ Start-Process explorer.exe $LogDir })
$panelButtons.Controls.Add($btnOpenLogs)

$global:txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.Location = New-Object System.Drawing.Point(18, 210)
$txtLog.Size = New-Object System.Drawing.Size(870, 360)
$txtLog.ReadOnly = $true
$txtLog.BackColor = [System.Drawing.Color]::FromArgb(18,18,18)
$txtLog.ForeColor = [System.Drawing.Color]::Gainsboro
$form.Controls.Add($txtLog)

$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Text = "Tip: for VM safety tests, use 'Test (Enable -> Disable)' and avoid reboot between steps."
$lblHint.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblHint.AutoSize = $true
$lblHint.Location = New-Object System.Drawing.Point(18, 580)
$form.Controls.Add($lblHint)

# Initial message
$txtLog.AppendText("[i] Ready. Use the buttons above.`r`n")
$txtLog.AppendText("[i] Logs: " + $LogFile + "`r`n")

[void]$form.ShowDialog()
