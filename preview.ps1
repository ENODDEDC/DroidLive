# Live preview launcher.
# On run it:
#   1. Asks you to pick the folder that holds your Compose screens.
#   2. Validates the folder (must have Kotlin files, must not be a full Android project).
#   3. Makes sure that folder has a PreviewRegistry.kt (creates a starter if not).
#   4. Starts the live preview. Edit your screens in Cursor and save to see changes.

Add-Type -AssemblyName System.Windows.Forms

function Pick-Folder {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Pick the folder with your Compose screens (UI-only .kt files, NOT your whole Android project)"
    $dialog.ShowNewFolderButton = $true
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }
    return $null
}

function Test-FolderValid([string]$path) {
    if (-not (Test-Path $path)) {
        Write-Host "That folder does not exist." -ForegroundColor Red
        return $false
    }

    # Full Android projects can't be compiled by this desktop tool. Warn, but let
    # the user override (e.g. if they really pointed at a clean screens subfolder).
    $markers = Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue `
        -Include "AndroidManifest.xml", "build.gradle", "build.gradle.kts" | Select-Object -First 1
    if ($markers) {
        Write-Host "This looks like a full Android project (found $($markers.Name))." -ForegroundColor Yellow
        Write-Host "This tool can only compile pure-Compose UI, so the build will likely fail here." -ForegroundColor Yellow
        Write-Host "For your REAL screens, use Paparazzi instead (ask the assistant to set it up)." -ForegroundColor Yellow
        $answer = Read-Host "Try anyway? (y/N)"
        if ($answer -ne "y" -and $answer -ne "Y") {
            return $false
        }
    }

    # Warn about files that use Android-only APIs (they won't compile on desktop).
    $ktFiles = Get-ChildItem -Path $path -Recurse -Filter *.kt -ErrorAction SilentlyContinue
    $androidUsing = $ktFiles | Where-Object {
        Select-String -Path $_.FullName -Pattern "^import android\.|androidx\.(activity|navigation|lifecycle|hilt)" -Quiet
    }
    if ($androidUsing) {
        Write-Host "Heads up: these files use Android-only APIs and will fail to compile here:" -ForegroundColor Yellow
        $androidUsing | ForEach-Object { Write-Host "   - $($_.Name)" -ForegroundColor Yellow }
        Write-Host ""
    }

    return $true
}

# Keep asking until we get a valid folder (or the user cancels).
$path = $null
while ($true) {
    $picked = Pick-Folder
    if (-not $picked) {
        Write-Host "Cancelled. Nothing changed."
        exit 0
    }
    if (Test-FolderValid $picked) {
        $path = $picked
        break
    }
    Write-Host "Let's try another folder..." -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "Valid folder selected: $path" -ForegroundColor Green

# Save the choice for the build (forward slashes are safest in .properties files).
$forwardPath = $path -replace '\\', '/'
"screensDir=$forwardPath" | Set-Content -Encoding ASCII -Path (Join-Path $PSScriptRoot "preview.properties")

# Make sure a registry exists in the chosen folder.
$registryDir = Join-Path $path "preview"
$registryFile = Join-Path $registryDir "PreviewRegistry.kt"
if (-not (Test-Path $registryFile)) {
    New-Item -ItemType Directory -Force -Path $registryDir | Out-Null
    $template = @'
package preview

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable

// List the screens you want to preview. Add one PreviewScreen per screen.
// Each screen must be a @Composable function that takes no required arguments.
fun registerScreens(): List<PreviewScreen> = listOf(
    PreviewScreen("Example") { Text("Edit preview/PreviewRegistry.kt to add your screens") },
)
'@
    Set-Content -Encoding UTF8 -Path $registryFile -Value $template
    Write-Host "Created starter: $registryFile" -ForegroundColor Green
}

Write-Host "Starting live preview..." -ForegroundColor Green
& "$PSScriptRoot\gradlew.bat" hotRun --auto
