<#
.SYNOPSIS
    Toggle PowerToys ZoomIt webcam overlay and audio capture settings.

.DESCRIPTION
    Updates ZoomIt registry settings and restarts the process. Run without
    arguments to open an interactive GUI. Pass -Webcam and/or -Audio to
    apply settings headlessly (useful for shortcuts or automation).

.PARAMETER Webcam
    Set webcam overlay: "on" or "off". Omit to leave unchanged (headless)
    or read from registry (GUI).

.PARAMETER Audio
    Set audio capture: "on" or "off". Omit to leave unchanged (headless)
    or read from registry (GUI).

.PARAMETER Help
    Show this help message and exit.

.EXAMPLE
    .\configure-zoomit.ps1
    Opens the GUI.

.EXAMPLE
    .\configure-zoomit.ps1 -Webcam on -Audio off
    Enables webcam overlay, disables audio capture, restarts ZoomIt.

.EXAMPLE
    .\configure-zoomit.ps1 -Webcam off
    Disables webcam overlay only; audio setting is left unchanged.

.EXAMPLE
    pwsh -WindowStyle Hidden -File .\configure-zoomit.ps1
    Opens the GUI without a console window (use in a shortcut).
#>

param(
    [string]$Webcam,
    [string]$Audio,
    [switch]$Help
)

if ($Help) {
    Get-Help $PSCommandPath -Detailed
    exit
}

foreach ($pair in @(@("Webcam", $Webcam), @("Audio", $Audio))) {
    if ($pair[1] -and $pair[1] -notin "on", "off") {
        Write-Error "-$($pair[0]) must be 'on' or 'off'. Run with -Help for usage."
        exit 1
    }
}

$regPath   = "HKCU:\Software\Sysinternals\ZoomIt"
$zoomitExe = "$env:LOCALAPPDATA\PowerToys\PowerToys.ZoomIt.exe"

function Get-RegVal($name) {
    try { return (Get-ItemPropertyValue -Path $regPath -Name $name -EA Stop) } catch { return 0 }
}

function Set-RegVal($name, $value) {
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    Set-ItemProperty -Path $regPath -Name $name -Value $value -Type DWord
}

function Apply-And-Restart($webcamVal, $audioVal) {
    Stop-Process -Name "PowerToys.ZoomIt" -Force -EA SilentlyContinue
    Set-RegVal "WebcamOverlay" $webcamVal
    Set-RegVal "CaptureAudio"  $audioVal
    Start-Process -FilePath $zoomitExe
}

# --- Headless mode ---
if ($Webcam -or $Audio) {
    $newWebcam = if ($Webcam) { [int]($Webcam -eq "on") } else { Get-RegVal "WebcamOverlay" }
    $newAudio  = if ($Audio)  { [int]($Audio  -eq "on") } else { Get-RegVal "CaptureAudio"  }
    Apply-And-Restart $newWebcam $newAudio
    exit
}

# --- GUI mode ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text            = "ZoomIt"
$form.Size            = New-Object System.Drawing.Size(240, 135)
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false
$form.StartPosition   = 'CenterScreen'
$form.KeyPreview      = $true   # form sees keystrokes before controls do

$cbWebcam = New-Object System.Windows.Forms.CheckBox
$cbWebcam.Text     = "[W]  Webcam Overlay"
$cbWebcam.Location = New-Object System.Drawing.Point(15, 12)
$cbWebcam.Checked  = ((Get-RegVal "WebcamOverlay") -eq 1)
$cbWebcam.AutoSize = $true

$cbAudio = New-Object System.Windows.Forms.CheckBox
$cbAudio.Text     = "[A]  Capture Audio"
$cbAudio.Location = New-Object System.Drawing.Point(15, 36)
$cbAudio.Checked  = ((Get-RegVal "CaptureAudio") -eq 1)
$cbAudio.AutoSize = $true

$btn = New-Object System.Windows.Forms.Button
$btn.Text     = "Apply && Restart  [Enter]"
$btn.Location = New-Object System.Drawing.Point(30, 67)
$btn.Size     = New-Object System.Drawing.Size(175, 26)
$btn.Add_Click({
    Apply-And-Restart ([int]$cbWebcam.Checked) ([int]$cbAudio.Checked)
    $form.Close()
})

# Enter triggers Apply; Escape closes without applying
$form.AcceptButton = $btn

$form.Add_KeyDown({
    param($s, $e)
    switch ($e.KeyCode) {
        'W'      { $cbWebcam.Checked = -not $cbWebcam.Checked; $e.Handled = $true }
        'A'      { $cbAudio.Checked  = -not $cbAudio.Checked;  $e.Handled = $true }
        'Escape' { $form.Close();                               $e.Handled = $true }
    }
})

$form.Controls.AddRange(@($cbWebcam, $cbAudio, $btn))
$form.Add_Shown({ $form.Activate() })
$form.ShowDialog() | Out-Null
