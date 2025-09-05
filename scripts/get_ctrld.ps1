<#
  ctrld fetcher for Windows
  Features:
    - Auto-elevate when -Install is used
    - -Version (default: latest), -List, -Check
    - Extracts .zip and (if ever) .tar.gz
#>

param(
  [string]$Version = "latest",   # accept with/without leading v
  [switch]$Install,
  [switch]$List,
  [switch]$Check,
  [switch]$Help
)

$Repo = "Control-D-Inc/ctrld"

function Show-Help {
@"
Usage:
  .\ctrld-get.ps1 [-Version <tag>] [-Install] [-List] [-Check] [-Help]

Options:
  -Version <tag>   Specific release (ex: 1.4.3 or v1.4.3). Default: latest
  -Install         Copy ctrld.exe into Program Files\ctrld (requires Admin)
  -List            List available release tags
  -Check           Dry-run: print detected arch and download URL, then exit
  -Help            Show this help message

Examples:
  .\ctrld-get.ps1
  .\ctrld-get.ps1 -Version 1.4.3
  .\ctrld-get.ps1 -Check
  .\ctrld-get.ps1 -Install
  .\ctrld-get.ps1 -Version v1.4.3 -Install
"@
}

if ($Help) { Show-Help; exit 0 }

# List mode
if ($List) {
  $tags = (Invoke-RestMethod -UseBasicParsing -Uri "https://api.github.com/repos/$Repo/releases") |
          ForEach-Object { $_.tag_name } |
          ForEach-Object { $_ -replace '^v','' } |
          Sort-Object -Descending
  $tags | ForEach-Object { Write-Output $_ }
  exit 0
}

# Detect arch (Windows => zip assets, arch usually amd64)
$OS = "windows"
$Arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }

# Normalize version label
$VerLabel = if ($Version -eq "latest") { "latest" } else { "v" + ($Version -replace '^v','') }

# Query API for matching asset
$ApiUrl = if ($VerLabel -eq "latest") {
  "https://api.github.com/repos/$Repo/releases/latest"
} else {
  "https://api.github.com/repos/$Repo/releases/tags/$VerLabel"
}

try {
  $release = Invoke-RestMethod -UseBasicParsing -Uri $ApiUrl
} catch {
  Write-Error "Failed to query GitHub API: $ApiUrl"
  exit 1
}

# Find asset that matches OS + Arch
$asset = $release.assets | Where-Object {
  $_.name -match $OS -and $_.name -match $Arch
} | Select-Object -First 1

if (-not $asset) {
  Write-Error "No matching asset found for $OS-$Arch (version: $VerLabel)"
  exit 1
}

$Url = $asset.browser_download_url

if ($Check) {
  Write-Output "OS:    $OS"
  Write-Output "Arch:  $Arch"
  Write-Output "Ver:   $VerLabel"
  Write-Output "URL:   $Url"
  exit 0
}

# Download
$OutFile = Join-Path $env:TEMP ($asset.name)
Write-Host "Downloading: $Url"
Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $OutFile

# Extract (zip expected; handle .tar.gz if it ever appears)
$ExtractDir = Join-Path $env:TEMP "ctrld-extract"
if (Test-Path $ExtractDir) { Remove-Item -Recurse -Force $ExtractDir }
New-Item -ItemType Directory -Path $ExtractDir | Out-Null

switch -regex ($OutFile) {
  '\.zip$'   { Expand-Archive -Force -Path $OutFile -DestinationPath $ExtractDir }
  '\.tar\.gz$' {
      # Fallback using tar if present (Git for Windows/Cygwin)
      if (Get-Command tar -ErrorAction SilentlyContinue) {
        tar -xzf $OutFile -C $ExtractDir
      } else {
        Write-Error "tar not found to extract .tar.gz"
        exit 1
      }
  }
  default { Write-Error "Unknown archive format: $OutFile"; exit 1 }
}

Remove-Item -Force $OutFile

# Optional install
if ($Install) {
  # Ensure elevation
  $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
             ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if (-not $IsAdmin) {
    Write-Host "Re-running with elevated privileges..."
    $argLine = @()
    if ($Version) { $argLine += "-Version `"$Version`"" }
    $argLine += "-Install"
    $ps = Start-Process -PassThru -Verb RunAs powershell -ArgumentList @(
      "-ExecutionPolicy Bypass",
      "-File `"$PSCommandPath`"",
      ($argLine -join ' ')
    )
    $ps.WaitForExit()
    exit $ps.ExitCode
  }

  # Locate ctrld(.exe)
  $bin = Get-ChildItem -Path $ExtractDir -Recurse -File -Include ctrld,ctrld.exe | Select-Object -First 1
  if (-not $bin) { Write-Error "ctrld binary not found after extraction"; exit 1 }

  $
