#!/usr/bin/env bash
# sync.sh — pulls core source files from vercel-labs/agent-browser and patches them
# for use as a standalone library crate.
#
# This file is part of agent-browser-core-unofficial.
# Original work Copyright 2025 Vercel Inc., licensed under Apache-2.0.
# Modifications Copyright contributors of agent-browser-core-unofficial.
set -euo pipefail

UPSTREAM_RAW="https://raw.githubusercontent.com/vercel-labs/agent-browser/main"
UPSTREAM_API="https://api.github.com/repos/vercel-labs/agent-browser/contents"
SRC="cli/src"

echo "Syncing from upstream vercel-labs/agent-browser..."

# Sync version from upstream Cargo.toml
VERSION=$(curl -fsSL "$UPSTREAM_RAW/cli/Cargo.toml" \
  | grep '^version' | head -1 | sed 's/version = "\(.*\)"/\1/')
sed -i.bak "s/^version = .*/version = \"$VERSION\"/" Cargo.toml && rm Cargo.toml.bak
echo "Version: $VERSION"

# Core source files to sync (excludes CLI-only: main.rs, install.rs, upgrade.rs)
CORE_FILES=(color.rs commands.rs connection.rs flags.rs output.rs validation.rs test_utils.rs)

mkdir -p src
for f in "${CORE_FILES[@]}"; do
  curl -fsSL "$UPSTREAM_RAW/$SRC/$f" -o "src/$f"
  echo "  synced src/$f"
done

# Sync native/ directory recursively
sync_dir() {
  local api_path="$1"
  local local_path="$2"
  mkdir -p "$local_path"

  curl -fsSL "$UPSTREAM_API/$api_path" | python3 -c "
import sys, json
items = json.load(sys.stdin)
for item in items:
    print(item['type'] + ' ' + item['name'])
" | while read -r type name; do
    if [ "$type" = "file" ]; then
      curl -fsSL "$UPSTREAM_RAW/$api_path/$name" -o "$local_path/$name"
      echo "  synced $local_path/$name"
    elif [ "$type" = "dir" ]; then
      sync_dir "$api_path/$name" "$local_path/$name"
    fi
  done
}

sync_dir "$SRC/native" "src/native"

echo "Sync complete: $VERSION"
