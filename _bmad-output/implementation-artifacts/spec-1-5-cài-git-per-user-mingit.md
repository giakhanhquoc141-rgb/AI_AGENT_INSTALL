---
title: 'Cài Git per-user (MinGit)'
type: 'feature'
created: '2026-08-26'
baseline_revision: '3bb1c9ccc96d745286dc5f8ac1e800affc424c5b'
baseline_commit: '3bb1c9ccc96d745286dc5f8ac1e800affc424c5b'
status: 'done'
review_loop_iteration: 1
followup_review_recommended: true
context: ['_bmad-output/implementation-artifacts/epic-1-context.md']
warnings: []
deferred: []
---

<intent-contract>

## Intent

**Problem:** Execute phase mới cài được Node (1.4); Git là mục độc lập tiếp theo — cần cài per-user không UAC kể cả khi tài khoản là admin.

**Approach:** Thêm `:install_git` vào execute: tải MinGit ZIP từ git-for-windows GitHub releases (bản trong `VL_Git`), giải nén vào `%LOCALAPPDATA%\Programs\Git`, thêm PATH `<dir>\cmd` qua PATH-controller (đã dùng chung, cần khử hardcode node), verify `git --version` trong phiên, ghi manifest. Refactor nhẹ `:execute_block` sang pattern `:try_install_<item>` để các story sau (1.6–1.8) chỉ thêm/đổi một subroutine.

## Boundaries & Constraints

**Always:**
- Một file `.bat` (AD-3); UI tiếng Việt/UTF-8, zero tiếng Anh (AD-11); execute bước 4/6 (AD-1).
- Per-user/no-admin gate cứng (AD-4): MinGit = không UAC kể cả admin, không `C:\Program Files\Git`; chỉ `%LOCALAPPDATA%`, HKCU, user PATH.
- Nguồn chính thức + retry 3 (AD-7); lỗi một mục không làm hỏng mục khác (AD-12); PATH-controller giữ `REG_EXPAND_SZ`, không `setx`, không truncate/trùng (AD-10).
- Git chỉ cài phiên bản trong `VL_Git` (đã chuẩn hóa `X.Y.Z.windows.P`); mọi mutation ghi manifest (AD-5).
- Hợp đồng bước: đúng 1 dòng log `install | ok|fail|skip` (AD-9). PATH-controller tái sử dụng phải khử hardcode node (PA_EXPANDED tính từ entry, không đặc tả node) — vẫn giữ đúng hành vi node đã verify ở 1.4.
- Update phải bảo toàn bản Git đang hoạt động cho tới khi bản staged đã hợp lệ; nếu replace, PATH, verify hoặc manifest thất bại thì phục hồi thư mục Git cũ và PATH cũ.
- Verify phải gọi trực tiếp `%LOCALAPPDATA%\Programs\Git\cmd\git.exe`, xác nhận executable đúng thư mục và phiên bản bằng `VL_Git`; không được để Git khác trên PATH tạo false positive.
- Manifest là một phần của transaction: lỗi tạo/ghi manifest làm install thất bại và kích hoạt rollback.
- PATH-controller không được làm hỏng dấu `!`, chỉ thay `%LOCALAPPDATA%` khi là prefix, và không thêm trùng session PATH khi gọi lại.

**Block If:** `LOCALAPPDATA` trống; hoặc `VL_Git` trống/`-`/không đúng dạng `X.Y.Z.windows.P` → không đoán, báo lỗi tiếng Việt, log `install | skip | unknown-version` và trả lỗi để execute không báo thành công.

**Never:**
- Không dùng installer Git đầy đủ (tự nâng UAC trên admin); không `setx`/`%ProgramFiles%`/HKLM/UAC (AD-4).
- Không cài Python/VSCode/npm items (1.6–1.8); không configure/report (1.9–1.11).
- Không nguồn không chính thức/telemetry/API key (AD-7/AD-8).

</intent-contract>

## Code Map

- `AI_Tools_Installer.bat` — `:execute_block` hiện có nhánh `not-supported-yet` cho Git (L436–440); `:path_append` (L98–157) có hardcode node (`PA_EXPANDED=%LOCALAPPDATA%\node`, L103); `:install_node` (L470+) là mẫu để dựng `:install_git`.
- Run-state: `ST_Git`/`VR_Git`/`VL_Git`.
- `epic-1-context.md` — stack cài Git: MinGit ZIP → `%LOCALAPPDATA%\Programs\Git`, PATH `<dir>\cmd`.

## Tasks & Acceptance

**Execution:**
- [x] `AI_Tools_Installer.bat` -- Refactor `:execute_block` sang pattern `:try_install_<item>` (Node, Git, và stub `:try_install_python/vscode/vscodeext/openclaw/9router` giữ `not-supported-yet`); giữ nguyên UI/hợp đồng cũ.
- [x] `AI_Tools_Installer.bat` -- Tổng quát hóa `:path_append` cho Node/Git nhưng bảo toàn mọi PATH hiện có kể cả dấu `!`, dedup registry + session theo dạng tương đương, chỉ đổi `%LOCALAPPDATA%` ở prefix; hành vi Node phải giữ nguyên.
- [x] `AI_Tools_Installer.bat` -- Thêm `:install_git`: validate `LOCALAPPDATA` và `VL_Git=X.Y.Z.windows.P`; ánh xạ tên asset bỏ `.windows`; retry 3; staging; backup/replace/rollback an toàn; PATH; verify trực tiếp executable + version; manifest có kiểm tra lỗi; đúng một log kết quả; cleanup.

**Acceptance Criteria:**
- Given Git chưa cài hoặc cần cập nhật, when execute chạy, then MinGit được giải nén vào `%LOCALAPPDATA%\Programs\Git` và `git --version` chạy được trong cùng phiên.
- Given tài khoản Windows là admin (UAC on), when cài Git, then không có UAC prompt, không cài vào `C:\Program Files\Git` — MinGit per-user.
- Given tool ghi PATH cho Git, when PATH-controller thêm `<dir>\cmd`, then entry đúng thư mục cài, không trùng lặp, PATH không bị cắt, giữ `REG_EXPAND_SZ`.
- Given `VL_Git` không xác định, when cài, then báo lỗi tiếng Việt + log `install | skip | unknown-version`.
- Given tải/giai nén lỗi, when cài, then retry 3, lỗi báo rõ, các mục khác không bị ảnh hưởng.
- Given máy đã có MinGit per-user, when update lỗi ở replace/PATH/verify/manifest, then bản Git cũ và PATH cũ được phục hồi.
- Given một Git khác có trước trên system PATH, when verify bản vừa cài, then chỉ executable trong `%LOCALAPPDATA%\Programs\Git\cmd` được chấp nhận và version phải khớp `VL_Git`.
- Given Git hiện tại và mới nhất chỉ khác revision `.windows.P`, when scan so sánh, then revision thấp hơn được quyết định `UPDATE` thay vì `SKIP`.

## Spec Change Log

- 2026-08-26: Hoàn tất bộ điều phối cài theo từng mục, PATH-controller dùng entry chung và luồng cài MinGit per-user.
- 2026-08-26 — Review loop 1: review phát hiện replace phá hủy bản cũ, verify nhầm Git hệ thống, manifest không transactional và PATH có thể hỏng/nhân đôi. Đặc tả bổ sung backup/rollback, verify executable+version trực tiếp, kiểm tra lỗi manifest, hard-block LOCALAPPDATA/version và các bất biến PATH. Tránh trạng thái xóa đích rồi move không thể phục hồi. KEEP: dispatch `try_install_*`, retry 3, staging, asset mapping chính thức, cài per-user và PATH-controller dùng chung.
- 2026-08-26 — Review loop 2: rollback filesystem/PATH/manifest chạy độc lập và không xóa bản Git cũ nếu backup chưa được tạo; PATH giữ nguyên cả thành phần rỗng và chuẩn bị output phiên trước khi commit registry; manifest dedup theo item+version+path chuẩn hóa; retry bao trọn tải+giải nén+verify staging; tên transaction dùng GUID và từ chối collision; verify gồm executable tuyệt đối lẫn phân giải `git` qua PATH cùng phiên.

## Review Triage Log

### 2026-08-26 — Review pass 1
- bad_spec: 1; patch: 5; defer: 0; reject: 16.
- Re-derived implementation with transactional backup/rollback, exact executable/version verification, manifest error handling, safe PATH handling, official asset-name mapping, and Git `.windows.P` comparison.

### 2026-08-26 — Review pass 2
- intent_gap: 0; bad_spec: 0; patch: 7; defer: 0; reject: 19.
- Patched rollback guard and independent restoration, PATH empty-segment preservation and write ordering, manifest path identity, PATH-based Git verification, whole-attempt retry, GUID temp names, and verification notes.
- Follow-up review remains recommended because destructive install/update failure injection was not run against the real HKCU PATH and Git directory.

## Design Notes

MinGit asset: Git for Windows release tag `v<VL_Git>` giữ hậu tố `.windows.N`, còn tên asset bỏ `.windows` (VD tag `v2.55.0.windows.5`, asset `MinGit-2.55.0.5-64-bit.zip`). Giải nén giống node (staging + atomic replace). PATH entry `<root>\cmd`. `:path_append` sau refactor phải giữ: REG_EXPAND_SZ lưu literal `%LOCALAPPDATA%...`, REG_SZ lưu expanded, refresh in-session dùng expanded (P1/P2 từ 1.4).

## Verification

**Commands:**
- `cmd /c "echo HH| AI_Tools_Installer.bat"` -- expected: hủy plan, không có `install` log, exit 0.
- `curl -sI https://github.com/git-for-windows/git/releases/download/v<VL_Git>/MinGit-<VL_Git bỏ .windows>-64-bit.zip` -- expected: HTTP 200 (VD tag 2.55.0.windows.5 → asset 2.55.0.5).
- Scratch path_append (redirect registry): gọi với entry Git → lưu literal `%LOCALAPPDATA%\Programs\Git\cmd` + REG_EXPAND_SZ, `where git` resolve được trong phiên; chạy lại → không trùng.
- Scratch regression node entry: path_append với `%%LOCALAPPDATA%%\node` vẫn lưu literal + resolve trong phiên (không phá 1.4).

**Manual checks (nếu cần):**
- Kiểm tra execute_block không còn `not-supported-yet` cho Git; giữ cho 5 mục còn lại.

**Kết quả 2026-08-26:**
- Luồng hủy `(echo H&echo H) | AI_Tools_Installer.bat`: đạt, thoát 0 và không chạy bước cài.
- Kiểm tra URL sau redirect cho tag `2.55.0.windows.5` → asset `MinGit-2.55.0.5-64-bit.zip`: HTTP 200.
- Kiểm tra tĩnh source: đủ 7 dispatcher `try_install_*`; Git không còn stub; retry bao trọn tải/giải nén/verify staging; verify dùng cả đường dẫn tuyệt đối và `Get-Command git`; rollback ba miền độc lập; tên tạm dùng GUID; không có `setx`, full installer hay `%ProgramFiles%\Git`: đạt.
- `git diff --check`: đạt. Chưa chạy cài/update MinGit end-to-end vì phép thử này sẽ thay đổi thư mục Git và HKCU PATH thật của máy.

## Suggested Review Order

**Luồng điều phối**

- Bắt đầu tại dispatcher để thấy thứ tự và cách cô lập lỗi từng mục.
  [`AI_Tools_Installer.bat:364`](../../AI_Tools_Installer.bat#L364)

**Transaction cài Git**

- Theo dõi validate, retry, staging và commit bản MinGit per-user.
  [`AI_Tools_Installer.bat:438`](../../AI_Tools_Installer.bat#L438)

- Kiểm tra verify trực tiếp và qua PATH trước khi ghi manifest.
  [`AI_Tools_Installer.bat:498`](../../AI_Tools_Installer.bat#L498)

- Rà rollback độc lập cho filesystem, PATH và manifest.
  [`AI_Tools_Installer.bat:560`](../../AI_Tools_Installer.bat#L560)

**Hạ tầng dùng chung**

- PATH-controller bảo toàn giá trị, kiểu registry và dấu chấm than.
  [`AI_Tools_Installer.bat:98`](../../AI_Tools_Installer.bat#L98)

- Manifest dedup theo item, phiên bản và đường dẫn chuẩn hóa.
  [`AI_Tools_Installer.bat:124`](../../AI_Tools_Installer.bat#L124)

- So sánh đầy đủ revision `.windows.P` để quyết định update Git.
  [`AI_Tools_Installer.bat:195`](../../AI_Tools_Installer.bat#L195)

**Theo dõi sprint**

- Xác nhận story chuyển sang review mà không ảnh hưởng backlog kế tiếp.
  [`sprint-status.yaml:43`](sprint-status.yaml#L43)
