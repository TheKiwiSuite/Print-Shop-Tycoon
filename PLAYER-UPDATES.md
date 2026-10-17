# Player updates

The current built-in flow is **Settings → Game updates + save backups**, or **F10 → Help → Check for updates**, starting in version 0.3.2. It supports verified download, save backup, explicit restart, atomic replacement and startup rollback. Read [UPDATING.md](UPDATING.md) for player instructions, recovery and security boundaries.

Players on 0.3.0 or earlier need one manual official ZIP download to obtain an updater. Close the game, extract the new version, run `windows/Print Shop Tycoon.exe` and choose Continue. AppData progress is separate from the extracted folder. Do not delete `%APPDATA%/PrintShopTycoonNative` or start a new shop to load an existing career.

Version 0.3.1 introduced a separate-folder PowerShell updater. It remains available under **Help → Separate-folder updater (fallback)** and as `windows/Update-Game.ps1`. It prepares a verified version folder and save backup without replacing the old installation or launching downloaded software. Open the prepared executable manually and adjust the old shortcut if needed. If Windows policy blocks this fallback, use the manual ZIP method; do not disable security settings.

All flows preserve local saves and the official alpha is unsigned. Only the in-game flow in 0.3.2 adds automatic startup confirmation and executable rollback; a fallback/manual rollback after a newer save-schema change requires restoring the corresponding pre-update profile backup first.
