---
title: "PRD: AI Tools Installer"
status: final
created: 2026-08-14
updated: 2026-08-15
---

# PRD: AI Tools Installer
*Bản nháp Fast-path — dựa trên brief đã duyệt (`brief-AI_AGENT_INSTALL-2026-08-14`). Bộ stack gồm 7 mục (thêm **Git** theo yêu cầu người dùng 2026-08-15). Các `[ASSUMPTION]` được đánh dấu inline và tập hợp ở §12.*

## 0. Document Purpose

PRD này phục vụ các bước downstream (UX, Architecture, Epics & Stories, Build) và PM/developer của AI Tools Installer. Cấu trúc: từ vựng chuẩn ở Glossary (§3), feature nhóm theo **8 vùng** với FR đánh số toàn cục (FR-1…FR-N), giả định đánh dấu inline và chỉ mục ở §12. PRD xây dựng trên brief sản phẩm đã duyệt (mở rộng stack từ 6 lên 7 mục với Git) và addendum kỹ thuật (`prd-AI_AGENT_INSTALL-2026-08-14/addendum.md`) — không lặp lại chúng.

## 1. Vision

AI Tools Installer là một file `.bat` duy nhất biến một máy Windows mới thành "môi trường AI sẵn sàng làm việc" trong khoảng 10–15 phút tùy tốc độ mạng — mà người dùng không cần biết dòng lệnh, không cần quyền admin, không cần mở hàng tá trang tải. Người dùng chạy một file, bấm "tiếp" qua từng bước, và ra về với Git, Node.js, Python, VSCode (kèm extension Claude Code), OpenClaw và 9Router đã cài đúng phiên bản, có sẵn combo `my-combo`, khởi động cùng Windows, và gỡ được sạch khi không dùng nữa.

Về bản chất, nó là *phễu đưa người không chuyên vào hệ sinh thái AI coding 2026* mà không bắt họ học terminal. Về lâu dài (v2+), nó là cách chuẩn để "lên môi trường AI" trên Windows — mở rộng stack theo hệ sinh thái, hỗ trợ offline/portable, và có mặt trên macOS.

## 2. Target User

### 2.1 Jobs To Be Done

- **Dân văn phòng (người dùng chính):** "Khi máy mới được bàn giao, tôi cần có AI để làm việc — nhưng tôi không muốn đọc hướng dẫn dòng lệnh, không muốn chờ IT, và không muốn làm hỏng máy."
- **Người dùng chính — tình cảm:** cảm giác *làm được việc công nghệ mà không cần là dân kỹ thuật*; không sợ "cài nhầm thứ gì đó".
- **IT / người hỗ trợ (người dùng phụ):** "Tôi cần dựng nhanh một máy mới chuẩn, và gỡ sạch khi máy không dùng nữa."
- **Chức năng, theo ngữ cảnh:** chạy trên máy Windows 10/11 có internet; không có quyền admin.

### 2.2 Non-Users (v1)

- **Dev nâng cao** thích tự cài, kiểm soát từng bước bằng tay — không cần wizard. *(Được người dùng xác nhận.)*
- IT cần **cài đặt hàng loạt tự động** (silent fleet automation) không người tương tác — v1 là tương tác từng máy.
- Máy không có mạng / macOS / Linux (xem §8, §9.2).

### 2.3 Key User Journeys

- **UJ-1. Lan nhận máy mới và "có AI" trong một buổi sáng.**
  - **Persona + context:** Lan, nhân viên kế toán văn phòng, nhận laptop mới cài Windows 11 nguyên bản, không có gì. Cô nghe IT nói "chạy file này là xong".
  - **Entry state:** chưa đăng nhập vào bất kỳ dịch vụ nào của bộ stack; máy mới tinh, có internet.
  - **Path:** (1) chạy `AI_Tools_Installer.bat`; (2) thấy logo + câu chào tiếng Việt, bấm phím; (3) tool quét máy → hiện kế hoạch "sẽ cài 7 mục"; (4) cô bấm đồng ý; (5) từng bước cài chạy, mỗi bước hiện ✓/✗; (6) bước cấu hình lần đầu dẫn cô mở dashboard 9Router và hoàn tất OpenClaw, hướng dẫn nhập key; (7) màn kết thúc tóm tắt "Đã cài xong 7/7 — log tại …".
  - **Climax:** cô thấy dòng "Đã cài xong 7/7, không cần quyền admin" — mở VSCode thấy extension Claude Code, mở 9Router thấy combo `my-combo`.
  - **Resolution:** mọi thứ khởi động cùng Windows; lần sau mở máy là có AI. Edge case: nếu giữa chừng mạng chập, tool báo rõ bước lỗi và "chạy lại là tiếp tục".

- **UJ-2. Lan chạy lại sau vài tháng để cập nhật.**
  - **Persona + context:** Lan đã dùng được 3 tháng; bạn đồng nghiệp bảo "bản 9Router mới hơn rồi".
  - **Entry state:** máy đã có đủ stack, có bản cũ.
  - **Path:** chạy lại file → tool quét → kế hoạch "9Router 0.5.50 → 0.5.55 (cập nhật), Node 24 LTS → mới nhất (bỏ qua)" → cô bấm đồng ý → cập nhật đúng các mục cũ → báo cáo.
  - **Climax:** cô thấy "2/7 mục cập nhật, 5/7 đã mới nhất" — không bị hỏi những thứ cô không hiểu.
  - **Resolution:** các tool mới hơn, mọi thứ vẫn chạy. Edge case: bản mới gây lỗi → tool giữ bản cũ + log, người dùng có thể chạy lại bản cũ *(xem OQ-4)*.

- **UJ-3. IT gỡ sạch AI tools khi máy chuyển cho người khác.**
  - **Persona + context:** Tuấn, IT, cần thu hồi laptop đã cài stack và bàn giao lại — phải sạch.
  - **Entry state:** máy có manifest của tool.
  - **Path:** chạy file → chọn chế độ "Gỡ cài" → tool đọc manifest → liệt kê những gì nó đã cài → Tuấn xác nhận → gỡ từng mục (npm uninstall -g, xóa thư mục + PATH cho ZIP/MinGit, bộ gỡ cho Python/VSCode, xóa autostart shortcut) → báo cáo.
  - **Climax:** thông báo "Đã gỡ 7/7" và không còn mục nào tự chạy khi mở máy.
  - **Resolution:** máy sạch; manifest được cập nhật. Edge case: nếu người dùng tự cài thêm app khác thì tool không đụng vào.

## 3. Glossary

- **AI Tools Installer** — bản thân sản phẩm: một file `.bat` duy nhất.
- **Bộ stack** — nhóm 7 mục cài: Git, Node.js, Python, VSCode, extension Claude Code, OpenClaw, 9Router.
- **Phiên chạy** — một lần chạy tool từ lúc khởi động đến khi kết thúc (thành công hoặc lỗi).
- **Per-user install** — cài đặt trong phạm vi người dùng, không cần admin/UAC, chỉ ghi vào `%LOCALAPPDATA%` và PATH người dùng.
- **Silent install** — cài đặt âm thầm (không hiện cửa sổ wizard của bộ cài).
- **Manifest** — file cục bộ ghi những gì tool đã cài (mục, phiên bản, thời điểm); nền tảng của chức năng gỡ cài.
- **Combo** — trong 9Router: nhóm model với chuỗi fallback; ở đây là `my-combo` (DeepSeek v4 Flash: OpenCode Free → OpenRouter → DeepSeek).
- **Khởi động cùng Windows** — đăng ký để chạy tự động khi người dùng đăng nhập.
- **Cập nhật ngầm** — tự cập nhật nền không cần người dùng hành động (không thuộc v1).

## 4. Features

### 4.1 Giao diện & dẫn dắt (wizard)

**Description:** Console có logo ASCII/ANSI, màu sắc, giao diện tiếng Việt, và dẫn dắt người dùng qua từng bước bằng phím bấm. Realizes UJ-1, UJ-2.

**Functional Requirements:**

#### FR-1: Chào mừng và định danh
Khi khởi động, **AI Tools Installer** hiển thị logo (ASCII, 11 dòng, màu cam/trắng), tên, phiên bản, khẩu hiệu và lời giới thiệu một dòng bằng tiếng Việt.

**Consequences (testable):**
- Logo render đủ 11 dòng, không vỡ cột trên console mặc định.
- Không cần thao tác nào ở bước này; phím bất kỳ để tiếp tục.

#### FR-2: Điều hướng từng bước
**Người dùng** (không rành kỹ thuật) có thể tiến qua mọi bước bằng một phím; mỗi bước có tiêu đề rõ, trạng thái (đang chạy / đã xong / lỗi) và hướng dẫn hành động.

**Consequences (testable):**
- Mọi thao tác đều qua phím đơn (không cần gõ lệnh).
- Người dùng luôn biết đang ở bước X/Y, bước đó làm gì, và còn bao nhiêu bước.
- Người dùng có thể dừng/hủy an toàn bất cứ lúc nào (dừng giữa chừng không làm hỏng máy).
- Bước lỗi hiển thị rõ "✗" + dòng mô tả + hành động gợi ý.
- Người dùng không rành kỹ thuật, chưa từng mở cmd, hoàn tất phiên cài mà không cần trợ giúp ngoài hướng dẫn trên màn hình (đo trong beta-test).

#### FR-3: Tóm tắt kế hoạch và xác nhận
Trước khi thay đổi máy, **AI Tools Installer** hiển thị kế hoạch đầy đủ (mỗi mục: cài mới / bỏ qua / cập nhật, kèm phiên bản) và yêu cầu **người dùng** xác nhận bằng phím (Y/N).

**Consequences (testable):**
- Không có thay đổi nào trên máy trước khi xác nhận.
- Kế hoạch liệt kê đủ 7 mục, không bỏ sót mục đang cần cập nhật.

#### FR-4: Ngôn ngữ
Toàn bộ giao diện và thông báo của **AI Tools Installer** bằng tiếng Việt (mã hóa UTF-8, `chcp 65001`), không dùng biệt ngữ kỹ thuật.

**Consequences (testable):**
- Không có chuỗi tiếng Anh hiện cho người dùng cuối.
- Tiếng Việt hiển thị đúng (không loạn ký tự) trên Win10/Win11.

### 4.2 Phát hiện & kiểm tra phiên bản

**Description:** Tool quét máy, xác định mục nào đã cài và phiên bản, so với phiên bản mới nhất (nguồn chính thức) rồi quyết định cài mới / bỏ qua / cập nhật. Realizes UJ-1, UJ-2.

**Functional Requirements:**

#### FR-5: Phát hiện trạng thái cài đặt
**AI Tools Installer** xác định từng mục trong bộ stack (Git, Node.js, Python, VSCode, extension Claude Code, OpenClaw, 9Router) đã cài hay chưa, **không bị đánh lừa bởi** các cạm bẫy: Python Store-stub (WindowsApps) và portable node của OpenClaw trên PATH.

**Consequences (testable):**
- Máy chỉ có stub Python (WindowsApps) → tool báo Python "chưa cài".
- `where node` trúng portable node của OpenClaw → tool không kết luận nhầm "đã cài Node chính thức".

#### FR-6: So phiên bản và quyết định
Với mỗi mục đã cài, **AI Tools Installer** so phiên bản hiện tại với phiên bản mới nhất (nguồn chính thức của từng mục) và trả về đúng một trong ba: cài mới / bỏ qua / cập nhật. Với Node, "mới nhất" = LTS mới nhất hợp lệ (xem FR-8).

**Consequences (testable):**
- So sánh đúng định dạng từng mục (Node `v` đầu câu, VSCode dòng 1 của `code --version`, OpenClaw kiểu lịch `2026.7.1-2`, Git `git version 2.x.windows.1`, Python/9Router sạch).
- Mỗi mục luôn trả về đúng 1 trong 3 trạng thái; không trạng thái nào mơ hồ.

#### FR-7: Không hạ cấp
**AI Tools Installer** không bao giờ cài đè xuống phiên bản thấp hơn phiên bản hiện có.

**Consequences (testable):**
- Nếu bản hiện có ≥ bản mới nhất → trạng thái "bỏ qua", không cài đè.

#### FR-8: Chọn phiên bản Node tương thích OpenClaw
**AI Tools Installer** cài Node **LTS 22.x hoặc 24.x** (khoảng engine OpenClaw `>=22.22.3 <23 || >=24.15 <25 || >=25.9`), không bao giờ chọn Node "Current" (26.x). `[ASSUMPTION A1]`

**Consequences (testable):**
- Bản Node được chọn thuộc dòng LTS 22.x/24.x.
- Sau khi cài, `openclaw --version` chạy được (không vỡ do Node không tương thích).

### 4.3 Cài đặt

**Description:** Tải bộ cài chính thức và cài silent, per-user, không admin. Realizes UJ-1, UJ-2.

**Functional Requirements:**

#### FR-9: Tải từ nguồn chính thức
**AI Tools Installer** tải mọi bộ cài / gói từ nguồn chính thức: git-scm.com/git-for-windows, nodejs.org, python.org, update.code.visualstudio.com, npm registry — không từ nguồn bên thứ ba.

**Consequences (testable):**
- Mọi URL tải đều trỏ về domain chính thức của từng sản phẩm.
- Tải lỗi/gián đoạn được báo rõ và không làm hỏng các mục khác.

#### FR-10: Cài per-user, không admin
**AI Tools Installer** cài mọi mục trong phạm vi người dùng; không cần UAC/admin.

**Consequences (testable):**
- Toàn bộ phiên chạy không xuất hiện lời nhắc UAC.
- Không ghi vào `%ProgramFiles%` hay registry HKLM (trừ mục do chính bộ cài bắt buộc và được xác minh là per-user).

#### FR-11: Cài Node per-user
**AI Tools Installer** cài Node per-user (giải nén ZIP chính thức vào `%LOCALAPPDATA%\node` hoặc `msiexec /a` giải nén payload) và thêm vào PATH người dùng không làm tràn/truncate. `[ASSUMPTION A6 — chọn cơ chế ở addendum, xác minh build]`

**Consequences (testable):**
- `node --version` và `npm --version` chạy được sau khi mở console mới.
- PATH người dùng không bị cắt (>1024 ký tự) sau khi thêm.

#### FR-12: Cài Python silent per-user
**AI Tools Installer** cài Python bản stable hiện tại (3.13.x) bằng bộ cài chính thức silent, per-user, `Include_launcher=0` để không cần admin.

**Consequences (testable):**
- Python cài vào `%LOCALAPPDATA%\Programs\Python`, không yêu cầu admin.
- `python --version` chạy được từ console mới; stub Store không còn cản trở.

#### FR-13: Cài VSCode user setup silent
**AI Tools Installer** cài VSCode bản User Setup silent (`/VERYSILENT /NORESTART /MERGETASKS=!runcode`).

**Consequences (testable):**
- VSCode cài vào `%LOCALAPPDATA%\Programs\Microsoft VS Code`, không admin.
- Không tự mở cửa sổ VSCode sau khi cài.

#### FR-14: Cài Git per-user silent
**AI Tools Installer** cài Git for Windows theo cách per-user, silent, không admin — dùng **MinGit** làm mặc định. `[ASSUMPTION A9 — cơ chế/cờ chính xác ở addendum, xác minh build]`

**Consequences (testable):**
- `git --version` chạy được từ console mới.
- Git nằm trong phạm vi người dùng (không `%ProgramFiles%`), không yêu cầu admin, không UAC.

#### FR-15: Cài OpenClaw và 9Router qua npm
**AI Tools Installer** cài OpenClaw (`openclaw@latest`) và 9Router (`9router`) bằng npm global, xử lý đúng chính sách lifecycle scripts của npm (không để npm chặn script của OpenClaw).

**Consequences (testable):**
- `openclaw --version` và `9router --version` chạy được từ console mới.
- Cài đặt không bị chặn bởi policy lifecycle scripts (npm 11/12).

#### FR-16: Cài extension Claude Code
**AI Tools Installer** cài extension `anthropic.claude-code` cho VSCode bằng CLI, đảm bảo PATH đã refresh trước khi gọi.

**Consequences (testable):**
- `code --list-extensions` có `anthropic.claude-code`.
- Lệnh trả về exit code 0.

#### FR-17: Refresh môi trường trong phiên
**AI Tools Installer** cập nhật/refresh PATH trong cùng phiên để bước sau nhìn thấy công cụ vừa cài (không cần mở console mới giữa chừng).

**Consequences (testable):**
- Sau khi cài Node, bước npm cài OpenClaw/9Router chạy được ngay trong cùng phiên.

### 4.4 Tạo combo 9Router `my-combo`

**Description:** Tự tạo combo đúng cấu hình máy tham chiếu. Realizes UJ-1.

**Functional Requirements:**

#### FR-18: Tạo combo my-combo
**AI Tools Installer** tạo combo 9Router tên `my-combo` (model `deepseek-v4-flash`, fallback: `oc/deepseek-v4-flash-free` → `openrouter/deepseek-v4-flash` → `ds/deepseek-v4-flash`) nếu chưa tồn tại; không tạo trùng lặp.

**Consequences (testable):**
- Sau khi chạy, 9Router có đúng 1 combo `my-combo` với 3 model theo đúng thứ tự fallback.
- Chạy lại → không tạo ra combo trùng.

#### FR-19: Không đụng API key
**AI Tools Installer** không đọc, ghi, lưu, hay truyền API key của người dùng.

**Consequences (testable):**
- Không có key trong manifest, log, hoặc bất kỳ file nào tool tạo ra.
- Bước cấu hình chỉ dẫn người dùng tự nhập key vào dashboard 9Router.

### 4.5 Cấu hình lần đầu

**Description:** Sau khi cài, tool dẫn dắt để người dùng có bộ stack "dùng được ngay": khởi động cùng Windows, nhập key, và hoàn tất onboarding OpenClaw — không cần gõ lệnh. Realizes UJ-1.

**Functional Requirements:**

#### FR-20: Đăng ký khởi động cùng Windows
**AI Tools Installer** đăng ký **9Router** (Run key HKCU → `9router.cmd --no-browser --skip-update`) và **OpenClaw** (cơ chế autostart chính thức của gateway — `openclaw gateway install`) chạy cùng Windows. `[ASSUMPTION A2 — cơ chế chính xác xác minh build; addendum §Autostart]`

**Consequences (testable):**
- Sau đăng nhập lại Windows, `9router` và gateway OpenClaw tự chạy mà không cần người dùng.
- Không có cửa sổ console hiện ra gây khó chịu (wrapper ẩn khi cần).

#### FR-21: Hướng dẫn hoàn tất setup lần đầu (API key + onboarding OpenClaw)
**AI Tools Installer** dẫn **người dùng** hoàn tất setup lần đầu bằng tiếng Việt: (a) nhập API key tại dashboard 9Router (OpenCode Free thường chạy không cần key; OpenRouter/DeepSeek cần key); (b) hoàn tất **onboarding OpenClaw** ngay trong tool (chạy `openclaw onboard` guided / mở giao diện) — người dùng không phải gõ lệnh thủ công.

**Consequences (testable):**
- Người dùng hoàn tất ≥1 kết nối hoạt động trong dashboard 9Router sau khi được hướng dẫn.
- OpenClaw có tài khoản/model được cấu hình mà người dùng không cần gõ lệnh.
- Hướng dẫn không yêu cầu nhập key vào tool.

#### FR-22: Mở dashboard
**AI Tools Installer** mở dashboard 9Router (`http://localhost:20128`) và giao diện OpenClaw để người dùng hoàn tất cấu hình.

**Consequences (testable):**
- Dashboard mở được trên trình duyệt mặc định; gateway đang chạy.

### 4.6 Gỡ cài

**Description:** Gỡ sạch những gì tool đã cài, dựa trên manifest. Realizes UJ-3.

**Functional Requirements:**

#### FR-23: Ghi manifest
**AI Tools Installer** ghi manifest cục bộ (mỗi mục: tên, phiên bản, thời điểm cài) tại vị trí ổn định **`%LOCALAPPDATA%\AITools\manifest.txt`** và cập nhật sau mỗi phiên thay đổi máy.

**Consequences (testable):**
- Sau khi cài, manifest liệt kê đủ các mục đã cài + phiên bản.
- Sau khi gỡ, manifest được cập nhật.

#### FR-24: Gỡ cài theo manifest
**AI Tools Installer** gỡ các mục có trong manifest: OpenClaw/9Router qua `npm uninstall -g`; **Node và Git** (cài dạng ZIP/MinGit) bằng cách **xóa thư mục cài + gỡ entry PATH người dùng**; **Python/VSCode** qua bộ gỡ tương ứng; xóa các đăng ký autostart do tool tạo; không đụng mục không phải do tool cài.

**Consequences (testable):**
- Sau gỡ, không còn shortcut/đăng ký autostart của tool.
- `git --version` / `openclaw --version` / `9router --version` / `code --version` không còn; Node/Git/Python gỡ khỏi PATH người dùng (phần tool thêm).

### 4.7 Tự cập nhật tool

**Description:** Tool kiểm tra và cập nhật chính nó từ repo GitHub. Realizes UJ-2 (ở tầng tool).

**Functional Requirements:**

#### FR-25: Kiểm tra phiên bản mới của chính tool
**AI Tools Installer** so phiên bản hiện tại của nó với bản mới nhất trong repo GitHub `giakhanhquoc141-rgb/AI_AGENT_INSTALL` (Releases API hoặc file version).

**Consequences (testable):**
- Nếu có bản mới, tool báo rõ số phiên bản hiện tại và mới.
- Không tự tải khi người dùng chưa đồng ý.

#### FR-26: Thay thế chính nó
Khi **người dùng** đồng ý, **AI Tools Installer** tải bản `.bat` mới và tự thay thế (xử lý an toàn file đang chạy — tải về file tạm, thay thế ở lần khởi động kế tiếp hoặc qua rename). `[ASSUMPTION A7]`

**Consequences (testable):**
- Sau khi thay thế, lần chạy sau là bản mới (đúng phiên bản).
- Bản cũ không bị hỏng dở giữa chừng; nếu tải lỗi, giữ nguyên bản cũ + báo lỗi.

### 4.8 Log & báo cáo

**Description:** Minh bạch kết quả, phục vụ chẩn đoán khi ~10% phiên gặp lỗi. Realizes UJ-1, UJ-2, UJ-3.

**Functional Requirements:**

#### FR-27: Log cục bộ
**AI Tools Installer** ghi log kết quả từng bước (thành công/lỗi, phiên bản, đường dẫn, thời điểm) vào **`%LOCALAPPDATA%\AITools\logs\`**; **không gửi dữ liệu đi đâu**.

**Consequences (testable):**
- Sau mỗi phiên, log có nội dung đầy đủ các bước.
- Không có request mạng nào từ tool ngoài việc tải bộ cài, tra cứu phiên bản và kiểm tra update đã được khai báo.

#### FR-28: Báo cáo cuối
Kết thúc phiên, **AI Tools Installer** hiển thị tóm tắt (số mục thành công/lỗi, đường dẫn log) để người dùng biết nếu cần gửi log cho hỗ trợ.

**Consequences (testable):**
- Màn kết thúc luôn hiển thị: X/Y thành công, các mục lỗi (nếu có), vị trí log.

## 5. Cross-Cutting NFRs

- **NFR-SEC-1 — Nguồn tin cậy:** Mọi tải về chỉ từ nguồn chính thức; không nhúng/đọc credential của người dùng.
- **NFR-SEC-2 — Riêng tư:** Không telemetry; không thu thập dữ liệu ngoài log cục bộ.
- **NFR-REL-1 — Độ tin cậy:** Tải có retry; lỗi một mục không làm hỏng các mục khác; chạy lại an toàn (idempotent — không cài đè/hạ cấp).
- **NFR-REL-2 — Hiện lỗi thân thiện:** Mọi lỗi hiển thị ở mức người không chuyên hiểu được (mô tả tiếng Việt + hành động tiếp theo), không để lộ mã lỗi thô; log đầy đủ để chẩn đoán khi cần hỗ trợ.
- **NFR-COMP-1 — Tương thích:** Chạy trên Windows 10 (1803+) và Windows 11; UTF-8.
- **NFR-PERF-1 — Hiệu năng (mềm):** Phiên cài mới hoàn tất trong ~10–15 phút tùy tốc độ mạng. `[ASSUMPTION A3]`
- **NFR-OBS-1 — Quan sát:** Log đủ chi tiết để chẩn đoán lỗi mà không cần chạy lại nhiều lần.

## 6. Constraints and Guardrails

- **Riêng tư:** Không telemetry; log cục bộ; không bao giờ lưu/đọc API key (xem NFR-SEC-2, FR-19).
- **Bảo mật:** Chỉ tải từ nguồn chính thức; chạy không cần admin (giảm bề mặt tấn công); tự cập nhật chỉ từ repo chính thức của tool (xem NFR-SEC-1, FR-9, FR-25).
- **Phân phối (v1):** File `.bat` chưa ký — chấp nhận cảnh báo SmartScreen; README hướng dẫn "More info → Run anyway"; phát hành qua GitHub release kèm **SHA256** để xác minh. *(Quyết định v1.)*
- **Chi phí:** Miễn phí; không có hạ tầng thu thập dữ liệu.

## 7. Aesthetic and Tone

- **Tham chiếu thị giác:** Console tối mặc định của Windows; logo ASCII/ANSI ngôi sao (màu cam `38;5;214`) + chữ trắng đậm + khẩu hiệu xám mờ (xem brief addendum — logo). Lấy cảm hứng trình cài đặt `npx bmad-method install`.
- **Phản tham chiếu:** Console nhàm chán toàn chữ trắng; màn hình dày đặc biệt ngữ; cửa sổ wizard của bộ cài mặc định.
- **Giọng văn:** tiếng Việt thân thiện, khích lệ, không biệt ngữ; "bấm phím bất kỳ để tiếp tục", "Đã cài xong 7/7 🎉" (emoji hạn chế). Tin cậy hơn là "ngầu": mỗi bước đều báo đang làm gì.
- **Thuộc tính UX (bắt buộc, testable — được FR-2 hậu thuẫn):** người dùng luôn biết — đang ở bước nào (X/Y), bước đó làm gì, còn bao nhiêu bước, và có thể dừng/hủy an toàn bất cứ lúc nào. Chuẩn trải nghiệm trình cài `npx bmad-method install`.

## 8. Non-Goals (Explicit)

- Không phải trình quản lý gói tổng quát (winget/Chocolatey/Scoop); không cài tool ngoài danh sách.
- Không nắm giữ/lưu trữ API key (xem FR-19).
- Không tự cập nhật ngầm nền các tool — người dùng chạy lại tool để cập nhật (xem §9.2).
- Không phục vụ dev nâng cao tự cài tay; không phục vụ IT fleet silent automation (xem §2.2).
- Không cài Node "Current" — chỉ LTS 22.x/24.x tương thích OpenClaw (xem FR-8).
- Không telemetry tự động (xem NFR-SEC-2, §6).
- Không ký code signature trong v1 — chấp nhận SmartScreen + hướng dẫn "More info → Run anyway" (xem §6).
- Không hỗ trợ offline / máy không mạng và macOS trong v1 (xem §9.2 — lên lịch v2).
- Không phải công cụ "hướng dẫn dùng AI" (không dạy prompt, không cấu hình model ngoài combo có sẵn).

## 9. MVP Scope

### 9.1 In Scope

- Cài đặt: Git (MinGit), Node.js (LTS 22/24), Python (3.13 stable), VSCode, extension Claude Code, OpenClaw, 9Router — tất cả per-user, không admin.
- Tự phát hiện + kiểm tra phiên bản; quyết định cài mới / bỏ qua / cập nhật; không hạ cấp.
- Tạo combo 9Router `my-combo` (DeepSeek v4 Flash: OpenCode Free → OpenRouter → DeepSeek).
- Cấu hình lần đầu: dashboard 9Router/OpenClaw, onboarding OpenClaw, khởi động cùng Windows, hướng dẫn nhập key.
- Gỡ cài theo manifest; tự cập nhật tool qua GitHub.
- Giao diện tiếng Việt; log cục bộ; báo cáo cuối.
- Windows 10 (1803+)/11 có internet. `[ASSUMPTION A8]`

### 9.2 Out of Scope for MVP

- Hỗ trợ offline/portable (lên lịch v2). `[NOTE FOR PM: dân văn phòng có thể có máy "không cho mạng" — cân nhắc v2.]`
- Bản macOS (lên lịch v2).
- Fleet silent automation cho IT.
- Telemetry/hạ tầng đo lường (không cần — log cục bộ).
- Tự cập nhật nền cho các tool (lên lịch v2).
- Đa ngôn ngữ (chỉ tiếng Việt v1). `[ASSUMPTION A4]`

## 10. Success Metrics

**Primary**
- **SM-1**: ≥90% phiên chạy hoàn tất trọn bộ 7 mục (Git, Node.js, Python, VSCode, extension Claude Code, OpenClaw, 9Router) không cần hỗ trợ. **Ước lượng** từ log cục bộ (người dùng/IT gửi khi gặp lỗi) + số issue hỗ trợ trên GitHub. Validates FR-9–17, FR-27–28. *(Không telemetry — con số là ước lượng. `[ASSUMPTION A5]`)*
- **SM-2**: 0 lời nhắc UAC/admin trong mọi phiên. Validates FR-10–16.

**Secondary**
- **SM-3**: 100% quyết định phiên bản đúng — không cài đè, không hạ cấp, không báo nhầm "chưa cài". Validates FR-5–8.
- **SM-4**: Sau cấu hình lần đầu, combo `my-combo` có ≥1 kết nối hoạt động. Validates FR-18, FR-21–22. ⚠️ Phụ thuộc free-tier OpenCode Free (một số free-tier đã ngừng trong 2026) — nếu `oc/` ngừng, đo theo kết nối OpenRouter/DeepSeek.
- **SM-5**: Gỡ cài sạch — sau gỡ, không còn autostart/manifest lộn xộn, các lệnh `--version` không còn. Validates FR-20, FR-23–24.
- **SM-6**: Khi có bản mới, tool phát hiện và cập nhật thành công theo yêu cầu người dùng — tỉ lệ thành công ≥95% trong test. Validates FR-25–26.

**Counter-metrics (do not optimize)**
- **SM-C1**: Không tối ưu thời gian cài (NFR-PERF) bằng cách bỏ kiểm tra phiên bản hoặc bỏ retry — độ tin cậy (SM-1) quan trọng hơn tốc độ. Counterbalances SM-1/NFR-PERF.
- **SM-C2**: Không thêm telemetry để "đo chính xác" SM-1 — vi phạm cam kết riêng tư (NFR-SEC-2). Counterbalances SM-1.

## 11. Open Questions

- **OQ-1**: Kênh hỗ trợ chính thức khi người dùng gặp lỗi? *(Giả định: GitHub Issues trên repo — cần tạo template issue "gửi log".)*
- **OQ-2**: Quy trình kiểm chứng SM-1 trước khi phát hành? *(Giả định: test nội bộ trên ~10 máy thật, gom log thủ công.)*
- **OQ-3**: Cơ chế cài Node: ZIP giải nén vs `msiexec /a`? *(Quyết định kỹ thuật — addendum §Node; build xác minh chọn 1.)*
- **OQ-5**: Cách gom log khi người dùng không rành kỹ thuật gửi hỗ trợ (tự copy file? nút tạo zip?) — cần quyết định khi xây UX.
- **OQ-6**: Cờ silent per-user của Git for Windows (Inno Setup) — đã xác minh khuyến nghị **MinGit**; xác nhận cuối khi build. `[ASSUMPTION A9]`

**Quyết định đã chốt trong run này (giữ để lưu context — không phải câu hỏi mở):**
- **OQ-4** *(đã chốt)*: Không có chế độ quay về bản cũ riêng trong v1 — cập nhật lỗi giữ bản cũ + log (FR-26); người dùng có thể chạy lại bản cũ.
- **SmartScreen** *(đã chốt)*: chấp nhận cảnh báo + hướng dẫn "More info → Run anyway" + SHA256 (xem §6).

## 12. Assumptions Index

- **[A1]** (§4.2/FR-8) Node: cài LTS 22.x/24.x trong khoảng tương thích OpenClaw, không phải Current. — *Từ nghiên cứu engine OpenClaw.*
- **[A2]** (§4.5/FR-20) Cơ chế autostart 9Router (Run key → `9router.cmd --no-browser --skip-update`) và OpenClaw (gateway install/scheduled task) — xác minh build.
- **[A3]** (§5/NFR-PERF) Phiên cài mới ~10–15 phút tùy mạng.
- **[A4]** (§9.2) Chỉ tiếng Việt trong v1.
- **[A5]** (§10/SM-1) Đo lường 90% qua log cục bộ + issue, không telemetry — con số ước lượng.
- **[A6]** (§4.3/FR-11) Chọn cơ chế cài Node (ZIP vs msiexec /a) — addendum.
- **[A7]** (§4.7/FR-26) Cơ chế thay thế file .bat đang chạy — tải bản tạm + thay ở lần khởi động kế tiếp.
- **[A8]** (§9.1) Người dùng có internet; không phải phòng cấm mạng.
- **[A9]** (§4.3/FR-14, OQ-6) Git: dùng **MinGit** (per-user chắc chắn, không admin/UAC) làm mặc định; bộ cài full silent chỉ đảm bảo per-user trên tài khoản standard. — *Từ nghiên cứu Inno Setup + thử nghiệm thực tế (installer Git tự elevate khi tài khoản là admin).*
