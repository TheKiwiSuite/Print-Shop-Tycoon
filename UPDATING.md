# Updating Print Shop Tycoon

## Players with 0.3.0 or earlier

Those builds cannot gain an updater remotely. Download 0.3.2 or newer once from the official release page, close the old game normally, extract the full ZIP to a writable folder, and open `windows/Print Shop Tycoon.exe`. Choose **Continue**. Do not create a new shop to load existing progress.

Player saves live separately in `%APPDATA%/PrintShopTycoonNative`, not in the extracted game folder. Keep this folder when replacing or moving the game. A manual backup is a copy of that whole folder. Old shortcuts may still point to the old extracted folder; update the shortcut target or extract to the previous location while the game is closed.

## Built-in update flow from 0.3.2

Open **Settings → Game updates + save backups**. Choose **Check for updates**, then **Download verified update**. When ready, choose **Save, back up + restart to install**. Updates never start in the background without these actions.

The game saves first and copies JSON saves, fallback backups, archived shops and preferences into a unique `updates/<operation>/saves` folder under AppData. The current game must close before installation. An isolated copy of the existing executable performs the update without administrator access. The new game opens at its title screen; Continue resumes the saved production state.

The installer retains `Print Shop Tycoon.rollback-<operation>.exe` alongside the normal executable. If the new process does not acknowledge startup and validate an existing save, the helper closes only the process it started and restores the previous executable. Windows locks or permissions can block replacement or rollback; the retained executable and AppData backup remain available for manual recovery. Update logs and result messages are in the operation folder. Backups are not automatically deleted.

## Security boundary

- Only the fixed `TheKiwiSuite/Print-Shop-Tycoon` GitHub repository and `vX.Y.Z-windows-alpha` release channel are eligible. Versions compare numerically; equal/older versions, drafts, invalid filenames, unsupported URLs and missing GitHub SHA-256 digests are rejected.
- HTTPS certificate verification stays enabled. Download length and SHA-256 must match GitHub's release-asset API record. The isolated helper fetches that record again before installing and verifies the archive again. A checksum sidecar, release-body link or downloaded installer script cannot authorize an update.
- Only the canonical embedded-PCK Windows executable is read from the ZIP; archive directory paths are never extracted. ZIP downloads and executable payloads have size limits. The installed executable must still match the original hash.
- Windows' built-in .NET `File.Replace` performs replacement with a retained backup. The helper uses a fixed, locally bundled command with literal escaped paths through the system PowerShell executable. It does not change execution policy, elevate, install dependencies, run downloaded scripts or create a service.
- At least 600 MB of free space and a writable extracted game folder are required. Failed downloads never replace the current application. Saves are never sent to GitHub.

This trusts the official GitHub repository, GitHub's HTTPS infrastructure and the Windows trust store. It is not an independently signed update manifest or Authenticode publisher signature; the alpha remains unsigned. Repository takeover or compromise of the player's own Windows account is outside the digest guarantee. Publisher signing requires a separate release-signing setup.

## Release checks

`updater_security` rejects malformed metadata, downgrade attempts, external URLs, bad size/hash, and unsafe archive paths; verifies exact save backups; and runs on Linux. The actual exported Windows executable additionally exercises atomic replacement, failed replacement without losing the old file, rollback, literal paths containing quotes/metacharacters, and startup confirmation in an isolated copy. The normal five-route Windows save/reload walkthrough remains a release gate. These are automated component and executable checks; they do not certify every antivirus, Windows policy, interrupted power state or future save-schema migration.
