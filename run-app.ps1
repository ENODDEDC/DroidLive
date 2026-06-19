# Live runner for ANY Android app (no Android Studio).
# Run this from the Android tool folder:
#   powershell -ExecutionPolicy Bypass -File C:\Users\ENODD\Android\run-app.ps1
#
# It asks you to pick an Android project folder, then builds it, installs it to
# your connected phone or a running emulator, launches it, and re-deploys
# automatically every time you save a file in Cursor.

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms

# --- 1. Pick the project folder ---
$dialog = New-Object System.Windows.Forms.FolderBrowserDialog
$dialog.Description = "Pick the Android project folder (the one that contains gradlew)"
$dialog.ShowNewFolderButton = $false
if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "Cancelled."
    exit 0
}
$projectRoot = $dialog.SelectedPath

$gradlew = Join-Path $projectRoot "gradlew.bat"
if (-not (Test-Path $gradlew)) {
    Write-Host "That folder is not an Android project (no gradlew found)." -ForegroundColor Red
    exit 1
}
Write-Host "Project: $projectRoot" -ForegroundColor Cyan

# --- 2. Find the app module + applicationId ---
$appGradle = Get-ChildItem -Path $projectRoot -Recurse -ErrorAction SilentlyContinue `
    -Include "build.gradle.kts", "build.gradle" |
    Where-Object { Select-String -Path $_.FullName -Pattern 'applicationId' -Quiet } |
    Select-Object -First 1
if (-not $appGradle) {
    Write-Host "Could not find an app module with an applicationId." -ForegroundColor Red
    exit 1
}
$pkg = (Select-String -Path $appGradle.FullName -Pattern 'applicationId\s*=?\s*"([^"]+)"').Matches.Groups[1].Value
$srcPath = Join-Path $appGradle.Directory.FullName "src"
Write-Host "App package: $pkg" -ForegroundColor Cyan

# --- 3. Locate the SDK / adb ---
if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk" }
$adb = Join-Path $env:ANDROID_HOME "platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    Write-Host "adb not found. Run android-sdk-setup.ps1 first, then reopen the terminal." -ForegroundColor Red
    exit 1
}
$env:Path = "$($env:ANDROID_HOME)\platform-tools;$env:Path"

# --- Make sure Java is available (Gradle needs it) ---
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

# Make sure Gradle can find the SDK.
$sdkForProps = ($env:ANDROID_HOME -replace '\\', '\\')
"sdk.dir=$sdkForProps" | Set-Content -Encoding ASCII -Path (Join-Path $projectRoot "local.properties")

# --- 4. Wait for a device / emulator ---
Write-Host "Waiting for a phone (USB debugging ON) or a running emulator..." -ForegroundColor Yellow
& $adb wait-for-device
# Wait until the device has fully booted (so install doesn't fail mid-boot).
do {
    Start-Sleep -Seconds 2
    $boot = ((& $adb shell getprop sys.boot_completed 2>$null) -join "").Trim()
} while ($boot -ne "1")
$model = (& $adb shell getprop ro.product.model) -join ""
Write-Host "Connected to: $model" -ForegroundColor Green

function Deploy {
    Write-Host ""
    Write-Host ("=" * 50) -ForegroundColor DarkGray
    Write-Host "Building + installing..." -ForegroundColor Cyan
    & $gradlew "-p" $projectRoot installDebug
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed. Fix the error above and save again." -ForegroundColor Red
        return
    }
    & $adb shell monkey -p $pkg -c android.intent.category.LAUNCHER 1 | Out-Null
    Write-Host "Launched. Edit a file in Cursor and save to update." -ForegroundColor Green
}

Deploy

# --- 5. Watch for changes and redeploy ---
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $srcPath
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

Write-Host ""
Write-Host "Watching for changes. Press Ctrl+C to stop." -ForegroundColor Yellow

$lastRun = [DateTime]::MinValue
while ($true) {
    $change = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::All, 1000)
    if ($change.TimedOut) { continue }
    if (([DateTime]::Now - $lastRun).TotalMilliseconds -lt 1500) { continue }
    if ($change.Name -match '\.(kt|java|xml|md|gradle\.kts|gradle)$') {
        Start-Sleep -Milliseconds 300
        $lastRun = [DateTime]::Now
        Deploy
    }
}
