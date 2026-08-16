# Epic 1 Context: Cài đặt AI tools trong một lần chạy

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Deliver the core install/update flow: a single self-contained `.bat` that, in one run on Windows 10/11, walks a non-technical user through a Vietnamese console wizard, scans for the 7-item AI stack (Git, Node.js, Python, VSCode + Claude Code extension, OpenClaw, 9Router), compares each against official latest, installs everything per-user without admin, creates the 9Router `my-combo`, guides first-run config, registers autostart with Windows, logs locally, and reports a final summary. One file run — "now you have AI", with no terminal knowledge, admin, or manual setup.

## Stories

- Story 1.1: Tool init & welcome wizard
- Story 1.2: Scan & version decision for the 7 items
- Story 1.3: Install plan + Y/N confirmation
- Story 1.4: Per-user Node install + in-session PATH refresh
- Story 1.5: Per-user Git (MinGit)
- Story 1.6: Silent per-user Python
- Story 1.7: VSCode User Setup + Claude Code extension
- Story 1.8: OpenClaw + 9Router via npm
- Story 1.9: Create `my-combo`, never touch API keys
- Story 1.10: First-run config — autostart + onboarding + dashboard
- Story 1.11: Local logging + final report

## Requirements & Constraints

- All user-facing text Vietnamese under UTF-8 (`chcp 65001`); no English or jargon shown to end users.
- Per-user / no-admin is a hard gate: all writes confined to `%LOCALAPPDATA%`, HKCU, and user PATH; zero UAC prompts, zero `%ProgramFiles%`/HKLM writes, whole session. Target is 64-bit Windows 10/11. A step that would need admin is routed around, never elevated.
- Downloads only from each item's official source, with bounded retry (3 attempts); a failed/partial download is reported and must not affect other items.
- Each of the 7 items resolves to exactly one of `INSTALL/SKIP/UPDATE` vs official latest; never downgrade.
- Node installs only LTS 22.x/24.x (OpenClaw engine range `>=22.22.3 <23 || >=24.15 <25 || >=25.9`); never Current 26.x.
- Never read/write/store/transmit API keys; keys are entered by the user in the 9Router dashboard only. No telemetry; only declared official fetches.
- Nothing mutates the machine before the user confirms the plan; cancel safely at any step (safe because steps are idempotent and nothing commits pre-confirm).
- Every step exits 0/nonzero, appends exactly one log line, and on failure shows a Vietnamese non-technical message (what happened + next action); raw codes go to the log only.
- Every machine mutation is recorded in the manifest; every autostart artifact is recorded by kind + exact name + target so uninstall can remove exactly it later.

## Technical Decisions

- Hybrid runtime: batch (`cmd.exe`) orchestrates the pipeline, sequencing, and console UI; inline PowerShell 5.1 (in-box) owns all network, JSON parsing, and version comparison. No version math in pure batch.
- Single-file rule: one self-contained `.bat` with all helpers, PS blocks, UI, manifest, and update logic inlined — no sidecar files.
- Phased pipeline with mode router: fixed order welcome → scan → plan+confirm → execute → configure → report. Execute order is topological: Node before npm items (OpenClaw, 9Router), VSCode before the Claude Code extension. Uninstall/self-update router branches are "not yet supported" stubs in this epic.
- Per-item install: Node = official `win-x64` ZIP to `%LOCALAPPDATA%\node`; Git = MinGit ZIP to `%LOCALAPPDATA%\Programs\Git`, PATH entry `<dir>\cmd` (never the full installer — it auto-elevates on admin accounts); Python = official 3.13.x silent `InstallAllUsers=0 PrependPath=1 Include_launcher=0 Shortcuts=0` to `%LOCALAPPDATA%\Programs\Python\Python313`; VSCode = User Setup silent `/VERYSILENT /NORESTART /MERGETASKS=!runcode` to `%LOCALAPPDATA%\Programs\Microsoft VS Code`, then `code.cmd --install-extension anthropic.claude-code --force` after PATH refresh; OpenClaw/9Router = `npm install -g openclaw@latest --allow-scripts openclaw` and `npm install -g 9router` (npm 12 blocks lifecycle scripts by default, so `--allow-scripts openclaw` is required).
- Detection & versions: one shared version-check helper is the only producer of normalized version strings — plan, manifest, and log all record exactly its output. Exclude the Python Store-stub (`WindowsApps`) and OpenClaw's portable node on PATH from "installed". Official latest sources: `nodejs.org/dist/index.json` (first LTS entry), python.org downloads API (name like `Python 3.13*`, non-prerelease, newest by date), GitHub latest release for VSCode and Git, npm dist-tags for openclaw/9router. Normalization: Node strips `v`; Python/9Router clean semver; VSCode line 1 of `code --version`; OpenClaw token 2 (calendar version — string compare); Git takes `X.Y.Z.windows.P` tail.
- PATH discipline: one controller does read → append-if-absent → write, preserving `REG_EXPAND_SZ` via `reg add HKCU\Environment`; never `setx` (truncates >1024 chars); refresh in-session from the registry (not captured console env) after each PATH-mutating step before dependent steps.
- Run-state (per-item decisions) written once by scan/decide, read-only afterwards within a run; every run re-scans and re-decides.
- Combo: create exactly one 9Router `my-combo` — model `deepseek-v4-flash`, fallbacks `oc/deepseek-v4-flash-free` → `openrouter/deepseek-v4-flash` → `ds/deepseek-v4-flash`; never duplicate.
- Autostart: 9Router via HKCU Run key → `9router.cmd --no-browser --skip-update` (Startup-folder `.lnk` fallback); OpenClaw via official mechanism (`openclaw gateway install`). Each artifact recorded by kind + exact name + target.
- Fixed endpoints: 9Router `localhost:20128`, OpenClaw gateway `127.0.0.1:18789`.
- Manifest `%LOCALAPPDATA%\AITools\manifest.txt` lines `item | version | installed-at-YYYY-MM-DD | path`; log `%LOCALAPPDATA%\AITools\logs\ai-tools-installer.log`, one line per step.
- Single-file block layout (fixed order): init, helpers, router, scan, plan, execute, configure, uninstall, self-update, report. Dependency direction: presentation → pipeline → helpers → (official sources | manifest | logs). Only presentation prints/launches the browser; only pipeline steps mutate machine/manifest; helpers never print or mutate.

## UX & Interaction Patterns

- Console wizard: ASCII logo (11 lines, orange `38;5;214` + bold white + gray slogan), Vietnamese encouraging tone, minimal emoji, every step announces what it is doing.
- All navigation via single keys; every screen shows step X/Y, what it does, and how many remain; safe cancel any time.
- A failed step renders "✗" + plain-Vietnamese description + suggested next action (no raw codes on screen).
- Plan screen lists all 7 items as install/skip/update with versions, confirmed Y/N; no machine change before confirmation.
- First-run config drives the user through the browser: opens the 9Router dashboard and OpenClaw UI, guides entering the API key in the dashboard, completes OpenClaw onboarding — the user never types commands.
- Final screen always shows X/Y succeeded, failed items (if any), and the log location.

## Cross-Story Dependencies

- Fixed pipeline order: scan (1.2) → plan (1.3) → execute (1.4–1.8) → configure (1.9–1.10) → report (1.11); each phase consumes the prior one's output.
- Node install + in-session PATH refresh (1.4) must land before npm installs (1.8) and the VSCode extension install (1.7).
- The shared version-check helper (1.2) feeds the plan table (1.3) and the manifest/log lines (1.11).
- Manifest-recording built into install/configure stories (1.4–1.10) is the contract Epic 3's uninstall depends on; the log framework (1.11) is reused by Epics 2 and 3.
- The router skeleton in 1.1 leaves uninstall/self-update branches as stubs for Epics 2 and 3.
- Autostart artifacts recorded in 1.10 must match exactly what Epic 3's uninstall removes (kind + exact name + target).
