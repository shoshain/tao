# new-oracle.ps1 — scaffold a TAO oracle/ bundle into a target product.
#
# Copies templates/oracle/ -> <Into>/oracle/, drops the .tmpl suffixes, and does a
# light placeholder pass (<PRODUCT>, <product>). Refuses to overwrite an existing
# oracle/. After scaffolding you still must fill the TODO(product) hooks.
#
# Usage:
#   pwsh scripts/new-oracle.ps1 -Product RGCanary -Into C:\AIP\RELIABILITY\RGCanary

param(
    [Parameter(Mandatory = $true)][string]$Product,    # display name, e.g. "RGCanary"
    [Parameter(Mandatory = $true)][string]$Into,        # path to the product repo root
    [string]$CratePrefix = ""                            # kebab crate prefix; default = lowercased Product
)
$ErrorActionPreference = "Stop"
if ($CratePrefix -eq "") { $CratePrefix = $Product.ToLower() }

$src = Join-Path $PSScriptRoot "..\templates\oracle"
$dst = Join-Path $Into "oracle"
if (-not (Test-Path $src)) { throw "template not found: $src" }
if (Test-Path $dst) { throw "$dst already exists — refusing to overwrite (oracle already scaffolded?)" }

Copy-Item -Recurse $src $dst

# Drop .tmpl suffixes.
Get-ChildItem -Recurse $dst -Filter *.tmpl | ForEach-Object {
    $new = $_.FullName.Substring(0, $_.FullName.Length - 5)
    Move-Item $_.FullName $new -Force
}

# Light placeholder substitution (the deep hooks are deliberately left as TODOs).
Get-ChildItem -Recurse $dst -File |
    Where-Object { $_.Extension -in ".rs", ".toml", ".md", ".txt", ".ps1" } |
    ForEach-Object {
        $t = Get-Content -Raw $_.FullName
        $t = $t.Replace("<PRODUCT>", $Product).Replace("<product>", $CratePrefix)
        Set-Content -Encoding utf8 $_.FullName $t
    }

Write-Host "Scaffolded TAO oracle -> $dst"
Write-Host "Next steps:"
Write-Host "  1. Add 'oracle' to the workspace members; path-dep the product crates in oracle/Cargo.toml."
Write-Host "  2. Fill the TODO(product) hooks in src/bin/oracle_score.rs (kernel + verifier) and reference.rs."
Write-Host "  3. Curate gen_oracle_cases.rs + write the LLM-OFF path in baseline_proposals.rs."
Write-Host "  4. See ../docs/checklist.md for the full recipe."
