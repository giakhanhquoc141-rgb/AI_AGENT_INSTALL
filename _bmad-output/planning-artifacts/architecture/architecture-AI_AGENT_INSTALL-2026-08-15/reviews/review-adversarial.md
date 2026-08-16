# Adversarial Review — Divergence Hunting

- **Reviewer gate:** BMad Architecture reviewer — adversarial divergence hunting
- **Target:** `ARCHITECTURE-SPINE.md` (2026-08-15, draft, feature altitude)
- **Product:** AI Tools Installer — single-file `.bat` per-user wizard over a 7-item AI stack
- **Date:** 2026-08-15
- **Method:** For each shared-data shape, entity, and mutation path named by the spine, construct two units one level down that each obey every AD literally yet build incompatible products. A divergence pair that is closed by the existing ADs is fine; one that is not is a hole and earns a new or tightened AD. Also audited the Deferred section for latent divergence and each AD Rule for readings that two builders would resolve differently.

## Verdict

**PASS WITH CONCERNS** (borderline FAIL). The spine's core shape — mode router, single-file boundary, batch-orchestrates/PowerShell-computes runtime split, presentation boundary, manifest-as-source-of-truth — is sound and would keep epics from diverging on *flow*. But five shared-data shapes/entities have **no single owner or an ambiguous contract**, and each demonstrably produces two fully AD-compliant, mutually incompatible builds. Findings 1 and 2 will ship real user-visible defects (corrupted update decisions; uninstall residue) if not closed before epics start. All fixes are localized AD tightening; none require re-shaping the paradigm.

---

## Finding 1 — CRITICAL — The manifest `version` is owned by two units that define it differently (detection-normalized vs installed-record)

**The two units, both AD-compliant:**
- **Unit-Scan** builds the version-check + scan phase. It obeys AD-6: the version-check returns "exactly one of `INSTALL | SKIP | UPDATE` plus a **normalized** version string (per addendum §1 map: strip Node `v`, token 2 of `openclaw --version`, line 1 of `code --version`, etc.)." Here "version" means a *detection/compare-normalized* string.
- **Unit-Install** builds the execute blocks that record mutations. It obeys AD-5: "every machine mutation ... is recorded in manifest.txt (`item|version|installed-at`)." Here "version" means *the version I just installed*.

**The incompatibility:** both write to the same manifest `version` field, but AD-6 defines normalization for **reading an installed item** and AD-5 only says "version" — nothing says the recorded version is the AD-6-normalized form, nor which unit computes it.

Concrete case, OpenClaw: the seed table pins OpenClaw as npm `latest`, "calendar version, e.g. `2026.7.1-2`". Unit-Install records the npm package version it installed, `2026.7.1-2`. Unit-Scan, on the next run, runs `openclaw --version` and normalizes token 2 to `2026.7.1`. Two different strings for one installation, in the field the update-check reads to decide UPDATE vs SKIP. Semver ordering puts `2026.7.1-2` *below* `2026.7.1`, so the update-check (a third consumer) either never updates OpenClaw or, with a suffix-blind comparison, spuriously returns UPDATE — reinstalling over a current install and breaking AD-12/AD-6's never-downgrade guard.

Concrete case, Node ZIP (the Deferred-favored mechanism): the just-installed Node cannot be version-detected until the PATH refresh lands, so Unit-Install must record the **pinned download version**. Whether that is `24.5.0` or `v24.5.0` is unpinned; AD-6's normalizer strips the `v`. A builder that records `v24.5.0` produces a manifest the update-check cannot compare against its normalized `24.x` scan — a permanent spurious-UPDATE or permanent SKIP.

The AD-9 log `version` field inherits the same ambiguity (AD-9 says only "version"), so the log the user ships for support disagrees with the manifest and the plan table.

**Root cause:** one symbol, "version," with two meanings (detection-normalized vs installed-record) and no named owner of the canonical form. AD-6 defines detection; AD-5 and AD-9 reuse the symbol without inheriting the definition.

**Fix — tighten AD-5 (+ AD-9 + Consistency Conventions):** the `version` written to manifest and log is **exactly the AD-6-normalized string for that item**, produced by the single shared version-check helper — never raw command output, never a seed constant unless passed through the same normalizer. This requires the full per-item §1 normalization map to be **inlined into the spine** (currently it lives only in the PRD addendum source), so both builders normalize identically. Add one line: "manifest version and log version are the same normalized string the version-check returns for that item."

---

## Finding 2 — HIGH — Uninstall's removal predicate (`AITools-` prefix) cannot match the autostart artifacts the configure unit actually creates — the deferred OpenClaw mechanism is the trap

**The two units, both AD-compliant:**
- **Unit-Config** (first-config block, FR-20–22) registers autostart for 9Router and OpenClaw. It obeys AD-12 ("never duplicate an autostart registration") and the Deferred note: OpenClaw autostart via `openclaw gateway install` (official), 9Router via "Run key primary, Startup-folder `.lnk` fallback."
- **Unit-Uninstall** (FR-23–24) obeys AD-5 to the letter: "Uninstall removes only: items in the manifest, and autostart entries the tool created (prefixed `AITools-`)."

**The incompatibility:** `openclaw gateway install` creates an artifact under OpenClaw's own identity (a scheduled task / startup registration / Run entry the tool does not name and cannot force an `AITools-` prefix onto without departing from the official mechanism the spine itself selects). Unit-Uninstall filters for `AITools-*` only, so the OpenClaw gateway autostart **survives uninstall** — residue, exactly what AD-5's "prevent uninstall overreach" framing does not cover because the residue is the tool's own doing, not the user's.

The 9Router branch is the same disease one step earlier: the Deferred pins a *mechanism* (Run key primary, Startup `.lnk` fallback) but never the **Run value name or `.lnk` filename**. Unit-Config naturally registers `HKCU\...\Run\9Router`; Unit-Uninstall removes only `AITools-*`; the 9Router autostart also survives. If, instead, Unit-Config renames its artifacts to `AITools-9Router`, it has invented a contract AD-5 implies but never states — and a second builder of Unit-Config may pick the natural name instead, while Unit-Uninstall still filters on prefix. Either way the predicate ("prefixed `AITools-`") and the artifact identity are defined by different units with no link between them.

**Root cause:** AD-5 contracts what uninstall *may remove* but not what configure *creates*, and the exact identity of created autostart artifacts is deferred. Deferring the *mechanism* (scheduled task vs startup folder) is fine; deferring the *identity* of the artifact is a shared-data divergence.

**Fix — move out of Deferred into a tightened AD-5 (or new AD-13):** every autostart artifact the tool creates — by whatever mechanism — is **recorded in the manifest** (kind + exact artifact name + target); uninstall removes exactly the recorded set, and the prefix filter is replaced by manifest-driven removal. Pin 9Router's concrete artifacts as `AITools-9Router` (Run value and `.lnk`). The *exact Windows behavior* of `openclaw gateway install` may stay deferred; the **recording of whatever it creates** is now an invariant. The Deferred line "OpenClaw autostart mechanism ... verified at build" must be re-worded so the *record-the-artifact* contract is not deferred with it.

---

## Finding 3 — HIGH — The user PATH is one entity with N writers and no owner of the read-modify-write protocol

**The two units, both AD-compliant:**
- **Unit-Install-Git / Unit-Install-Node / Unit-Install-Python / Unit-Install-npm-globals** each mutate the user PATH. Each obeys AD-10: write via `reg add "HKCU\Environment" /v Path` (never `setx`, never direct `set PATH=`), refresh in-session before the next dependent step, read back from the registry.
- **Unit-Refresh** implements the "read back from the registry" half.

**The incompatibility:** AD-10 controls the *write channel* but not the *owner of the full PATH value*. Four install steps each do read → append → write, and two builders will diverge on:
1. **Append form.** The convention "local paths always `%LOCALAPPDATA%`-anchored" is ambiguous between literal (`%LOCALAPPDATA%\nodejs`) and expanded (`C:\Users\HP\AppData\Local\nodejs`). A later dedupe or compare assuming the other form misses → duplicate entries.
2. **REG type preservation.** User PATH is frequently `REG_EXPAND_SZ` (contains `%USERPROFILE%` references). `reg add ... /v Path /d <new>` with the default type silently rewrites it to `REG_SZ`, and every `%USERPROFILE%`-based entry stops expanding — the user's PATH is corrupted as a side effect of an install step, and dependent steps read a rotten PATH. AD-10 says nothing about `-t REG_EXPAND_SZ` (or preserving the existing value type).
3. **Ordering and dedup.** AD-12 forbids duplicate *autostart* registrations but says nothing about duplicate PATH entries; a re-run after a partial failure appends again (idempotency AD-12 is silent on PATH). Whether each entry is appended at the head or tail, and in which order across items, is unpinned.
4. **Refresh trigger.** "refreshed in-session after each PATH-mutating step before the next dependent step" does not say whether refresh is the tail of the mutating step or the head of the dependent step — two builders place it differently, and whichever reads PATH from the registry still works for resolution, but the divergence on *when* the refreshed value is captured feeds the run-state/log inconsistency in Finding 5.

**Root cause:** one entity (the user PATH) with multiple writers and a protocol (read-modify-write, type preservation, dedup, ordering) no single owner defines.

**Fix — tighten AD-10 into a single PATH-controller rule:** exactly one helper owns read (preserving `REG_EXPAND_SZ`) → tokenize → append-if-absent → write (preserving type). Install steps contribute a *declaration* of their entry in canonical form (`%LOCALAPPDATA%\...` — pick literal, state it) and never touch PATH themselves. The controller is the only refresh trigger and runs once after each item, before the next dependent step. Add: "PATH writes preserve the existing registry value type (`REG_EXPAND_SZ` kept); appended entries are canonicalized and appended-if-absent (AD-12)."

---

## Finding 4 — HIGH — Manifest schema is 60% specified: `installed-at` is date-or-path, and the item → removal-target map is owned by nobody

**The two units, both AD-compliant:**
- **Unit-Install** records mutations, obeying AD-5 (`item|version|installed-at`) and the Consistency Conventions ("dates `YYYY-MM-DD`; local paths always `%LOCALAPPDATA%`-anchored").
- **Unit-Uninstall** reads the manifest to know what to remove, obeying AD-5 ("uninstall removes only items in the manifest").

**The incompatibility:** the manifest's third field, `installed-at`, reads as a **date** to one builder and as an **installation path** to another — and uninstall needs a path, not a date.
- Unit-Install-1 writes `vscode|1.133.0|2026-08-15`. Unit-Uninstall-2, needing the removal target, reads field 3 as a path and tries to remove `2026-08-15` — a no-op or error.
- Even if both agree it is a date, the item → removal-target mapping (VSCode apps dir, MinGit root, the npm global prefix/package for OpenClaw and 9Router) is **derived, not recorded**, and pinned nowhere. Unit-Uninstall-3 derives `%LOCALAPPDATA%\Programs\Microsoft VS Code`; Unit-Uninstall-4 derives a different root, or derives a *command* (`npm uninstall -g openclaw`) where another derives a *folder to delete*. Both obey every AD.

Secondary contradiction inside AD-5 itself: "every machine mutation ... is recorded" cannot be satisfied by a one-line-per-item schema (it cannot hold PATH appends, folders created, or autostart artifacts), so the sentence and the schema force builders to resolve the gap differently — one writes one line per item and treats removal targets as implied (guessing, which AD-5's own "prevent destructive guessing" forbids), another stretches the schema to one line per mutation. Both are "obeying AD-5."

**Root cause:** the manifest is the load-bearing shared-data shape for uninstall, but its schema is 60% pinned and the removal-target derivation is implicit. This is the same hole the Deferred Node/Git mechanism choices flow into (below).

**Fix — tighten AD-5 to the exact schema and make uninstall 100% manifest-driven:** four fields — `item|version|installed-at-YYYY-MM-DD|path` — where `path` is the install root/identifier (VSCode apps dir, MinGit root, npm global name for OpenClaw/9Router). Pin a single item → removal-target map owned by Unit-Uninstall (or, better, record the target per-line so uninstall removes exactly the recorded `path` and nothing derived). Re-word AD-5's "every mutation is recorded" to match the schema, and state explicitly that the third field is a date, not a path.

---

## Finding 5 — MEDIUM — Run-state contract is a sentence, not a schema; and AD-12's "re-derives every decision" can give the plan and the execute phase two different owners of one decision

**The two units, both AD-compliant:**
- **Unit-Scan** writes per-item decisions+versions into run state (AD-6) and obeys "one in-memory run-state variable set per session" (Consistency Conventions).
- **Unit-Plan / Unit-Execute / Unit-Report** read run state (AD-1, AD-9).

**The incompatibility:** the spine pins a run-state *variable set* but no identifiers, no shapes, no writer. Batch has no type checker — a missing/renamed variable is silently empty. Unit-Scan writes `%DECISION_GIT%`; Unit-Execute reads `%ACTION_GIT%`; plan shows a plan that execute never honors, or execute treats an empty var as "no action" (skip) where scan meant INSTALL. Nothing catches it.

Compounding ambiguity in AD-12: "The plan phase re-derives every decision on each run rather than caching a prior plan." Read strictly, Unit-Plan re-runs the version-check during planning; read loosely, it consumes the scan-phase run-state. If Unit-Plan re-derives (strict) while Unit-Execute consumes the scan-phase value (AD-6's output), and the machine state changed between scan and plan (a PATH refresh from Finding 3 landed, a second process touched an install), the plan table can display a decision the execute phase does not act on — a within-run contradiction the spine does not forbid, because AD-12's "re-derives" never says *within run* vs *across runs*.

**Root cause:** the run-state contract is one prose line, and AD-12's re-derivation clause is ambiguous about scope.

**Fix — add to Consistency Conventions (or a new AD):** the run-state set is **written once by the scan phase and read-only thereafter**; pin identifiers and value domains (e.g., `AIT_<item>_DECISION ∈ {INSTALL,SKIP,UPDATE}`, `AIT_<item>_VER`, `AIT_RESULT_<item>`, `AIT_LAST_REFRESHED_PATH`); re-state AD-12's re-derivation as applying **across runs**, with the within-run plan/execute/report consuming the scan-phase values verbatim. This is the single cheapest fix per unit of divergence prevented.

---

## Deferred-section audit

| Deferred item | Verdict |
| --- | --- |
| **OpenClaw autostart mechanism** (+ 9Router Run/`.lnk` naming) | **MUST MOVE to an AD** — Finding 2. The *mechanism* may stay deferred; the *artifact identity + manifest recording* cannot, or uninstall and configure diverge. |
| **Node install mechanism — ZIP vs `msiexec /a`** | **Conditionally safe.** The choice changes the install layout, which flows into PATH entries (AD-10) and uninstall targets (AD-5). If Finding 4's item → layout map becomes an AD, the mechanism is a pure per-item detail and can stay deferred. Without that AD, deferring the mechanism leaks a shared-data divergence (install root) to two units. |
| **Git — MinGit vs full silent installer** | **Conditionally safe**, same reasoning: MinGit appends `<root>\cmd`, the full installer's PATH entry and uninstall target differ. Safe only if Finding 4's map AD lands. |
| **npm `--allow-scripts` policy band (11.13–11.15)** | **Safe as deferred.** Build-time verification of a flag's behavior; no cross-unit shared data. |
| **Console visual polish** | **Safe as deferred.** Confined by the AD-1 presentation boundary. |
| **Log-collection UX for support** | **Safe as deferred.** A report-block decision; only touches AD-9's boundary, already owned. |
| **Support channel / v2 scope** | **Safe as deferred.** Process/product decisions, no unit divergence. |

---

## Ambiguous AD Rules (readings two builders would resolve differently)

1. **AD-6 "token 2 of `openclaw --version`"** — tokenization (whitespace-delimited? multiline output? first line vs last?) is not defined in the spine; the full §1 map lives only in the addendum *source* document. AD-5, AD-6, and AD-9 all depend on the same normalized string, so the map must be **inlined into the spine** as the single authoritative copy. Secondary severity only because the addendum is listed in `sources` and a builder *may* read it.
2. **AD-5 "recorded"** — "every machine mutation is recorded" vs a schema that holds one line per item (Finding 4). Needs re-wording to match the schema.
3. **AD-12 "re-derives every decision"** — within-run vs across-run scope (Finding 5). Needs an explicit scope.
4. **AD-3 "No additional shipped files at any altitude"** — does a runtime *temporary* file (e.g., a temp `.ps1` for a long PowerShell block) violate the single-file rule? Two builders would read it differently, but each produces a self-consistent artifact, so this is a lower-severity clarification (one line), not a divergence hole.
5. **AD-9 `step` field** — phase-level records vs item-level records ("welcome shown" vs `git|ok|...`); minor, but one line in AD-9 saying `step` is the item id (or phase id for non-item steps) closes it.

---

## Consolidated AD change list (what to close before epics start)

1. **Tighten AD-5 (+ AD-9 + Conventions):** manifest/log `version` = the AD-6-normalized string, produced by the single shared version-check helper; inline the §1 normalization map into the spine. *(Finding 1)*
2. **New/tightened AD (AD-13 or AD-5):** every autostart artifact is manifest-recorded (kind + exact name + target); uninstall removes the recorded set, not a prefix guess; move the OpenClaw/9Router autostart identity out of Deferred. *(Finding 2)*
3. **Tighten AD-10:** single PATH controller owns read (preserving `REG_EXPAND_SZ`) → append-if-absent → write (preserving type); install steps declare entries, never write PATH; canonical entry form pinned; controller is the only refresh trigger. *(Finding 3)*
4. **Tighten AD-5:** exact four-field manifest schema with `installed-at-YYYY-MM-DD` and `path`; uninstall is 100% manifest-driven; re-word "every mutation is recorded." *(Finding 4)*
5. **Add to Conventions/new AD:** run-state variable set pinned with identifiers + value domains; single writer (scan); AD-12 re-derivation scoped to across-runs. *(Finding 5)*
