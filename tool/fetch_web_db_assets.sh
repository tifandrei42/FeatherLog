#!/usr/bin/env bash
# Fetches the web SQLite assets drift needs at runtime into web/.
#
# These are third-party library artifacts (not our source), so they are NOT
# committed — they're downloaded here for local web runs and in the Docker
# build. Versions are pinned to match pubspec.lock (drift / sqlite3).
set -euo pipefail

DRIFT_VERSION="2.33.0"
SQLITE3_VERSION="3.3.2"

cd "$(dirname "$0")/.."

echo "Fetching drift_worker.js (drift $DRIFT_VERSION)…"
curl -fsSL -o web/drift_worker.js \
  "https://github.com/simolus3/drift/releases/download/drift-${DRIFT_VERSION}/drift_worker.js"

echo "Fetching sqlite3.wasm (sqlite3 $SQLITE3_VERSION)…"
curl -fsSL -o web/sqlite3.wasm \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${SQLITE3_VERSION}/sqlite3.wasm"

echo "Done. web/drift_worker.js and web/sqlite3.wasm are ready."
