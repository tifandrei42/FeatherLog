# Fetches the web SQLite assets drift needs at runtime into web/ (Windows dev).
#
# These are third-party library artifacts (not our source), so they are NOT
# committed. Run this once before `flutter run -d chrome` / `flutter build web`.
# Versions are pinned to match pubspec.lock (drift / sqlite3).
$ErrorActionPreference = 'Stop'

$driftVersion = '2.33.0'
$sqlite3Version = '3.3.2'

$root = Split-Path -Parent $PSScriptRoot
$web = Join-Path $root 'web'

Write-Host "Fetching drift_worker.js (drift $driftVersion)…"
Invoke-WebRequest -UseBasicParsing `
  -Uri "https://github.com/simolus3/drift/releases/download/drift-$driftVersion/drift_worker.js" `
  -OutFile (Join-Path $web 'drift_worker.js')

Write-Host "Fetching sqlite3.wasm (sqlite3 $sqlite3Version)…"
Invoke-WebRequest -UseBasicParsing `
  -Uri "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$sqlite3Version/sqlite3.wasm" `
  -OutFile (Join-Path $web 'sqlite3.wasm')

Write-Host 'Done. web/drift_worker.js and web/sqlite3.wasm are ready.'
