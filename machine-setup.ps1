$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=== Machine Setup: Node.js + Git + pnpm ===" -ForegroundColor Cyan
Write-Host ""

function Require-Command($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Ensure-Winget {
    if (-not (Require-Command "winget")) {
        Write-Host "winget is not installed or not available on this machine." -ForegroundColor Red
        Write-Host "Install App Installer / winget first, then rerun this script." -ForegroundColor Red
        exit 1
    }
}

function Install-WingetPackage($id, $label) {
    Write-Host ""
    Write-Host "Checking $label..." -ForegroundColor Yellow

    if ($id -eq "OpenJS.NodeJS.LTS") {
        if (Require-Command "node") {
            Write-Host "$label is already installed. Skipping." -ForegroundColor Green
            return
        }
    }

    if ($id -eq "Git.Git") {
        if (Require-Command "git") {
            Write-Host "$label is already installed. Skipping." -ForegroundColor Green
            return
        }
    }

    Write-Host "Installing $label..." -ForegroundColor Yellow
    winget install --id $id --exact --accept-source-agreements --accept-package-agreements

    Write-Host "$label install command finished." -ForegroundColor Green
}

Ensure-Winget

# 1. Install Node.js LTS
Install-WingetPackage "OpenJS.NodeJS.LTS" "Node.js LTS"

# 2. Install Git
Install-WingetPackage "Git.Git" "Git"

# 3. Refresh PATH for current session
$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPath"

# 4. Install pnpm
Write-Host ""
Write-Host "Checking pnpm..." -ForegroundColor Yellow

if (Require-Command "pnpm") {
    Write-Host "pnpm is already installed. Skipping." -ForegroundColor Green
}
else {
    if (-not (Require-Command "npm")) {
        Write-Host "npm is not available yet. Node.js may need a new terminal session." -ForegroundColor Red
        Write-Host "Close this terminal, open a new one, and rerun machine-setup.ps1 if pnpm is still missing." -ForegroundColor Red
        exit 1
    }

    Write-Host "Installing pnpm..." -ForegroundColor Yellow
    npm install -g pnpm
    Write-Host "pnpm install command finished." -ForegroundColor Green
}

# 5. Refresh PATH again
$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPath"

Write-Host ""
Write-Host "=== Machine Setup Summary ===" -ForegroundColor Cyan
Write-Host ""

if (Require-Command "node") {
    Write-Host ("Node.js: " + (node -v)) -ForegroundColor Green
}
else {
    Write-Host "Node.js: not detected in current terminal session" -ForegroundColor Yellow
}

if (Require-Command "git") {
    Write-Host ("Git: " + (git --version)) -ForegroundColor Green
}
else {
    Write-Host "Git: not detected in current terminal session" -ForegroundColor Yellow
}

if (Require-Command "pnpm") {
    Write-Host ("pnpm: " + (pnpm -v)) -ForegroundColor Green
}
else {
    Write-Host "pnpm: not detected in current terminal session" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "If any tool is not detected, close this terminal, open a new one, and check again." -ForegroundColor Yellow
Write-Host "After machine setup is ready, run your project bootstrap." -ForegroundColor Cyan
Write-Host ""