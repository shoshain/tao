# run_proposers.ps1 — spawns FRESH, answer-isolated Claude Opus 4.8 subagents
# (via `claude -p --model opus`) to produce proposals for each held-out oracle
# case. GENERIC across products (TAO Pillar I — Answer-Isolated Proposal).
#
# Answer isolation (hard):
#   * Each batch runs in a brand-new `claude -p` process => zero shared context.
#   * The prompt contains ONLY each case's input.json. It NEVER contains
#     expected.json, the reference, the allowed-value catalogue, or the scorer.
#   * cwd = a temp scratch dir containing NONE of the repo; --permission-mode plan
#     (read-only). The subagent cannot read the answer off disk.
#
# Output: <ProposalsDir>/_batch-N-raw.txt (raw, for audit). Then run
# `normalize_oracle_proposals` + `oracle-score`.

param(
    [string]$CasesDir = "oracle/cases",
    [string]$ProposalsDir = "oracle/proposals",
    [string]$SystemPromptFile = "oracle/proposer_system.txt",
    [int]$BatchSize = 8,
    [string]$Model = "opus",
    [string]$Only = ""
)

$ErrorActionPreference = "Stop"
$CasesDir = (Resolve-Path $CasesDir).Path
if (-not (Test-Path $ProposalsDir)) { New-Item -ItemType Directory -Force $ProposalsDir | Out-Null }
$ProposalsDir = (Resolve-Path $ProposalsDir).Path
$systemPrompt = Get-Content -Raw $SystemPromptFile

$onlySet = @()
if ($Only -ne "") { $onlySet = $Only.Split(",") | ForEach-Object { $_.Trim() } }

$caseDirs = Get-ChildItem -Directory $CasesDir | Sort-Object Name
if ($onlySet.Count -gt 0) { $caseDirs = $caseDirs | Where-Object { $onlySet -contains $_.Name } }
Write-Host "Found $($caseDirs.Count) cases; batch size $BatchSize; model $Model"

$batchIndex = 0
for ($i = 0; $i -lt $caseDirs.Count; $i += $BatchSize) {
    $batchIndex++
    $batch = $caseDirs[$i..([Math]::Min($i + $BatchSize - 1, $caseDirs.Count - 1))]

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("Here are $($batch.Count) cases. For EACH, produce your proposal per the system instructions. Return ONE JSON object with a top-level `"proposals`" array covering all cases in this batch.")
    [void]$sb.AppendLine("")
    foreach ($cd in $batch) {
        $inp = Get-Content -Raw (Join-Path $cd.FullName "input.json")
        [void]$sb.AppendLine("=== CASE case_id: $($cd.Name) ===")
        [void]$sb.AppendLine($inp)
        [void]$sb.AppendLine("")
    }
    $prompt = $sb.ToString()

    $scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("tao-oracle-proposer-" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force $scratch | Out-Null
    Write-Host "Batch $batchIndex ($($batch.Count) cases): $($batch.Name -join ', ')"

    Push-Location $scratch
    try {
        $raw = $prompt | claude -p `
            --model $Model `
            --append-system-prompt $systemPrompt `
            --output-format text `
            --permission-mode plan
    }
    finally {
        Pop-Location
        Remove-Item -Recurse -Force $scratch -ErrorAction SilentlyContinue
    }

    $rawText = ($raw -join "`n")
    Set-Content -Encoding utf8 (Join-Path $ProposalsDir "_batch-$batchIndex-raw.txt") $rawText
    Write-Host "  wrote _batch-$batchIndex-raw.txt ($($rawText.Length) chars)"
}

Write-Host "Done. Raw batches in $ProposalsDir. Now run normalize_oracle_proposals + oracle-score."
