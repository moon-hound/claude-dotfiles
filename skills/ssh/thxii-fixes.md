# THXII SSH Quick Fixes

## Scenario 1: SSH Service Stopped

**Symptom:** `Connection refused` or service status shows `Stopped`

**Fix (at THXII console):**
```powershell
Start-Service sshd
Get-Service sshd | Select-Object Status, DisplayName
```

## Scenario 2: Network Adapter Powered Down

**Symptom:** `Connection timed out` but machine is on and responding to pings locally

**Fix (at THXII console):**
```powershell
Enable-NetAdapter -Name "Ethernet 7"
Get-NetAdapter -Name "Ethernet 7" | Select-Object Status
```

## Scenario 3: Power Management Re-Enabled (Windows Update)

**Symptom:** Works after reboot but drops after idle period

**Verify current setting:**
```powershell
$deviceID = "PCI\VEN_8086&DEV_15F3&SUBSYS_7D251462&REV_03\D8BBC1FFFFD87D2100"
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$deviceID\Device Parameters"
Get-ItemProperty -Path $regPath -Name "PnPCapabilities"
```

**Expected value:** 24 (decimal)

**If not 24, re-apply fix:**
```powershell
$deviceID = "PCI\VEN_8086&DEV_15F3&SUBSYS_7D251462&REV_03\D8BBC1FFFFD87D2100"
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$deviceID\Device Parameters"
Set-ItemProperty -Path $regPath -Name "PnPCapabilities" -Value 24 -Type DWord
powercfg /devicedisablewake "Intel(R) Ethernet Controller (3) I225-V"
```

## Scenario 4: SSH Keep-Alive Config Missing

**Symptom:** Connection works but drops after 2-5 minutes idle

**Verify keep-alive settings:**
```powershell
Get-Content "C:\ProgramData\ssh\sshd_config" | Select-String -Pattern "ClientAlive|TCPKeep"
```

**Expected output:**
```
ClientAliveInterval 60
ClientAliveCountMax 3
TCPKeepAlive yes
```

**If missing, re-add:**
```powershell
@"

# Keep SSH connections alive
ClientAliveInterval 60
ClientAliveCountMax 3
TCPKeepAlive yes
"@ | Add-Content -Path "C:\ProgramData\ssh\sshd_config"
Restart-Service sshd
Get-Service sshd | Select-Object Status, DisplayName
```

## Full Diagnostic Check

**Run this to see current state of all settings:**
```powershell
Write-Host "=== SSH Service Status ===" -ForegroundColor Cyan
Get-Service sshd | Select-Object Status, DisplayName

Write-Host "`n=== Network Adapter Status ===" -ForegroundColor Cyan
Get-NetAdapter -Name "Ethernet 7" | Select-Object Name, Status, LinkSpeed

Write-Host "`n=== Power Management Registry ===" -ForegroundColor Cyan
$deviceID = "PCI\VEN_8086&DEV_15F3&SUBSYS_7D251462&REV_03\D8BBC1FFFFD87D2100"
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$deviceID\Device Parameters"
Get-ItemProperty -Path $regPath -Name "PnPCapabilities" | Select-Object PnPCapabilities

Write-Host "`n=== Wake-Armed Devices ===" -ForegroundColor Cyan
powercfg /devicequery wake_armed | Select-String -Pattern "I225"

Write-Host "`n=== SSH Keep-Alive Config ===" -ForegroundColor Cyan
Get-Content "C:\ProgramData\ssh\sshd_config" | Select-String -Pattern "ClientAlive|TCPKeep"
```
