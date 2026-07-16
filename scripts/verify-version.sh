#!/usr/bin/env bash
# verify-version.sh — assert CHANGELOG.md's top version entry matches the
# version stated in METHODOLOGY.md's title and README.md's Status line.
#
# Local sanity check only (no CI wiring). Exits 0 if all three agree,
# non-zero (with a diagnostic) if any disagree or can't be found.
#
# Usage: bash scripts/verify-version.sh

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail() {
  echo "verify-version: FAIL — $1" >&2
  exit 1
}

changelog_version=$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md \
  | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') \
  || fail "no version entry found in CHANGELOG.md (expected a line like '## [X.Y.Z]')"

methodology_version=$(grep -m1 -oE '— v[0-9]+\.[0-9]+\.[0-9]+' METHODOLOGY.md \
  | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') \
  || fail "no version found in METHODOLOGY.md title (expected '... — vX.Y.Z')"

readme_version=$(grep -m1 -oE '\*\*v[0-9]+\.[0-9]+\.[0-9]+\*\*' README.md \
  | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') \
  || fail "no version found in README.md Status line (expected '**vX.Y.Z**')"

if [[ "$changelog_version" != "$methodology_version" || "$changelog_version" != "$readme_version" ]]; then
  fail "version mismatch — CHANGELOG.md=$changelog_version METHODOLOGY.md=$methodology_version README.md=$readme_version"
fi

echo "verify-version: OK — all files agree on v$changelog_version"
