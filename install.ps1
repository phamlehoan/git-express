# Install gx for Windows (PowerShell / CMD / Git Bash)
# Usage:  powershell -ExecutionPolicy Bypass -File .\install.ps1
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Src = Join-Path $Root "bin\gx"
$InstallDir = if ($env:INSTALL_DIR) { $env:INSTALL_DIR } else {
  Join-Path $env:LOCALAPPDATA "gx\bin"
}

if (-not (Test-Path $Src)) {
  Write-Error "Missing $Src"
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-Item -Force $Src (Join-Path $InstallDir "gx")

# Docs → %LOCALAPPDATA%\gx\docs
$DocsSrc = Join-Path $Root "docs"
$DocsDir = if ($env:GX_DOCS_DIR) { $env:GX_DOCS_DIR } else {
  Join-Path $env:LOCALAPPDATA "gx\docs"
}
if (Test-Path $DocsSrc) {
  New-Item -ItemType Directory -Force -Path $DocsDir | Out-Null
  Copy-Item -Force -Recurse (Join-Path $DocsSrc "*") $DocsDir
  Write-Host "[OK] Docs → $DocsDir"
} else {
  Write-Host "[Warn] No docs\ folder found next to install.ps1"
}

# Hook templates → %LOCALAPPDATA%\gx\hooks (enable per repo: gx hooks on)
$HooksSrc = Join-Path $Root "hooks"
$HooksDir = if ($env:GX_HOOKS_DIR) { $env:GX_HOOKS_DIR } else {
  Join-Path $env:LOCALAPPDATA "gx\hooks"
}
if (Test-Path $HooksSrc) {
  if (Test-Path $HooksDir) { Remove-Item -Recurse -Force $HooksDir }
  New-Item -ItemType Directory -Force -Path $HooksDir | Out-Null
  Copy-Item -Force -Recurse (Join-Path $HooksSrc "*") $HooksDir
  Write-Host "[OK] Hooks → $HooksDir"
} else {
  Write-Host "[Warn] No hooks\ folder found next to install.ps1"
}

# CMD shim: prefer Git Bash if available
$GitBashCandidates = @(
  (Join-Path ${env:ProgramFiles} "Git\bin\bash.exe"),
  (Join-Path ${env:ProgramFiles(x86)} "Git\bin\bash.exe"),
  (Join-Path $env:LOCALAPPDATA "Programs\Git\bin\bash.exe")
)
$Bash = $GitBashCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

$GxScript = (Join-Path $InstallDir "gx") -replace '\\', '/'
# Convert Windows path to Git Bash style when needed
function ConvertTo-BashPath([string]$WinPath) {
  $p = $WinPath -replace '\\', '/'
  if ($p -match '^([A-Za-z]):/(.*)$') {
    return "/$($Matches[1].ToLower())/$($Matches[2])"
  }
  return $p
}
$BashGx = ConvertTo-BashPath $GxScript

$CmdShim = @"
@echo off
setlocal
set "GX_SCRIPT=$GxScript"
if exist "%ProgramFiles%\Git\bin\bash.exe" (
  "%ProgramFiles%\Git\bin\bash.exe" "%GX_SCRIPT%" %*
  exit /b %ERRORLEVEL%
)
if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" (
  "%ProgramFiles(x86)%\Git\bin\bash.exe" "%GX_SCRIPT%" %*
  exit /b %ERRORLEVEL%
)
where bash >nul 2>&1 && (
  bash "%GX_SCRIPT%" %*
  exit /b %ERRORLEVEL%
)
echo [Error] Git Bash / bash not found. Install Git for Windows, then re-run install.ps1.
exit /b 1
"@
Set-Content -Path (Join-Path $InstallDir "gx.cmd") -Value $CmdShim -Encoding ASCII

# PowerShell function shim (optional convenience file users can dot-source)
$PsShim = @"
function gx {
  param([Parameter(ValueFromRemainingArguments = `$true)] `$Args)
  & '$($Bash -replace "'", "''")' '$BashGx' @Args
}
"@
if ($Bash) {
  Set-Content -Path (Join-Path $InstallDir "gx.ps1") -Value $PsShim -Encoding UTF8
}

# Add InstallDir to user PATH if missing
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $userPath) { $userPath = "" }
$parts = $userPath -split ';' | Where-Object { $_ -ne "" }
if ($parts -notcontains $InstallDir) {
  $newPath = if ($userPath.TrimEnd(';')) { "$userPath;$InstallDir" } else { $InstallDir }
  [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
  $env:Path = "$env:Path;$InstallDir"
  Write-Host "[OK] Added to User PATH: $InstallDir"
} else {
  Write-Host "[OK] PATH already contains: $InstallDir"
}

Write-Host "[OK] Installed gx -> $InstallDir"
Write-Host "     Open a new terminal, then run:  gx h"
Write-Host "     Docs: gx docs | gx docs vi | gx docs ja"
Write-Host "     Hooks: gx hooks on  (per repo)"
if (-not $Bash) {
  Write-Host "[Warn] Git Bash not detected. gx.cmd needs bash on PATH."
}
