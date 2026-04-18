#!/usr/bin/env bash
# Remove Terraform working dirs and lock files recursively from repo root.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

find "$ROOT" -type d -name ".terraform" -prune -exec rm -rf {} +

echo "Cleaned .terraform dirs under $ROOT"
