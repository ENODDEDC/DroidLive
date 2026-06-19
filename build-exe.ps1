# Builds a real DroidLive.exe from DroidLive.ps1 (one-time).
# Run once via build-exe.cmd. Afterwards just double-click DroidLive.exe.

$ErrorActionPreference = "Stop"

try {
    # PowerShell Gallery needs TLS 1.2 + the NuGet provider.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if (-not (Get-Module -ListAvailable -Name ps2exe)) {
        Write-Host "Installing build helper (ps2exe), one-time..." -ForegroundColor Cyan
        Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
        if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne "Trusted") {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }
        Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module ps2exe

    $src = Join-Path $PSScriptRoot "DroidLive.ps1"
    $out = Join-Path $PSScriptRoot "DroidLive.exe"

    Write-Host "Building DroidLive.exe..." -ForegroundColor Cyan
    # -noConsole = no black terminal window pops up when you run DroidLive.exe.
    Invoke-ps2exe -InputFile $src -OutputFile $out -title "DroidLive" -product "DroidLive" -noConsole

    if (Test-Path $out) {
        Write-Host ""
        Write-Host "SUCCESS: DroidLive.exe created. Double-click it to run." -ForegroundColor Green
    } else {
        Write-Host "Build finished but DroidLive.exe was not found." -ForegroundColor Red
    }
}
catch {
    Write-Host ""
    Write-Host "BUILD ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
