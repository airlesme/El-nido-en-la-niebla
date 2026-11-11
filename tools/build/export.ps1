<#
.SYNOPSIS
  One-command export of one preset (ADR-0018 D1). Windows / local.
.DESCRIPTION
  Steps: pin check -> templates check -> --import -> --export-debug|release ->
  D4 layer-2 audit (tools/ci/audit_artifact.sh, needs bash) -> SHA256SUMS.txt.
  playtest-* use --export-debug, demo-* use --export-release (hard-coded pairing,
  ADR-0018 D1.3). Fails loudly (non-zero exit, message on stderr) on any gap.
  Locates the editor like tools/godot/godot.ps1 (bin\Godot_v<VERSION>_win64_console.exe)
  but never calls setup.ps1: this script downloads nothing.
.EXAMPLE
  .\tools\build\export.ps1 -Preset playtest-windows
#>
param(
    [Parameter(Mandatory)]
    [ValidateSet('playtest-windows', 'playtest-linux', 'demo-windows', 'demo-linux')]
    [string]$Preset,
    # Explicitly skip the D4 audit (e.g. while tools/ci/audit_artifact.sh does not exist). Never for a delivered demo.
    [switch]$SkipAudit
)
$ErrorActionPreference = 'Stop'
function Fail([string]$msg) { [Console]::Error.WriteLine("export.ps1: FAIL: $msg"); exit 1 }

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$godotDir = Join-Path $root 'tools\godot'
$cfg = @{}
Get-Content (Join-Path $godotDir 'version.txt') | Where-Object { $_ -match '^\s*[A-Z0-9_]+=' } | ForEach-Object {
    $k, $v = $_ -split '=', 2; $cfg[$k.Trim()] = $v.Trim()
}

# 1. Pin check: the running editor must match BUILD.
# Editor lookup order: $env:GODOT_BIN, tools\godot\bin\..., `godot` on PATH. The pin check below still applies.
$exe = $env:GODOT_BIN
if (-not $exe) {
    $local = Join-Path $godotDir ("bin\Godot_v{0}_win64_console.exe" -f $cfg.VERSION)
    if (Test-Path $local) { $exe = $local }
    else { $cmd = Get-Command godot -ErrorAction SilentlyContinue; if ($cmd) { $exe = $cmd.Source } }
}
if (-not $exe -or -not (Test-Path $exe)) { Fail "Godot not found (set GODOT_BIN, put godot on PATH, or run tools\godot\setup.ps1)" }
$sw = [System.Diagnostics.Stopwatch]::StartNew()
function Lap([string]$what) { Write-Host ("export.ps1: TIME {0} {1:N1}s" -f $what, $sw.Elapsed.TotalSeconds); $sw.Restart() }
$actual = (& $exe --version | Select-Object -First 1).Trim()
if ($actual -ne $cfg.BUILD) { Fail "Godot version '$actual' != pinned '$($cfg.BUILD)' (tools/godot/version.txt)" }

# 2. Templates: pinned in version.txt AND installed.
if ($cfg.TEMPLATES_SHA512 -like 'NOT VERIFIED*' -or $cfg.TEMPLATES_ARCHIVE -like 'NOT VERIFIED*') {
    Fail 'templates are not pinned in tools/godot/version.txt (NOT VERIFIED). Install them and record archive + SHA-512 first (V-18-3).'
}
$tplCandidates = @(
    (Join-Path $godotDir ("bin\editor_data\export_templates\{0}" -f $cfg.TEMPLATES_DIR)),
    (Join-Path $env:APPDATA ("Godot\export_templates\{0}" -f $cfg.TEMPLATES_DIR))
)
$tpl = $tplCandidates | Where-Object { Test-Path (Join-Path $_ 'version.txt') } | Select-Object -First 1
if (-not $tpl) { Fail "export templates $($cfg.TEMPLATES_DIR) not installed. Looked in: $($tplCandidates -join '; ')" }

# 3. Preset exists.
if (-not (Select-String -Path (Join-Path $root 'export_presets.cfg') -Pattern ('^name="{0}"' -f [regex]::Escape($Preset)) -Quiet)) {
    Fail "preset '$Preset' not found in export_presets.cfg"
}

# 4. Import, with the bounded exit-139 retry (ADR-0018 D6 / E6).
& $exe --headless --path $root --import
$rc = $LASTEXITCODE
if ($rc -eq 139) { Write-Warning 'import exited 139; retrying once (E6)'; & $exe --headless --path $root --import; $rc = $LASTEXITCODE }
if ($rc -ne 0) { Fail "--import exited $rc" }
Lap 'import'

# 5. Export; the debug/release pairing is hard-coded.
$mode = if ($Preset -like 'demo-*') { '--export-release' } else { '--export-debug' }
$bin = if ($Preset -like '*-windows') { 'el-nido.exe' } else { 'el-nido.x86_64' }
$outDir = Join-Path $root "build\$Preset"
if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
New-Item -ItemType Directory $outDir | Out-Null
$out = Join-Path $outDir $bin
& $exe --headless --path $root $mode $Preset $out
if ($LASTEXITCODE -ne 0) { Fail "$mode $Preset exited $LASTEXITCODE" }
if (-not (Test-Path $out)) { Fail "export reported success but $out does not exist" }

# 6. D4 layer-2 audit.
if ($SkipAudit) {
    [Console]::Error.WriteLine('export.ps1: WARNING: audit SKIPPED by -SkipAudit; artifact is NOT verified free of dev tools.')
} else {
    Lap 'export'
    $audit = Join-Path $root 'tools\ci\audit_artifact.sh'
    if (-not (Test-Path $audit)) { Fail 'tools/ci/audit_artifact.sh missing (ADR-0018 D4 layer 2). Pass -SkipAudit to export without it.' }
    $bash = Get-Command bash -ErrorAction SilentlyContinue
    if (-not $bash) { Fail 'bash not found; needed for the D4 audit' }
    Push-Location $root
    try {
        # The audit must itself pass its fixtures before its verdict on the artifact counts.
        & $bash.Source 'tools/ci/test_audit_artifact.sh'
        if ($LASTEXITCODE -ne 0) { Fail 'tools/ci/test_audit_artifact.sh failed: the audit is not trustworthy' }
        & $bash.Source 'tools/ci/audit_artifact.sh' "build/$Preset"; $arc = $LASTEXITCODE
    } finally { Pop-Location }
    if ($arc -ne 0) { Fail "audit_artifact.sh exited $arc" }
    Lap 'audit'
}

# 7. Checksums.
$lines = Get-ChildItem $outDir -File | Where-Object Name -ne 'SHA256SUMS.txt' | ForEach-Object {
    '{0}  {1}' -f (Get-FileHash -Algorithm SHA256 $_.FullName).Hash.ToLower(), $_.Name
}
Set-Content -Path (Join-Path $outDir 'SHA256SUMS.txt') -Value $lines -Encoding ascii
Write-Host "export.ps1: OK $Preset -> $outDir"
