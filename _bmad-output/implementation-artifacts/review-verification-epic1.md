# Epic 1 — Verification-gap review

## Verification-gap findings

### 1. Combo harness does not verify the primary model in the API payload

- **Location:** `AI_Tools_Installer.bat:489`
- **Trigger condition:** The combo code stores `COMBO_VERSION=deepseek-v4-flash`, but the JSON sent to 9Router contains only `name` and `models`; the harness passes merely because the string appears somewhere in the batch file.
- **Missing guard:** Mock the `GET`/`POST`/`PUT` combo API and assert the emitted JSON has `name == my-combo`, the primary model field/value `deepseek-v4-flash`, and the three fallbacks in order; then assert the second run performs no duplicate create.
- **Potential consequence:** A payload can omit or misname the primary model while `story-1-9-combo-harness.ps1` still reports PASS, so 9Router may create an unusable or incorrectly configured combo.
- **Gap shape:** `broken-verification-gap`
- **Consumer:** The local 9Router combo API called by `:configure_9router_combo` (`AI_Tools_Installer.bat:489`).
- **Evidence:** `story-1-9-combo-harness.ps1` checks `COMBO_VERSION=deepseek-v4-flash`, endpoint/method strings, and fallback literals, but never executes the PowerShell request or inspects a request body (`_bmad-output/scratch/story-1-9-combo-harness.ps1:6-19`).

### 2. npm retry and continuation claims are simulations, not tests of the installer path

- **Location:** `_bmad-output/scratch/story-1-8-npm-harness.ps1:21-34`
- **Trigger condition:** The harness’s retry loop and “9Router still attempted after OpenClaw failure” assertions operate on local booleans and counters unrelated to `:npm_install_openclaw` / `:npm_install_9router`.
- **Missing guard:** Run the actual installer subroutines against fake `npm.cmd`, `openclaw`, and `9router` executables that fail on selected attempts; assert exactly three attempts, independent continuation, verification, manifest/log results, and the user-scoped prefix.
- **Potential consequence:** Retry bounds or continuation can regress in the batch code while the harness continues to pass because its simulation is independent of that code.
- **Gap shape:** `broken-verification-gap`
- **Consumer:** The npm execution pipeline (`AI_Tools_Installer.bat:699-776`) and the final report’s per-item result state.
- **Evidence:** The harness only regex-checks source text and then increments `$attempts` in a standalone `1..3 | ForEach-Object`; no npm or installer path is invoked (`story-1-8-npm-harness.ps1:5-19,21-34`).

### 3. Autostart/onboarding harness does not observe browser launch or onboarding behavior

- **Location:** `_bmad-output/scratch/story-1-10-autostart-harness.ps1:5-24`
- **Trigger condition:** The harness checks that URL strings and `Start-Process -WindowStyle Hidden` occur in the configure block, but never runs `:configure_onboarding`, checks both `start` calls, or verifies failure handling when a browser cannot be opened.
- **Missing guard:** Execute the onboarding block with a controlled browser launcher (or a stubbed `start`) and assert both exact URLs are attempted, a launch failure returns nonzero and logs one failure line, and no API-key value is read or persisted.
- **Potential consequence:** A missing/altered browser launch, wrong URL, or broken error path can ship while the harness still reports PASS; the acceptance criterion “opens both dashboards and guides setup” remains unproven.
- **Gap shape:** `broken-verification-gap`
- **Consumer:** `:configure_onboarding` and the user’s first-run browser setup (`AI_Tools_Installer.bat:546-557`).
- **Evidence:** The harness only uses `.Contains(...)` checks over source text (`story-1-10-autostart-harness.ps1:8-22`); it does not invoke the batch block or inspect process/browser side effects.

### 4. Story 1.11 harness checks report text but not report correctness under failures

- **Location:** `_bmad-output/scratch/story-1-11-logging-report-harness.ps1:12-28`
- **Trigger condition:** The harness asserts that `report_block` contains `X/Y`, `6/6`, a log path, and one `log_append` call, but never executes it with mixed `RESULT_*` states or checks the resulting log line schema/count across the whole run.
- **Missing guard:** Invoke `:report_block` with success, failure, and unset result variables; assert exact X/Y counts, failed-item names, status, and one well-formed `step | status | version | path | timestamp` line per completed step.
- **Potential consequence:** The report can claim success for an unset result (the batch treats every value other than `fail` as success at `AI_Tools_Installer.bat:565-570`) or miscount failed items without this harness failing.
- **Gap shape:** `broken-verification-gap`
- **Consumer:** The final report shown to users and the report log line (`AI_Tools_Installer.bat:559-585`).
- **Evidence:** `story-1-11-logging-report-harness.ps1` reads substrings and regex-matches them; it performs no invocation or output parsing (`:12-28`).

### 5. Core Epic 1 paths have no executable harness found in the repository

- **Location:** `AI_Tools_Installer.bat:205-228,322-410,593-644,1055-1279`
- **Trigger condition:** The repository has isolated harnesses for stories 1.8–1.11 plus Python/VS Code checks, but no harness invoking or asserting the welcome wizard, Y/N plan gate, Node installer, or Git installer paths.
- **Missing guard:** Add isolated tests for the concrete entry paths that simulate key input and fake downloads/tools, asserting the 11-line welcome/UTF-8 contract, no mutation before confirmation, Node PATH/version verification, Git MinGit target/PATH, retry/failure continuation, and manifest/log outcomes.
- **Potential consequence:** Regressions in these acceptance-critical paths can pass the available verification set entirely; a missing confirmation gate or broken Node/Git install would not be detected.
- **Gap shape:** `regression-gap`
- **Consumer:** The normal install router (`:run_install`) and its welcome/plan/Node/Git consumers (`AI_Tools_Installer.bat:186-200`).
- **Evidence:** A whole-repository filename/symbol search found no story-1-1/1-2/1-3/1-4/1-5 harness; existing scripts inspected were `story-1-8` through `story-1-11`, `test-python-installer.ps1`, `test-vscode-installer.ps1`, and `unit.ps1`.

### 6. VS Code failure-continuation check is currently brittle and does not run green

- **Location:** `_bmad-output/scratch/test-vscode-installer.ps1:17-21`
- **Trigger condition:** The harness requires the exact text `call :try_install_vscode` followed by a non-parenthesized `if errorlevel 1 set ...`; the production code uses the equivalent parenthesized form, so the harness fails before completing its checks.
- **Missing guard:** Assert behavior (or normalize the batch AST/text enough to accept equivalent syntax), then execute the continuation path with a fake VS Code installer failure and assert Claude Code is still attempted and failure is recorded.
- **Potential consequence:** Verification is blocked or may be “fixed” by weakening/removing the assertion; the acceptance criterion that a VS Code failure does not prevent the extension attempt is not currently protected by a passing test.
- **Gap shape:** `broken-verification-gap`
- **Consumer:** Execute ordering/continuation in `:execute_block` (`AI_Tools_Installer.bat:431-443`).
- **Evidence:** Running the harness produced PASS for earlier checks but failed at `failure continuation`; the mismatch is between the regex at `test-vscode-installer.ps1:17` and the parenthesized production branch at `AI_Tools_Installer.bat:433-435`.
