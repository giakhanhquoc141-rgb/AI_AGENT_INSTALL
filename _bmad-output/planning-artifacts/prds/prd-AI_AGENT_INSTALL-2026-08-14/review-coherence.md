# Review Coherence — PRD AI Tools Installer

- Ngày review: 2026-08-15
- Nguồn xem xét: `prd.md`, `addendum.md`, `brief-AI_AGENT_INSTALL-2026-08-14/brief.md`, kèm `.memlog.md` (lịch sử quyết định) và `review-rubric.md` (pass review trước, lens khác).
- Phạm vi: 5 tiêu chí coherence theo yêu cầu; severity Medium/Low/Info.

## Verdict tổng

**ĐẠT — không có mâu thuẫn chặn (blocking).** PRD nhất quán ở tất cả cam kết cốt lõi (no-admin/UAC, riêng tư, không hạ cấp, glossary) và đã xử lý sạch mở rộng 6→7 Git. Có **3 vấn đề Medium** cần sửa trước khi chuyển phase (một cross-reference gãy, thiếu Success Metric cho tự cập nhật tool, và căng thẳng cách chọn Node LTS) + 4 vấn đề Low/nit. Không phát hiện mâu thuẫn mâu thuẫn trực tiếp nào ở nhóm 5 cam kết.

## Kết quả theo 5 tiêu chí

### 1. Brief → PRD; mở rộng 6→7 Git — ĐẠT (1 lưu ý chuỗi tài liệu)

Mọi năng lực của brief đều có FR tương ứng: wizard→FR-1–4; phát hiện/kiểm tra phiên bản→FR-5–8; cài tự động silent chính thức→FR-9–17; combo `my-combo`→FR-18–19; cấu hình lần đầu (dashboard, khởi động cùng Windows, nhập key)→FR-20–22; gỡ cài theo manifest→FR-23–24; tự cập nhật→FR-25–26; tiếng Việt + báo cáo→FR-4/27–28.

7 mục nhất quán toàn văn PRD: Glossary §3 (dòng 62), UJ-1 "7/7" (41–42), UJ-2 "2/7…5/7" (49), UJ-3 "7/7" (56), FR-3 (98), FR-5 (114), SM-1 (369), MVP §9.1 (349), Vision §1 (17), tone §7 (332). **Không còn "6 mục" sót trong PRD** — grep xác nhận; chuỗi "6" chỉ tồn tại ở ngữ cảnh mô tả quá khứ (dòng 9, 13) và `.memlog`/brief.

- **[info]** F8 — Brief gốc vẫn ghi stack 6 mục (brief dòng 51 "trọn bộ 6 mục", dòng 61 phạm vi) và không có Git; PRD §0 (dòng 9, 13) ghi nhận mở rộng và `.memlog` dòng 8 tuyên bố "PRD supersedes". Không phải lỗi của PRD, nhưng nên cập nhật brief để chuỗi tài liệu đồng bộ (brief vẫn là nguồn "đã duyệt").

### 2. FR↔UJ cross-reference — GẦN ĐẠT (1 ref gãy + 2 under-claim)

Các khai báo "Realizes UJ-x" đa số hợp lý về ngữ nghĩa: 4.1/4.2→UJ-1, UJ-2; 4.4/4.5→UJ-1; 4.6→UJ-3; 4.7→UJ-2 ("ở tầng tool" — đúng, không trùng non-goal "không tự cập nhật ngầm các tool").

- **[medium]** F1 — **UJ-2 dẫn sai Open Question**: edge case "quay lại cài lại bản cũ" ghi *(mở, xem OQ-5)* (prd dòng 50), nhưng OQ-5 (dòng 387) là về "cách gom log gửi hỗ trợ". Đúng chủ đề là **OQ-4** (dòng 386) "Xử lý 'cập nhật gây lỗi' — có chế độ quay về bản cũ không?". Sửa OQ-5 → OQ-4. *(Đã được review-rubric dòng 57 bắt độc lập — tái xác nhận tại đây.)*
- **[low]** F4 — **Under-claim**: 4.3 (FR-9–17) chỉ khai "Realizes UJ-1" (dòng 142) nhưng UJ-2 path "cập nhật đúng các mục cũ" (dòng 48) cũng chạy cài/cập nhật; 4.8 (FR-27–28) khai "UJ-1, UJ-3" (dòng 296) thiếu UJ-2 — phiên cập nhật cũng ghi log và có "báo cáo" cuối (dòng 48). Nên bổ sung UJ-2.

### 3. Success Metrics — GẦN ĐẠT (1 tiêu chí thành công của brief không có SM)

Ánh xạ SM↔FR đúng vùng: SM-1→FR-9–17/27–28; SM-2→FR-10–16; SM-3→FR-5–8; SM-4→FR-18/21–22; SM-5→FR-24. Tất cả SM bám thesis của brief (≥90% hoàn tất, 0 UAC, quyết định phiên bản đúng, combo dùng được, gỡ sạch). Counter-metrics là đối trọng thật: SM-C1 chặn tối ưu tốc độ (đánh đổi SM-1/NFR-PERF), SM-C2 chặn thêm telemetry để đo chính xác hơn (bảo vệ NFR-SEC-2). Cân bằng đúng hướng.

- **[medium]** F2 — **Tiêu chí thành công của brief "Tool tự nhận biết phiên bản mới của chính nó từ GitHub và cho phép cập nhật" (brief dòng 56) không có SM nào validate**: §10 không SM nào nhắc FR-25/26 (tự cập nhật tool). Thêm SM (vd: "≥1 phiên nâng cấp tool thành công, sau đó chạy lại ra bản mới — Validates FR-25–26") hoặc gộp vào SM-1. *(FR-19 no-key, FR-20 autostart không có SM riêng nhưng được che bởi NFR-SEC-2/constraint §6 và consequence FR-20 — chấp nhận được, không đáng mở SM.)*

### 4. Glossary — ĐẠT

- **Bộ stack** (7 mục): định nghĩa dòng 62 = danh sách dùng lại y hệt ở FR-5, §9.1, SM-1.
- **Phiên chạy**: dùng đúng nghĩa ("một lần chạy tool…") ở FR-10, FR-23, FR-27, FR-28, NFR-PERF-1, SM-1.
- **Per-user / Silent**: FR-10–14 nhất quán với định nghĩa (%LOCALAPPDATA% + PATH người dùng, không wizard bộ cài).
- **Manifest**: UJ-3, FR-19 (consequence), FR-23–24 đều dùng đúng nghĩa "file ghi mục đã cài".
- **Combo `my-combo`**: FR-18, FR-21, SM-4, §9.1 — chuỗi fallback 3 tầng trùng khớp addendum §4.
- **Khởi động cùng Windows**: FR-20, UJ-1/UJ-2 resolution, FR-24 — đúng định nghĩa "chạy khi người dùng đăng nhập".
- **Cập nhật ngầm**: non-goal dòng 339 dùng đúng nghĩa glossary; **không trùng** FR-25/26 (tự cập nhật CHÍNH tool, có xác nhận người dùng — dòng 285 "Không tự tải khi người dùng chưa đồng ý"). Phân biệt "9Router" (sản phẩm) / "9router" (npm) nhất quán.
- *(Ghi chú: A8 chỉ xuất hiện ở index §12, không có tag inline — đã có trong review-rubric dòng 58, chấp nhận được cho giả định toàn văn.)*

### 5. Mâu thuẫn nội bộ — GẦN ĐẠT (0 mâu thuẫn cứng, 3 căng nhẹ)

- **no-admin/UAC vs FR-10–16**: **Nhất quán.** Addendum xác minh từng mục: Node MSI là per-machine nên chọn ZIP (addendum 20–25), Python per-user `Include_launcher=0` (27–32), VSCode User Setup (34–38), npm global per-user (FR-15), extension qua `code.cmd` (FR-16). Git: bộ cài full TỰ ELEVATE trên tài khoản admin → A9 chốt **MinGit** (addendum 40–55) nên FR-10 exception "trừ mục do chính bộ cài bắt buộc" không có trường hợp thực tế vi phạm.
  - **[low]** F7 — FR-14 tựa "Cài Git per-user **silent**" (dòng 181) nhưng A9 chọn MinGit (ZIP giải nén, không installer → không có cửa sổ wizard để "silent"). Từ "silent" ở đây lỏng so với định nghĩa glossary; đổi tựa thành "cài Git per-user (MinGit)" hoặc chú thích.
- **Riêng tư (no telemetry, no API key) vs FR-18/27/28**: **Nhất quán.** FR-18 chỉ tạo combo (tham chiếu provider, không lưu key — addendum §4 "không đọc/lưu API key"); FR-19 cấm đụng key, consequence "không có key trong manifest/log"; FR-21/22 chỉ dẫn mở dashboard để người dùng **tự** nhập; FR-27 "không gửi dữ liệu đi đâu" và consequence liệt kê đúng các request mạng khai báo (tải bộ cài / tra cứu phiên bản / kiểm tra update); SM-C2 chặn telemetry để đo chính xác hơn. Không mâu thuẫn.
- **Không hạ cấp vs FR-7**: **Nhất quán** ở mức hiện tại (FR-6/FR-7/SM-3/§9.1 đồng bộ). Có **tension tiềm ẩn**: UJ-2 edge case (dòng 50) + OQ-4 mở hướng "quay lại cài bản cũ" — nếu build quyết định hỗ trợ rollback thì đối đầu trực tiếp FR-7 ("không bao giờ cài đè xuống phiên bản thấp hơn"). OQ-4 hiện để ngỏ (chưa phải cam kết) nên CHƯA phải mâu thuẫn, nhưng nên đánh dấu `[NOTE FOR PM]` để quyết định ở tầng product trước khi Stories, và nếu giữ rollback thì scope lại FR-7 ("không hạ cấp trong quyết định phiên bản **tự động**"). *(Trùng nudge O-1 của review-rubric.)*
- **Non-goal "không phải trình quản lý gói" vs thực tế tool** (dòng 336): **[low]** F6 — tool thực hiện hành vi kiểu package-manager (manifest, quyết định cài/bỏ qua/cập nhật, gỡ theo manifest, tự cập nhật, cài npm global). Khác biệt chỉ hợp lệ nhờ lập luận "wizard 1-file **chuyên biệt, danh sách cố định 7 mục**, cho người không chuyên" (brief dòng 44). Không phải mâu thuẫn cứng, chỉ cần giữ rõ lập luận đó khi trả lời.

## Findings tổng hợp

| # | Severity | Finding | Vị trí |
|---|---|---|---|
| F1 | Medium | UJ-2 edge case dẫn sai OQ: "xem OQ-5" nhưng chủ đề rollback là OQ-4 | prd 50, 386, 387 |
| F2 | Medium | Tiêu chí thành công "tự cập nhật tool" của brief không có SM nào validate FR-25/26 | brief 56; prd §10 (368–379) |
| F3 | Medium | Chọn Node mâu thuẫn nội bộ: "latest LTS" (addendum §1) vs "LTS trong range OpenClaw" (FR-8) vs "luôn 22.x/24.x" (addendum pitfall 7); FR-6 "mới nhất" mơ hồ — với Node phải là "mới nhất đủ điều kiện" (UJ-2 dòng 48 cho thấy Node 24→"bỏ qua" dù Current 26 mới hơn) | prd 120–138; addendum 9, 105; UJ-2 prd 48 |
| F4 | Low | FR↔UJ under-claim: 4.3 thiếu UJ-2; 4.8 thiếu UJ-2 | prd 142, 296 |
| F5 | Low | FR-24 gỡ Node/Git "qua bộ gỡ/registry" nhưng cơ chế cài là ZIP (không uninstaller) — gỡ phải xóa thư mục + bỏ PATH user | prd 268; addendum 22–48 |
| F6 | Low | Non-goal "không phải package manager" căng nhẹ với hành vi thực tế (manifest/cập nhật/gỡ) | prd 336 |
| F7 | Low | FR-14 "silent" vs cơ chế thực tế MinGit (ZIP, không installer) | prd 181; addendum 44–48 |
| F8 | Info | Brief gốc còn 6 mục, chưa đồng bộ Git — PRD đã supersede (ghi nhận, không phải lỗi PRD) | brief 51, 61; prd 9, 13; memlog 8 |

*Không lặp lại: D-1 (SmartScreen/MoTW), S-1 (OpenClaw first-run vs "không cần dòng lệnh"), S-2 (free-tier churn vs SM-4), D-2 (manifest/log chưa chốt đường dẫn), D-3 (FR-21 consequence không đo được bằng tool) — đã có đầy đủ trong `review-rubric.md`, không thuộc phạm vi coherence này.*

## Khuyến nghị tối thiểu trước khi chuyển phase

1. Sửa con trỏ UJ-2: OQ-5 → OQ-4 (F1).
2. Thêm SM cho tự cập nhật tool, phủ FR-25/26 (F2).
3. Chốt baseline Node = LTS **trong range OpenClaw (22.x/24.x)** cho cả so sánh lẫn cài đặt, và sửa FR-6 thành "phiên bản mới nhất **đủ điều kiện**"; đồng bộ addendum §1 (F3).
4. (Option) Đánh dấu OQ-4 là `[NOTE FOR PM]` và scope FR-7 nếu giữ rollback.
