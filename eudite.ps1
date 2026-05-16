# ============================================
# Remote Desktop Setup Script
# Windows 10 Home
# ============================================
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([
    Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Run PowerShell as Administrator"
    pause
    exit
}
$temp = "$env:TEMP\rdp_setup"
New-Item -ItemType Directory -Force -Path $temp | Out-Null
# ============================================
# Enable Remote Desktop
# ============================================
Write-Host "Enabling Remote Desktop..."
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
# ============================================
# Disable single session restriction
# ============================================
Write-Host "Configuring multi-session policies..."
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "fSingleSessionPerUser" -Value 0 -Type DWord
# ============================================
New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 1 -Type DWord
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -Type DWord
Set-ItemProperty -Path "HKCU:\AppEvents\Schemes" -Name "(Default)" -Value ".None"
# ============================================
# Install Tailscale
# ============================================
Write-Host "Installing Tailscale..."
$tailscaleInstaller = "$temp\tailscale-setup.exe"
Invoke-WebRequest `
    -Uri "https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe" `
    -OutFile $tailscaleInstaller
Start-Process $tailscaleInstaller -ArgumentList "/S" -Wait
# ============================================
# Install RDP Wrapper
# ============================================
Write-Host "Installing RDP Wrapper..."
$rdpZip = "$temp\rdpwrap.zip"
$rdpFolder = "$temp\rdpwrap"

# Resolve the actual latest release tag from GitHub
$latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/stascorp/rdpwrap/releases/latest"
$rdpAsset = $latestRelease.assets | Where-Object { $_.name -like "RDPWrap-*.zip" } | Select-Object -First 1
if (-not $rdpAsset) {
    Write-Host "ERROR: Could not find RDP Wrapper zip in latest release. Check https://github.com/stascorp/rdpwrap/releases"
    pause
    exit
}

Invoke-WebRequest `
    -Uri $rdpAsset.browser_download_url `
    -OutFile $rdpZip
Expand-Archive -Path $rdpZip -DestinationPath $rdpFolder -Force
Start-Process "$rdpFolder\install.bat" -Verb RunAs -Wait
# ============================================
# Restart RDP service
# ============================================
Write-Host "Restarting Remote Desktop Services..."
Restart-Service TermService -Force
# ============================================
# Set services to automatic
# ============================================
Set-Service TermService -StartupType Automatic
# ============================================
# Final
# ============================================
Write-Host ""
Write-Host "======================================="
Write-Host "Setup completed"
Write-Host "======================================="
Write-Host ""
Write-Host "Next steps:"
Write-Host ""
Write-Host "1. Reboot the PC"
Write-Host "2. Open Tailscale"
Write-Host "3. Login"
Write-Host "4. Connect using RDP"
Write-Host ""
Write-Host "Command:"
Write-Host "mstsc"
Write-Host ""
Write-Host "Or use FreeRDP:"
Write-Host "xfreerdp /v:<TAILSCALE-IP> /u:<USER>"
Write-Host ""
pause
