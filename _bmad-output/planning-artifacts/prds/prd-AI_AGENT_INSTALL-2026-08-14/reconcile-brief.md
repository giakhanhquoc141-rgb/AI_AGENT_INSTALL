# Reconcile: Brief → PRD

**Input:** `briefs/brief-AI_AGENT_INSTALL-2026-08-14/brief.md` + `addendum.md`
so với `prds/prd-AI_AGENT_INSTALL-2026-08-14/prd.md` + `addendum.md`

**Ngày:** 2026-08-15. **Ghi chú:** stack tăng 6 → 7 (thêm Git theo yêu cầu người dùng 2026-08-15) — PRD thay thế brief ở điểm này, không tính là gap.

---

## Gap 1 — Giao diện phải gợi được cảm giác "làm được việc công nghệ mà không cần là dân kỹ thuật" ở mọi bước (brief §Vấn đề, §Giải pháp, §Điều làm nên khác biệt; addendum §Branding)

**Brief nói:** Dân văn phòng không rành kỹ thuật là người dùng chính; nếu gặp khó sẽ nản và bỏ cuộc. Giao diện có màu sắc, logo, tiếng Việt, "bấm phím để đi tiếp". Cam kết cảm giác tin cậy: người dùng không cần hiểu dòng lệnh, không sợ "cài nhầm", không bao giờ bị đẩy vào nơi phải tự mày mò.

**PRD làm:** FR-1→FR-4 bắt đúng tầng chức năng (logo 11 dòng, phím đơn, kế hoạch + Y/N, tiếng Việt). Nhưng **không có FR hoặc `Consequences` nào khẳng định ngay từ lúc "hello world"**: người dùng có thể hiểu và khởi động bộ cài bình thường như một office worker — tức là các yêu cầu này chỉ được định hình và cho test được ở các bước có thao tác cụ thể, không phải ở "cảm giác" tổng thể. Yếu tố qualitative này dễ bị bỏ rơi khi triển khai.

**Mức độ:** Cao — đây là "cam kết trải nghiệm" lõi của brief, sai sốt là mất luôn mục tiêu sản phẩm (không phải vấn đề về lệnh nào chạy).
**Về đâu:** Section 7 (Aesthetic & Tone) — thêm một yêu cầu đánh giá "office-worker confidence" như một NFR (đánh giá xuyên bước): mọi bước đều phải có state "đang làm gì / đã xong / lỗi + hành động tiếp" và mọi thông báo đều có hướng dẫn tiếp theo rõ ràng. Thêm dòng trong §7 và các `Consequences` testable có thể kiểm được (không chỉ "no English strings").

---

## Gap 2 — Không có NFR/guardrail nào về thái độ với lỗi (nổi trên bề mặt, không lặng lẽ)

**Brief nói:** "Tool tự phát hiện… kiểm tra phiên bản mới nhất, cài đặt âm thầm"; "báo cáo kết quả cuối cùng rõ ràng". Addendum cảnh báo rõ các cạm bẫy sẽ gặp (Python Store-stub, `where node` trúng portable node, version-band OpenClaw, npm 11/12 chặn lifecycle scripts, Git installer tự elevate trên tài khoản admin…) và đặt một cam kết: nếu lỗi xảy ra, tool phải cho người dùng thấy lỗi ở đâu và làm gì tiếp. Ưu tiên độ tin cậy (≥90%) hơn tốc độ.

**PRD làm:** FR-2 có "bước lỗi hiển thị ✗ + gợi ý hành động" và NFR-REL-1 có retry/idempotency — nhưng tất cả là **ngang ngửa** trong danh sách, không có **guardrail/NFR đi ngang** nào buộc mọi lỗi phải nổi lên đúng cấp độ theo vai người dùng (và người không chuyên phải đọc hiểu được). Một triển khai vắn tắt sẽ để lỗi nằm âm thầm trong log modal hoặc ẩn sau một lời hỏi dày đặc — đúng thứ mà brief và addendum cùng đang cảnh báo.

**Mức độ:** Trung bình.
**Về đâu:** Section 6 (Constraints and Guardrails) — thêm guardrail "mọi failure khi chạy wizard phải nổi bề mặt ở tầng tương ứng (dòng lỗi người đọc hiểu được, không lặng lẽ bỏ qua)"; §7 có thêm dòng tone về lỗi. Tham chiếu FR-2/FR-9/FR-28 để chốt các `Consequences`.

---

## Gap 3 — Tham chiếu UX bmad-method-install bị phá loãng thành một dòng "cảm hứng"

**Brief nói:** (thông qua addendum §Branding) trải nghiệm cài đặt kiểu `npx bmad-method install` — từng bước, có màu, pro — chính là tham chiếu hành vi cho trải nghiệm wizard. Đây là một "tài liệu UX cụ thể" chứ không chỉ là 1 ý tưởng về màu sắc.

**PRD làm:** §7 chỉ đưa vào một dòng: "Lấy cảm hứng trình cài đặt `npx bmad-method install`". Từ "cảm hứng" làm cho nó trở thành một decorative reference — không được dịch sang các thuộc tính đánh giá được (bước nào → màn hình nào, loại điều hướng, mật độ và nhịp tổng thể) và **không hề được nhắc trong §4.1** hay §§ Success Metrics/Open Questions. Như vậy nó sẽ mất khi vào Architecture/Design.

**Mức độ:** Trung bình (chủ yếu về UX, dễ mất khi về Phase Build).
**Về đâu:** §7 + §4.1 (thêm `Consequences` nói rõ "có thể hoàn tất mọi thao tác mà không cần đọc hướng dẫn" và "không phải cửa sổ wizard mặc định của Windows"). Nếu muốn chắc chắn, đưa một mục nhỏ vào Open Questions / MoSCoW về việc tham chiếu. Không đủ quan trọng để trở thành một đứng riêng, nhưng nên hiện diện ở đâu đó trong PRD khi làm Design.

---

## Gap 4 — Tiêu chí thành công "tự cập nhật chính nó" (brief #6) không có metric trong §10

**Brief nói:** Danh sách *6 tiêu chí thành công* (brief §Tiêu chí thành công): (1) ≥90% hoàn tất trọn bộ; (2) không UAC/admin; (3) mọi tool kiểm tra phiên bản — không cài đè/hạ cấp; (4) combo `my-combo` tạo ra và ≥1 kết nối hoạt động; (5) gỡ sạch những gì tool đã cài; (6) **tool tự nhận biết phiên bản mới của chính nó từ GitHub và cho phép cập nhật**.

**PRD làm:** §10 khớp được 5/6 tiêu chí: SM-1→(1), SM-2→(2), SM-3→(3), SM-4→(4), SM-5→(5). Riêng tiêu chí (6) — tự cập nhật — dù có FR-25/FR-26, **không hề được ghi nhận ở bất kỳ Success Metric nào**. FR-25/26 bị "mồ côi" khỏi metric; một triển khai có thể giữ đúng FR mà vẫn không ai đo được nó. (Các bước UI FR-1–4 cũng không có metric, nhưng FR-25/26 rõ hơn vì nó là tiêu chí thành công tường minh trong brief.)

**Mức độ:** Thấp–Trung bình (metric bị thiếu — không phải lệch scope).
**Về đâu:** §10 — thêm một secondary metric: "Sau khi có bản mới từ GitHub, chạy update thành công và phiên kế tiếp chạy đúng bản mới (SM-6, validates FR-25–26)".