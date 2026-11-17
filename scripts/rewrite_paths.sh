#!/usr/bin/env bash
# Rewrite old absolute rm_sim paths after moving the source tree.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "用法: $0 <old_root> <new_root>"
  echo "例:   $0 /home/shaun/static/Mtools/rm_sim /opt/rm_sim"
  exit 1
fi

OLD="${1%/}"
NEW="${2%/}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Old: $OLD"
echo "New: $NEW"
echo "Repo: $ROOT"

mapfile -t FILES < <(
  grep -RIl --exclude-dir=.git --exclude-dir=build --exclude-dir=install \
    --exclude-dir=log --exclude-dir=logs --exclude-dir=__pycache__ \
    --exclude-dir=media --exclude='*.pcd' --exclude='*.pgm' \
    --exclude='*.stl' --exclude='*.png' --exclude='*.jpg' \
    "$OLD" "$ROOT" 2>/dev/null || true
)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "没有找到需要替换的文本文件。"
  exit 0
fi

for file in "${FILES[@]}"; do
  echo "rewrite: ${file#$ROOT/}"
  sed -i "s|$OLD|$NEW|g" "$file"
done

echo "完成。下一步:"
echo "  $NEW/scripts/install_desktop.sh"
echo "  $NEW/scripts/check_env.sh"
