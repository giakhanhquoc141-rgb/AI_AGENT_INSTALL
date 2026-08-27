# AI Tools Installer — Context triển khai

## Mẫu giao diện chuẩn

Prototype tại `_bmad-output/planning-artifacts/ux-designs/ux-AI_AGENT_INSTALL-2026-08-27/.working/installer-wizard-preview.html` là mẫu tham chiếu bắt buộc khi xây dựng và chỉnh sửa `AI_Tools_Installer.bat`.

- Tool thực tế là ứng dụng thuần CMD trên Windows.
- Thứ tự màn hình, nội dung lời nhắc, phím điều khiển, trạng thái lựa chọn, bảng kế hoạch, tiến trình và báo cáo phải bám theo prototype.
- `DESIGN.md` quy định cách hiển thị; `EXPERIENCE.md` quy định hành vi. Hai tài liệu này có quyền ưu tiên cao hơn chi tiết minh họa trong HTML nếu có xung đột.
- Prototype chỉ mô phỏng giao diện; không được dùng nó để thực thi tải xuống, cài đặt, sửa PATH, registry hoặc filesystem.

## Quy tắc kiểm soát thay đổi

Khi một yêu cầu làm thêm, bớt hoặc thay đổi tính năng có thể ảnh hưởng đến giao diện hay hành trình CMD:

1. Phải nói rõ phần nào của mẫu giao diện có thể bị ảnh hưởng.
2. Phải hỏi người dùng có muốn cập nhật prototype và tài liệu UX tương ứng hay không.
3. Chỉ cập nhật mẫu giao diện sau khi người dùng xác nhận.
4. Nếu người dùng không muốn cập nhật mẫu, phải giữ nguyên hợp đồng giao diện hiện tại và nêu rõ cách tính năng mới tuân thủ hợp đồng đó.

Không được tự ý để implementation và mẫu giao diện lệch nhau.
