---
name: AI Tools Installer CMD
status: draft
updated: 2026-08-27
colors:
  canvas: '#090b0d'
  panel: '#202124'
  panel-raised: '#11151a'
  text: '#d7dde5'
  text-muted: '#77808b'
  accent: '#51d6e8'
  accent-strong: '#63dc86'
  warning: '#f2c66d'
  danger: '#ff7d89'
  border: '#263548'
typography:
  ui: 'Consolas, Cascadia Mono, Courier New, monospace'
rounded:
  sm: 8px
  md: 14px
  lg: 20px
spacing:
  unit: 8px
components:
  primary-button: '{colors.accent-strong}'
  focus-ring: '{colors.accent}'
---

## Brand & Style

Tool thuần CMD trên Windows. HTML chỉ mô phỏng cửa sổ Command Prompt; mọi nội dung, lựa chọn và trạng thái phải chuyển được nguyên vẹn về batch script.

## Colors

Màu xanh bạc hà biểu thị hành động an toàn/hoàn tất; vàng cho cảnh báo có thể tiếp tục; đỏ chỉ dùng khi lỗi chặn luồng.

## Typography

Segoe UI và font hệ thống để gần trải nghiệm Windows, ưu tiên tiếng Việt dễ đọc.

## Layout & Spacing

Một vùng terminal duy nhất. Không sidebar, card, wizard chrome hoặc điều khiển chuột dành riêng cho GUI.

## Elevation & Depth

Phân lớp bằng màu nền và viền; bóng nhẹ chỉ dành cho cửa sổ wizard.

## Shapes

Bo góc vừa phải, không dùng pill cho các khối nội dung lớn.

## Components

Dòng lựa chọn `[✓]`, con trỏ `>` với nền tô sáng, phím ↑/↓–Space–Enter, bảng monospace, xác nhận C/H, thanh tiến trình ASCII và báo cáo cuối.

## Do's and Don'ts

| Do | Don't |
|---|---|
| Giải thích tool sẽ làm gì trước khi thực hiện | Ẩn dependency tự động |
| Cho quay lại sửa lựa chọn | Bắt đầu tải ngay khi chọn |
| Phân biệt cài mới, cập nhật, giữ nguyên | Chỉ hiển thị một thanh tiến trình chung chung |
