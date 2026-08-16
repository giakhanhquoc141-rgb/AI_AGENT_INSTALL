# Verification Review — AI Tools Installer Architecture Spine

- **Reviewer gate:** Architecture reviewer — lens: **verification**
- **Date of review:** 2026-08-15 (live spot-checks run same day)
- **Review target:** `_bmad-output/planning-artifacts/architecture/architecture-AI_AGENT_INSTALL-2026-08-15/ARCHITECTURE-SPINE.md`
- **Authoritative reality-check:** `_bmad-output/planning-artifacts/prds/prd-AI_AGENT_INSTALL-2026-08-14/addendum.md`
- **Verdict:** **PASS WITH CONCERNS**

---

## Scope & method

Verification lens = every committed decision in the spine must trace to the addendum, the existing project, or a web-reality check — not training data. I read the spine and addendum in full, then live spot-checked the spine's current-ness claims against the same official sources the addendum claims to have used (npm registry, nodejs.org, python.org, GitHub API), plus Microsoft's own curl/tar documentation. WebSearch was non-functional in this environment (returned empty result blocks); I used direct HTTP GETs and page fetches instead.

## Verification log (live results, 2026-08-15)

| Spine claim | Checked against | Result |
| --- | --- | --- |
| Node Current is 26.x | `nodejs.org/dist/index.json` | CONFIRMED — `v26.7.0` (2026-08-05) is index [0], `lts:false`. Matches addendum §1. |
| "LTS 22.x/24.x", never Current | same feed | CONFIRMED — latest LTS is `v24.19.0` (`lts:"Krypton"`, 2026-08-03); Node 22 line still in maintenance. OpenClaw engines `>=24.15.0 <25` satisfied by 24.19.0. |
| Node ZIP URL shape `win-x64` (not `-x64`) | `index.json` files array | CONFIRMED — asset is `win-x64-zip` (`node-v24.19.0-win-x64.zip`). Addendum §2's `-x64.zip`-404 warning is correct. |
| OpenClaw `latest` = calendar version 2026.7.1-2 | `registry.npmjs.org/-/package/openclaw/dist-tags` | CONFIRMED — `latest: 2026.7.1-2`; also `alpha 2026.5.19-alpha.1`, `beta 2026.8.1-beta.1`, `extended-stable 2026.6.34`. Calendar (non-semver) versioning confirmed. |
| OpenClaw engine range | `registry.npmjs.org/openclaw/2026.7.1-2` `engines` | CONFIRMED — `">=22.22.3 <23 || >=24.15.0 <25 || >=25.9.0"`. Matches addendum §2 (addendum wrote `>=24.15`; actual `>=24.15.0` — notational only). |
| 9Router `latest` | `registry.npmjs.org/-/package/9router/dist-tags` | CONFIRMED WITH NOTE — `latest: 0.5.55`. Addendum's `0.5.50` was the observed *installed* version on the reference machine; latest has already moved. Spine correctly labels `0.5.50 at authoring` and the design fetches `latest` at runtime — right call, moving target is expected. |
| Git latest 2.55.0.windows.4 | `api.github.com/repos/git-for-windows/git/releases/latest` | CONFIRMED — `tag_name: v2.55.0.windows.4`. |
| MinGit zip naming | GitHub release `v2.55.0.windows.4` assets | CONFIRMED — asset `MinGit-2.55.0.4-64-bit.zip` exists (also 32-bit, arm64, busybox variants). `cmd\git.exe` layout is the documented MinGit convention. |
| VS Code latest stable 1.133.0 | `api.github.com/repos/microsoft/vscode/releases/latest` | CONFIRMED — `tag_name: 1.133.0`. (Addendum also notes the GitHub release has no binary assets → `update.code.visualstudio.com` is the right download source; User Setup URL shape `.../latest/win32-x64-user/stable` matches the official update feed convention.) |
| Python 3.13.9 full installer | `python.org/ftp/python/3.13.9/python-3.13.9-amd64.exe` | CONFIRMED — installer exists at that path; 3.13.x full-installer pin is valid today. |
| Python 3.14 "deprecates full installer" | CPython 3.14 `Doc/whatsnew/3.14.rst`, `python.org/downloads/windows/`, `python.org/downloads/release/python-3140/` | **NOT CORROBORATED** — see F2. No mention of full-installer deprecation or the Python Install Manager in any of the three primary sources checked. |
| curl.exe/tar.exe in-box since 17063 → 1803 | Microsoft DevBlogs "Tar and Curl Come to Windows!" | CONFIRMED — verbatim: "Windows 10 Insider build 17063 and later now include the real-deal curl and tar executables that you can execute directly from Cmd or PowerShell." GA in 1803 is the standard accompanying fact. |
| PowerShell 5.1, certutil.exe, reg.exe in-box | Microsoft-documented, trivially true on Win10/Win11 | CONFIRMED — 5.1 ships with every supported Windows 10/11; certutil/reg are legacy in-box. Not worth deeper checking (per review brief). Note: the addendum's silent-install snippets use `reg add`/`reg query` throughout, so reg.exe usage is exercised. |
| Tool's own self-update repo | `api.github.com/repos/giakhanhquoc141-rgb/AI_AGENT_INSTALL` + `/releases/latest` | CONFIRMED repo exists; **repo has no releases yet** — `releases/latest` returns 404. See F4. |
| 9Router port 20128, OpenClaw gateway 127.0.0.1:18789 | addendum §1/§2 | CONFIRMED — both stated in addendum; internally consistent. |

## Findings (ranked by severity)

### F1 — MEDIUM — Stack header misattributes verification coverage to the addendum
The spine's tool-runtime table is introduced as "*Verified 2026-08-15 (addendum + Microsoft).*" But the addendum never covers the in-box runtime row at all: it contains **no** mention of curl.exe, tar.exe, certutil, reg.exe, or the "PowerShell 5.1 in-box" / "Win10 1803+" claims. Only Microsoft documents those, and no Microsoft citation is recorded anywhere in the spine or addendum. The factual claims are all **true** (I re-confirmed 17063 against Microsoft's own post), so this is a sourcing-integrity defect, not a factual error — but the stated verification source does not contain the verified claim.
**Fix:** reword to "*Verified 2026-08-15 — addendum for stack items; in-box runtime per Microsoft (DevBlogs 'Tar and Curl Come to Windows!', build 17063)*", and pin that URL in the spine's `sources:` frontmatter. Smallest possible edit that makes the citation honest.

### F2 — MEDIUM — "3.14 deprecates full installer" is stated as fact but not corroborated by any primary source
Spine Stack row: *"Python | 3.13.x (3.13.9; **3.14 deprecates full installer**)".* The 3.13.9 pin itself is verified. But the deprecation rationale is not: today I checked the CPython 3.14 release notes (`Doc/whatsnew/3.14.rst`), the python.org Windows download page, and the 3.14.0 release page — **none** mention the full installer being deprecated or a Python Install Manager replacement. The addendum §2 asserts it and §6 lists it as an open decision ("Python 3.13 vs 3.14 … 3.14 deprecated → pin 3.13.x"), i.e. the research agent itself treated it as unresolved, yet the spine upgrades it to a stated fact. If wrong, the decision survives (3.13 is still a sound pin), so this is rationale-integrity, not architecture-breaking.
**Fix:** soften to "*3.13.x pinned (3.13.9 installer verified); 3.14 full-installer status under change at python.org — re-verify at build*", and either cite the exact source the researcher used or drop the deprecation justification until confirmed.

### F3 — LOW–MEDIUM — certutil "(SHA256 verify)" implies a runtime mechanism the addendum never verifies
The runtime table annotates certutil.exe as "(SHA256 verify)", implying the tool verifies downloads' SHA256 at runtime. Addendum §8 only discusses SHA256 as a **README/distribution** artifact for IT users ("kèm SHA256 để xác minh") — it does not verify a runtime verification step, nor which per-version hash the tool would compare against and how it would fetch it for each source (nodejs `SHASUMS256.txt` and VS Code update feed and git-for-windows `.sha256` do exist; python.org publishes checksums; npm has built-in integrity — but the tool's mechanism is unspecified and unverified).
**Fix:** either cite, per source, how the tool fetches the authoritative hash, or move the SHA256-verify step to a build-time decision (the official-sources-only rule AD-7 already constrains supply-chain risk without it).

### F4 — LOW — Self-update endpoint returns 404 until the first release is cut
AD-7 / §5 point self-update at `api.github.com/repos/giakhanhquoc141-rgb/AI_AGENT_INSTALL/releases/latest`. The repo exists (confirmed), but currently has **no releases** — the endpoint returns 404. That is expected for a pre-v1 tool, but it means FR-25/26 is untestable until a release exists and the self-update helper must treat 404/empty `tag_name` as "no update available" rather than an error on every pre-release run.
**Fix:** design note for build — handle 404 and empty releases in the PowerShell release check; cut an initial v0.1 release before wiring self-update tests.

### F5 — LOW (informational) — "LTS 22.x/24.x" is correct today but is a moving floor
Node 24 (`v24.19.0`) is the Active LTS and satisfies OpenClaw's engine; Node 22 is in maintenance and also satisfies `>=22.22.3 <23`. Both fit today. The 22.x leg will fall out of support during v1's lifetime. The spine already frames this as a range policy ("never Current 26.x"), which is the right altitude — no action required, just do not let it harden into a literal 22.x pin at build.
**Also informational:** 9Router `latest` already moved 0.5.50 → 0.5.55 the same day; the spine's "at authoring" qualifier and the runtime `dist-tags` fetch are exactly correct and should stay as-is.

## What was verified clean (no action)

- Every named technology exists and fits: Node LTS, MinGit zip naming, Python 3.13.9 full installer, VS Code User Setup URL shape, npm dist-tags for OpenClaw/9Router.
- OpenClaw calendar versioning + engine range (live `engines` field matches addendum; LTS 24.19.0 is in-range).
- All official-source URLs in AD-7 resolve to the right domains; ports 20128/18789 consistent with addendum.
- Node ZIP `win-x64` naming and the addendum's `-x64.zip`-404 caveat are correct.
- curl/tar in-box (build 17063, Microsoft primary source) — accurate.
- Decision labels are mostly disciplined: "at authoring" (VS Code, 9Router) and "deferred/verify at build" (Node ZIP vs `msiexec /a`, MinGit vs full, npm 11.13–11.15 band, OpenClaw autostart) are all properly qualified in the spine. F1/F2 are the two places that overstate.

## Bottom line

The spine's stack and every named technology were re-confirmed against live official sources on the review date — the only mislabeled pieces are F1 (in-box runtime sourced to Microsoft but attributed to the addendum) and F2 (one deprecation rationale stated as fact that primary sources do not corroborate). Both are text-level corrections, not architectural defects. F3/F4 are build-time verification notes. **PASS WITH CONCERNS**.
