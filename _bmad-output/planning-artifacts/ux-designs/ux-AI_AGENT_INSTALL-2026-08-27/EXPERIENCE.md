---
name: AI Tools Installer CMD
status: draft
updated: 2026-08-27
sources:
  - npx bmad-method install official flow
  - AI_Tools_Installer.bat current behavior
---

# AI Tools Installer — Experience Spine

## Foundation

Prototype của tool thuần CMD trên Windows, tiếng Việt. HTML chỉ mô phỏng terminal và không thực thi cài đặt thật.

## Information Architecture

| Bề mặt | Mục đích |
|---|---|
| Chào mừng | Hiện logo, phiên bản, kiểm tra cập nhật và ENTER để bắt đầu |
| Thành phần | Mũi tên lên/xuống di chuyển; Space bật/tắt; Enter xác nhận |
| Kiểm tra máy | Nhận diện phiên bản hiện tại và phiên bản đề xuất |
| Xem lại | Phân loại cài mới/cập nhật/giữ nguyên, xác nhận rõ ràng |
| Tiến trình | Theo dõi từng thành phần, tải xuống, cài và xác minh |
| Hoàn tất | Báo kết quả, vị trí log/manifest và bước tiếp theo |

## Voice and Tone

Ngắn, bình tĩnh, nói rõ hậu quả. Ví dụ: “Node.js được chọn tự động vì OpenClaw cần npm.”

## Component Patterns

| Thành phần | Quy tắc |
|---|---|
| Prompt CMD | Chỉ nhận các phím được liệt kê ngay trên màn hình |
| Tool row | Hiển thị `[✓]`/`[ ]`; dòng hiện tại có con trỏ `>` và nền tương phản |
| Plan row | Luôn có hành động, phiên bản hiện tại, phiên bản đích |
| Progress row | Trạng thái chờ/đang làm/xong/lỗi; lỗi có nút thử lại |
| Confirmation | Nút chính chỉ bật khi kế hoạch hợp lệ |

## State Patterns

Cold start, đang quét, offline nhưng tiếp tục được, dependency tự chọn, không có thay đổi, đang tải, thử lại 1/3, lỗi chặn, thành công một phần, hoàn tất và cần khởi động lại ứng dụng.

## Interaction Primitives

Bàn phím là tương tác chính: mũi tên lên/xuống để di chuyển, Space để bật/tắt, Enter để xác nhận; C/H và R cho các bước sau. Nhấp chuột trong HTML chỉ là tiện ích xem trước.

## Accessibility Floor

WCAG 2.2 AA, focus ring rõ, không dùng màu làm tín hiệu duy nhất, vùng bấm tối thiểu 44px, trạng thái tiến trình có văn bản và `aria-live`.

## Responsive & Platform

Ưu tiên cửa sổ desktop từ 900px. Dưới 760px, stepper chuyển thành thanh ngang rút gọn và nội dung xếp một cột.

## Key Flows

### Cài mới — Minh thiết lập máy Windows mới

1. Minh mở wizard và chọn “Cài đặt công cụ”.
2. Minh chọn OpenClaw và 9Router; Node.js được thêm tự động với giải thích.
3. Wizard quét phiên bản đã có.
4. Minh xem bảng kế hoạch, sửa lựa chọn nếu cần.
5. **Climax:** Minh bấm “Bắt đầu cài đặt” khi biết chính xác mục nào cài mới, cập nhật hay giữ nguyên.
6. Tiến trình xác minh từng công cụ; màn hình hoàn tất đưa ra bước tiếp theo.

### Khôi phục lỗi mạng — Minh mất kết nối khi tải Python

1. Python báo lần tải 1/3 thất bại.
2. Các công cụ đã hoàn tất vẫn được giữ nguyên.
3. Minh bấm thử lại riêng Python.
4. **Climax:** tiến trình tiếp tục từ thành phần lỗi, không chạy lại toàn bộ.
