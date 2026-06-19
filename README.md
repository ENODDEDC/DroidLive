# DroidLive

Live-preview and hot-reload any native Android app from your code editor — no Android Studio needed.

DroidLive lets you build, run, and instantly reload your Android app on an emulator
or phone while you code in a lightweight editor like Cursor or VS Code. Pick a
project folder, and every time you save, the app rebuilds and relaunches — no
waiting on CI or opening a heavy IDE.

## What you get

- **One-command run:** a folder picker selects any Android project, then it builds,
  installs, launches, and watches for changes.
- **Auto-reload on save:** edit a `.kt` / `.xml` file, save, and the app updates.
- **No Android Studio:** uses only the command-line Android SDK + your project's Gradle.
- **Emulator or phone:** run on a built-in emulator, or your own device over USB.

## Requirements

- Windows with PowerShell
- A JDK (e.g. `winget install EclipseAdoptium.Temurin.21.JDK`)

## Setup (one-time)

Install the Android SDK (no Android Studio):

```powershell
powershell -ExecutionPolicy Bypass -File .\android-sdk-setup.ps1
```

Reopen the terminal afterwards, then confirm with `adb version`.

## Run your app

1. Start a device — either plug in your phone (USB debugging on), or launch the emulator:

```powershell
powershell -ExecutionPolicy Bypass -File .\emulator-setup.ps1
```

   Wait for "EMULATOR IS READY".

2. Run the live loop and pick your project folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\run-app.ps1
```

Your app installs and launches. Edit and save in your editor — it redeploys automatically.

## Scripts

- `android-sdk-setup.ps1` — installs the command-line Android SDK + `adb`.
- `emulator-setup.ps1` — creates and starts an emulator (software graphics for compatibility).
- `run-app.ps1` — pick a project, build, install, launch, and auto-reload on save.

## Notes

- The emulator uses software rendering for maximum compatibility, so it may feel
  slow on low-end machines; a physical phone over USB is faster.
- DroidLive works with any standard Gradle-based Android app (Compose or XML).
