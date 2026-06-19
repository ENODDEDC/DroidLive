# Installs the Android command-line SDK (no Android Studio) so you can build
# and install your app to your phone locally. Run from anywhere.
#
#   powershell -ExecutionPolicy Bypass -File .\android-sdk-setup.ps1
#
# After it finishes, CLOSE and REOPEN your terminal so ANDROID_HOME / PATH apply.

$ErrorActionPreference = "Stop"

$sdkRoot = "$env:LOCALAPPDATA\Android\Sdk"
$cmdlineParent = Join-Path $sdkRoot "cmdline-tools"
$tmpZip = Join-Path $env:TEMP "android-cmdline-tools.zip"
$url = "https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip"

Write-Host "Installing Android SDK to $sdkRoot"
New-Item -ItemType Directory -Force -Path $cmdlineParent | Out-Null

$latestDir = Join-Path $cmdlineParent "latest"
$sdkmanager = Join-Path $latestDir "bin\sdkmanager.bat"

if (Test-Path $sdkmanager) {
    Write-Host "Command-line tools already present, skipping download."
} else {
    Write-Host "Downloading command-line tools..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $tmpZip
    } catch {
        Write-Host "Download failed. Get the current 'Command line tools' zip link from:"
        Write-Host "  https://developer.android.com/studio#command-line-tools-only"
        Write-Host "Then edit the `\$url` in this script and rerun."
        exit 1
    }

    Write-Host "Extracting..."
    $extractTmp = Join-Path $env:TEMP "android-cmdline-extract"
    if (Test-Path $extractTmp) { Remove-Item -Recurse -Force $extractTmp }
    Expand-Archive -Path $tmpZip -DestinationPath $extractTmp -Force
    # The zip contains a 'cmdline-tools' folder; SDK expects it under cmdline-tools\latest
    if (Test-Path $latestDir) { Remove-Item -Recurse -Force $latestDir }
    Move-Item -Path (Join-Path $extractTmp "cmdline-tools") -Destination $latestDir
}

# Persist environment variables for future terminals.
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkRoot, "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $sdkRoot, "User")
$env:ANDROID_HOME = $sdkRoot
$env:ANDROID_SDK_ROOT = $sdkRoot

$binPaths = @(
    (Join-Path $latestDir "bin"),
    (Join-Path $sdkRoot "platform-tools")
)
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
foreach ($p in $binPaths) {
    if ($userPath -notlike "*$p*") { $userPath = "$p;$userPath" }
}
[Environment]::SetEnvironmentVariable("Path", $userPath, "User")
$env:Path = "$($binPaths -join ';');$env:Path"

# --- Make sure Java is available (sdkmanager/Gradle need it) ---
if (-not $env:JAVA_HOME -or -not (Test-Path (Join-Path $env:JAVA_HOME "bin\java.exe"))) {
    $searchRoots = @(
        "C:\Program Files\Eclipse Adoptium",
        "C:\Program Files\Java",
        "C:\Program Files\Microsoft",
        "$env:LOCALAPPDATA\Programs\Eclipse Adoptium"
    )
    $jdk = $null
    foreach ($root in $searchRoots) {
        if (Test-Path $root) {
            $jdk = Get-ChildItem $root -Directory -ErrorAction SilentlyContinue |
                Where-Object { Test-Path (Join-Path $_.FullName "bin\java.exe") } |
                Sort-Object Name -Descending | Select-Object -First 1
            if ($jdk) { break }
        }
    }
    if ($jdk) {
        $env:JAVA_HOME = $jdk.FullName
        [Environment]::SetEnvironmentVariable("JAVA_HOME", $jdk.FullName, "User")
        Write-Host "Found Java at $($jdk.FullName)" -ForegroundColor Green
    }
}
if ($env:JAVA_HOME) {
    $env:Path = "$($env:JAVA_HOME)\bin;$env:Path"
} else {
    Write-Host "Java not found. Install it first:  winget install EclipseAdoptium.Temurin.21.JDK" -ForegroundColor Red
    exit 1
}

# Many "y" answers so every license prompt is accepted (there are several).
$yes = ("y`r`n" * 60)

Write-Host "Accepting licenses..."
$yes | & $sdkmanager --licenses

# Matches HinaReader (compileSdk 34). Add more platforms later if needed.
Write-Host "Installing platform-tools, build-tools and platform (this downloads ~200-400 MB)..."
$yes | & $sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

$adbPath = Join-Path $sdkRoot "platform-tools\adb.exe"
Write-Host ""
if (Test-Path $adbPath) {
    Write-Host "DONE. Close and reopen your terminal, then check with:" -ForegroundColor Green
    Write-Host "    adb version"
} else {
    Write-Host "platform-tools still missing. Make sure Java is installed (java -version)" -ForegroundColor Red
    Write-Host "and that you have internet access, then run this script again." -ForegroundColor Red
}
