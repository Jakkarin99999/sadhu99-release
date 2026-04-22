# SADHU99 One-Click Installer
# ============================
# Run in PowerShell:
#   irm https://raw.githubusercontent.com/Jakkarin99999/sadhu99-release/main/install.ps1 | iex

$ErrorActionPreference = 'Continue'
$installDir = "C:\SADHU99"
$repo = "Jakkarin99999/sadhu99-release"

function Pause-Exit($code) {
    Write-Host ""
    Write-Host "  Press any key to close..." -ForegroundColor DarkGray
    try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch {}
    exit $code
}

Write-Host ""
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host "    SADHU99 AI Trading Engine Installer   " -ForegroundColor Cyan
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host ""

# Step 0: Kill running SADHU99 processes
Write-Host "[0/4] Stopping running SADHU99..." -ForegroundColor Yellow
$procs = @("SADHU99","sadhu99-app","mt5-bridge","inference","databento-bridge")
foreach ($p in $procs) {
    Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2
Write-Host "       Done." -ForegroundColor DarkGreen

# Step 1: Find latest release
Write-Host "[1/4] Finding latest version..." -ForegroundColor Yellow
$release = $null
$asset = $null
try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -Headers @{ 'User-Agent' = 'SADHU99' } -ErrorAction Stop
    $asset = $release.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1
    if (-not $asset) {
        $asset = $release.assets | Where-Object { $_.name -like '*.exe' } | Select-Object -First 1
    }
    $version = $release.tag_name
    Write-Host "       Found: $version" -ForegroundColor DarkGreen
} catch {
    Write-Host ""
    Write-Host "  No release available yet." -ForegroundColor Red
    Write-Host "  Contact support." -ForegroundColor Yellow
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor DarkGray
    Pause-Exit 1
}

if (-not $asset) {
    Write-Host "  No installer file found in release." -ForegroundColor Red
    Pause-Exit 1
}

# Step 2: Download
$sizeMB = [math]::Round($asset.size / 1MB, 1)
Write-Host "[2/4] Downloading SADHU99 $version ($sizeMB MB)..." -ForegroundColor Yellow
$zipPath = "$env:TEMP\SADHU99-$version.zip"
try {
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
    Write-Host "       Download complete." -ForegroundColor DarkGreen
} catch {
    Write-Host "  Download failed: $($_.Exception.Message)" -ForegroundColor Red
    Pause-Exit 1
}

# Step 3: Install
Write-Host "[3/4] Installing to $installDir..." -ForegroundColor Yellow
try {
    if (Test-Path $installDir) {
        Write-Host "       Removing previous version..." -ForegroundColor DarkYellow
        Remove-Item $installDir -Recurse -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        if (Test-Path $installDir) {
            cmd /c "rd /s /q `"$installDir`"" 2>$null
            Start-Sleep -Seconds 1
        }
    }
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Write-Host "       Installed." -ForegroundColor DarkGreen
} catch {
    Write-Host "  Install failed: $($_.Exception.Message)" -ForegroundColor Red
    Pause-Exit 1
}

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
    Write-Host "       Shortcut created." -ForegroundColor DarkGreen
} catch {
    Write-Host "       Shortcut skipped." -ForegroundColor DarkYellow
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

Pause-Exit 0
