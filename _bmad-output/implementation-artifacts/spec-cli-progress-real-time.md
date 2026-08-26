---
title: 'Tiến độ CLI thời gian thực và màu sắc ổn định'
type: 'bugfix'
created: '2026-08-26'
status: 'done'
review_loop_iteration: 0
baseline_commit: '23e6abaa1641d86d946a044f71a77be87db28c07'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** File BAT có dòng LF xen giữa CRLF khiến `cmd.exe` cắt sai lệnh và báo `'GAN' is not recognized`. Các trạng thái quét, tải và cài đặt chưa phản ánh tiến độ thật nên người dùng không biết công cụ còn hoạt động hay đã treo.

**Approach:** Chuẩn hóa BAT thành CRLF, hiển thị tiến độ dựa trên số mục đã quét hoặc số byte đã tải, đồng thời dùng màu và hoạt ảnh thật trong các khoảng chờ mạng/cài đặt.

## Boundaries & Constraints

**Always:** Giữ công cụ là một file BAT tự chứa; tương thích Windows `cmd.exe` và PowerShell có sẵn; tiến độ tải phải lấy từ số byte thực; quét phải thể hiện đủ 7 mục; lỗi mạng phải thử lại và thoát an toàn; bảo toàn thay đổi hiện có ngoài phạm vi.

**Ask First:** Dừng tiến trình VirtualBox hoặc ứng dụng khác đang giữ khóa file chính; thay đổi nền tảng phân phối ngoài GitHub Releases.

**Never:** In phần trăm giả theo bộ đếm thời gian; che toàn bộ đầu ra của npm; ghi đè trực tiếp file đang chạy; đưa thông tin xác thực vào mã hoặc log; xóa thay đổi không liên quan.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Quét bình thường | Chạy công cụ | 7 mốc từ 14% đến 100%, con quay khi gọi mạng, kết quả từng ứng dụng | Nguồn lỗi được thử tối đa 3 lần rồi tiếp tục an toàn |
| Tải có kích thước | Máy chủ trả `Content-Length` | Thanh 0–100%, MiB đã tải/tổng, màu cyan và hoàn tất màu xanh | Xóa file tải dở và thử lại |
| Tải không có kích thước | Không có `Content-Length` | Con quay và MiB thực đã nhận | Giữ cơ chế thử lại như trên |
| Chờ trình cài | VS Code/Python đang chạy im lặng | Con quay và số giây đã chờ thay đổi liên tục | Trả đúng exit code của trình cài |
| Checkout/biên tập BAT | Git hoặc trình sửa file xử lý xuống dòng | Mọi dòng BAT là CRLF | `.gitattributes` ép `eol=crlf` |

</frozen-after-approval>

## Code Map

- `AI_Tools_Installer.bat` -- router, helper giao diện, quét phiên bản, tải xuống, cài đặt và self-update.
- `.gitattributes` -- bất biến CRLF cho `.bat`/`.cmd`, ngăn tái phát lỗi parser.
- `_bmad-output/scratch/story-2-2-self-replace-harness.ps1` -- kiểm tra tĩnh luồng thay thế an toàn; cần chấp nhận helper tải streaming mới.

## Tasks & Acceptance

**Execution:**
- [x] `AI_Tools_Installer.bat` -- thêm helper tải streaming, tiến độ quét, hoạt ảnh chờ cài và màu trạng thái; giữ nguyên cơ chế rollback/self-update.
- [x] `.gitattributes` -- ép CRLF cho script Windows.
- [x] `_bmad-output/scratch/story-2-2-self-replace-harness.ps1` -- cập nhật nhận diện phương thức tải chính thức mới.
- [x] `_bmad-output/scratch/story-ui-progress-harness.ps1` -- bảo vệ tiến độ thật, hoạt ảnh, màu sắc và bất biến CRLF.
- [x] `_bmad-output/scratch/story-ui-progress-runtime-harness.ps1` -- chạy tải cục bộ có độ dài, chunked và retry khi bị cắt.
- [x] `_bmad-output/scratch/test-vscode-installer.ps1` và `test-python-installer.ps1` -- cập nhật hợp đồng kiểm thử cho argument array, helper tải và retry xác minh mới.

**Acceptance Criteria:**
- Given file BAT đã checkout, when kiểm tra byte xuống dòng, then không có LF đứng một mình.
- Given quét máy bình thường, when hoàn tất, then có đúng 7 mốc tiến độ và không có lỗi parser/`not recognized`.
- Given tải asset phát hành, when luồng dữ liệu được nhận, then phần trăm và số MiB tăng theo byte thực rồi kết thúc 100%.
- Given toàn bộ harness hồi quy, when chạy trên artifact mới, then tất cả đều thoát mã 0.

## Spec Change Log

## Design Notes

PowerShell ghi trạng thái quét lên stderr để `for /f` vẫn dành stdout cho dữ liệu máy đọc. Ký tự carriage return dùng `[char]13` thay vì chuỗi PowerShell nháy đơn để hoạt ảnh ghi đè đúng một dòng.

## Verification

**Commands:**
- Chạy `--update` trên bản mới -- mong đợi nhận diện đang ở bản mới nhất, không có lỗi nhãn lệnh.
- Chạy luồng quét rồi chọn `H` -- mong đợi 7 mốc, hoạt ảnh mạng và hủy không thay đổi máy.
- Chạy 10 harness trong `_bmad-output/scratch` trên bản mới -- mong đợi 10/10 đạt.
- Đếm CRLF/LF bằng byte -- mong đợi `LONE_LF=0`.

**Kết quả đã quan sát:**
- `--update`: exit 0, nhận diện 0.3.0 là bản mới nhất.
- Quét rồi hủy: 7 mốc 14–100%, 60 khung hoạt ảnh, 6 nguồn mạng hoàn tất, không có lỗi parser.
- Hồi quy cuối: 10/10 harness đạt; kiểm thử tải cục bộ đạt với `Content-Length`, chunked, dữ liệu bị cắt rồi retry; wait loop VS Code/Python đạt với exit 0 và exit 7.
- Hai kiểm thử installer kế thừa (`test-vscode-installer.ps1`, `test-python-installer.ps1`) đều đạt sau khi cập nhật hợp đồng cú pháp.

## Suggested Review Order

**Luồng tiến độ chính**

- Helper streaming dùng byte thật, timeout, heartbeat và phát hiện tải bị cắt.
  [`AI_Tools_Installer.bat:88`](../../AI_Tools_Installer.bat#L88)

- Quét chỉ tăng phần trăm sau khi từng ứng dụng hoàn tất.
  [`AI_Tools_Installer.bat:274`](../../AI_Tools_Installer.bat#L274)

- Hủy kế hoạch thoát sạch, không in báo cáo thành công giả.
  [`AI_Tools_Installer.bat:239`](../../AI_Tools_Installer.bat#L239)

**Cài đặt và cập nhật**

- VS Code chờ có timeout và tô màu theo exit code thật.
  [`AI_Tools_Installer.bat:815`](../../AI_Tools_Installer.bat#L815)

- Python áp dụng cùng hợp đồng chờ và rollback hiện có.
  [`AI_Tools_Installer.bat:969`](../../AI_Tools_Installer.bat#L969)

- Self-update tái sử dụng helper tải nhưng giữ thay thế trì hoãn an toàn.
  [`AI_Tools_Installer.bat:1481`](../../AI_Tools_Installer.bat#L1481)

**Bảo vệ hồi quy**

- Runtime test chạy fixed-length, chunked, truncated retry và exit code trình cài.
  [`story-ui-progress-runtime-harness.ps1:64`](../scratch/story-ui-progress-runtime-harness.ps1#L64)

- Static contract kiểm tra đường gọi helper và định dạng file BAT.
  [`story-ui-progress-harness.ps1:12`](../scratch/story-ui-progress-harness.ps1#L12)

- Git buộc script Windows checkout bằng CRLF.
  [`.gitattributes:1`](../../.gitattributes#L1)
