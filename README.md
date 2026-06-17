# configure-zoomit.ps1

A small PowerShell utility to toggle [PowerToys ZoomIt](https://learn.microsoft.com/en-us/sysinternals/downloads/zoomit) webcam overlay and audio capture settings. ZoomIt does not expose these settings at runtime, so the script writes to the registry and restarts the process.

## Requirements

- Windows 10/11
- PowerToys installed (default path: `%LOCALAPPDATA%\PowerToys\`)
- PowerShell 5.1 or PowerShell 7+

## Usage

### GUI mode

```powershell
pwsh -WindowStyle Hidden -File .\zoomit.ps1
```

Opens a small dialog showing the current state of each toggle. Click **Apply & Restart** to write the settings and restart ZoomIt.

### Headless mode

```powershell
.\zoomit-configure.ps1 -Webcam on -Audio off
.\zoomit-configure.ps1 -Webcam off          # Audio left unchanged
.\zoomit-configure.ps1 -Audio on            # Webcam left unchanged
```

Parameters are independent — omitting one leaves that registry value as-is.

### Help

```powershell
.\zoomit-configure.ps1 -Help
Get-Help .\zoomit-configure.ps1 -Detailed   # equivalent
```

## Creating a shortcut

To launch the GUI without a console window, set the shortcut **Target** to:

```
pwsh.exe -WindowStyle Hidden -NoProfile -File "C:\path\to\zoomit-configure.ps1"
```

For Windows PowerShell 5, use `powershell.exe` instead of `pwsh.exe`. Alternatively, place a `launcher.vbs` alongside the script:

```vbs
CreateObject("WScript.Shell").Run "powershell -WindowStyle Hidden -File """ & _
    CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & _
    "\zoomit-configure.ps1""", 0
```

## Registry keys

| Setting | Path | Value name | Type |
|---|---|---|---|
| Webcam overlay | `HKCU\Software\Sysinternals\ZoomIt` | `WebcamOverlay` | DWORD |
| Audio capture | `HKCU\Software\Sysinternals\ZoomIt` | `CaptureAudio` | DWORD |

`1` = enabled, `0` = disabled.
