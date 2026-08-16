# Architecture Review — Good-Spine Checklist (Rubric Walker)

- **Date:** 2026-08-15
- **Gate:** BMad Architecture reviewer gate
- **Lens:** good-spine checklist (rubric walker)
- **Document judged:** `ARCHITECTURE-SPINE.md` (2026-08-15, status: draft)
- **Cross-checked against:** `prd.md`, `addendum.md` (prd-AI_AGENT_INSTALL-2026-08-14); repo contents (greenfield check)

## Verdict: PASS WITH CONCERNS

This is a good spine by the checklist's standards: it fixes the divergence points that would otherwise break two independent builders (presentation ownership, step contract, decision model, mutation recording, PATH, language), it ratifies a genuinely greenfield starting point, and it is the only draft so far that has explicitly owned the operational/environmental envelope — closing the PRD review's D-1 trust/signing gap in the spine itself. The concerns are real but none is critical: the pipeline-level failure policy is ungoverned, execute-phase item ordering is unpinned, one Deferred item (OpenClaw autostart) breaks the removal contract AD-5 relies on, and the browser-launch/onboarding channel sits outside the presentation boundary with no owner. Each has a one-line fix. None of the 12 ADs is unenforceable; AD-4, AD-5, AD-6, AD-9, AD-10 are exemplary.

---

## Checklist walk

### 1. Fixes the real divergence points for the level below, and misses none — mostly, with 3 misses

The spine correctly names its load-bearing shape: the **presentation boundary**, because the wizard epic and the install/uninstall epic are the two independent builders below this altitude, and console-output ownership is exactly where they would diverge. AD-1 (router + fixed phase order), AD-9 (step contract: exit codes, log line, Vietnamese failure message), AD-11 (language/encoding), AD-6 (decision enum + normalization), AD-5 (mutation record), AD-10 (PATH), AD-4 (no-admin gate) each prevents a divergence a builder could otherwise invent. This is a genuinely high-coverage set.

Misses (each a divergence point two builders could resolve differently):

- **Pipeline-level failure policy** — AD-9 defines the *per-step* contract but nothing states what happens at the *pipeline* level when a step fails: abort-the-run vs record-and-continue. The PRD implies continue ("không làm hỏng các mục khác" FR-9, "X/Y thành công" FR-28), but the spine never makes it a rule. A wizard-epic step that returns nonzero and an install-epic step can disagree on whether the session stops there. See **R-1**.
- **Execute-phase item ordering** — AD-1 pins phase order but not item order inside `[execute]`. Node must precede the npm items (OpenClaw, 9Router) and the Claude Code extension needs VSCode + refreshed PATH; AD-10 covers the PATH freshness mechanism but not the topological order. Two independently built execute blocks can assume incompatible ordering. See **R-2**.
- **External-UI / browser-launch channel** — the presentation boundary (AD-1) governs *console* prints only. FR-21/FR-22 launch 9Router's dashboard (`localhost:20128`) and the OpenClaw UI in a browser and guide the user through external screens. That is a second interaction channel with no owner and no rule, sitting outside the only boundary that fixes console divergence. See **R-4**.

### 2. Every AD's Rule is enforceable and actually prevents its stated divergence — yes, with one structural hole

Walked all 12. Each Rule is a checkable property (a reviewer can verify "URLs point at official domains," "no `setx`," "writes confined to `%LOCALAPPDATA%`/HKCU/user PATH," "no English user-facing strings," "one log line per step," etc.), and each prevents the divergence it names. No Rule is theater.

The one hole is **AD-5**: its removal contract is keyed to items in the manifest *and* autostart entries "prefixed `AITools-`". But the OpenClaw autostart the tool creates comes from `openclaw gateway install`, which (per addendum §3) may register a Scheduled Task with a name the tool does not control and that will **not** carry the `AITools-` prefix. As written, uninstall would leave that registration behind — precisely the "destructive guessing" failure AD-5 exists to prevent, now in the reverse direction (under-removal). This is a checklist-2/3 intersection: the AD is enforceable, but it does not fully prevent the stated divergence for the OpenClaw case until either the autostart identity is recorded in the manifest or uninstall is bound to `openclaw gateway uninstall`. See **R-3**.

### 3. Nothing under Deferred could let two units diverge — one item can

Deferred is otherwise safe: Node ZIP vs `msiexec /a` (both AD-4-compliant, path recorded in manifest so uninstall is mechanism-agnostic), npm `--allow-scripts` band (single owner), console polish and log-gathering UX (contained by the presentation boundary / single report block), support channel and v2 (process/out-of-scope). Two notes:

- **OpenClaw autostart mechanism (deferred)** is the divergence: it interacts with AD-5's removal contract (see R-3). Because AD-5 promises "only autostart entries the tool created (prefixed `AITools-`)", the *removal* rule is fixed while the *creation* mechanism is deferred — the two units (configure block creates, uninstall block removes) cannot agree until the mechanism is known. The safe state is to move the removal side into the manifest contract rather than leave it implied.
- **Git full-installer branch (deferred)** — "only for accounts verified standard" — requires an admin/standard detection that no AD pins; if the detection is wrong on an admin account the full installer self-elevates and violates AD-4. AD-4's "must not be implemented — route around" stance is the backstop, so this is acceptable, but the branch deserves one line recording that elevation-detection is part of the deferred verification. Low.

### 4. Named tech is verified-current — pass

Every runtime tool (cmd, PowerShell 5.1, curl/tar, certutil, reg) and every installed stack item is pinned with a date (verified 2026-08-15) and is internally consistent with the addendum's verified findings: Node LTS 22.x/24.x and never Current 26.x (OpenClaw engine range), Python 3.13.9 (3.14 deprecation noted), VSCode 1.133.0, MinGit 2.55.0.4-64-bit, OpenClaw 2026.7.1-2 (calendar-version string compare), 9Router 0.5.50, `anthropic.claude-code` marketplace-managed. No contradiction with the addendum found on any named mechanism. Note that these are authoring-date pins by design; runtime freshness is owned by AD-6's version-check (correct placement).

### 5. Ratifies rather than contradicts a brownfield codebase — pass (greenfield)

No `.bat` or any code exists in the repo (only BMad skill/config commit; untracked `_bmad-output/`). The spine's single-file rule, runtime split, and scaffold-level structural seed ratify that greenfield starting point without inventing a false legacy. Nothing contradicts the repo.

### 6. If a spec/PRD drove it, it covers that spec's capabilities — strong, with one dropped requirement

All 8 PRD feature areas and FR-1–FR-28 map to ADs with matching rule text; the addendum's hardest pitfalls (Store-stub, portable-node `where` trap, Git self-elevation, `setx` truncation, registry read-back, version-format map, "no version-math in batch") are absorbed into AD-4/6/7/10. FR-15's npm lifecycle-scripts band and FR-20's autostart mechanism are honestly deferred with a build-time verification — acceptable for build-detail. Two bookkeeping notes: **retry** (NFR-REL-1's first clause, "Tải có retry") lands nowhere — AD-7 gets isolation and reporting but not retry (agreeing with reconcile F1); and NFR-OBS-1 is in AD-9's binds but omitted from frontmatter `binds`, NFR-PERF-1 bound nowhere (soft, benign). Frontmatter bookkeeping should be tidied.

### 7. Parent spine inheritance — N/A

No parent spine is inherited (`companions: []`); no new AD weakens an inherited one.

### 8. Every owned dimension decided, deferred, or an open question — pass overall, with the strongest envelope this product has seen; two silent corners

The "Environment / operational envelope" section is exactly the paragraph checklist item 8 is looking for: no deployed infrastructure, local-only mutation, outbound-only HTTPS to official sources and the tool's own repo, no telemetry, no inbound services, GitHub-release distribution with the unsigned-`.bat` + SHA256 SmartScreen posture, local-log observability. This closes the PRD review's D-1 (trust/signing) as a *spine* decision rather than leaving it to build. Dashboard/gateway ports are pinned in Consistency Conventions (20128, 18789). Two silent corners remain:

- **x64-only is an assumption, not a gate.** Every installer path and stack entry is `-x64` (Node `win-x64`, VSCode `win32-x64`, Git `-64-bit`), and the PRD's platform clause says "Windows 10 (1803+)/11" without an architecture qualifier. The spine never states that the tool's supported environment is 64-bit Windows — a builder on a 32-bit host would silently fail all seven installs. One line in the envelope or AD-4's scope.
- **certutil (SHA256 verify) is listed in the runtime stack but no AD binds its use.** Either a rule requires verifying installer payloads against a pinned checksum (a strengthening of AD-7), or the stack entry is decoration that implies a control nobody owns. Currently a build may skip verification entirely and violate nothing.

---

## Findings (ranked by severity)

### R-1 — MEDIUM — Pipeline-level failure policy is ungoverned (abort vs record-and-continue)

**Issue:** AD-9 fixes the per-step contract but no invariant says what the *pipeline* does when a step fails. The PRD's flow (FR-9 "không làm hỏng các mục khác", FR-28 "X/Y thành công") implies continue-and-report, but the spine never states it. A wizard-epic step and an install-epic step can implement different session-level behavior — abort on first failure vs isolate, report, continue — with both satisfying every AD.

**Fix:** One line under AD-1 or AD-12: *"a failed step is recorded (AD-9) and reported; the pipeline continues to the next item; the run ends with a report of failed items, and a re-run re-attempts only outstanding work (AD-12)."* (Checklist 1.)

### R-2 — MEDIUM — Execute-phase item ordering / dependency chain is not pinned

**Issue:** AD-1 fixes phase order; it does not fix item order inside `[execute]`. Node must precede the npm globals (OpenClaw, 9Router), and the Claude Code extension requires VSCode and a refreshed PATH. Two independently built install blocks can assume incompatible ordering and both be "following the spine."

**Fix:** Pin a topological order as part of AD-1 (phase-internal order): `git → node → python → vscode → claude-code ext → openclaw/9router` (or state the dependency rule: *"npm-based items and the VSCode extension run after their runtime dependencies and after PATH refresh (AD-10)"*). (Checklist 1.)

### R-3 — MEDIUM — Deferred OpenClaw autostart breaks AD-5's removal contract

**Issue:** AD-5's uninstall rule removes "only… autostart entries the tool created (prefixed `AITools-`)." The OpenClaw autostart is created by `openclaw gateway install`, which may register a Scheduled Task with a tool-unknown name — no `AITools-` prefix. Uninstall as specified would leave it running at login, failing FR-24's "xóa các đăng ký autostart do tool tạo" and reopening the under-removal half of AD-5's stated divergence. This is a checklist-2/3 intersection: the deferred creation mechanism and the fixed removal rule cannot both hold until they agree.

**Fix:** Extend AD-5 to cover whatever the OpenClaw mechanism creates — either record the created autostart identity (task name / shortcut path) in the manifest at configure time, or bind uninstall to `openclaw gateway uninstall`. Move the OpenClaw-autostart verification out of a build-time `[ASSUMPTION]` and into a named removal contract. (Checklist 3.)

### R-4 — MEDIUM-LOW — The browser-launch / external-UI onboarding channel is outside every boundary

**Issue:** AD-1's presentation boundary owns console output, but FR-21/FR-22's onboarding runs in an *external browser* (9Router dashboard, OpenClaw UI) that the tool launches. Nothing governs who owns that channel, what strings appear around it, or how the tool hands off to it — a step could print raw English browser text, bypass the boundary, or diverge between the wizard and configure blocks. The reconcile review already flags the related S-1-style gap in the PRD; the spine inherits it.

**Fix:** Extend AD-1 (or AD-9) with one clause: *"launching external UI (9Router dashboard, OpenClaw UI) is a governed channel: the tool opens it at the fixed endpoints and all accompanying guidance is Vietnamese, non-technical (AD-11)."* (Checklist 1/8.)

### R-5 — LOW — "No telemetry" is a convention, not an invariant

**Issue:** The spine states no-telemetry twice (Consistency Conventions; environment envelope), and the capability map binds NFR-SEC-2 to AD-7/AD-8 — but **no AD rule text** forbids an undeclared outbound request. AD-7 governs download sources, AD-8 governs secrets; neither prohibits a future step from phoning home. A build could add a heartbeat or usage count and violate no written rule. (This matches reconcile F2; confirming from the rubric lens — the envelope is the right home, it just lacks rule force.)

**Fix:** Elevate to a rule — extend AD-8: *"the only outbound HTTPS the tool ever makes are the declared official-source fetches (AD-7) and the self-update check; nothing else, no telemetry, no remote state (NFR-SEC-2)."* (Checklist 8.)

### R-6 — LOW — Silent environmental corner: x64-only assumption; certutil listed but unbound

**Issue (a):** All seven install paths are `-x64`, but neither the spine nor the PRD platform clause restricts the supported environment to 64-bit Windows. On a 32-bit host every install silently fails. **Issue (b):** `certutil.exe (SHA256 verify)` is listed in the runtime stack, but no AD binds when/how downloads are verified — a control advertised with no owner.

**Fix:** (a) One line in the envelope / AD-4 scope: *"supported environment is 64-bit Windows 10 (1803+)/11"* (and optionally an init-block gate). (b) Either add to AD-7 *"downloaded installer payloads are SHA256-verified before execution"* or drop certutil from the stack. (Checklist 8/4.)

---

## Tail (roll-up, not ranked)

- **Retry** (NFR-REL-1 first clause) is dropped from AD-7 — agrees with reconcile F1; add a bounded-retry clause to AD-7.
- **Frontmatter `binds` bookkeeping:** NFR-OBS-1 is bound by AD-9 but omitted from frontmatter; NFR-PERF-1 bound nowhere (soft, benign). Tidy or drop.
- **FR-2 safe stop/cancel** is only implicitly covered (AD-12 is the mechanism, not the contract) — agrees with reconcile F4; one line under AD-1/AD-12.
- **Self-update replace mechanics** (A7 rename dance) are deferred to the addendum with no AD beyond AD-7/AD-12 — low risk, single owner; note only.
- **Git full-installer branch** requires admin/standard detection no AD pins; AD-4's route-around stance is the backstop — acceptable, add one line at build verification.

## Things that landed well (no action)

- **AD-4** is the strongest invariant: it converts the addendum's Git self-elevation finding into a hard, checkable rule with the correct stance ("failure to route around, not to elevate"), binding SM-2.
- **AD-10** absorbs every PATH hazard (`reg add HKCU\Environment` not `setx`, in-session refresh FR-17, registry read-back) — exactly the trap family a divergence lens hunts for.
- **AD-6** carries the version-format map and both FR-5 traps (Store-stub, portable-node) verbatim.
- **Operational/environmental envelope** is explicitly owned — the PRD's D-1 trust/signing risk is decided in-spine (unsigned + SHA256 + SmartScreen guidance), not deferred to build.
- **Deferred** is otherwise safe: every entry names why it can wait, and the two mechanism choices (Node, Git) both stay inside AD-4's invariant.
- No contradiction found between the spine and the addendum on any verified mechanism, and no AD is unenforceable or theatrical.
