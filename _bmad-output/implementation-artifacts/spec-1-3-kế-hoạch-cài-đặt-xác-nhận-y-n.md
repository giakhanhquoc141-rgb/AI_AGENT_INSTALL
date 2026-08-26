---
title: 'Kế hoạch cài đặt + xác nhận Y/N'
type: 'feature'
created: '2026-08-26'
baseline_revision: 'c07fad813f541b7ab156d192bae96b959ef06cb7'
status: 'done'
review_loop_iteration: 0
followup_review_recommended: false
context: ['_bmad-output/implementation-artifacts/epic-1-context.md']
warnings: []
deferred:
  - summary: >-
      plan_block trả về exit 0 cho cả 3 kết cục (confirmed/cancelled/insufficient-scan) — pipeline
      chưa phân biệt được "hủy" với "đã xác nhận"; khi execute phase xuất hiện (story 1.4), hủy
      vẫn sẽ chạy tiếp vào cài đặt.
    evidence: |-
      Đọc AI_Tools_Installer.bat:274-284: nhánh cancel và guard đều exit /b 0; :run_install chỉ
      gate theo errorlevel 1. Intent yêu cầu "H → thoát sạch" — cần tín hiệu hủy riêng (flag hoặc
      RC) để pipeline dừng, xử lý tại story 1.4 khi execute được thêm vào.
    location: >-
      AI_Tools_Installer.bat:274
    severity: medium
  - summary: >-
      Không có test tự động nào chạy surface plan/confirm mới (render 7 mục, tổng kết, nhánh
      choice, dòng log) — chỉ có chạy tay qua console.
    evidence: |-
      Verification-gap review: unit.ps1 chỉ assert các helper quyết định version; offline-test.bat và
      partial-test.bat vẫn dừng ở stub plan cũ. Cùng khoảng trống đã ghi trong deferred-work cho
      story 1-1/1-2 — cần test harness dùng chung cho batch.
    location: >-
      AI_Tools_Installer.bat:228
    severity: medium
---

<intent-contract>

## Intent

**Problem:** Người dùng quét máy xong nhưng chưa được xem kế hoạch đầy đủ và chưa có bước xác nhận — plan hiện chỉ là stub "chưa hỗ trợ".

**Approach:** Thay `:plan_block` stub bằng màn hình kế hoạch: liệt kê đủ 7 mục với quyết định Cài mới/Bỏ qua/Cập nhật kèm phiên bản, tổng kết số lượng, rồi xác nhận bằng phím đơn (C = tiếp tục, H = hủy an toàn). Không thay đổi máy trước xác nhận; mỗi kết cục ghi đúng 1 dòng log (ok/skip).

## Boundaries & Constraints

**Always:**
- Một file `.bat` duy nhất (AD-3); UI tiếng Việt/UTF-8, zero tiếng Anh (AD-11).
- Pha plan là bước 3/6 theo thứ tự cố định welcome → scan → plan+confirm → execute → configure → report (AD-1); UI luôn báo bước X/Y, đang làm gì và còn bao nhiêu bước.
- Không có mutation máy nào trước khi xác nhận (FR-3): plan chỉ đọc run-state từ scan (ST_/VR_/VL_) và hiển thị.
- Hủy an toàn bất cứ lúc nào trong bước (AD-1): H → thoát sạch, không làm hỏng gì.
- Phím đơn cho mọi thao tác (FR-2); hợp đồng bước: đúng 1 dòng log `plan | ok|skip` (AD-9).
- Nguồn dữ liệu duy nhất: biến run-state do scan tạo — không quét lại, không gọi mạng trong plan.

**Block If:** Nếu run-state scan thiếu (thiếu biến ST_*) → không đoán, thoát an toàn với log `plan | skip | insufficient-scan`.

**Never:**
- Không execute/configure/report (1.4–1.11); không cài đặt, không sửa PATH/registry/manifest.
- Không `setx`/`%ProgramFiles%`/HKLM/UAC (AD-4); không nguồn không chính thức/telemetry/API key (AD-7/AD-8).
- Không phụ thuộc network trong plan — dữ liệu lấy từ run-state scan.

</intent-contract>

## Code Map

- `AI_Tools_Installer.bat` (project root) — thay `:plan_block` stub (L228–232) bằng plan thật; thêm helper `:plan_item`, `:plan_count`; đổi `call :run_step "plan" ":plan_block"` (L107) thành `call :plan_block` (giống `:scan_block`, tự log).
- Biến run-state: `ST_<item>` (INSTALL/SKIP/UPDATE), `VR_<item>` (current), `VL_<item>` (latest) — xuất từ `:scan_block` (L188), parse tại `:scan_parse` (L190–201).
- `epic-1-context.md` (cùng thư mục) — AD-1 pha pipeline, AD-9 hợp đồng log, UX plan screen.
- `spec-1-2-...md` — continuity: `:show_item` (L203) làm mẫu render; contract `color_echo`/`log_append`.

## Tasks & Acceptance

**Execution:**
- `AI_Tools_Installer.bat` -- Thay `:plan_block` stub bằng màn hình kế hoạch: guard dữ liệu scan; liệt kê đủ 7 mục (tên + Cài mới/Bỏ qua/Cập nhật + phiên bản); dòng tổng kết số lượng; `choice /c CH /n` xác nhận phím đơn. C → log `plan | ok | confirmed` + return 0; H → thông báo hủy + log `plan | skip | cancelled` + return 0; guard thiếu dữ liệu → log `plan | skip | insufficient-scan` + return 0. Đổi L107 thành `call :plan_block`. Thêm `:plan_item` (render 1 dòng mục) và `:plan_count` (đếm INSTALL/UPDATE/SKIP).

**Acceptance Criteria:**
- Given scan đã xong, when hiển thị kế hoạch, then liệt kê đủ 7 mục — mỗi mục hiện đúng Cài mới/Bỏ qua/Cập nhật kèm phiên bản — không bỏ sót mục cần cập nhật.
- Given kế hoạch đang hiển thị, when tôi chưa bấm C, then không có thay đổi nào trên máy được thực hiện.
- Given tôi bấm H, when thoát, then tool thoát an toàn, log `plan | skip | cancelled`, không làm hỏng máy.
- Given tôi bấm C, when xác nhận, then log `plan | ok | confirmed` và pipeline sẵn sàng sang execute.
- Given bước này chạy, when UI hiển thị, then luôn thấy bước 3/6, bước làm gì và còn bao nhiêu bước.

## Spec Change Log

## Review Triage Log

### 2026-08-26 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 2: (high 0, medium 0, low 2)
- defer: 2: (high 0, medium 2, low 0)
- reject: 14
- addressed_findings:
  - `[low]` `[patch]` plan_item hiển thị "bản mới nhất -"/"sang -" khi chưa xác định được bản mới nhất (ext chưa cài hoặc mất mạng) — thêm nhánh render bỏ phần version khi VL là "-".
  - `[low]` `[patch]` Màn hình hủy thiếu gợi ý bước tiếp theo — thêm dòng "Bạn có thể chạy lại bất cứ lúc nào."

## Auto Run Result

- **Summary:** Thay `:plan_block` stub bằng màn hình kế hoạch + xác nhận phím đơn (C/H) — liệt kê đủ 7 mục (Cài mới/Bỏ qua/Cập nhật + phiên bản), tổng kết số lượng, hiển thị bước 3/6, guard dữ liệu scan, log đúng 1 dòng ok/skip.
- **Files changed:**
  - `AI_Tools_Installer.bat` — `:plan_block` thật + helpers `:plan_item`/`:plan_count`; `:run_install` gọi `:plan_block` trực tiếp (self-log như `:scan_block`).
- **Review findings breakdown:** patches 2 (low 2) · deferred 2 (medium 2) · rejected 14.
- **Follow-up review recommendation:** false (score = 3×0 + 1×2 = 2 < 5; không có finding high).
- **Verification performed:**
  - `cmd /c "echo HH | AI_Tools_Installer.bat"` → exit 0, "Đã hủy" + gợi ý chạy lại, log `plan | skip | cancelled`.
  - `cmd /c "echo HC | AI_Tools_Installer.bat"` → exit 0, "Đã xác nhận. Bắt đầu cài đặt...", log `plan | ok | confirmed`.
  - Seeded run-state (bản sao tạm): INSTALL/UPDATE với VL="-" render không dash ("cài mới"/"cập nhật — VR"), tổng kết 3 cài mới · 2 cập nhật · 2 bỏ qua đúng dữ liệu cấp.
  - Scan thật trên máy: 7 mục hiển thị đủ, tổng kết 2 cài mới · 2 cập nhật · 3 bỏ qua, không tiếng Anh cho người dùng cuối.
- **Residual risks:**
  - Cancel gating với execute phase (chưa tồn tại) — deferred, xử lý tại story 1.4.
  - Không có test tự động cho plan surface — deferred (test harness dùng chung).

## Design Notes

Màn hình plan (3/6): tiêu đề "Bước 3/6 — Kế hoạch cài đặt (còn 3 bước)", dòng giới thiệu "chưa có gì thay đổi cho tới khi bạn xác nhận", 7 dòng mục theo thứ tự scan (Git, Node.js, Python, VSCode, ext Claude Code, OpenClaw, 9Router), dòng tổng kết "Tổng kết: N cài mới · N cập nhật · N bỏ qua", rồi prompt `choice /c CH /n /m "  (C/H) "`. Update hiển thị `VR sang VL`; SKIP hiện `đã cài VR` (ext đã cài hiện `đã cài`); INSTALL hiện `bản mới nhất VL`. Không dùng `run_step` cho plan — self-log để phân biệt ok/skip (AD-9); kết cục return 0 cả khi hủy (thoát an toàn, không phải lỗi).

## Verification

**Commands:**
- `cmd /c "echo HH | AI_Tools_Installer.bat"` -- expected: plan hiện 7 mục, "Đã hủy", thoát 0; log chứa `plan | skip | cancelled`.
- `cmd /c "echo HC | AI_Tools_Installer.bat"` -- expected: "Đã xác nhận", log `plan | ok | confirmed`.
- `cmd /c AI_Tools_Installer.bat` -- expected: không xuất hiện chuỗi tiếng Anh cho người dùng cuối.

**Manual checks (nếu scan chậm do mạng):**
- Chạy và quan sát màn hình plan: đủ 7 mục, nhãn đúng, bước 3/6, không thay đổi máy trước xác nhận.
