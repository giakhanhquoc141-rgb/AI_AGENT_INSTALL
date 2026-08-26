---
title: 'Cài OpenClaw và 9Router qua npm'
type: 'feature'
created: '2026-08-26'
baseline_commit: '8f96b36ca417d9269f9b9576cb7f9ee89edaa943'
status: 'in-progress'
review_loop_iteration: 0
context: ['_bmad-output/implementation-artifacts/epic-1-context.md']
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** OpenClaw và 9Router hiện chỉ ghi `not-supported-yet`, nên sau khi Node đã cài người dùng vẫn chưa có gateway hoặc dashboard AI.

**Approach:** Dùng npm của Node per-user đã refresh PATH để cài `openclaw@latest` và `9router` global từ npm registry, xử lý lifecycle-script policy của npm mới, rồi verify version trong phiên và console mới.

## Boundaries & Constraints

**Always:** Node/npm phải được resolve từ PATH sau story 1.4; nguồn npm registry chính thức; OpenClaw chạy `npm install -g openclaw@latest --allow-scripts openclaw` hoặc flag tương đương được kiểm chứng theo npm version; 9Router `npm install -g 9router`; retry tối đa 3 cho mỗi package; cài per-user, không UAC/Program Files/HKLM; từng package độc lập, lỗi package này không chặn package kia; refresh PATH sau npm global bin; verify `openclaw --version`/`9router --version` trực tiếp và qua PATH; manifest chỉ ghi sau verify; đúng một log kết quả mỗi package; không đọc/ghi API key.

**Ask First:** npm không hỗ trợ flag lifecycle an toàn, Node/npm resolve ngoài per-user target, hoặc npm global prefix nằm ngoài `%LOCALAPPDATA%`/user scope.

**Never:** Không dùng installer ngoài npm, `setx`, UAC, system-wide prefix, telemetry, API key, dashboard configuration, combo creation hoặc autostart (story 1.9–1.10).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| OpenClaw | Node/npm ready, package absent/outdated | npm global install with lifecycle policy; version command works | Retry 3, one fail log, continue 9Router |
| 9Router | Node/npm ready | npm global install; version command works | Retry 3, one fail log |
| npm unavailable | PATH stale or Node missing | No package mutation | Vietnamese error, continue next item |
| lifecycle blocked | npm rejects scripts policy | Do not silently bypass; use approved compatible flag only | Fail with action guidance |
| rerun | package already current | Decision SKIP, no duplicate install | One skip log |

</frozen-after-approval>

## Code Map

- `AI_Tools_Installer.bat:367` — execute order; Node/Python/VSCode must precede npm items.
- `AI_Tools_Installer.bat:447` — OpenClaw stub to replace with dispatcher/installer.
- `AI_Tools_Installer.bat:450` — 9Router stub to replace with dispatcher/installer.
- `AI_Tools_Installer.bat:98` — shared PATH controller; npm global bin must be refreshed through it or equivalent session-safe logic.
- `AI_Tools_Installer.bat:124` — manifest helper for successful package records.
- `AI_Tools_Installer.bat:193` — scan already supplies `ST/VR/VL_OpenClaw` and `ST/VR/VL_9Router`; execute must consume state without re-scan.

## Tasks & Acceptance

**Execution:**
- [x] `AI_Tools_Installer.bat` — replace OpenClaw/9Router stubs with independent npm dispatchers, bounded retry, lifecycle-policy handling, PATH refresh and verification.
- [x] `AI_Tools_Installer.bat` — write manifest/log only after each package succeeds; preserve per-user/no-key boundaries.
- [x] `_bmad-output/scratch/` — add isolated harness for npm commands/flags, retry, skip, continuation and no-key checks without package mutation.

**Acceptance Criteria:**
- Given Node/npm ready, when execute runs, then both commands work from a new console and no UAC appears.
- Given OpenClaw lifecycle scripts are blocked by npm policy, when install runs, then the approved policy flag allows only OpenClaw scripts and does not silently weaken safety.
- Given one package fails, when execute continues, then the other package is still attempted and logs remain independent.

## Spec Change Log

## Design Notes

Use `npm.cmd` explicitly to avoid a Windows shim ambiguity. Determine npm global bin with `npm prefix -g`/`npm bin -g` using the current npm, validate it is user-scoped, then prepend it to the current session PATH without changing system scope. Verify package versions from the resolved per-user commands.

## Verification

**Commands:**
- `cmd /d /c "echo HH| AI_Tools_Installer.bat"` — expected: cancellation, no install log.
- Harness isolated — expected: flags/prefix/retry/skip/continuation/no-key checks PASS.
- `git diff --check` — expected: clean.

**Manual checks:**
- Disposable user: npm global prefix under user scope; both packages run from fresh `cmd.exe`; no API-key reads/writes.
