# SADHU99 One-Click Installer
# ============================
# Run in PowerShell:
#   irm https://raw.githubusercontent.com/Jakkarin99999/sadhu99-release/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'
$installDir = "C:\SADHU99"
$repo = "Jakkarin99999/sadhu99-release"

Write-Host ""
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host "    SADHU99 AI Trading Engine Installer   " -ForegroundColor Cyan
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Find latest release
Write-Host "[1/4] Finding latest version..." -ForegroundColor Yellow
try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -Headers @{ 'User-Agent' = 'SADHU99' }
    $asset = $release.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1
    $version = $release.tag_name
    Write-Host "       Found: $version" -ForegroundColor DarkGreen
} catch {
    Write-Host "  ERROR: Could not reach download server." -ForegroundColor Red
    Write-Host "  Check your internet connection and try again." -ForegroundColor Yellow
    exit 1
}

if (-not $asset) {
    Write-Host "  ERROR: No installer found." -ForegroundColor Red
    Write-Host "  Please contact support." -ForegroundColor Yellow
    exit 1
}

# Step 2: Download
$sizeMB = [math]::Round($asset.size / 1MB, 1)
Write-Host "[2/4] Downloading SADHU99 ($sizeMB MB)..." -ForegroundColor Yellow
$zipPath = "$env:TEMP\SADHU99-$version.zip"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing
Write-Host "       Download complete." -ForegroundColor DarkGreen

# Step 3: Install
Write-Host "[3/4] Installing to $installDir..." -ForegroundColor Yellow
if (Test-Path $installDir) {
    Write-Host "       Removing previous version..." -ForegroundColor DarkYellow
    Remove-Item $installDir -Recurse -Force
}
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Write-Host "       Installed." -ForegroundColor DarkGreen

# Step 4: Create desktop shortcut
Write-Host "[4/4] Creating desktop shortcut..." -ForegroundColor Yellow
try {
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut("$env:PUBLIC\Desktop\SADHU99.lnk")
    $bat = Join-Path $installDir "Start-SADHU99.bat"
    $exe = Join-Path $installDir "SADHU99.exe"
    if (Test-Path $bat) { $lnk.TargetPath = $bat }
    elseif (Test-Path $exe) { $lnk.TargetPath = $exe }
    $lnk.WorkingDirectory = $installDir
    $lnk.Description = "SADHU99 AI Trading Engine"
    $lnk.Save()
    Write-Host "       Shortcut created on Desktop." -ForegroundColor DarkGreen
} catch {
    Write-Host "       Shortcut skipped (non-critical)." -ForegroundColor DarkYellow
}

# Done
Write-Host ""
Write-Host "  ========================================" -ForegroundColor Green
Write-Host "    SADHU99 $version Installed!           " -ForegroundColor Green
Write-Host "  ========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Location : $installDir" -ForegroundColor White
Write-Host "  Start    : Double-click SADHU99 on Desktop" -ForegroundColor White
Write-Host "             or run C:\SADHU99\Start-SADHU99.bat" -ForegroundColor White
Write-Host ""

# Auto-start
$bat = Join-Path $installDir "Start-SADHU99.bat"
if (Test-Path $bat) {
    Write-Host "  Launching SADHU99..." -ForegroundColor Cyan
    Start-Process $bat -WorkingDirectory $installDir
}
