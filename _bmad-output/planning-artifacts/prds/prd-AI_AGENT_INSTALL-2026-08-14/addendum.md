# Addendum — PRD AI Tools Installer (Kỹ thuật)

Nội dung kỹ thuật đã **kiểm chứng** 2026-08-15 (nghiên cứu subagent trực tiếp trên npm registry, nodejs.org, python.org, GitHub API, update.code.visualstudio.com, Inno Setup source + máy thật). Dùng cho giai đoạn Architecture/Build. PRD giữ ở tầng năng lực; đây là nơi chứa "how".

## 1. Bản đồ kiểm tra phiên bản

| Mục | Phát hiện đã cài | Phiên bản hiện tại | Nguồn "mới nhất" (chính thức) | Lệnh fetch cho .bat (PowerShell) |
|---|---|---|---|---|
| **Node.js** | `where node` (cẩn thận: có thể trúng portable node của OpenClaw); MSI chính thức tại `C:\Program Files\nodejs\node.exe` | `node --version` → `v26.7.0` (có `v` đầu — strip) | `https://nodejs.org/dist/index.json` — `[0]` = Current; entry đầu có `lts` truthy = LTS | `((Invoke-RestMethod 'https://nodejs.org/dist/index.json') | Where-Object { $_.lts } | Select-Object -First 1).version` → LTS |
| **Python** | `where python` **loại dòng `WindowsApps`** (Store-stub) hoặc registry `HKLM\SOFTWARE\Python\PythonCore\<ver>\InstallPath` | `python --version` → `Python 3.13.2` | `https://www.python.org/api/v2/downloads/release/?is_published=true` — lọc theo **`name`**, không `version` (version là số int bị cắt) | `((Invoke-RestMethod 'https://www.python.org/api/v2/downloads/release/?is_published=true') | Where-Object { $_.name -like 'Python 3.13*' -and -not $_.pre_release } | Sort-Object release_date -Descending | Select-Object -First 1).name` |
| **VSCode** | `where code`; user setup tại `%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd`; system tại `%ProgramFiles%\Microsoft VS Code\bin\code.cmd` | `code --version` → **dòng 1** = `1.133.0` (dòng 2 commit, dòng 3 arch) | GitHub `api.github.com/repos/microsoft/vscode/releases/latest` → `tag_name` (không `v`); hoặc feed `update.code.visualstudio.com/api/releases/stable` `[0]` | `(Invoke-RestMethod 'https://api.github.com/repos/microsoft/vscode/releases/latest').tag_name` |
| **Git** | `where git`; hoặc kiểm tra `cmd\git.exe` trong thư mục cài | `git --version` → `git version 2.55.0.windows.4` | GitHub `api.github.com/repos/git-for-windows/git/releases/latest` → tag `v2.55.0.windows.4` (có `v`; URL tải đổi `vX.Y.Z.windows.P` → `Git-X.Y.Z.P-64-bit.exe`) | `(Invoke-RestMethod 'https://api.github.com/repos/git-for-windows/git/releases/latest').tag_name` |
| **OpenClaw** | `where openclaw` / `npm ls -g openclaw --depth=0` | `openclaw --version` → `OpenClaw 2026.7.1-2 (0790d9f)` — **token 2** | npm dist-tag `latest`: `registry.npmjs.org/-/package/openclaw/dist-tags` (version **kiểu lịch**, không semver — so bằng chuỗi) | `(Invoke-RestMethod 'https://registry.npmjs.org/-/package/openclaw/dist-tags').latest` |
| **9Router** | `where 9router` / `npm ls -g 9router --depth=0` | `9router --version` → `0.5.50` (semver sạch) | npm dist-tag `latest`: `registry.npmjs.org/-/package/9router/dist-tags` | `(Invoke-RestMethod 'https://registry.npmjs.org/-/package/9router/dist-tags').latest` |

*Extension Claude Code: phát hiện qua `code --list-extensions`; phiên bản do VSCode Marketplace quản lý — `--force` cài bản mới nhất, không cần dòng so sánh.*

⚠️ **Node (đã chốt):** baseline cài đặt/cập nhật = **LTS 22.x/24.x**, KHÔNG lấy Current 26.x — ràng buộc engine xem §2 OpenClaw (FR-8).

**Khuyến nghị:** so sánh "mới nhất > hiện tại?" ngay trong cùng lệnh PowerShell — truyền version hiện tại vào làm tham số, trả về `INSTALL/SKIP/UPDATE`. Không thực hiện so sánh phiên bản (version-math) ngay trong batch thuần.

## 2. Lệnh cài đặt silent (đã kiểm chứng)

### Node.js — MSI là per-MACHINE (cần admin) → dùng ZIP
- MSI: `msiexec /i node-vXX-x64.msi /qn /norestart /l*v "%TEMP%\node-install.log"` — **nhưng MSI = per-machine, yêu cầu admin, không per-user được.**
- **Chọn per-user (không admin):** ZIP chính thức → `https://nodejs.org/dist/latest-v22.x/node-v22.x-win-x64.zip` (lưu ý `win-x64`, không phải `-x64`; `-x64.zip` 404). Giải nén vào `%LOCALAPPDATA%\node` (`node.exe`, `npm.cmd`, `npx.cmd` ở gốc). Thêm PATH:
  - `reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "%LOCALAPPDATA%\node;%PATH%" /f` — **không dùng setx** (sẽ cắt chuỗi PATH dài >1024 ký tự).
- Phương án khác: `msiexec /a node.msi TARGETDIR=%LOCALAPPDATA%\node /qn` (giải nén payload, không cần admin) — chọn 1 trong 2, xác minh build (OQ-3).
- npm global prefix mặc định: `%APPDATA%\npm`.

### Python — per-user mặc định, không admin (xác nhận)
```
python-3.13.9-amd64.exe /quiet InstallAllUsers=0 PrependPath=1 Include_test=0 Include_launcher=0 Shortcuts=0 Include_doc=0 TargetDir=%LOCALAPPDATA%\Programs\Python\Python313
```
- `Include_launcher=0` → tắt `py` launcher (cờ đi kèm `InstallLauncherAllUsers` mặc định là 1, cần admin → tắt để giữ no-admin). `Shortcuts=0` → không tạo Start Menu. URL: `https://www.python.org/ftp/python/3.13.9/python-3.13.9-amd64.exe`.
- ⚠️ Bộ cài full bị **deprecated ở Python 3.14** (thay bằng Python Install Manager `py install`) — 3.13 vẫn dùng được, lưu ý tương lai.

### VSCode — User Setup, không admin
```
"VSCodeUserSetup-x64-1.133.0.exe" /VERYSILENT /NORESTART /MERGETASKS=!runcode
```
- URL: `https://update.code.visualstudio.com/latest/win32-x64-user/stable` (segment `-user` = bản per-user). GitHub release **không có** binary assets. `code` CLI nằm tại `%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd` (installer tự thêm user PATH).

### Git for Windows — bộ cài full sẽ ELEVATE khi tài khoản là admin → dùng MinGit
- **Phát hiện quan trọng:** installer Git (Inno Setup, `PrivilegesRequired=none`) hoạt động theo quyền tài khoản:
  - **Tài khoản thường (standard)** → per-user, không UAC: cài `%LOCALAPPDATA%\Programs\Git`, registry HKCU, PATH người dùng. ✅
  - **Tài khoản admin (UAC on)** → tự **ELEVATE (có UAC)** và cài all-users vào `C:\Program Files\Git`, HKLM, PATH hệ thống. ❌ Không có cờ nào ép per-user cho tài khoản admin.
- **Chọn MinGit để chắc chắn không admin/UAC** (đúng mô hình Node→ZIP):
  ```
  URL: https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.4/MinGit-2.55.0.4-64-bit.zip
  ```
  Giải nén vào `%LOCALAPPDATA%\Programs\Git` → có `cmd\git.exe`; thêm `<dir>\cmd` vào user PATH bằng `reg add HKCU\Environment` (không setx). Không installer, không UAC, hoàn toàn per-user.
- Nếu dùng bộ cài full (chỉ khi chắc chắn tài khoản là standard), lệnh silent (Inno):
  ```
  start /wait "" "Git-2.55.0.4-64-bit.exe" /VERYSILENT /NORESTART /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTARTAPPLICATIONS /DIR=%LOCALAPPDATA%\Programs\Git
  ```
  Lưu ý cờ là **`/DIR=`**, không phải `/InstallDir=`; `/CURRENTUSER`/`/ALLUSERS` bị **bỏ qua**. Exit code: `0` = thành công, `>=1` = lỗi (`if errorlevel 1 exit /b 1`).
- Installer tạo folder `Git` trong Start Menu → xóa sau cài: `rmdir /s /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Git"`. Không có desktop icon mặc định.
- Đề xuất **MinGit** là lựa chọn mặc định (A9) — build xác minh `git --version`, `git config --global user.*` nếu cần.

### OpenClaw — npm global (không chạy onboard khi cài)
```
npm install -g openclaw@latest --allow-scripts openclaw
```
- **npm 12 chặn lifecycle scripts mặc định** → phải `--allow-scripts openclaw` (npm 11.16 cảnh báo nhưng chạy; ≤11.12 không ảnh hưởng; **11.13–11.15 cần xác minh khi build**).
- Engine: `node >=22.22.3 <23 || >=24.15 <25 || >=25.9` → cài Node LTS 22.x/24.x (baseline đã chốt ở §1). Config dir: **`~/.openclaw/`** (không phải %APPDATA%). Gateway UI: `http://127.0.0.1:18789`.
- Setup lần đầu **deferred** khỏi bước cài silent: `openclaw onboard --install-daemon` — nhưng được **chạy theo hướng dẫn từng bước trong bước cấu hình lần đầu** (FR-21): tool tự chạy `openclaw onboard`/mở giao diện và dẫn dắt, người dùng không gõ lệnh tay.
- ⚠️ Khi installer này cài `Include_launcher=0`, máy **sẽ không có `py` launcher** — nên phát hiện Python đã cài bằng registry `PythonCore` thay vì `py -0p` (xem §4 #1).

### 9Router — npm global
```
npm install -g 9router
```
- Dashboard: `http://localhost:20128`. Chạy nền: `9router --no-browser --skip-update`. Đăng nhập mặc định: `123456`. Dữ liệu: `%APPDATA%\9router\db\data.sqlite`. Engine `node >=18`.
- **Combo `my-combo` (cấu hình lần đầu):** model `deepseek-v4-flash`, fallback gồm 3 nhà cung cấp: `oc/deepseek-v4-flash-free` (OpenCode Free) → `openrouter/deepseek-v4-flash` → `ds/deepseek-v4-flash`. Trích từ máy tham chiếu (bảng `combos` trong `%APPDATA%\9router\db\data.sqlite`). Tool tạo lại combo này trên máy mới, không tạo trùng (FR-18). **KHÔNG đọc/lưu API key** — key do người dùng nhập trong dashboard (FR-19/21). ⚠️ OpenCode Free có thể bị ngừng/đóng cửa (một số free-tier của 9Router đã ngừng trong 2026) — combo giữ 3 tầng để fallback; theo dõi khi build.

### Extension Claude Code — sau khi PATH refresh
```
set "PATH=%LOCALAPPDATA%\Programs\Microsoft VS Code\bin;%PATH%"
"%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd" --install-extension anthropic.claude-code --force
```
- PATH bị chụp lúc mở console → refresh trong batch trước khi gọi (mẹo chung xem §4 #9). `code.cmd` chờ hoàn tất + `%errorlevel%` đáng tin (code.exe là GUI launcher trả về ngay). Kiểm tra `%errorlevel%` = 0.

## 3. Autostart (không admin) — xác minh build (A2)

**9Router — chọn 1 trong 2:**
- **Chính — Run key HKCU:**
  ```
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "AITools-9router" /t REG_SZ /d "\"%APPDATA%\npm\9router.cmd\" --no-browser --skip-update" /f
  ```
- **Dự phòng — Startup-folder .lnk** (dùng nếu Run key bị chính sách chặn):
  ```
  powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\AITools-9router.lnk');$s.TargetPath='%APPDATA%\npm\9router.cmd';$s.WorkingDirectory='%APPDATA%\npm';$s.Arguments='--no-browser --skip-update';$s.Save()"
  ```
- ⚠️ Target là `.cmd` sẽ **nháy console** khi đăng nhập — dùng wrapper ẩn (wscript) nếu gây khó chịu; quote đường dẫn có khoảng trắng.

**OpenClaw — dùng cơ chế chính thức (không tự bịa):**
- `openclaw gateway install` (docs: Windows = Scheduled Task, fallback Startup-folder). Xác minh `openclaw --help` / `openclaw gateway --help` khi build.
- Chỉ dùng `schtasks` tay khi cần: `schtasks /create /sc onlogon /tn <tên> /tr "<lệnh>" /f /np` (run level LIMITED = không admin; `/np` tránh hỏi mật khẩu; thêm `/delay` nếu cần mạng sẵn sàng).

## 4. Cạm bẫy (mỗi cái đã demo trên máy thật)

1. **Python Store-stub**: `where python` → `WindowsApps\python.exe`, `python --version` in ra "Python was not found…" → lọc `WindowsApps`, hoặc dùng registry `PythonCore` (máy do installer này cài sẽ **không có `py` launcher** — không dựa vào `py -0p`).
2. **PATH chưa refresh trong cùng console**: tool mới cài không thấy được cho tới console mới → tự set PATH trong batch (FR-17).
3. **`Invoke-RestMethod` pipe gotcha**: `(Invoke-RestMethod URL | Select -First 1).field` KHÔNG đúng cho mảng — phải bọc ngoặc quanh toàn bộ lời gọi: `((Invoke-RestMethod URL) | ... ).field`.
4. **Định dạng phiên bản khác nhau**: Node `v26.7.0` (có `v`), `code --version` 3 dòng (lấy dòng 1), `openclaw --version` token 2, Git `git version X.Y.Z.windows.P`, Python/9Router sạch. OpenClaw version **kiểu lịch** — so chuỗi, không semver.
5. **`where` trúng nhầm**: máy này `where node` → portable node của OpenClaw (`%LOCALAPPDATA%\OpenClaw\deps\portable-node`); `where openclaw/9router` → shim của bundle đó. Kiểm tra PATH cụ thể hoặc `npm root -g`/`npm ls -g`.
6. **VSCode GitHub release không có binary** — tải từ update.code.visualstudio.com. VSCode mới lưu app content trong thư mục commit-hash → ưu tiên `code --version` hơn đọc product.json.
7. **Node Current (26.x) làm vỡ OpenClaw** → cài Node LTS 22.x/24.x (ràng buộc engine ở §2 OpenClaw).
8. **Git installer tự ELEVATE trên tài khoản admin** (UAC + all-users) → dùng **MinGit** để chắc chắn per-user (phân tích chi tiết ở §2 Git).
9. **PATH người dùng vừa mới ghi**: đọc lại từ registry trong batch:
   ```
   for /f "skip=2 tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path') do set "PATH=%%B;%PATH%"
   ```

## 5. Tự cập nhật tool (FR-25/26)

- **So sánh phiên bản local** (biến trong .bat) với GitHub Releases API `api.github.com/repos/giakhanhquoc141-rgb/AI_AGENT_INSTALL/releases/latest` (qua PowerShell); nếu có bản mới → tải `.bat` mới và tự thay thế.
- **Thay thế file đang chạy** (A7): tải về `AI_Tools_Installer.new.bat`, đổi tên file hiện tại thành `AI_Tools_Installer.old.bat`, rồi đổi tên `.new` → `.bat` ở lần khởi động kế tiếp (hoặc dùng `cmd /c` lệnh thay thế trì hoãn). Không ghi đè trực tiếp file đang thực thi.

## 6. Quyết định kỹ thuật mở (cho Architecture/Build)

- **Node**: ZIP giải nén vs `msiexec /a` (OQ-3).
- **Git**: MinGit (mặc định — chắc chắn no-admin) vs bộ cài full silent (chỉ cho tài khoản standard) (A9, OQ-6).
- **npm policy**: xác minh `--allow-scripts` hoạt động trên npm bản đích; xác minh hành vi npm 11.13–11.15.
- **Autostart OpenClaw**: xác minh `openclaw gateway install` trên Windows thật (A2).
- **Python 3.13 vs 3.14**: 3.13 còn bộ cài full; 3.14 deprecated → pin 3.13.x.

## 7. Manifest & Log (vị trí đã chốt)

- Manifest: `%LOCALAPPDATA%\AITools\manifest.txt` — mỗi mục: tên, phiên bản, thời điểm cài (FR-23).
- Log: `%LOCALAPPDATA%\AITools\logs\ai-tools-installer.log` — từng bước: thành công/lỗi, phiên bản, đường dẫn, thời điểm (FR-27).
- Cả hai KHÔNG chứa API key; được xóa sạch khi gỡ cài.

## 8. Phân phối & tin cậy (quyết định v1)

- File `.bat` chưa ký → SmartScreen cảnh báo "Windows protected your PC" trên máy tải từ internet.
- Quyết định (đã chốt): **chấp nhận + hướng dẫn** — README ghi rõ bước "More info → Run anyway"; phát hành file qua **GitHub release** (nguồn tin cậy); kèm **SHA256** để xác minh (đặc biệt cho IT).
- Build: cân nhắc xử lý Mark-of-the-Web (xóa zone identifier) là tùy chọn — không khuyến khích vì giảm cảnh báo bảo mật.
