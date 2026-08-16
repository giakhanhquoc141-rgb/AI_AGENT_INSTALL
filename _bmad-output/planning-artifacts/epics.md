---
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
  - step-03-create-stories
  - step-04-final-validation
inputDocuments:
  - prds/prd-AI_AGENT_INSTALL-2026-08-14/prd.md
  - prds/prd-AI_AGENT_INSTALL-2026-08-14/addendum.md
  - architecture/architecture-AI_AGENT_INSTALL-2026-08-15/ARCHITECTURE-SPINE.md
---

# AI Tools Installer - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for AI Tools Installer, decomposing the requirements from the PRD, UX Design if it exists, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

- **FR-1** — Chào mừng và định danh: hiển thị logo (ASCII, 11 dòng, cam/trắng), tên, phiên bản, khẩu hiệu, giới thiệu 1 dòng tiếng Việt; phím bất kỳ để tiếp tục.
- **FR-2** — Điều hướng từng bước: mọi thao tác qua phím đơn; luôn biết bước X/Y, bước đang làm gì, còn bao nhiêu bước; dừng/hủy an toàn; bước lỗi hiển thị "✗" + mô tả + hành động gợi ý.
- **FR-3** — Tóm tắt kế hoạch + xác nhận: hiển thị kế hoạch đầy đủ (mỗi mục: cài mới/bỏ qua/cập nhật + phiên bản); xác nhận Y/N; không thay đổi máy trước xác nhận.
- **FR-4** — Ngôn ngữ: toàn bộ UI/notification tiếng Việt, UTF-8 (`chcp 65001`), không biệt ngữ kỹ thuật.
- **FR-5** — Phát hiện trạng thái cài đặt: xác định từng mục trong 7 mục đã cài hay chưa, không bị đánh lừa bởi Python Store-stub (`WindowsApps`) và portable node của OpenClaw trên PATH.
- **FR-6** — So phiên bản và quyết định: mỗi mục đã cài so với "mới nhất" (nguồn chính thức) → đúng 1 trong 3: cài mới / bỏ qua / cập nhật; Node "mới nhất" = LTS.
- **FR-7** — Không hạ cấp: không bao giờ cài đè xuống phiên bản thấp hơn hiện có.
- **FR-8** — Chọn Node tương thích OpenClaw: cài LTS 22.x/24.x (engine `>=22.22.3 <23 || >=24.15 <25 || >=25.9`), không bao giờ Current 26.x. `[ASSUMPTION A1]`
- **FR-9** — Tải từ nguồn chính thức: mọi bộ cài/gói từ git-scm.com, nodejs.org, python.org, update.code.visualstudio.com, npm registry; lỗi/gián đoạn được báo rõ và không làm hỏng mục khác.
- **FR-10** — Cài per-user, không admin: mọi mục trong phạm vi người dùng; không UAC/admin; không ghi `%ProgramFiles%` hay HKLM (trừ mục bộ cài bắt buộc và đã xác minh per-user).
- **FR-11** — Cài Node per-user: ZIP vào `%LOCALAPPDATA%\node` hoặc `msiexec /a` giải nén payload; thêm PATH không tràn/truncate (>1024 ký tự). `[ASSUMPTION A6]`
- **FR-12** — Cài Python silent per-user: bản stable 3.13.x, `Include_launcher=0` (không admin), `%LOCALAPPDATA%\Programs\Python`.
- **FR-13** — Cài VSCode User Setup silent: `/VERYSILENT /NORESTART /MERGETASKS=!runcode`, không tự mở VSCode.
- **FR-14** — Cài Git per-user silent: **MinGit** mặc định (không UAC kể cả tài khoản admin). `[ASSUMPTION A9]`
- **FR-15** — Cài OpenClaw (`openclaw@latest`) và 9Router qua npm global; xử lý đúng lifecycle-scripts policy (npm 11/12, `--allow-scripts openclaw`).
- **FR-16** — Cài extension Claude Code: `anthropic.claude-code` qua CLI VSCode, PATH refresh trước khi gọi; exit code 0.
- **FR-17** — Refresh môi trường trong phiên: PATH được refresh để bước sau thấy tool vừa cài ngay trong cùng phiên.
- **FR-18** — Tạo combo `my-combo`: model `deepseek-v4-flash`, fallback `oc/deepseek-v4-flash-free` → `openrouter/deepseek-v4-flash` → `ds/deepseek-v4-flash`; không tạo trùng lặp.
- **FR-19** — Không đụng API key: không đọc/ghi/lưu/truyền key; bước cấu hình chỉ dẫn người dùng tự nhập key vào dashboard 9Router.
- **FR-20** — Đăng ký khởi động cùng Windows: 9Router (Run key HKCU → `9router.cmd --no-browser --skip-update`) + OpenClaw (`openclaw gateway install`); không cửa sổ console gây khó chịu. `[ASSUMPTION A2]`
- **FR-21** — Hướng dẫn hoàn tất setup lần đầu: nhập API key tại dashboard 9Router + onboarding OpenClaw ngay trong tool (không gõ lệnh tay).
- **FR-22** — Mở dashboard: mở 9Router `localhost:20128` và giao diện OpenClaw trên trình duyệt mặc định.
- **FR-23** — Ghi manifest: `%LOCALAPPDATA%\AITools\manifest.txt` (tên, phiên bản, thời điểm cài), cập nhật sau mỗi phiên thay đổi máy.
- **FR-24** — Gỡ cài theo manifest: OpenClaw/9Router qua `npm uninstall -g`; Node/Git xóa thư mục + entry PATH; Python/VSCode qua bộ gỡ; xóa autostart do tool tạo; không đụng mục không phải tool cài.
- **FR-25** — Kiểm tra bản mới của tool: so với repo GitHub `giakhanhquoc141-rgb/AI_AGENT_INSTALL` (Releases API); báo rõ version hiện tại/mới; không tự tải khi chưa đồng ý.
- **FR-26** — Tự thay thế: tải `.bat` mới, thay thế an toàn file đang chạy (file tạm + rename ở lần khởi động kế tiếp); tải lỗi giữ nguyên bản cũ. `[ASSUMPTION A7]`
- **FR-27** — Log cục bộ: ghi kết quả từng bước vào `%LOCALAPPDATA%\AITools\logs\`; không gửi dữ liệu đi đâu.
- **FR-28** — Báo cáo cuối: tóm tắt X/Y thành công, các mục lỗi (nếu có), vị trí log.

### NonFunctional Requirements

- **NFR-SEC-1** — Nguồn tin cậy: mọi tải về chỉ từ nguồn chính thức; không nhúng/đọc credential của người dùng.
- **NFR-SEC-2** — Riêng tư: không telemetry; không thu thập dữ liệu ngoài log cục bộ.
- **NFR-REL-1** — Độ tin cậy: tải có retry; lỗi một mục không làm hỏng các mục khác; chạy lại an toàn (idempotent — không cài đè/hạ cấp).
- **NFR-REL-2** — Hiện lỗi thân thiện: mọi lỗi hiển thị ở mức người không chuyên hiểu (tiếng Việt + hành động tiếp theo), không lộ mã lỗi thô; log đầy đủ để chẩn đoán.
- **NFR-COMP-1** — Tương thích: Windows 10 (1803+) và Windows 11; UTF-8.
- **NFR-PERF-1** — Hiệu năng (mềm): phiên cài mới hoàn tất ~10–15 phút tùy tốc độ mạng. `[ASSUMPTION A3]`
- **NFR-OBS-1** — Quan sát: log đủ chi tiết để chẩn đoán lỗi mà không cần chạy lại nhiều lần.

### Additional Requirements

Các ràng buộc kỹ thuật từ **Architecture Spine** (13 ADs, `ARCHITECTURE-SPINE.md`):

- **AD-1** — Phased pipeline + mode router (install / uninstall / self-update); thứ tự pha cố định welcome → scan → plan+confirm → execute → configure → report; policy lỗi cấp pipeline (ghi nhận + chạy tiếp, chạy lại chỉ retry phần chưa xong); thứ tự execute topo (Node trước npm-items, VSCode trước extension); hủy an toàn bất cứ lúc nào.
- **AD-2** — Hybrid runtime: batch điều phối + console UI; PowerShell lo mọi mạng/JSON/so-version.
- **AD-3** — Một file `.bat` duy nhất: mọi helper/PS block/UI/manifest/update inline, không file phụ trợ.
- **AD-4** — No-admin/per-user là gate cứng: mọi ghi trong `%LOCALAPPDATA%`, HKCU, user PATH; zero HKLM/`%ProgramFiles%`/UAC; nền tảng Windows 10/11 **64-bit**.
- **AD-5** — Manifest là nguồn sự thật của gỡ cài: schema chính xác 4 trường `item | version | installed-at-YYYY-MM-DD | path`; version là chuỗi đã chuẩn hóa (AD-6); uninstall chỉ gỡ những gì manifest ghi; xóa manifest + logs khi gỡ xong.
- **AD-6** — Mô hình quyết định từng mục: mỗi mục trả về đúng 1 trong `INSTALL/SKIP/UPDATE` + version chuẩn hóa; một version-check helper dùng chung là nguồn duy nhất tạo chuỗi version; không hạ cấp; lọc Store-stub Python và portable-node của OpenClaw.
- **AD-7** — Nguồn chính thức + tải đã xác minh: URL chỉ tới domain chính thức; self-update chỉ từ repo tool; retry có giới hạn (3 lần); xác minh SHA256 nơi nguồn cung cấp hash; 404/trống = "không có bản mới".
- **AD-8** — Không đụng API key + không telemetry: không đọc/ghi/lưu/truyền key; không outbound không khai báo.
- **AD-9** — Hợp đồng bước: exit 0/nonzero; mỗi bước 1 dòng log (`step | ok|fail|skip | version | path | timestamp`); lỗi hiển thị tiếng Việt mức người không chuyên; mã lỗi thô chỉ vào log.
- **AD-10** — PATH một-controller: read → append-if-absent → write, giữ `REG_EXPAND_SZ`; không `setx`; refresh PATH trong phiên; đọc lại từ registry.
- **AD-11** — UTF-8 + tiếng Việt: `chcp 65001`; không chuỗi tiếng Anh cho người dùng cuối.
- **AD-12** — Idempotency: chạy lại an toàn; không cài đè/hạ cấp/trùng combo/trùng autostart; run-state ghi một lần ở scan, read-only sau đó.
- **AD-13** — Autostart artifact ghi manifest: mọi artifact autostart (Run key/.lnk 9Router, gateway OpenClaw) ghi kind + tên chính xác + target; uninstall gỡ đúng tập đã ghi.
- **Structural seed** — Layout các block trong file (init, helpers, router, scan, plan, execute, configure, uninstall, self-update, report); chiều phụ thuộc presentation → pipeline → helpers → (official sources | manifest | logs); cổng cố định 9Router `localhost:20128`, OpenClaw gateway `127.0.0.1:18789`.
- **Stack (seed)** — Runtime in-box (cmd.exe, PowerShell 5.1, curl/tar/certutil/reg); stack cài: Node LTS 22/24, Python 3.13.x, VSCode User Setup, Git MinGit, OpenClaw npm latest, 9Router npm latest, extension `anthropic.claude-code`.

### UX Design Requirements

Không có UX design contract riêng (bước `bmad-ux` đã bỏ qua). Yêu cầu UX được kế thừa từ **PRD §7 Aesthetic & Tone** (console tối, logo ASCII/ANSI 11 dòng cam `38;5;214` + trắng đậm + khẩu hiệu xám, giọng văn tiếng Việt thân thiện khích lệ, emoji hạn chế, mỗi bước báo đang làm gì) và các AD presentation trong spine (**AD-1** presentation boundary, **AD-9** step contract, **AD-11** UTF-8/tiếng Việt). Khi cần chi tiết visual bổ sung, xử lý như Deferred của Architecture (visual polish ở tầng UX/build).

### FR Coverage Map

- **FR-1**: Epic 1 — Wizard: chào mừng & định danh
- **FR-2**: Epic 1 — Điều hướng từng bước
- **FR-3**: Epic 1 — Kế hoạch + xác nhận
- **FR-4**: Epic 1 — Ngôn ngữ tiếng Việt (UTF-8)
- **FR-5**: Epic 1 — Phát hiện trạng thái cài đặt
- **FR-6**: Epic 1 — So phiên bản & quyết định
- **FR-7**: Epic 1 — Không hạ cấp
- **FR-8**: Epic 1 — Node LTS 22/24 tương thích OpenClaw
- **FR-9**: Epic 1 — Tải từ nguồn chính thức
- **FR-10**: Epic 1 — Cài per-user, không admin
- **FR-11**: Epic 1 — Cài Node per-user
- **FR-12**: Epic 1 — Cài Python silent per-user
- **FR-13**: Epic 1 — Cài VSCode User Setup silent
- **FR-14**: Epic 1 — Cài Git per-user (MinGit)
- **FR-15**: Epic 1 — Cài OpenClaw + 9Router qua npm
- **FR-16**: Epic 1 — Cài extension Claude Code
- **FR-17**: Epic 1 — Refresh môi trường trong phiên
- **FR-18**: Epic 1 — Tạo combo `my-combo`
- **FR-19**: Epic 1 — Không đụng API key
- **FR-20**: Epic 1 — Đăng ký khởi động cùng Windows
- **FR-21**: Epic 1 — Hướng dẫn setup lần đầu
- **FR-22**: Epic 1 — Mở dashboard
- **FR-23**: Epic 3 — Ghi manifest *(ghi trong Epic 1 theo AD-5; sở hữu chính — schema + lifecycle — ở Epic 3)*
- **FR-24**: Epic 3 — Gỡ cài theo manifest
- **FR-25**: Epic 2 — Kiểm tra bản mới của chính tool
- **FR-26**: Epic 2 — Tự thay thế an toàn
- **FR-27**: Epic 1 — Log cục bộ (nền tảng; tái dùng bởi Epic 2/3)
- **FR-28**: Epic 1 — Báo cáo cuối (tái dùng bởi Epic 2/3)

## Epic List

### Epic 1: Cài đặt AI tools trong một lần chạy
Người dùng chạy một file `.bat`, đi qua wizard tiếng Việt từng bước; tool tự phát hiện + so phiên bản, cài bộ stack 7 mục per-user không cần admin, tạo combo `my-combo`, dẫn cấu hình lần đầu và đăng ký khởi động cùng Windows — xong là "có AI" dùng được.
**FRs covered:** FR-1, FR-2, FR-3, FR-4, FR-5, FR-6, FR-7, FR-8, FR-9, FR-10, FR-11, FR-12, FR-13, FR-14, FR-15, FR-16, FR-17, FR-18, FR-19, FR-20, FR-21, FR-22, FR-27, FR-28

### Epic 2: Tự cập nhật an toàn
Tool biết khi nào có bản mới của chính nó, báo người dùng, và thay thế file đang chạy một cách an toàn (không hỏng dở; tải lỗi giữ bản cũ).
**FRs covered:** FR-25, FR-26

### Epic 3: Gỡ cài sạch sẽ
Người dùng/IT gỡ đúng những gì tool đã cài (dựa trên manifest + autostart đã ghi), không đụng các ứng dụng khác, và máy trở về sạch.
**FRs covered:** FR-23, FR-24

---

## Epic 1: Cài đặt AI tools trong một lần chạy

Người dùng chạy một file `.bat`, đi qua wizard tiếng Việt từng bước; tool tự phát hiện + so phiên bản, cài bộ stack 7 mục per-user không cần admin, tạo combo `my-combo`, dẫn cấu hình lần đầu và đăng ký khởi động cùng Windows — xong là "có AI" dùng được.

### Story 1.1: Khởi tạo tool & wizard chào mừng

As a người dùng không rành kỹ thuật,
I want chạy một file duy nhất và thấy màn chào mừng tiếng Việt rõ ràng,
So that tôi biết tool hoạt động và tự tin bấm tiếp.

**Acceptance Criteria:**

**Given** tôi chạy `AI_Tools_Installer.bat` trên Windows 10/11 mới tinh
**When** tool khởi động
**Then** hiển thị logo ASCII đủ 11 dòng, tên, phiên bản, khẩu hiệu và giới thiệu 1 dòng bằng tiếng Việt, không vỡ cột trên console mặc định
**And** console chạy `chcp 65001` — tiếng Việt hiển thị đúng, không loạn ký tự

**Given** màn chào mừng đang hiển thị
**When** tôi bấm phím bất kỳ
**Then** tool sang bước tiếp theo mà không cần gõ lệnh

**Given** tool khởi động
**When** kiểm tra nội bộ
**Then** khung sườn đã có: helpers (in màu, `log_append`, khung step-contract), sườn router với nhánh install hoạt động và nhánh uninstall/self-update hiện thông báo "chưa hỗ trợ" rồi thoát an toàn
**And** không có chuỗi tiếng Anh nào hiện ra cho người dùng cuối

*(FR-1, FR-4; AD-1, AD-3, AD-9, AD-11)*

### Story 1.2: Quét & quyết định phiên bản 7 mục

As a người dùng có máy có thể đã có vài tool,
I want tool biết chính xác cái gì đã cài và cần làm gì,
So that tôi không bị cài lại hoặc hạ cấp những gì đã có.

**Acceptance Criteria:**

**Given** máy chỉ có stub Python (WindowsApps)
**When** tool quét Python
**Then** tool báo Python "chưa cài" (không bị stub đánh lừa)

**Given** `where node` trúng portable node của OpenClaw trên PATH
**When** tool quét Node
**Then** tool không kết luận nhầm "đã cài Node chính thức"

**Given** mỗi mục trong 7 mục đã được quét
**When** tool so phiên bản hiện tại với bản mới nhất (nguồn chính thức)
**Then** mỗi mục trả về đúng 1 trong 3 trạng thái `INSTALL/SKIP/UPDATE` — không trạng thái nào mơ hồ

**Given** phiên bản hiện có ≥ phiên bản mới nhất
**When** tool quyết định
**Then** trạng thái là SKIP, không bao giờ cài đè xuống bản thấp hơn

**Given** Node đang cần cài
**When** tool chọn phiên bản
**Then** chọn Node LTS 22.x/24.x trong khoảng tương thích OpenClaw, không bao giờ chọn Current 26.x

**Given** version được đọc từ các lệnh khác nhau (Node có `v` đầu, VSCode 3 dòng, OpenClaw kiểu lịch, Git `windows.P`, Python/9Router sạch)
**When** một helper version-check dùng chung xử lý
**Then** mọi version được chuẩn hóa theo đúng định dạng từng mục và ghi vào manifest/log đúng chuỗi chuẩn hóa đó

*(FR-5, FR-6, FR-7, FR-8; AD-2, AD-6, AD-12)*

### Story 1.3: Kế hoạch cài đặt + xác nhận Y/N

As a người dùng không rành kỹ thuật,
I want thấy rõ kế hoạch trước khi tool đổi bất cứ thứ gì trên máy,
So that tôi có thể xác nhận hoặc dừng lại an toàn.

**Acceptance Criteria:**

**Given** bước scan đã xong
**When** tool hiển thị kế hoạch
**Then** kế hoạch liệt kê đủ 7 mục — mỗi mục: cài mới / bỏ qua / cập nhật kèm phiên bản — không bỏ sót mục cần cập nhật

**Given** kế hoạch đang hiển thị
**When** tôi chưa xác nhận (Y)
**Then** không có thay đổi nào trên máy được thực hiện

**Given** tôi muốn dừng
**When** tôi hủy bất cứ lúc nào trong bước này
**Then** tool thoát an toàn, không làm hỏng máy

**Given** bước này đang chạy
**When** giao diện hiển thị
**Then** tôi luôn biết đang ở bước X/Y, bước làm gì và còn bao nhiêu bước

*(FR-2, FR-3; AD-1, AD-11)*

### Story 1.4: Cài Node per-user + refresh PATH trong phiên

As a người dùng,
I want Node được cài mà không cần quyền admin,
So that tôi không phải đối mặt với UAC và có thể dùng npm ngay.

**Acceptance Criteria:**

**Given** Node chưa cài hoặc cần cập nhật (INSTALL/UPDATE)
**When** tool tải ZIP chính thức từ `nodejs.org` và giải nén vào `%LOCALAPPDATA%\node`
**Then** `node --version` và `npm --version` chạy được ngay trong cùng phiên (PATH đã refresh)

**Given** tool ghi PATH người dùng
**When** PATH-controller ghi entry (giữ kiểu `REG_EXPAND_SZ`, không dùng `setx`)
**Then** PATH người dùng không bị cắt/truncate (>1024 ký tự)

**Given** tải bị lỗi/gián đoạn
**When** tool tải lại
**Then** thực hiện retry tối đa 3 lần, lỗi được báo rõ và không làm hỏng các mục khác

**Given** toàn bộ phiên cài Node
**When** tool thực hiện
**Then** không xuất hiện lời nhắc UAC, không ghi `%ProgramFiles%` hay HKLM

*(FR-9, FR-10, FR-11, FR-17; AD-4, AD-7, AD-10, AD-12)*

### Story 1.5: Cài Git per-user (MinGit)

As a người dùng,
I want Git được cài âm thầm trong phạm vi người dùng,
So that tôi có `git` dùng được mà không cần admin.

**Acceptance Criteria:**

**Given** Git chưa cài hoặc cần cập nhật
**When** tool tải MinGit từ git-for-windows GitHub releases và giải nén vào `%LOCALAPPDATA%\Programs\Git`
**Then** `git --version` chạy được từ console mới

**Given** tài khoản Windows của tôi là admin (UAC on)
**When** tool cài Git
**Then** không có UAC prompt, không cài vào `C:\Program Files\Git` — MinGit đảm bảo per-user

**Given** tool ghi PATH người dùng cho Git
**When** PATH-controller thêm entry `<dir>\cmd`
**Then** entry đúng thư mục cài, không trùng lặp, PATH không bị cắt

*(FR-9, FR-10, FR-14; AD-4, AD-7, AD-10, AD-12)*

### Story 1.6: Cài Python silent per-user

As a người dùng,
I want Python bản stable được cài không cần admin,
So that tôi có thể chạy `python` mà không bị Store-stub làm phiền.

**Acceptance Criteria:**

**Given** Python chưa cài hoặc cần cập nhật
**When** tool tải installer chính thức từ `python.org` (3.13.x) và chạy silent với `InstallAllUsers=0 PrependPath=1 Include_launcher=0 Shortcuts=0`
**Then** Python được cài vào `%LOCALAPPDATA%\Programs\Python\Python313`, không yêu cầu admin

**Given** cài xong
**When** mở console mới
**Then** `python --version` chạy được, stub Store không còn cản trở

**Given** toàn bộ phiên cài Python
**When** tool thực hiện
**Then** không xuất hiện lời nhắc UAC

*(FR-9, FR-10, FR-12; AD-4, AD-7, AD-12)*

### Story 1.7: Cài VSCode User Setup + extension Claude Code

As a người dùng,
I want VSCode và extension Claude Code được cài sẵn,
So that tôi mở VSCode là có AI coding dùng được ngay.

**Acceptance Criteria:**

**Given** VSCode chưa cài
**When** tool tải User Setup từ `update.code.visualstudio.com` và chạy `/VERYSILENT /NORESTART /MERGETASKS=!runcode`
**Then** VSCode cài vào `%LOCALAPPDATA%\Programs\Microsoft VS Code`, không tự mở cửa sổ VSCode sau khi cài

**Given** VSCode vừa cài xong
**When** tool refresh PATH trong phiên rồi gọi `code.cmd --install-extension anthropic.claude-code --force`
**Then** `code --list-extensions` có `anthropic.claude-code` và lệnh trả về exit code 0

**Given** toàn bộ phiên cài VSCode
**When** tool thực hiện
**Then** không xuất hiện lời nhắc UAC, không ghi `%ProgramFiles%`

*(FR-9, FR-10, FR-13, FR-16, FR-17; AD-4, AD-7, AD-12)*

### Story 1.8: Cài OpenClaw + 9Router qua npm

As a người dùng,
I want OpenClaw và 9Router được cài qua npm sau khi có Node,
So that tôi có gateway AI và dashboard dùng được.

**Acceptance Criteria:**

**Given** Node đã cài và PATH đã refresh
**When** tool chạy `npm install -g openclaw@latest --allow-scripts openclaw` và `npm install -g 9router`
**Then** `openclaw --version` và `9router --version` chạy được từ console mới

**Given** npm đời mới có chính sách chặn lifecycle scripts
**When** tool cài OpenClaw
**Then** cài đặt không bị chặn bởi policy (xử lý `--allow-scripts`/flag tương đương đúng npm bản đích)

**Given** toàn bộ phiên cài npm
**When** tool thực hiện
**Then** không xuất hiện lời nhắc UAC

*(FR-9, FR-10, FR-15, FR-17; AD-4, AD-7, AD-12)*

### Story 1.9: Tạo combo my-combo + không đụng API key

As a người dùng,
I want tool tự tạo sẵn combo model dùng được ngay,
So that tôi không phải cấu hình model tay trong 9Router.

**Acceptance Criteria:**

**Given** 9Router đã cài và combo `my-combo` chưa tồn tại
**When** tool tạo combo
**Then** 9Router có đúng 1 combo `my-combo` với model `deepseek-v4-flash` và 3 fallback đúng thứ tự: `oc/deepseek-v4-flash-free` → `openrouter/deepseek-v4-flash` → `ds/deepseek-v4-flash`

**Given** combo `my-combo` đã tồn tại
**When** tool chạy lại
**Then** không tạo ra combo trùng lặp

**Given** tool thao tác với 9Router
**When** toàn bộ phiên chạy
**Then** tool không đọc/ghi/lưu/truyền bất kỳ API key nào; bước cấu hình chỉ hướng dẫn tôi tự nhập key vào dashboard

**Given** phiên đã chạy
**When** kiểm tra các file tool tạo (manifest, log)
**Then** không chứa API key

*(FR-18, FR-19; AD-8, AD-12)*

### Story 1.10: Cấu hình lần đầu — autostart + onboarding + mở dashboard

As a người dùng,
I want 9Router và OpenClaw tự chạy cùng Windows và được dẫn dắt nhập key,
So that lần sau mở máy là "có AI", không cần gõ lệnh.

**Acceptance Criteria:**

**Given** cài xong bộ stack
**When** tool đăng ký khởi động cùng Windows
**Then** 9Router đăng ký Run key HKCU (`9router.cmd --no-browser --skip-update`) và OpenClaw đăng ký qua cơ chế chính thức (`openclaw gateway install`), không tạo cửa sổ console khó chịu khi đăng nhập

**Given** autostart vừa tạo
**When** tool ghi manifest
**Then** mỗi artifact autostart được ghi theo kind + tên chính xác + target (AD-13)

**Given** cấu hình lần đầu
**When** tool dẫn dắt
**Then** tool mở dashboard 9Router `localhost:20128` và giao diện OpenClaw; hướng dẫn tiếng Việt hoàn tất ≥1 kết nối (nhập key trong dashboard) và onboarding OpenClaw mà tôi không phải gõ lệnh

**Given** tôi đăng nhập lại Windows
**When** mở máy
**Then** `9router` và gateway OpenClaw tự chạy mà không cần thao tác

**Given** tool chạy lại
**When** kiểm tra autostart
**Then** không tạo đăng ký trùng lặp

*(FR-20, FR-21, FR-22; AD-12, AD-13, AD-9)*

### Story 1.11: Log cục bộ + báo cáo cuối

As a người dùng,
I want tool ghi lại mọi bước và tóm tắt kết quả cuối,
So that tôi biết cái gì thành công/lỗi và gửi log khi cần hỗ trợ.

**Acceptance Criteria:**

**Given** mỗi bước trong phiên đã chạy
**When** bước hoàn tất (thành công/lỗi)
**Then** ghi đúng 1 dòng log (`step | ok|fail|skip | version | path | timestamp`) vào `%LOCALAPPDATA%\AITools\logs\ai-tools-installer.log`

**Given** bước gặp lỗi
**When** tool hiển thị
**Then** màn hình cho tôi thấy "✗" + mô tả tiếng Việt mức người không chuyên + hành động gợi ý; mã lỗi thô chỉ nằm trong log

**Given** phiên kết thúc
**When** tool hiển thị báo cáo cuối
**Then** luôn hiện: X/Y thành công, các mục lỗi (nếu có), và vị trí log

**Given** toàn bộ phiên
**When** kiểm tra hoạt động mạng
**Then** không có request nào ngoài việc tải bộ cài, tra cứu phiên bản và kiểm tra update đã khai báo

*(FR-27, FR-28; AD-9, AD-8)*

---

## Epic 2: Tự cập nhật an toàn

Tool biết khi nào có bản mới của chính nó, báo người dùng, và thay thế file đang chạy một cách an toàn (không hỏng dở; tải lỗi giữ bản cũ).

### Story 2.1: Kiểm tra bản mới của tool

As a người dùng,
I want tool cho tôi biết khi có phiên bản mới của chính nó,
So that tôi luôn dùng bản cập nhật mà không phải chủ động đi tìm.

**Acceptance Criteria:**

**Given** tool đang chạy và có kết nối mạng
**When** tool so version hiện tại (biến trong .bat) với GitHub Releases API của `giakhanhquoc141-rgb/AI_AGENT_INSTALL` (qua PowerShell)
**Then** nếu có bản mới, tool báo rõ số phiên bản hiện tại và phiên bản mới

**Given** có bản mới
**When** tool chuẩn bị tải
**Then** tool không tự tải khi tôi chưa đồng ý

**Given** repo chưa có release nào (API trả 404/trống)
**When** tool kiểm tra
**Then** tool coi như "đã là bản mới nhất", không crash, không báo lỗi

*(FR-25; AD-2, AD-7)*

### Story 2.2: Tự thay thế file đang chạy an toàn

As a người dùng,
I want tool tự thay thế chính nó bằng bản mới mà không làm hỏng gì,
So that tôi không phải tải lại file thủ công.

**Acceptance Criteria:**

**Given** tôi đồng ý cập nhật
**When** tool tải `.bat` mới về file tạm (`AI_Tools_Installer.new.bat`)
**Then** tool đổi tên bản hiện tại thành `.old`, rồi đưa `.new` về vị trí gốc — ở lần khởi động kế tiếp (hoặc lệnh `cmd /c` trì hoãn), không ghi đè trực tiếp file đang thực thi

**Given** lần chạy sau khi thay thế
**When** tool khởi động
**Then** chạy đúng bản mới (đúng phiên bản)

**Given** tải bản mới gặp lỗi/gián đoạn
**When** tool thay thế
**Then** giữ nguyên bản cũ + báo lỗi rõ ràng, bản cũ không bị hỏng dở giữa chừng

**Given** đã có bản `.old` dự phòng
**When** tool chạy ổn định bản mới
**Then** bản `.old` được dọn đi an toàn

*(FR-26; AD-7, AD-12)*

---

## Epic 3: Gỡ cài sạch sẽ

Người dùng/IT gỡ đúng những gì tool đã cài (dựa trên manifest + autostart đã ghi), không đụng các ứng dụng khác, và máy trở về sạch.

### Story 3.1: Manifest — schema và vòng đời

As a người dùng/IT,
I want tool ghi lại chính xác những gì nó đã cài,
So that việc gỡ cài sau này chỉ đụng đúng những gì do tool cài.

**Acceptance Criteria:**

**Given** tool thay đổi máy (cài/cập nhật/configure)
**When** các bước install/configure thực hiện
**Then** mọi mutation được ghi vào `%LOCALAPPDATA%\AITools\manifest.txt` theo đúng schema 4 trường: `item | version | installed-at-YYYY-MM-DD | path`

**Given** mục autostart được tạo
**When** tool ghi manifest
**Then** mỗi artifact autostart được ghi theo kind + tên chính xác + target (AD-13)

**Given** version được ghi
**When** kiểm tra manifest
**Then** version là chuỗi đã chuẩn hóa từ version-check helper dùng chung (AD-6), không lẫn định dạng thô của từng mục

**Given** phiên gỡ cài hoàn tất
**When** tool kết thúc
**Then** manifest và logs bị xóa sạch, không để lại dữ liệu lộn xộn

**Given** một mục không do tool cài
**When** kiểm tra manifest
**Then** mục đó không xuất hiện — uninstall sẽ không đụng tới

*(FR-23; AD-5, AD-6, AD-13)*

### Story 3.2: Gỡ cài theo manifest

As a người dùng/IT,
I want gỡ sạch những gì tool đã cài bằng một lần chạy,
So that máy trở về trạng thái sạch, không còn tool tự khởi động cùng Windows.

**Acceptance Criteria:**

**Given** tôi chạy tool với chế độ gỡ cài (nhánh `--uninstall` được kích hoạt trong router)
**When** tool đọc manifest
**Then** tool liệt kê những gì nó đã cài và yêu cầu tôi xác nhận trước khi gỡ

**Given** tôi xác nhận gỡ
**When** tool gỡ từng mục theo manifest
**Then** OpenClaw/9Router gỡ qua `npm uninstall -g`; Node/Git xóa thư mục cài + entry PATH (PATH-controller, không dùng `setx`); Python/VSCode qua bộ gỡ tương ứng

**Given** tool gỡ autostart
**When** xử lý các artifact đã ghi (AD-13)
**Then** gỡ đúng các Run key/`.lnk` do tool tạo và đăng ký OpenClaw qua cơ chế chính thức (`openclaw gateway uninstall`), ưu tiên đường gỡ chính thức

**Given** sau khi gỡ
**When** kiểm tra máy
**Then** `git --version`/`openclaw --version`/`9router --version`/`code --version` không còn; PATH người dùng sạch phần tool đã thêm; không còn shortcut/đăng ký autostart của tool; manifest + logs bị xóa

**Given** máy có các ứng dụng không do tool cài
**When** tool gỡ
**Then** không đụng vào bất kỳ mục nào không nằm trong manifest

*(FR-24; AD-5, AD-10, AD-13)*
