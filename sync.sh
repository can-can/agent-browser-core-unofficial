#!/usr/bin/env bash
# sync.sh — pulls source files from vercel-labs/agent-browser for use as a library crate.
# Original work Copyright 2025 Vercel Inc., licensed under Apache-2.0.
set -euo pipefail

RAW="https://raw.githubusercontent.com/vercel-labs/agent-browser/main"
SRC="$RAW/cli/src"

fetch() { curl -fsSL "$1" -o "$2" && echo "  synced $2"; }

echo "Syncing from upstream vercel-labs/agent-browser..."

# Sync version from upstream Cargo.toml
VERSION=$(curl -fsSL "$RAW/cli/Cargo.toml" \
  | grep '^version' | head -1 | sed 's/version = "\(.*\)"/\1/')
sed -i.bak "s/^version = .*/version = \"$VERSION\"/" Cargo.toml && rm Cargo.toml.bak
echo "Version: $VERSION"

# build.rs (required for cdp_generated.rs codegen via OUT_DIR)
fetch "$RAW/cli/build.rs" "build.rs"

# cdp-protocol JSON files (consumed by build.rs)
mkdir -p cdp-protocol
fetch "$RAW/cli/cdp-protocol/browser_protocol.json" "cdp-protocol/browser_protocol.json"
fetch "$RAW/cli/cdp-protocol/js_protocol.json"      "cdp-protocol/js_protocol.json"

# Top-level src files (excludes main.rs, upgrade.rs which are CLI-only)
mkdir -p src
for f in color.rs commands.rs connection.rs flags.rs install.rs output.rs validation.rs test_utils.rs; do
  fetch "$SRC/$f" "src/$f"
done

# src/native/ top-level files
mkdir -p src/native
for f in actions.rs auth.rs browser.rs cookies.rs daemon.rs diff.rs e2e_tests.rs \
          element.rs inspect_server.rs interaction.rs mod.rs network.rs \
          parity_tests.rs policy.rs providers.rs recording.rs screenshot.rs \
          snapshot.rs state.rs storage.rs stream.rs tracing.rs; do
  fetch "$SRC/native/$f" "src/native/$f"
done

# src/native/cdp/
mkdir -p src/native/cdp
for f in chrome.rs client.rs discovery.rs lightpanda.rs mod.rs types.rs; do
  fetch "$SRC/native/cdp/$f" "src/native/cdp/$f"
done

# src/native/webdriver/
mkdir -p src/native/webdriver
for f in appium.rs backend.rs client.rs ios.rs mod.rs safari.rs types.rs; do
  fetch "$SRC/native/webdriver/$f" "src/native/webdriver/$f"
done

echo "Sync complete: $VERSION"
