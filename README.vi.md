# gx — Git Express

[![English](https://img.shields.io/badge/English-6c757d?style=for-the-badge)](README.md)
[![Tiếng%20Việt](https://img.shields.io/badge/Tiếng_Việt-0078D4?style=for-the-badge)](README.vi.md)
[![日本語](https://img.shields.io/badge/日本語-6c757d?style=for-the-badge)](README.ja.md)

> **Ticket-driven Git, from branch to PR.**  
> Conventional commits. Rebase before PR.  
> One CLI. Clean history.  
> Short commands. Strict conventions.

Lệnh git ngắn gọn cho workflow hàng ngày. Cài một lần vào `PATH` — không cần chỉnh thư mục cài Git.

**Hướng dẫn đầy đủ:** [docs/USAGE.vi.md](docs/USAGE.vi.md) · sau khi cài: `gx docs vi` · `gx docs` · `gx docs ja`

Cấu hình theo project (PR URL, alias nhánh, trình duyệt, exclude, …) lưu tại `~/.config/gx/` và quản lý bằng `gx cfg`.

## Cài đặt

Repo: [github.com/phamlehoan/git-express](https://github.com/phamlehoan/git-express)

### Linux / macOS

```bash
git clone https://github.com/phamlehoan/git-express.git
cd git-express
chmod +x install.sh bin/gx
./install.sh
```

Mặc định: `~/.local/bin/gx`. Nếu shell không tìm thấy `gx`:

```bash
# bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# zsh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

```bash
INSTALL_DIR=/usr/local/bin ./install.sh   # đổi thư mục
GX_LINK=1 ./install.sh                    # symlink tới clone thay vì copy
```

### Windows — Git Bash (khuyến nghị)

Cần [Git for Windows](https://git-scm.com/download/win).

```bash
git clone https://github.com/phamlehoan/git-express.git
cd git-express
./install.sh
```

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Windows — PowerShell / CMD

Vẫn cần Git for Windows (`gx` chạy trên Bash).

```powershell
git clone https://github.com/phamlehoan/git-express.git
cd git-express
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Cài vào `%LOCALAPPDATA%\gx\bin` và thêm User `PATH`. **Mở terminal mới**, rồi chạy `gx h`.

### Kiểm tra / cập nhật

```bash
gx --version
gx h

cd git-express && git pull && ./install.sh   # PowerShell: .\install.ps1
```

| Môi trường | Cách cài |
|------------|----------|
| Linux / macOS | `git clone … && ./install.sh` |
| Windows (Git Bash) | giống trên |
| Windows (PowerShell) | `.\install.ps1` |

## Cấu hình project

Link tạo PR / MR được **suy ra từ `git remote origin`** (GitHub, GitLab, Bitbucket, Azure DevOps, AWS CodeCommit, Nulab Backlog). Thường chỉ cần alias nhánh, trình duyệt, hoặc exclude.

```bash
gx cfg init
gx cfg set browser chrome
gx cfg set base develop
gx cfg branch qa release          # gx pr qa → đích "release"
gx cfg protect qa develop         # nguồn PR ép về develop (trừ -f)
gx cfg exclude add path/to/secret.json
gx cfg                            # xem config
```

| Host | Dạng URL tạo PR |
|------|-----------------|
| GitHub | `…/compare/{target}...{source}?expand=1` |
| GitLab | `…/-/merge_requests/new?…source_branch…` |
| Bitbucket | `…/pull-requests/new?source=…&dest=…` |
| Azure DevOps | `…/pullrequestcreate?sourceRef=…` |
| AWS CodeCommit | URL console (region lấy từ remote) |
| Nulab Backlog | `…/git/{PROJECT}/{repo}/pullRequests/add/{base}...{topic}` |

```bash
gx cfg set pr_template 'https://example.com/{repo}?s={source}&t={target}'
```

| Token | Ý nghĩa |
|-------|---------|
| `{source}` / `{target}` | Tên nhánh đã URL-encode |
| `{source_raw}` / `{target_raw}` | Tên nhánh gốc |
| `{repo}` | `repo_name` trong config, hoặc tên thư mục |

Config: `~/.config/gx/projects/<hash>.conf` (`GX_CONFIG_DIR` để đổi). Global: `gx cfg global set <key> <value>`.

## Quy ước

| Khái niệm | Đặc tả | Cách `gx` dùng |
|-----------|--------|----------------|
| **Conventional Branch** | [conventional-branch.github.io](https://conventional-branch.github.io/) | `<type>/<TICKET-ID>` (vd. `feat/ABC-123`) |
| **Conventional Commits** | [conventionalcommits.org](https://www.conventionalcommits.org/) | `gx c` → `<type>: <description> (<ticket-id>)` |
| **Semantic Versioning** | [semver.org](https://semver.org/) | Tag `<env>-vX.Y.Z.N` (+ `.hotfixN`) qua `gx t` / `tn` / `tver` |

Nhánh là **nguồn sự thật duy nhất** cho type và ticket. Bạn gõ message ngắn; `gx` suy phần còn lại (camelCase → `snake_case`; giữ khoảng trắng).

Workflow: **feature branch + rebase-before-PR**, promotion môi trường tùy chọn (`gx cfg branch` / `protect`) ≈ [GitLab Flow](https://docs.gitlab.com/ee/topics/gitlab_flow.html).

## Hook quy ước (tùy chọn)

Chỉ ép **git thường / VS Code·Cursor**. Mọi lệnh `gx` set `GX_SKIP_HOOKS=1` và `--no-verify` khi cần — đường gx không chạy hook.

```bash
gx hooks on
gx hooks status
gx hooks off
```

| Thời điểm | Quy tắc |
|-----------|---------|
| `git branch` / `checkout -b` | `type/TICKET-ID` **hoặc** allowlist (`develop`, `uat`, `qa`, `staging`, `prod`, `tmp`, …) |
| Checkout nhánh base / scratch sẵn có | Luôn cho phép |
| Commit (VS Code / `git commit`) | Tự format giống `gx c -m`; phải đứng trên `type/TICKET-ID` |
| `git push` / `git tag` | Nhánh hợp lệ; tag `env-vX.Y.Z.N` |
| Mọi lệnh `gx …` | Bỏ qua hook |

## Ví dụ

```bash
gx a
gx c -m "add contract filter"
gx cp -m "fix login timeout"
gx c                          # amend, giữ message
gx c --amend -m "new wording"
gx hooks on                   # tùy chọn
gx f
gx p
gx pr qa
gx pr qa -f
gx h
gx cfg help
```

## Gỡ cài đặt

```bash
./uninstall.sh
```

Config trong `~/.config/gx` vẫn giữ trừ khi bạn tự xóa.

## Yêu cầu

- `git`
- Bash (Git Bash trên Windows)
- Clipboard (tuỳ chọn): `clip` / `pbcopy` / `xclip` / `xsel` / `wl-copy`
