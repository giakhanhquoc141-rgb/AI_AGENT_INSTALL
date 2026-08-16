# Architecture Review — Input Reconciliation (FR/NFR vs Spine)

- **Date:** 2026-08-15
- **Gate:** BMad Architecture reviewer gate
- **Lens:** Input reconciliation — do the load-bearing inputs (PRD FRs, cross-cutting NFRs, addendum findings) land in the spine?
- **Sources reviewed:**
  - `ARCHITECTURE-SPINE.md` (2026-08-15, status: draft)
  - `prd.md` (prd-AI_AGENT_INSTALL-2026-08-14)
  - `addendum.md` (prd-AI_AGENT_INSTALL-2026-08-14)

## Verdict: PASS WITH CONCERNS

The spine is a strong landing for this product: all 8 PRD feature areas (FR-1–FR-28) map to ADs, and the addendum's hardest pitfalls (Python Store-stub, portable-node `where` trap, Git installer self-elevation, `setx` truncation, PATH registry read-back, version-format map, "no version-math in pure batch") are all absorbed. **No FR is entirely ungoverned and nothing in the spine contradicts the addendum.** The concerns are three dropped/soft-landed requirements — retry-on-download, no-telemetry-as-invariant, and the no-console-flash autostart — plus two small unbound details.

---

## Coverage Matrix

| Input | Where it landed | Status |
| --- | --- | --- |
| FR-1 welcome/identity (logo, name, version) | AD-1/AD-11; `[init]` banner; Deferred "visual polish" | ✅ |
| FR-2 step nav, X/Y, **safe stop/cancel anytime** | AD-1 (phase order), AD-12 (idempotent re-run) — cancel contract implicit only | ⚠️ see F4 |
| FR-3 plan + Y/N before any change | AD-1 (plan+confirm phase); `[plan]` seed | ✅ |
| FR-4 Vietnamese / UTF-8 / no jargon | AD-11 | ✅ |
| FR-5 Store-stub + portable-node traps | AD-6 (explicit) | ✅ |
| FR-6 version-compare → INSTALL/SKIP/UPDATE | AD-6, AD-2 | ✅ |
| FR-7 never downgrade | AD-6, AD-12 | ✅ |
| FR-8 Node LTS 22/24, never Current | Stack table (FR-8); AD-6/AD-2 | ✅ |
| FR-9 official sources; failed download reported & isolated | AD-7 (report + isolation) | ⚠️ retry half missing, see F1 |
| FR-10 per-user, no UAC, no HKLM/ProgramFiles | AD-4 (zero UAC, SM-2) | ✅ |
| FR-11 Node per-user + PATH no-truncate | AD-4 (ZIP / `msiexec /a`), AD-10 (never `setx`) | ✅ |
| FR-12 Python silent `Include_launcher=0` | AD-4 | ✅ |
| FR-13 VSCode User Setup silent | AD-4 | ✅ |
| FR-14 Git per-user, MinGit default | AD-4 (MinGit), Deferred (full-installer alt) | ✅ |
| FR-15 npm globals + lifecycle-scripts policy | AD-2 (runtime), Deferred (npm 11.13–11.15 band) | ✅ |
| FR-16 Claude Code ext after PATH refresh | AD-10 general rule (FR-16 not in binds list — nit) | ✅ |
| FR-17 refresh-in-session | AD-10 (explicit) | ✅ |
| FR-18 `my-combo`, no duplicates | AD-12 | ✅ |
| FR-19 never touch API keys | AD-8 | ✅ |
| FR-20 autostart 9Router/OpenClaw; **no console flash** | AD-12 only; mechanism deferred [ASSUMPTION] | ⚠️ see F3 |
| FR-21 first-run config / onboarding, key in dashboard | AD-8, AD-11 | ✅ |
| FR-22 open dashboards | Conventions (fixed ports 20128/18789) | ✅ |
| FR-23 manifest at `%LOCALAPPDATA%\AITools` | AD-5 | ✅ |
| FR-24 uninstall by manifest, no overreach | AD-5, AD-10 | ⚠️ manifest/log cleanup unbound, see F5b |
| FR-25 self-update check from own repo | AD-7 | ✅ |
| FR-26 safe self-replace | AD-7, AD-12; `[self-update]` seed | ✅ |
| FR-27 local log, no data sent anywhere | AD-9; conventions/envelope "no telemetry" | ⚠️ convention-only, see F2 |
| FR-28 final report | AD-9, `[report]` seed | ✅ |
| NFR-SEC-1 official sources + no creds | AD-7, AD-8 | ✅ |
| NFR-SEC-2 no telemetry / no data collection | AD-7+AD-8 in map, but no rule text | ⚠️ see F2 |
| NFR-REL-1 **retry** + isolation + idempotent re-run | isolation=AD-7, re-run=AD-12; **retry = nowhere** | ❌ see F1 |
| NFR-REL-2 friendly errors, raw codes to log only | AD-9 | ✅ |
| NFR-COMP-1 Win10 1803+/Win11, UTF-8 | Stack table, AD-11 | ✅ |
| NFR-PERF-1 soft ~10–15 min | Absent from spine & frontmatter binds | ⚠️ see F5a |
| NFR-OBS-1 log sufficiency | AD-9 (binds list includes NFR-OBS-1; frontmatter omits it) | ⚠️ see F5a |

---

## Findings (ranked by severity)

### F1 — HIGH — NFR-REL-1 "tải có retry" (retry-on-download) is dropped from the spine

**Input:** PRD NFR-REL-1 first clause: *"Tải có retry"*; reinforced by UJ-1 edge case ("mạng chập… chạy lại là tiếp tục") and FR-9 ("Tải lỗi/gián đoạn được báo rõ").

**What landed / didn't:** AD-7 lands only half of NFR-REL-1 ("A failed/partial download is reported and must not corrupt other items"), and AD-12 lands the idempotent re-run. **Retry itself appears nowhere** — no AD, no structural-seed element, no convention. As written, a build that attempts each download exactly once and reports failure satisfies every invariant in the spine.

**Why it matters:** downloads are the dominant failure mode on this product's user base (non-technical, flaky consumer Wi-Fi; PRD acknowledges ~10% failing sessions, §4.8). Retry is the load-bearing reliability control — it is exactly the kind of soft constraint that drifts if no rule binds it.

**Fix:** Add a retry clause to AD-7: *"a failed or partial download is retried with bounded attempts before being reported; only after retries are exhausted does the step fail"* (binds NFR-REL-1). One sentence, restores the full NFR.

---

### F2 — MEDIUM-HIGH — NFR-SEC-2 (no-telemetry / only-declared network) is a stated convention, not an invariant

**Input:** NFR-SEC-2 *"Không telemetry; không thu thập dữ liệu ngoài log cục bộ"*; PRD §6 guardrail; FR-27 consequence *"không gửi dữ liệu đi đâu"*; SM-C2.

**What landed / didn't:** The capability map binds NFR-SEC-2 to AD-7 and AD-8, and the spine *states* "no telemetry, no remote state" twice (Consistency Conventions; Environment/operational envelope). But **no AD rule text forbids an undeclared outbound request**: AD-7 governs *download sources*, AD-8 governs *secrets* — neither prohibits a future step from phoning home with a heartbeat or usage count. A build could add telemetry and not violate any written rule, only a stated convention.

**Why it matters:** this is the product's core trust commitment (the PRD makes "no telemetry" a guardrail and a counter-metric). A convention-table entry is the weakest binding altitude for a constraint the whole product is positioned on.

**Fix:** Elevate to a rule — extend AD-8 (or add AD-13): *"the only outbound HTTPS requests the tool ever makes are the declared official-source fetches (AD-7) and the self-update check; nothing else, no telemetry, no remote state (NFR-SEC-2)."*

---

### F3 — MEDIUM — FR-20 "no console window flash on autostart" is unbound; addendum §3 pitfall dropped

**Input:** FR-20 consequence *"Không có cửa sổ console hiện ra gây khó chịu (wrapper ẩn khi cần)"*; addendum §3 explicitly flags that a `.cmd` target **will flash a console window** at login and prescribes a hidden wscript wrapper.

**What landed / didn't:** The spine binds §4.5 to AD-12 only and defers autostart to an `[ASSUMPTION]` ("OpenClaw autostart mechanism… verified at build"; 9Router Run-key primary / Startup-folder fallback). **Nothing binds the no-console-flash requirement** — a build registering a bare `9router.cmd` Run-key entry (the documented primary) satisfies every invariant and fails FR-20's testable consequence. The addendum's flash warning — a real, demoed pitfall — is lost between the spine and the build.

**Fix:** Bind FR-20 to AD-4 (autostart writes confined to HKCU scope) and record the hidden-wrapper / no-console-flash requirement as a required condition in the Deferred note (not optional "nếu gây khó chịu").

---

### F4 — LOW-MEDIUM — FR-2 "safe stop/cancel at any time" is only implicitly covered

**Input:** FR-2 testable consequence: *"Người dùng có thể dừng/hủy an toàn bất cứ lúc nào (dừng giữa chừng không làm hỏng máy)"* — a hard interaction requirement, and a §7 UX attribute.

**What landed / didn't:** AD-1 fixes phase order and AD-12's idempotency is the *mechanism* that makes interruption safe, but no invariant states the *contract* (the wizard must allow safe stop/cancel at any step; interruption leaves the machine re-runnable and reports state honestly). A build could present no cancel affordance and not violate any rule.

**Fix:** One line under AD-1 or AD-12: *"the wizard permits safe stop/cancel at any step; an interrupted run leaves the machine re-runnable (AD-12) and reports current state (AD-9)."*

---

### F5 — LOW — bookkeeping / small unbound details

**F5a — NFR bookkeeping:** Frontmatter `binds` lists "NFR-SEC-1/2, NFR-REL-1/2, NFR-COMP-1" but omits NFR-OBS-1 (which AD-9's binds list *does* include) and NFR-PERF-1 (bound nowhere). NFR-PERF-1 is soft, assumption A3, and counter-metric SM-C1 already guards "don't drop version-checks/retry to go faster" — so this is likely benign, but the omission isn't deliberate. Fix: either add a Deferred/perf note or drop NFR-PERF-1 from the claimed binds consistently.

**F5b — manifest/log cleanup on uninstall unbound:** addendum §7 states manifest + logs are wiped on uninstall ("được xóa sạch khi gỡ cài"); AD-5's uninstall rule covers recorded items and `AITools-` autostart entries but is silent on cleaning the tool's own `%LOCALAPPDATA%\AITools` manifest/log. Low risk (FR-24 consequence only says "manifest được cập nhật"), but the addendum's cleanup promise has no binding. Fix: one clause in AD-5.

**F5c — Python detection via `PythonCore` registry not in AD-6:** addendum §1/#1 (detect Python by registry `PythonCore` rather than `py -0p`, because this installer disables the `py` launcher) is a build-level detail AD-6's "Store-stub exclusion" loosely covers. Not a contradiction; no action required beyond noting it belongs in the version-check spec at build time.

---

## Things that landed well (no action)

- AD-4 is the strongest invariant in the spine — it upgrades FR-10–16 and the addendum Git elevation finding into a hard rule with the explicit "failure to route around, not to elevate" stance (SM-2).
- AD-10 correctly absorbs all PATH hazards: `reg add HKCU\Environment` not `setx`, in-session refresh (FR-17), and registry read-back of the just-written PATH (addendum §4 #9) — the exact trap the reconciliation lens looks for.
- AD-6 absorbs the "không bị đánh lừa bởi" traps (FR-5) verbatim, and the version-normalization map (addendum §1) including OpenClaw calendar-version string comparison.
- No contradiction found between spine and addendum on any verified mechanism (Node ZIP vs `msiexec /a`, Git MinGit vs full installer, npm `--allow-scripts`, autostart mechanisms, self-replace flow).
- All 8 feature areas and NFR-SEC-1, NFR-REL-2, NFR-COMP-1, NFR-OBS-1 land in ADs with matching rule text.
