$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=== Shadcn Next.js Bootstrap ===" -ForegroundColor Cyan
Write-Host ""

# 1. Ask for project name
$ProjectName = Read-Host "Enter new project name"

if ([string]::IsNullOrWhiteSpace($ProjectName)) {
  Write-Host "Project name cannot be empty." -ForegroundColor Red
  exit 1
}

# 2. Ask for parent folder, default = current folder
$DefaultParent = (Get-Location).Path
$ParentFolder = Read-Host "Enter parent folder path or press Enter to use current folder [$DefaultParent]"

if ([string]::IsNullOrWhiteSpace($ParentFolder)) {
  $ParentFolder = $DefaultParent
}

if (-not (Test-Path $ParentFolder)) {
  Write-Host "Parent folder does not exist: $ParentFolder" -ForegroundColor Red
  exit 1
}

$ProjectPath = Join-Path $ParentFolder $ProjectName

if (Test-Path $ProjectPath) {
  Write-Host "Folder already exists: $ProjectPath" -ForegroundColor Red
  exit 1
}

# 3. Pre-check required tools
function Require-Command($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    Write-Host "Missing required command: $name" -ForegroundColor Red
    exit 1
  }
}

Require-Command "node"
Require-Command "pnpm"
Require-Command "doppler"

Write-Host ""
Write-Host "Creating project at: $ProjectPath" -ForegroundColor Yellow

# 4. Create folder and move into it
New-Item -ItemType Directory -Path $ProjectPath | Out-Null
Set-Location $ProjectPath

# 5. Create Next.js app
pnpm create next-app@latest . --ts --tailwind --eslint --app --src-dir --import-alias "@/*"

# 6. Init shadcn
pnpm dlx shadcn@latest init -d --base radix

# 7. Doppler setup
$dopplerConfigured = $false

try {
  $null = doppler configure get 2>$null
  if ($LASTEXITCODE -eq 0) {
    $dopplerConfigured = $true
  }
} catch {
  $dopplerConfigured = $false
}

if (-not $dopplerConfigured) {
  Write-Host ""
  Write-Host "Select your Doppler project and config..." -ForegroundColor Cyan
  doppler setup
}

# Shared UTF-8 without BOM encoder
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# 8. Export secrets to .env.local
$envContent = doppler secrets download --no-file --format env 2>$null
if ($LASTEXITCODE -ne 0 -or -not $envContent) {
  Write-Host ""
  Write-Host "Failed to download Doppler secrets." -ForegroundColor Red
  Write-Host "Make sure you are logged into Doppler, have access to the selected project/config, and try again." -ForegroundColor Red
  exit 1
}

$envText = $envContent -join "`r`n"

if ($envText -notmatch '(^|[\r\n])EMAIL=' -or $envText -notmatch '(^|[\r\n])LICENSE_KEY=') {
  Write-Host ""
  Write-Host "Missing EMAIL or LICENSE_KEY in Doppler secrets." -ForegroundColor Red
  Write-Host "Add those secrets in the selected Doppler project/config and rerun the bootstrap." -ForegroundColor Red
  exit 1
}

[System.IO.File]::WriteAllText((Join-Path $ProjectPath ".env.local"), $envText, $utf8NoBom)

# 9. Overwrite components.json
$jsonContent = @'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "radix-nova",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "src/app/globals.css",
    "baseColor": "neutral",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  },
  "registries": {
    "@shadcn-studio": "https://shadcnstudio.com/r/{name}.json",
    "@ss-components": {
      "url": "https://shadcnstudio.com/r/components/{name}.json",
      "params": {
        "email": "${EMAIL}",
        "license_key": "${LICENSE_KEY}"
      }
    },
    "@ss-blocks": {
      "url": "https://shadcnstudio.com/r/blocks/{name}.json",
      "params": {
        "email": "${EMAIL}",
        "license_key": "${LICENSE_KEY}"
      }
    },
    "@ss-themes": {
      "url": "https://shadcnstudio.com/r/themes/{name}.json",
      "params": {
        "email": "${EMAIL}",
        "license_key": "${LICENSE_KEY}"
      }
    }
  }
}
'@
[System.IO.File]::WriteAllText((Join-Path $ProjectPath "components.json"), $jsonContent, $utf8NoBom)

# 10. Ensure .gitignore includes .env.local
if (Test-Path ".gitignore") {
  $gitignore = Get-Content ".gitignore" -Raw
  if ($gitignore -notmatch "(?m)^\.env\.local$") {
    Add-Content ".gitignore" "`n.env.local"
  }
}

Write-Host ""
Write-Host "Bootstrap complete." -ForegroundColor Green
Write-Host "Project created at: $ProjectPath" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. cd `"$ProjectPath`""
Write-Host "2. pnpm dev"
Write-Host "3. Start coding"
Write-Host ""