## Epic 1 adversarial findings (AI_Tools_Installer.bat)

1. **npm per-user check rejects valid npm on normal Windows paths** — lines 681, 690. PowerShell uses `StartsWith($u+'\\')` / `StartsWith($a+'\\')`; in a single-quoted PowerShell literal that is two backslashes, while `GetFullPath()` returns one. A normal `C:\Users\...\npm.cmd` fails the per-user guard and both npm installers abort. Use `Join-Path`/directory comparison or a single backslash literal and add a real-path test.

2. **Network scan failure does not stop execution** — lines 272–280, 193–197, 411–445. `scan_block` returns 1, but `run_install` still calls plan/execute; only missing `ST_*` sets `PLAN_ABORT`. With latest lookups unavailable, VS Code can still install from its latest URL and other components may mutate state after the UI says scan failed. Abort before plan/execute when `NET_ERR` is nonzero.

3. **Node replacement has no filesystem rollback** — lines 1230–1236, 1265–1278. Extraction deletes `%LOCALAPPDATA%\node` before moving the new tree. Any subsequent PATH write or node/npm verification failure leaves old Node gone and the new partial tree in place. Snapshot/move old tree to a transaction backup and restore on every post-replacement failure.

4. **Node manifest write failure is ignored** — lines 1244–1247. `call :manifest_append` is not followed by an error check, yet success is logged and installer exits 0. An unwritable/corrupt manifest makes uninstall unable to account for Node. Check errorlevel, rollback, and report failure.

5. **Node downloads are only size-checked** — lines 1218–1225. No SHA-256/signature validation for the ZIP; a compromised response can supply a valid-looking archive and arbitrary node/npm code. Pin and verify official checksum before extraction.

6. **Git ZIP is not cryptographically pinned** — lines 1093–1094. Checking git.exe version proves only embedded text, not provenance; a malicious archive can report requested version. Verify release checksum/signature before replacement.

7. **VS Code Authenticode verification is fail-open** — lines 820–823. If Get-AuthenticodeSignature is unavailable, script exits success and installs unsigned executable. Missing verification capability must fail closed (or use pinned SHA-256).

8. **Temporary Node stage is predictable/destructive** — lines 1219–1231. %TEMP%\node-stage-%VL_Node% is shared across concurrent runs and deleted without transaction ID/ownership check. A second run/process can delete/replace first run’s stage. Use GUID directory and refuse pre-existing paths.

9. **Global npm install is TOCTOU/unpinned** — lines 708–710, 735–736. Scan resolves a version, execution installs openclaw@latest and unversioned 9router; registry contents can change and displayed plan is no longer what is installed. Install exact scanned version and verify resulting package/version.

10. **npm lifecycle scripts are broadly trusted** — lines 703–710, 735–736. OpenClaw runs lifecycle scripts for npm <12 and 9Router has no script policy; a registry compromise gets arbitrary code execution. Require explicit allowlist/locked metadata and fail closed when policy cannot be enforced.

11. **npm PATH mutation is not rolled back** — lines 692–696, 701–729, 731–757. npm_prepare appends global bin to user PATH before package install. If install/verification/manifest fails, entry remains and may expose partial bin directory. Snapshot/restore PATH or commit only after successful install.

12. **npm verification can validate wrong executable** — lines 714–720, 741–748. Checks where openclaw/9router but never asserts first result is under NPM_BIN; stale/earlier PATH shim can satisfy check while new package is broken. Compare first where.exe result to expected bin path.

13. **Uninstall deletes entire shared install roots** — lines 1296 and allowed-path handling. Manifest ownership is only a path string; uninstall removes whole node, Git, Python313, or VS Code directories. Pre-existing/user-added files can be destroyed. Record ownership/backup state and remove only installer-owned artifacts.

14. **Uninstall leaves npm bin PATH entries behind** — line 1296 special-case OpenClaw/9Router. Branches remove package shims/modules and continue without adding manifest path to PATH-removal set. Fresh uninstall leaves %APPDATA%\npm (or NPM_BIN) in user PATH.

15. **Autostart configuration is not transactional and trusts PATH commands** — lines 517–535. 9Router Run key/manifest committed before openclaw gateway install; if latter fails registry entry remains. Start-Process openclaw.cmd resolves via PATH without checking it belongs to installed NPM_BIN. Commit after all steps and use verified absolute owned paths.

16. **Dashboard onboarding reports success for browser launch, not service readiness** — lines 546–555. start only confirms browser process launch, not endpoints listening. Report can mark onboarding success while services unavailable. Add bounded HTTP health checks.

17. **Manifest path canonicalization is incomplete** — lines 144–145. Only %LOCALAPPDATA% is canonicalized; %APPDATA%, %USERPROFILE%, symlink/casing forms remain raw. Uninstall exact comparisons can skip valid entries and PATH cleanup diverge. Canonicalize all environment variables/full paths at write time.

18. **PATH update can silently change registry type/content** — line 118. Existing REG_SZ PATH is expanded and rewritten REG_EXPAND_SZ; literal percent sequences/unresolved variables can change meaning. Preserve original kind/value semantics and broadcast WM_SETTINGCHANGE if new processes must see update.

