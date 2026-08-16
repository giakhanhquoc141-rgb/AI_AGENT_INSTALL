---
title: "Product Brief: AI Tools Installer"
status: done
created: 2026-08-14
updated: 2026-08-14
---

# Product Brief: AI Tools Installer

## Tóm tắt điều hành

AI Tools Installer là một file `.bat` duy nhất giúp bất kỳ ai — kể cả dân văn phòng không rành kỹ thuật — biến một máy Windows mới thành "môi trường AI sẵn sàng làm việc" chỉ trong vài phút. Thay vì tải và cài tay từng công cụ (Node.js, Python, VSCode, OpenClaw, 9Router) qua nhiều trang web và cửa sổ wizard, người dùng chỉ chạy một file, bấm tiếp qua từng bước có màu sắc, logo, thân thiện với người mới. Tool tự phát hiện công cụ nào đã có, kiểm tra phiên bản mới nhất, cài đặt âm thầm (silent), tạo sẵn combo 9Router `my-combo` (DeepSeek v4 Flash), hướng dẫn cấu hình lần đầu và đăng ký khởi động cùng Windows — và gỡ cài sạch nếu không dùng nữa.

Lý do bây giờ: bộ công cụ AI (OpenClaw, 9Router) đang dần trở thành lựa chọn phổ biến, nhưng việc cài đặt vẫn yêu cầu kiến thức dòng lệnh. AI Tools Installer đóng lỗ hổng đó bằng một trải nghiệm wizard đơn giản, miễn phí, an toàn và có thể thu hồi — hướng tới ≥90% phiên chạy hoàn tất trọn bộ mà không cần hỗ trợ.

## Vấn đề

Chuẩn bị một máy Windows mới để làm việc với các công cụ AI là một chuỗi thao tác thủ công, lặp lại và dễ sai:
- Phải tải từng bộ cài từ nhiều trang khác nhau, bấm qua nhiều cửa sổ wizard, tự lo cấu hình PATH.
- Khó biết phiên bản nào đang là mới nhất; dễ cài bản cũ, cài đè gây lỗi, hoặc bỏ sót.
- Với người không rành kỹ thuật (dân văn phòng), các hướng dẫn online giả định kiến thức dòng lệnh và package manager (npm, biến môi trường) — khiến họ dễ nản và bỏ cuộc, phải nhờ IT.
- Khi không dùng nữa, việc gỡ sạch các công cụ này cũng rải rác tương tự — không có nơi nào ghi lại "máy này đã cài gì".

**Chi phí hiện trạng:** 30–60 phút+ cho mỗi máy, tỉ lệ lỗi cao, và mỗi lần cài lại máy là làm lại từ đầu.

## Đối tượng phục vụ

- **Người dùng chính — dân văn phòng trên Windows**: không rành kỹ thuật, cần có AI để làm việc mà không muốn đọc hướng dẫn dòng lệnh. Thành công với họ: chạy 1 file → bấm "tiếp" vài lần → mở 9Router/OpenClaw là dùng được.
- **Người dùng phụ — IT / người hỗ trợ**: dùng để dựng nhanh một máy mới, hoặc gỡ cài khi máy không dùng nữa.

## Giải pháp

Một file `.bat` duy nhất — **AI Tools Installer** — chạy được ngay trên Windows 10/11 có kết nối internet, không cần cài bất kỳ phần mềm nào trước đó.
- **Từng bước có dẫn dắt**: giao diện console có màu sắc, logo, tiếng Việt; người dùng chỉ bấm phím để đi tiếp — không cần hiểu dòng lệnh.
- **Tự phát hiện & kiểm tra phiên bản**: quét trên máy xem từng công cụ trong bộ stack (Node.js, Python, VSCode + extension Claude Code, OpenClaw, 9Router) đã có chưa; so với phiên bản mới nhất rồi quyết định: cài mới / bỏ qua / cập nhật.
- **Cài tự động**: tải bộ cài chính thức từ nguồn tin cậy, cài đặt âm thầm (silent) Node, Python, VSCode, cài OpenClaw và 9Router qua npm, cài extension Claude Code cho VSCode (`anthropic.claude-code`) — rồi báo cáo kết quả cuối cùng rõ ràng.
- **Tự tạo combo 9Router `my-combo`**: DeepSeek v4 Flash với chuỗi fallback gồm 3 nhà cung cấp: OpenCode Free (`oc/deepseek-v4-flash-free`) → OpenRouter (`openrouter/deepseek-v4-flash`) → DeepSeek (`ds/deepseek-v4-flash`) — đúng cấu hình đang dùng trên máy tham chiếu.
- **Cấu hình lần đầu**: sau khi cài, dẫn dắt người dùng mở dashboard 9Router và OpenClaw, đăng ký cả hai khởi động cùng Windows, và hướng dẫn nhập API key cho các kết nối (OpenRouter/DeepSeek).
- **Gỡ cài an toàn**: ghi lại những gì tool đã cài và hỗ trợ gỡ chúng sạch sẽ.
- **Tự cập nhật**: kiểm tra phiên bản mới của chính tool từ repo GitHub của nó (`giakhanhquoc141-rgb/AI_AGENT_INSTALL`); nếu có bản mới thì tải về và thay thế chính nó.

## Điều làm nên khác biệt

- Không phải trình quản lý gói tổng quát (winget, Chocolatey, Scoop) — vốn yêu cầu dòng lệnh và kiến thức kỹ thuật; đây là wizard 1-file chuyên cho bộ AI stack, dùng được bởi người không chuyên.
- **Đi từ cài xong đến dùng được**: không dừng ở "đã cài", mà có sẵn combo `my-combo` + hướng dẫn cấu hình để người dùng mở lên là chạy.
- **An toàn và có thể thu hồi**: lưu manifest để gỡ cài sạch, tự cập nhật chính nó — không cài đè, không hạ cấp.
- Miễn phí.

## Tiêu chí thành công

- **≥90% phiên chạy hoàn tất trọn bộ 6 mục (Node.js, Python, VSCode, extension Claude Code, OpenClaw, 9Router) mà không cần hỗ trợ thêm** — thước đo chính.
- Người dùng không cần quyền admin, không gặp popup UAC.
- Mọi tool đều được kiểm tra phiên bản trước khi quyết định cài: không cài đè, không hạ cấp.
- Combo 9Router `my-combo` được tạo và có ít nhất một kết nối hoạt động sau bước cấu hình lần đầu.
- Gỡ cài sạch những gì tool đã cài (không để lại rác nhìn thấy được).
- Tool tự nhận biết phiên bản mới của chính nó từ GitHub và cho phép cập nhật.

## Phạm vi

**Trong v1:**
- Cài đặt: Node.js, Python, VSCode, extension Claude Code, OpenClaw, 9Router
- Tự phát hiện + kiểm tra phiên bản; quyết định cài mới / bỏ qua / cập nhật
- Tạo combo 9Router `my-combo` (DeepSeek v4 Flash: OpenCode Free → OpenRouter → DeepSeek)
- Cấu hình lần đầu: dashboard 9Router/OpenClaw, khởi động cùng Windows, nhập API key
- Gỡ cài những gì tool đã cài; tự cập nhật tool qua GitHub
- Giao diện tiếng Việt

**Ngoài v1:**
- Không phải trình quản lý gói tổng quát; không cài tool ngoài danh sách.
- Không nắm giữ API key của người dùng (key do người dùng nhập trong bước cấu hình).
- Không tự cập nhật ngầm các tool đã cài (người dùng chạy lại tool để cập nhật).

## Tầm nhìn

Trở thành cách chuẩn để biến một máy Windows thành "môi trường AI sẵn sàng làm việc". Trong 2-3 năm: bộ stack mở rộng theo hệ sinh thái AI mới, có chế độ cập nhật tự động cho các tool, bản offline/portable cho máy không có mạng, và có thể là phiên bản cho macOS. Mỗi máy Windows mới chỉ cách một cú chạy file — và người dùng không cần biết dòng lệnh.
