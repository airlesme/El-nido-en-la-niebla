<# Opens the project in the pinned portable Godot editor (installs it first if missing). #>
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$ver = ((Get-Content (Join-Path $PSScriptRoot 'version.txt') | Where-Object { $_ -match '^VERSION=' }) -split '=', 2)[1].Trim()
$exe = Join-Path $PSScriptRoot "bin\Godot_v${ver}_win64.exe"
if (-not (Test-Path $exe)) { & (Join-Path $PSScriptRoot 'setup.ps1') }
& $exe --editor --path $root @args
