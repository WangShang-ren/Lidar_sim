#!/usr/bin/env bash
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
exec "$DIR/scripts/go_pointlio_2026.sh" "$@"
