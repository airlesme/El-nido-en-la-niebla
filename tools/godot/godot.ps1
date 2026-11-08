<# Runs the pinned portable Godot (console build) with any arguments, e.g.
   .\tools\godot\godot.ps1 --headless --import --path .
   .\tools\godot\godot.ps1 --headless --path . --quit #>
$ErrorActionPreference = 'Stop'
$ver = ((Get-Content (Join-Path $PSScriptRoot 'version.txt') | Where-Object { $_ -match '^VERSION=' }) -split '=', 2)[1].Trim()
$exe = Join-Path $PSScriptRoot "bin\Godot_v${ver}_win64_console.exe"
if (-not (Test-Path $exe)) { & (Join-Path $PSScriptRoot 'setup.ps1') }
& $exe @args
exit $LASTEXITCODE
