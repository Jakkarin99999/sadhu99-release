# SADHU99 quick-install alias — forwards to get-sadhu99-vps.ps1
# This file is hosted at the root of sadhu99-release so customers can run:
#   irm https://raw.githubusercontent.com/Jakkarin99999/sadhu99-release/main/get-sadhu99.ps1 | iex

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

$REPO    = 'Jakkarin99999/sadhu99-release'
$API_URL = "https://api.github.com/repos/$REPO/releases/latest"

function Write-Banner($msg, $color = 'Cyan') {
    Write-Host ""
    Write-Host "  =============================================" -ForegroundColor $color
    Write-Host "   $msg" -ForegroundColor $color
    Write-Host "  =============================================" -ForegroundColor $color
}
function Write-OK($msg)   { Write-Host "  [OK]   $msg" -ForegroundColor Green  }
function Write-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red    }

Write-Banner "SADHU99 Auto-Installer"
Write-Host "  Fetching latest release from github.com/$REPO ..." -ForegroundColor Gray

try {
    $release = Invoke-RestMethod -Uri $API_URL -Headers @{ 'User-Agent' = 'sadhu99-installer' }
} catch {
    Write-Fail "Could not reach GitHub API: $($_.Exception.Message)"
    Write-Host "  Check your internet connection and try again." -ForegroundColor White
    Read-Host "Press Enter to exit"; exit 1
}

$tag     = $release.tag_name
$version = $tag.TrimStart('v')
Write-OK "Latest version: $tag"

$setupAsset = $release.assets | Where-Object { $_.name -match 'Setup\.exe$' } | Select-Object -First 1
if (-not $setupAsset) { $setupAsset = $release.assets | Where-Object { $_.name -match '\.exe$' } | Select-Object -First 1 }
if (-not $setupAsset) { Write-Fail "No installer found in release $tag."; exit 1 }

$tmpExe = Join-Path $env:TEMP "SADHU99-Setup-$version.exe"
Write-Host "  Downloading $($setupAsset.name) ($([math]::Round($setupAsset.size/1MB,1)) MB)..." -ForegroundColor Gray
try { Invoke-WebRequest -Uri $setupAsset.browser_download_url -OutFile $tmpExe -UseBasicParsing }
catch { Write-Fail "Download failed: $($_.Exception.Message)"; exit 1 }
Write-OK "Downloaded."

Write-Host "  Running installer silently..." -ForegroundColor Gray
$proc = Start-Process -FilePath $tmpExe -ArgumentList '/S' -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    Write-Warn "Silent install returned code $($proc.ExitCode) - launching interactive..."
    Start-Process -FilePath $tmpExe -Wait
} else { Write-OK "Installed." }

Remove-Item $tmpExe -Force -ErrorAction SilentlyContinue

$installDir = @("$env:ProgramFiles\SADHU99","$env:LOCALAPPDATA\Programs\SADHU99","$env:LOCALAPPDATA\SADHU99") |
    Where-Object { Test-Path $_ } | Select-Object -First 1
$desktopLnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'SADHU99.lnk'
if ($installDir -and -not (Test-Path $desktopLnk)) {
    $exe = Get-ChildItem "$installDir\*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($exe) {
        try {
            $sc = (New-Object -ComObject WScript.Shell).CreateShortcut($desktopLnk)
            $sc.TargetPath = $exe.FullName; $sc.WorkingDirectory = $installDir
            $sc.Description = "SADHU99 AI Trading Engine $tag"; $sc.Save()
            Write-OK "Desktop shortcut created."
        } catch {}
    }
}

Write-Banner "SADHU99 $tag installed!" 'Green'
Write-Host "  Launch from your desktop shortcut, enter license key, connect MT5." -ForegroundColor White
Write-Host ""
