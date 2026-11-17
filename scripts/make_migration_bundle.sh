#!/usr/bin/env bash
# Create repo-only and source-only tarballs for moving rm_sim to another machine.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/dist}"
STAMP="$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"

REPO_TAR="$OUT/rm_sim_repo_$STAMP.tar.gz"
SRC_TAR="$OUT/rm_sim_sources_$STAMP.tar.gz"

echo "Creating repo bundle..."
tar -C "$ROOT" \
  --exclude='./envs' \
  --exclude='./third_party' \
  --exclude='./.git' \
  --exclude='./dist' \
  --exclude='./.easyview' \
  --exclude='*/__pycache__' \
  --exclude='*.pyc' \
  --exclude='./tools/lio_tune/state' \
  --exclude='./tools/lio_tune/logs' \
  -czf "$REPO_TAR" .

echo "Creating source bundle..."
tar -C "$ROOT" \
  --exclude='*/build' \
  --exclude='*/install' \
  --exclude='*/log' \
  --exclude='*/logs' \
  --exclude='*/.git' \
  --exclude='*/__pycache__' \
  --exclude='*.pyc' \
  --exclude='*.pyo' \
  --exclude='*/.vscode' \
  -czf "$SRC_TAR" envs third_party

{
  echo "rm_sim migration bundle"
  echo "created: $(date -Is)"
  echo "host: $(uname -a)"
  echo "repo bundle: $(basename "$REPO_TAR")"
  echo "source bundle: $(basename "$SRC_TAR")"
  echo
  echo "repo bundle contents: repo entry/config/tools/docs, no envs/third_party"
  echo "source bundle contents: envs and third_party source, no build/install/log"
  echo
  echo "target build:"
  echo "  scripts/build_all.sh"
  echo "  scripts/check_env.sh"
  echo "  scripts/install_desktop.sh"
} | tee "$OUT/MANIFEST_$STAMP.txt"

echo
ls -lh "$REPO_TAR" "$SRC_TAR"
