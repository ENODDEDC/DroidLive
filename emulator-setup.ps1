# Creates and starts an Android emulator (no Android Studio).
# Run once to create the virtual device; afterwards it just starts it.
#
#   powershell -ExecutionPolicy Bypass -File C:\Users\ENODD\Android\emulator-setup.ps1
#
# Leave it open, then run run-app.ps1 in another terminal to deploy your app.

$ErrorActionPreference = "Stop"

if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk" }
$sdk = $env:ANDROID_HOME

# --- Make sure Java is available (sdkmanager/emulator need it) ---
if (-not $env:JAVA_HOME -or -not (Test-Path (Join-Path $env:JAVA_HOME "bin\java.exe"))) {
    $searchRoots = @(
        "C:\Program Files\Eclipse Adoptium",
        "C:\Program Files\Java",
        "C:\Program Files\Microsoft",
        "$env:LOCALAPPDATA\Programs\Eclipse Adoptium"
    )
    foreach ($root in $searchRoots) {
        if (Test-Path $root) {
            $jdk = Get-ChildItem $root -Directory -ErrorAction SilentlyContinue |
                Where-Object { Test-Path (Join-Path $_.FullName "bin\java.exe") } |
                Sort-Object Name -Descending | Select-Object -First 1
            if ($jdk) { $env:JAVA_HOME = $jdk.FullName; break }
        }
    }
}
if (-not $env:JAVA_HOME) {
    Write-Host "Java not found. Run android-sdk-setup.ps1 first." -ForegroundColor Red
    exit 1
}
$env:Path = "$($env:JAVA_HOME)\bin;$env:Path"
$sdkmanager = Join-Path $sdk "cmdline-tools\latest\bin\sdkmanager.bat"
$avdmanager = Join-Path $sdk "cmdline-tools\latest\bin\avdmanager.bat"
$emulator = Join-Path $sdk "emulator\emulator.exe"

$image = "system-images;android-34;google_apis;x86_64"
$avdName = "DroidLive"

if (-not (Test-Path $sdkmanager)) {
    Write-Host "SDK not found. Run android-sdk-setup.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "Installing emulator + system image (large download, one-time)..." -ForegroundColor Cyan
cmd /c "echo y| `"$sdkmanager`" --licenses" | Out-Null
& $sdkmanager "emulator" $image

$existing = (& $avdmanager list avd) -join "`n"
if ($existing -notlike "*$avdName*") {
    Write-Host "Creating virtual device '$avdName'..." -ForegroundColor Cyan
    cmd /c "echo no| `"$avdmanager`" create avd -n $avdName -k `"$image`" --device pixel_6"
} else {
    Write-Host "Virtual device '$avdName' already exists." -ForegroundColor Green
}

$adb = Join-Path $sdk "platform-tools\adb.exe"

Write-Host "Starting emulator '$avdName' in its own window..." -ForegroundColor Green
# -gpu host = use your real graphics card (much faster than software rendering).
# If you ever get a white/black screen, change "host" to "swiftshader_indirect".
# -scale shrinks the window so the whole phone fits on a laptop screen.
Start-Process -FilePath $emulator -ArgumentList @(
    "-avd", $avdName,
    "-gpu", "host",
    "-no-snapshot-load",
    "-no-boot-anim",
    "-no-metrics",
    "-scale", "0.4"
)

Write-Host "Waiting for the emulator to boot (first time can take 2-3 minutes)..." -ForegroundColor Yellow
& $adb start-server | Out-Null
& $adb wait-for-device
do {
    Start-Sleep -Seconds 3
    $boot = ((& $adb shell getprop sys.boot_completed) -join "").Trim()
    Write-Host "  ...still booting" -ForegroundColor DarkGray
} while ($boot -ne "1")

Write-Host ""
Write-Host "EMULATOR IS READY. Now run:" -ForegroundColor Green
Write-Host "    powershell -ExecutionPolicy Bypass -File C:\Users\ENODD\Android\run-app.ps1" -ForegroundColor Green
