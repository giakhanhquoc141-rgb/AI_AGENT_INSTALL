# PRD Quality Review — AI Tools Installer

## Overall verdict

This is a strong, unusually decision-honest PRD: every one of the 28 FRs carries a testable consequence, the load-bearing technical claims (no-admin Git, Node ZIP, Python silent, version-format handling) are verified in the addendum, and trade-offs are named rather than smoothed over (MinGit vs full Git installer, no-telemetry, ZIP vs `msiexec /a`). What's at risk is external-to-code reality, not spec quality: the delivery mechanism (an unsigned `.bat` over GitHub) that will meet SmartScreen/Defender/Mark-of-the-Web head-on for exactly the non-technical persona the PRD targets, and an OpenClaw first-run path (addendum defers `openclaw onboard --install-daemon` to manual) that quietly threatens the "không cần biết dòng lệnh" promise in §1. Both are fixable in text today and both gate the core value proposition, so they should be resolved before this feeds Architecture/Stories.

## Decision-readiness — strong

The PRD states decisions as decisions, not "considerations." The Git mechanism is a real call with its trade-off named — §12/A9: *"dùng **MinGit** (per-user chắc chắn, không admin/UAC) làm mặc định; bộ cài full silent chỉ đảm bảo per-user trên tài khoản standard"* — including the empirical finding that the full installer self-elevates on admin accounts. Node LTS-in-OpenClaw-range over Current (FR-8/A1), no-telemetry (SM-C2, NFR-SEC-2), and the 7-item stack (Git added per user request, §0) are all decisions with the rejected alternative visible. Counter-metrics SM-C1/C2 exist and are not decoration — they name what is deliberately *not* optimized. Open Questions are genuinely open: OQ-1 (support channel), OQ-4 (rollback), OQ-5 (log gathering UX) have no answer smuggled in the next sentence.

The one decision the PRD fails to make or even surface is the distribution/trust story — see finding D-1.

### Findings
- **[high]** D-1. Trust/signing risk for the delivery mechanism is never surfaced (§4.7/FR-25–26, §6 "Bảo mật", UJ-1 path step 1) — The PRD's whole security posture is "Chỉ tải từ nguồn chính thức; chạy không cần admin (giảm bề mặt tấn công)", but the product is delivered as an *unsigned* `.bat` fetched from GitHub that downloads and executes installers, writes `HKCU\Environment`, and runs `Invoke-RestMethod`. Nothing in the PRD or addendum mentions Windows SmartScreen ("Windows protected your PC"), Mark-of-the-Web, or Defender behavior — which is precisely the first screen a non-technical office worker will hit, contradicting the §2.1 emotional JTBD *"không sợ 'cài nhầm thứ gì đó'"*. This can block adoption of the entire product, so a decision-maker approving it today is blind to a potentially blocking risk. *Fix:* add a Trust/distribution NFR (code signing, or a documented unblock-MoTW step, or a named trusted-distribution path) and a consequence on FR-25/26 that the downloaded update is handled with an explicit trust decision.

## Substance over theater — strong

Nothing reads as furniture. Personas are load-bearing, not decorative: Lan drives UJ-1 and UJ-2, Tuấn drives UJ-3, and the Non-Users section (§2.2) does real scoping work (advanced dev, fleet IT, no-network excluded). NFRs carry product-specific thresholds rather than boilerplate: NFR-COMP-1 pins "Windows 10 (1803+)" and UTF-8; NFR-PERF-1 commits to "~10–15 phút tùy tốc độ mạng"; NFR-REL-1 is concrete (retry, per-item isolation, idempotent). The Vision (§1) could not be swapped into another PRD — it names the 7 items, `my-combo`, no-admin, per-user. Even §7 (aesthetic) is earned, not theater: for a wizard aimed at non-technical users, the ASCII logo dimensions, ANSI color `38;5;214`, and the specific anti-reference ("màn hình dày đặc biệt ngữ") are load-bearing. No findings.

## Strategic coherence — strong

There is a real thesis — a single `.bat` that turns a fresh Windows box into a working AI environment for people who won't touch a terminal — and the feature set (§4.1–4.8) is a unified arc toward it: wizard → detection → no-admin install → combo → first-run config → uninstall → self-update. Prioritization follows the thesis (no-admin and wizard-first are the bet, not the easy parts). Success Metrics validate the thesis rather than measure activity: SM-1 (completion without support), SM-2 (zero UAC), SM-3 (correct version decisions), SM-5 (clean uninstall) are quality measures with validating counter-metrics. MVP scope kind (problem-solving for office workers) matches the scope logic in §9.

Two coherence gaps sit where the arc meets the user:

### Findings
- **[high]** S-1. OpenClaw first-run cannot actually deliver the §1 promise as specified (§1, §4.5/FR-20, addendum §2) — §1 bets everything on *"không cần biết dòng lệnh"*, and UJ-1 path step 6 has the wizard lead Lan into OpenClaw's first-run setup. But addendum §2 states *"Setup lần đầu **deferred**: `openclaw onboard --install-daemon` (chạy thủ công sau, không trong silent install)"* — and no FR covers performing that onboarding inside the wizard. FR-20 only *registers* autostart ("cơ chế autostart chính thức của gateway", [ASSUMPTION A2]); it never explains how a non-technical user gets the daemon/gateway actually initialized without opening a terminal, or whether the OpenClaw web UI path alone is sufficient. As written, the two statements are in tension and the resolution is left to build. *Fix:* add an FR (or extend FR-20) specifying the wizard's OpenClaw onboarding path — UI-driven daemon setup or a guided action — so the no-terminal promise is verifiable, not assumed.
- **[medium]** S-2. SM-4 and FR-18 depend on external free-tier availability that the PRD does not flag (§10/SM-4, §4.4/FR-18) — SM-4 ("combo `my-combo` có ≥1 kết nối hoạt động") is an acceptance-level metric, but its first fallback tier `oc/deepseek-v4-flash-free` is subject to churn. The addendum (§4) admits *"OpenCode Free có thể bị churn (một số free-tier của 9Router đã ngừng trong 2026)"* — the PRD should surface this as a risk next to SM-4 and state the fallback posture (what happens to the metric if the free tier dies), so the metric isn't silently impossible. *Fix:* add a one-line risk note on SM-4 or [ASSUMPTION] and state the acceptance when free tiers are discontinued.

## Done-ness clarity — strong

This is the strongest dimension. Every FR has a "Consequences (testable)" block, and the consequences are genuinely verifiable rather than adjectives. FR-6 enumerates the per-item version format (Node `v` prefix, VSCode line 1 of `code --version`, OpenClaw date-style `2026.7.1-2`, Git `git version 2.x.windows.1`, Python/9Router clean). FR-5 names the exact traps (Python Store-stub in WindowsApps, portable node of OpenClaw on PATH). FR-11, FR-13, FR-15, FR-16 carry concrete paths, flags (`/VERYSILENT /NORESTART /MERGETASKS=!runcode`, `--allow-scripts openclaw`), and exit-code checks. NFRs use bounds, not adjectives. Downstream story creation can source-extract directly.

Two small soft spots:

### Findings
- **[low]** D-2. Manifest and log locations are never pinned (§4.6/FR-23, §4.8/FR-27) — Both say "tại vị trí ổn định" and UJ-1's climax literally reads *"log tại …"* with an ellipsis. Neither the PRD nor the addendum states the actual path (`%LOCALAPPDATA%\...\manifest.json`, log dir). Since the manifest is load-bearing for uninstall (FR-24) and the log path for support (OQ-5), the location should be named now rather than invented in Architecture. *Fix:* state the concrete locations in FR-23/FR-27 and keep them identical in Glossary.
- **[low]** D-3. FR-21's first consequence is not testable by the tool (§4.5/FR-21) — "Người dùng hoàn tất ≥1 kết nối hoạt động trong dashboard sau khi được hướng dẫn" depends on user behavior and external service availability; it's a guidance-effectiveness measure, not a tool outcome. Acceptable as an intent, but pair it with a tool-side check (e.g., gateway reachable on `http://localhost:20128`) so done is objectively observable.

## Scope honesty — strong

Non-Goals (§8) and Out-of-Scope (§9.2) do real work, and there is a `[NOTE FOR PM]` at the one genuine tension (offline/portable for machines "không cho mạng", §9.2). De-scoping is explicit (telemetry rejected *because* log-only is the measurement stance; fleet automation excluded while single-machine IT uninstall stays in via UJ-3). Open-item density is appropriate for a draft feeding downstream: 6 OQs + 9 assumptions, most of which the verified addendum already collapses to a short verification list (A2/A6/A9, OQ-3/OQ-6).

### Findings
- **[low]** O-1. OQ-4 is a product-scope decision wearing a technical hat (§11/OQ-4, §2.3/UJ-2) — "có chế độ quay về bản cũ không?" is a user-facing capability call (rollback: feature or not), yet it is deferred to build ("để build quyết định với log"). It is honestly flagged, so this is a nudge, not a defect: mark it `[NOTE FOR PM]` so it is resolved by product before Stories, since it changes UJ-2's resolution either way.

## Downstream usability — strong

The PRD is chain-top (feeds UX → Architecture → Stories) and is built for that: Glossary (§3) defines every domain noun and the terms are used identically across FRs/UJs/SM definitions; FR-8, FR-20, FR-11 cite the addendum for the "how" while staying at capability level. IDs are contiguous and unique — FR-1..28, UJ-1..3, NFR-SEC/REL/COMP/PERF/OBS, SM-1..5 + SM-C1/C2, OQ-1..6, A1..9 — with no gaps or duplicates. Each UJ has a named protagonist carrying context inline (Lan, Tuấn); no floating UJs. The verified addendum (version map, silent commands, autostart, pitfalls) makes this unusually extractable. Mechanical issues only (see below).

## Shape fit — strong

The shape matches the product. This is a UX-bearing tool for non-technical end users (consumer-adjacent), so UJs with named protagonists are appropriate and present — not over-formalized for a "single .bat". The internal mechanics are spec'd at capability level with the verified addendum holding the implementation detail, which is the right split. SMs mix user-facing and operational measures appropriately. The one forced-shape smell would be a thin "Vision theater" — it isn't; §1 is specific. No findings.

## Mechanical notes

- **Broken cross-ref:** UJ-2's edge case says *"mở, xem OQ-5"* (§2.3) but the rollback question it references is **OQ-4** (§11); OQ-5 is about log-gathering UX. Fix the pointer.
- **Assumptions Index roundtrip:** A8 appears only in the index (§12, marked "toàn văn") with no inline `[ASSUMPTION A8]` anywhere in the body — the one inline/index mismatch. Acceptable for a global assumption, but either tag it inline at a natural point (e.g., §4.3) or label it as global-only.
- **ID continuity:** clean — no gaps, no duplicates, all cross-refs resolve except the UJ-2→OQ-5 one above.
- **Glossary drift:** none material. The intentional "9Router" (product) vs "9router" (npm package) case distinction is consistent throughout; glossary defines "Combo", "Manifest", "Khởi động cùng Windows", "Cập nhật ngầm" and they're used as defined.
- **Required sections:** all present for a chain-top draft (Vision, Target User, Glossary, Features, NFRs, Constraints, Aesthetic, Non-Goals, MVP Scope, SMs, OQs, Assumptions).
