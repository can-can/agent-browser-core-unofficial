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

# Use Python to recursively list src/ via GitHub API, then curl to download each file
python3 - <<'PYEOF'
import urllib.request, json, os, subprocess

API = "https://api.github.com/repos/vercel-labs/agent-browser/contents"
RAW = "https://raw.githubusercontent.com/vercel-labs/agent-browser/main"
EXCLUDE = {"main.rs", "upgrade.rs"}

def fetch_dir(api_path, local_path):
    req = urllib.request.Request(
        f"{API}/{api_path}",
        headers={"User-Agent": "sync-script"}
    )
    with urllib.request.urlopen(req) as r:
        items = json.load(r)
    os.makedirs(local_path, exist_ok=True)
    for item in items:
        name = item["name"]
        if item["type"] == "file":
            if api_path == "cli/src" and name in EXCLUDE:
                continue
            dest = os.path.join(local_path, name)
            subprocess.run(
                ["curl", "-fsSL", f"{RAW}/{api_path}/{name}", "-o", dest],
                check=True
            )
            print(f"  synced {dest}")
        elif item["type"] == "dir":
            fetch_dir(f"{api_path}/{name}", os.path.join(local_path, name))

fetch_dir("cli/src", "src")
PYEOF

echo "Sync complete: $VERSION"
