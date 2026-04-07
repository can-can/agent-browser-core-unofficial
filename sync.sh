#!/usr/bin/env bash
# sync.sh — pulls source files from vercel-labs/agent-browser for use as a library crate.
# Original work Copyright 2025 Vercel Inc., licensed under Apache-2.0.
set -euo pipefail

RAW="https://raw.githubusercontent.com/vercel-labs/agent-browser/main"

echo "Syncing from upstream vercel-labs/agent-browser..."

# Sync version from upstream Cargo.toml
VERSION=$(curl -fsSL "$RAW/cli/Cargo.toml" \
  | grep '^version' | head -1 | sed 's/version = "\(.*\)"/\1/')
sed -i.bak "s/^version = .*/version = \"$VERSION\"/" Cargo.toml && rm Cargo.toml.bak
echo "Version: $VERSION"

# build.rs
curl -fsSL "$RAW/cli/build.rs" -o "build.rs"
echo "  synced build.rs"

# cdp-protocol JSON files (flat, consumed by build.rs)
mkdir -p cdp-protocol
for f in browser_protocol.json js_protocol.json; do
  curl -fsSL "$RAW/cli/cdp-protocol/$f" -o "cdp-protocol/$f"
  echo "  synced cdp-protocol/$f"
done

# Use Python to recursively fetch src/ via GitHub API (handles any future restructuring)
python3 - <<'PYEOF'
import urllib.request, json, os, sys

API = "https://api.github.com/repos/vercel-labs/agent-browser/contents"
RAW = "https://raw.githubusercontent.com/vercel-labs/agent-browser/main"

# Top-level files to exclude (CLI-only, not needed in the library)
EXCLUDE = {"main.rs", "upgrade.rs"}

def fetch_dir(api_path, local_path):
    url = f"{API}/{api_path}"
    with urllib.request.urlopen(url) as r:
        items = json.load(r)
    os.makedirs(local_path, exist_ok=True)
    for item in items:
        name = item["name"]
        if item["type"] == "file":
            if api_path == "cli/src" and name in EXCLUDE:
                continue
            dest = os.path.join(local_path, name)
            with urllib.request.urlopen(f"{RAW}/{api_path}/{name}") as r:
                with open(dest, "wb") as f:
                    f.write(r.read())
            print(f"  synced {dest}")
        elif item["type"] == "dir":
            fetch_dir(f"{api_path}/{name}", os.path.join(local_path, name))

fetch_dir("cli/src", "src")
PYEOF

echo "Sync complete: $VERSION"
