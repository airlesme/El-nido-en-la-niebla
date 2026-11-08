<#
.SYNOPSIS
  Downloads the pinned portable Godot into tools/godot/bin/ (gitignored).
.DESCRIPTION
  Reads version.txt, downloads the official build, verifies its SHA512, extracts
  it and creates the `_sc_` file so editor settings and export templates stay
  inside tools/godot/bin/ instead of %APPDATA%. Re-run with -Force to reinstall.
#>
param([switch]$Force)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$bin = Join-Path $here 'bin'

$cfg = @{}
Get-Content (Join-Path $here 'version.txt') | Where-Object { $_ -match '^\s*[A-Z0-9_]+=' } | ForEach-Object {
    $k, $v = $_ -split '=', 2; $cfg[$k.Trim()] = $v.Trim()
}
$exe = Join-Path $bin ("Godot_v{0}_win64.exe" -f $cfg.VERSION)

if ((Test-Path $exe) -and -not $Force) { Write-Host "Godot $($cfg.VERSION) already installed: $exe"; return }

$url = "https://github.com/godotengine/godot-builds/releases/download/$($cfg.VERSION)/$($cfg.ARCHIVE)"
$zip = Join-Path ([IO.Path]::GetTempPath()) $cfg.ARCHIVE
Write-Host "Downloading $url"
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing

$hash = (Get-FileHash -Algorithm SHA512 $zip).Hash.ToLower()
if ($hash -ne $cfg.SHA512.ToLower()) {
    Remove-Item $zip -Force
    throw "SHA512 mismatch. Expected $($cfg.SHA512), got $hash"
}
Write-Host 'SHA512 OK'

if (Test-Path $bin) { Remove-Item $bin -Recurse -Force }
New-Item -ItemType Directory $bin | Out-Null
Expand-Archive $zip -DestinationPath $bin
Remove-Item $zip -Force

# Self-contained mode: editor data lives next to the executable.
New-Item -ItemType File (Join-Path $bin '_sc_') | Out-Null
Write-Host "Installed: $exe"
