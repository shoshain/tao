<#
.SYNOPSIS
  TAO phantom-precision / stub detector (v0.2.0).

.DESCRIPTION
  Scans a product (or a whole portfolio) for the integrity anti-patterns that the
  Tolerance-Aware Oracle method exists to catch BEFORE a precision number is trusted:

    [PHANTOM-CONST]  precision_bench / scorer writes a hardcoded constant
                     (e.g. `let pr = if llm_off {1.0} else {0.72};`) instead of
                     measuring anything.
    [PHANTOM-CLAIM]  a manifest/README cites a precision / "N samples" / "held-out"
                     headline, but the referenced eval/held-out/cases dir is
                     absent or empty (the number describes data that doesn't exist).
    [STUB-LLM]       an "AI" path returns nothing real - Ok(vec![]) / -> None /
                     `return baseline` in a fn named *llm*/*plan*/*infer*/*ask*/*enrich*.
    [STUB-VERIFY]    a verifier/check fn whose whole body is `Ok(())` / `return true`
                     (passes unconditionally - cannot fail a wrong answer).

  These are HEURISTICS: every hit is a prompt to go read the code, not a verdict.
  TAO's discipline (LLM-free product-authority scorer + a discriminating --self-check
  + a real on-disk held-out set) is what actually proves a number; this tool just
  finds the places that haven't earned theirs yet.

.EXAMPLE
  ./detect-phantom-precision.ps1 -Root C:\AIP
  ./detect-phantom-precision.ps1 -Root C:\AIP\EMBEDDED\waiver-link -Json
#>
[CmdletBinding()]
param(
  [string]$Root = (Get-Location).Path,
  [switch]$Json
)

$ErrorActionPreference = 'Stop'

# --- what to skip (build output, vendored deps, vcs, oracle scratch) ---
# skip build output, vendored deps, vcs, AND the oracle/ tree itself (it is the
# CORRECTION layer — its NOT_APPLICABLE.md / STATE.md DESCRIBE the phantom, they
# are not the phantom; flagging them is crying wolf at the cure).
$skip = '\\(target|node_modules|\.git|dist|build|__pycache__|\.venv|venv|proposals|oracle|_batch|_scratch)\\'

# --- source-pattern rules: label, severity, file glob, regex ---
$rules = @(
  # direct assignment of a *named metric* to a constant fraction (NOT generic
  # `score = 0.0` init, NOT `>=`/`<=` threshold gates — those are legitimate).
  @{ Label='PHANTOM-CONST'; Sev='HIGH'; Ext='*.rs','*.py','*.ts','*.go'
     Rx='(?i)\b(precision|recall|f1[_-]?score|accuracy|pass_rate)\b\s*[=:]\s*"?(0\.\d+|1\.\d+)' }
  # the smoking gun: a precision_bench that returns a constant gated on llm_off.
  @{ Label='PHANTOM-CONST'; Sev='HIGH'; Ext='*.rs'
     Rx='if\s+llm_off\s*\{\s*1\.0' }
  @{ Label='STUB-LLM'; Sev='MED'; Ext='*.rs'
     Rx='(?i)fn\s+\w*(llm|plan|infer|ask|enrich|propose)\w*[^\{]*\{\s*(Ok\(vec!\[\]\)|None|Ok\(None\))' }
  # py bodies vary; only flag a non-test fn whose name is clearly an inference path.
  @{ Label='STUB-LLM'; Sev='MED'; Ext='*.py','*.ts'
     Rx='(?i)def\s+(?!test_)\w*(llm|infer|enrich|propose)\w*\b' }
  @{ Label='STUB-VERIFY'; Sev='HIGH'; Ext='*.rs'
     Rx='(?i)fn\s+\w*(verify|check|validate|judge|score)\w*[^\{]*->\s*[^\{]*\{\s*(Ok\(\(\)\)|return\s+true;?|true)\s*\}' }
)

$findings = New-Object System.Collections.Generic.List[object]

function Get-Product([string]$path) {
  # product = first path segment under $Root
  $rel = $path.Substring($Root.Length).TrimStart('\','/')
  $seg = $rel -split '[\\/]'
  if ($seg.Count -ge 2) { return "$($seg[0])/$($seg[1])" } else { return $seg[0] }
}

# --- 1) source anti-patterns ---
foreach ($rule in $rules) {
  $files = Get-ChildItem -Path $Root -Recurse -File -Include $rule.Ext -ErrorAction SilentlyContinue |
           Where-Object { $_.FullName -notmatch $skip }
  foreach ($f in $files) {
    $n = 0
    foreach ($line in [System.IO.File]::ReadLines($f.FullName)) {
      $n++
      if ($line -match $rule.Rx) {
        $findings.Add([pscustomobject]@{
          Product = Get-Product $f.FullName; Severity = $rule.Sev; Kind = $rule.Label
          File = $f.FullName; Line = $n; Text = $line.Trim()
        })
      }
    }
  }
}

# --- 2) phantom held-out CLAIMS: a doc cites a held-out/N-sample precision, but no populated eval set nearby ---
$claimRx = '(?i)(held[- ]?out|n\s*=\s*\d{2,}|\b\d{2,}\s+(samples|cases|examples)\b|precision[^\n]{0,30}\b\d{2,}%)'
$evalDirNames = 'eval','evals','heldout','held_out','held-out','cases','golden','fixtures','testset','test_set','dataset'
$docs = Get-ChildItem -Path $Root -Recurse -File -Include '*.md','*.json','*.toml','*.yaml','*.yml' -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch $skip }
foreach ($d in $docs) {
  $hit = Select-String -Path $d.FullName -Pattern $claimRx -List -ErrorAction SilentlyContinue
  if (-not $hit) { continue }
  # is there a populated eval-ish dir within this product?
  $prodRoot = Split-Path $d.FullName -Parent
  $up = $prodRoot; $populated = $false
  for ($i=0; $i -lt 4 -and $up -and $up.Length -ge $Root.Length; $i++) {
    foreach ($name in $evalDirNames) {
      $cand = Join-Path $up $name
      if (Test-Path $cand) {
        $cnt = (Get-ChildItem -Path $cand -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        if ($cnt -gt 0) { $populated = $true; break }
      }
    }
    if ($populated) { break }
    $up = Split-Path $up -Parent
  }
  if (-not $populated) {
    $findings.Add([pscustomobject]@{
      Product = Get-Product $d.FullName; Severity = 'HIGH'; Kind = 'PHANTOM-CLAIM'
      File = $d.FullName; Line = $hit.LineNumber; Text = ("claims precision/held-out but no populated eval dir: " + $hit.Line.Trim())
    })
  }
}

# --- report ---
if ($Json) {
  $findings | ConvertTo-Json -Depth 4
  return
}

if ($findings.Count -eq 0) {
  Write-Output "No phantom-precision / stub anti-patterns found under $Root."
  return
}

# Report on the SUCCESS stream (Write-Output) so `> file` / `| Out-File` / `| Select-String`
# all capture it. (Write-Host bypasses the pipeline; use -Json for structured machine output.)
Write-Output ""
Write-Output "TAO phantom-precision / stub scan - $Root"
Write-Output ("=" * 72)
foreach ($grp in ($findings | Group-Object Product | Sort-Object Name)) {
  Write-Output ""
  Write-Output (">> {0}  ({1} finding(s))" -f $grp.Name, $grp.Count)
  foreach ($fnd in ($grp.Group | Sort-Object Severity, Kind)) {
    $rel = $fnd.File.Substring($Root.Length).TrimStart('\','/')
    Write-Output ("   [{0}] {1}  {2}:{3}" -f $fnd.Severity, $fnd.Kind, $rel, $fnd.Line)
    Write-Output ("        {0}" -f $fnd.Text)
  }
}
# @(...) forces array context so .Count is reliable for 0/1/many (PS5.1 scalar pitfall).
$hi = @($findings | Where-Object Severity -eq 'HIGH').Count
$me = @($findings | Where-Object Severity -eq 'MED').Count
$np = @($findings | Group-Object Product).Count
Write-Output ""
Write-Output "Totals: $hi HIGH, $me MED across $np product(s). Each hit = go read the code."
