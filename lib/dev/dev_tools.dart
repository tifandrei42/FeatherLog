/// Whether to show the in-app developer-tools entry point (the flask icon on
/// Today that opens the dev menu / seeder).
///
/// Always gated behind `kDebugMode` at the call site, so release builds still
/// tree-shake the dev menu out regardless of this flag. This switch only exists
/// so the screenshot-capture harness can hide the dev button for clean
/// marketing captures (debug builds otherwise show it).
bool showDevTools = true;
