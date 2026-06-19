# DroidLive - desktop launcher with a simple GUI.
# Flow: pick a project folder -> clean status window -> (hidden) build/install,
# emulator starts, app runs and live-reloads on save. No terminal, no popups.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Find our own folder (works as .ps1 and as a compiled .exe).
$tool = $PSScriptRoot
if (-not $tool) {
    $tool = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}

# ---- 1. Pick the project folder FIRST ----
$picker = New-Object System.Windows.Forms.FolderBrowserDialog
$picker.Description = "Pick your Android project folder (the one with gradlew)"
if ($picker.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
$projectRoot = $picker.SelectedPath

if (-not (Test-Path (Join-Path $projectRoot "gradlew.bat"))) {
    [System.Windows.Forms.MessageBox]::Show(
        "That folder is not an Android project (no gradlew found).",
        "DroidLive", "OK", "Error") | Out-Null
    return
}

# ---- Shared status between the worker and the UI ----
$sync = [hashtable]::Synchronized(@{ Status = "Starting..."; Failed = $false })

# ---- 2. Background worker: does all the heavy work, updates $sync.Status ----
$worker = [powershell]::Create()
$null = $worker.AddScript({
    param($projectRoot, $tool, $sync)
    function Set-Status($t) { $sync.Status = $t }
    try {
        if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk" }
        $adb = Join-Path $env:ANDROID_HOME "platform-tools\adb.exe"
        if (-not (Test-Path $adb)) { throw "Android SDK not found. Run android-sdk-setup.ps1 once." }

        # Locate Java.
        if (-not $env:JAVA_HOME -or -not (Test-Path (Join-Path $env:JAVA_HOME "bin\java.exe"))) {
            foreach ($r in @("C:\Program Files\Eclipse Adoptium", "C:\Program Files\Java", "C:\Program Files\Microsoft")) {
                if (Test-Path $r) {
                    $j = Get-ChildItem $r -Directory -EA SilentlyContinue |
                        Where-Object { Test-Path (Join-Path $_.FullName "bin\java.exe") } |
                        Sort-Object Name -Descending | Select-Object -First 1
                    if ($j) { $env:JAVA_HOME = $j.FullName; break }
                }
            }
        }
        $env:Path = "$($env:JAVA_HOME)\bin;$($env:ANDROID_HOME)\platform-tools;$env:Path"

        # App package + source folder.
        $appGradle = Get-ChildItem $projectRoot -Recurse -Include "build.gradle.kts", "build.gradle" -EA SilentlyContinue |
            Where-Object { Select-String -Path $_.FullName -Pattern 'applicationId' -Quiet } | Select-Object -First 1
        if (-not $appGradle) { throw "No app module with an applicationId was found." }
        $pkg = (Select-String -Path $appGradle.FullName -Pattern 'applicationId\s*=?\s*"([^"]+)"').Matches.Groups[1].Value
        $srcPath = Join-Path $appGradle.Directory.FullName "src"

        # Point Gradle at the SDK.
        "sdk.dir=$(($env:ANDROID_HOME -replace '\\','\\'))" | Set-Content -Encoding ASCII (Join-Path $projectRoot "local.properties")

        # Make sure a device is available.
        & $adb start-server *> $null
        $connected = (& $adb devices) | Where-Object { $_ -match '\bdevice$' }
        if (-not $connected) {
            Set-Status "Starting emulator (first time may download)..."
            & (Join-Path $tool "emulator-setup.ps1") *> $null
        }
        Set-Status "Waiting for the device to finish booting..."
        & $adb wait-for-device
        do { Start-Sleep 2; $b = ((& $adb shell getprop sys.boot_completed 2>$null) -join "").Trim() } while ($b -ne "1")

        $gradlew = Join-Path $projectRoot "gradlew.bat"
        $script:firstBuild = $true
        function Deploy {
            if ($script:firstBuild) {
                Set-Status "Building and installing your app...`nFirst build can take a few minutes - please wait."
            } else {
                Set-Status "Change detected - rebuilding and updating the app..."
            }
            & $gradlew "-p" $projectRoot installDebug *> $null
            if ($LASTEXITCODE -ne 0) { Set-Status "Build failed - fix the error in your code and save again."; return }
            & $adb shell monkey -p $pkg -c android.intent.category.LAUNCHER 1 *> $null
            $script:firstBuild = $false
            Set-Status "App is LIVE on the emulator.`nWatching for changes - edit a file and save to update."
        }
        Deploy

        # Watch for changes and redeploy.
        $fsw = New-Object System.IO.FileSystemWatcher
        $fsw.Path = $srcPath
        $fsw.IncludeSubdirectories = $true
        $fsw.EnableRaisingEvents = $true
        $last = [DateTime]::MinValue
        while ($true) {
            $c = $fsw.WaitForChanged([System.IO.WatcherChangeTypes]::All, 1000)
            if ($c.TimedOut) { continue }
            if (([DateTime]::Now - $last).TotalMilliseconds -lt 1500) { continue }
            if ($c.Name -match '\.(kt|java|xml|gradle\.kts|gradle)$') {
                Start-Sleep -Milliseconds 300
                $last = [DateTime]::Now
                Deploy
            }
        }
    }
    catch {
        $sync.Failed = $true
        $sync.Status = "Error: $($_.Exception.Message)"
    }
}).AddArgument($projectRoot).AddArgument($tool).AddArgument($sync)

$rs = [runspacefactory]::CreateRunspace()
$rs.ApartmentState = "STA"
$rs.Open()
$worker.Runspace = $rs
$null = $worker.BeginInvoke()

# ---- 3. The status window ----
$form = New-Object System.Windows.Forms.Form
$form.Text = "DroidLive"
$form.Size = New-Object System.Drawing.Size(440, 230)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(26, 31, 46)

$title = New-Object System.Windows.Forms.Label
$title.Text = "DroidLive"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::FromArgb(255, 179, 71)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(24, 22)
$form.Controls.Add($title)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Starting..."
$status.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$status.ForeColor = [System.Drawing.Color]::White
$status.Location = New-Object System.Drawing.Point(26, 78)
$status.Size = New-Object System.Drawing.Size(380, 60)
$form.Controls.Add($status)

$bar = New-Object System.Windows.Forms.ProgressBar
$bar.Style = "Marquee"
$bar.MarqueeAnimationSpeed = 30
$bar.Location = New-Object System.Drawing.Point(26, 150)
$bar.Size = New-Object System.Drawing.Size(384, 18)
$form.Controls.Add($bar)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 400
$timer.Add_Tick({
    $status.Text = $sync.Status
    if ($sync.Failed) { $bar.Style = "Continuous"; $bar.Value = 0 }
})

$form.Add_Shown({ $timer.Start() })
$form.Add_FormClosing({
    try { $timer.Stop() } catch {}
    try { $worker.Stop() } catch {}
    try { $rs.Close() } catch {}
})

[System.Windows.Forms.Application]::Run($form)
