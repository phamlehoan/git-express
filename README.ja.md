# gx — Git Express

[![English](https://img.shields.io/badge/English-6c757d?style=for-the-badge)](README.md)
[![Tiếng%20Việt](https://img.shields.io/badge/Tiếng_Việt-6c757d?style=for-the-badge)](README.vi.md)
[![日本語](https://img.shields.io/badge/日本語-0078D4?style=for-the-badge)](README.ja.md)

> **Ticket-driven Git, from branch to PR.**  
> Conventional commits. Rebase before PR.  
> One CLI. Clean history.  
> Short commands. Strict conventions.

日常の Git 作業向けの短いサブコマンドです。一度 `PATH` に入れれば使えます。Git のインストールディレクトリを編集する必要はありません。

**詳細ガイド:** [docs/USAGE.ja.md](docs/USAGE.ja.md) · インストール後: `gx docs ja` · `gx docs` · `gx docs vi`

プロジェクトごとの設定（PR URL、ブランチエイリアス、ブラウザ、exclude など）は `~/.config/gx/` に保存され、`gx cfg` で管理します。

## インストール

リポジトリ: [github.com/phamlehoan/git-express](https://github.com/phamlehoan/git-express)

### Linux / macOS

```bash
git clone https://github.com/phamlehoan/git-express.git
cd git-express
chmod +x install.sh bin/gx
./install.sh
```

デフォルト: `~/.local/bin/gx`。シェルが `gx` を見つけられない場合:

```bash
# bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# zsh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

```bash
INSTALL_DIR=/usr/local/bin ./install.sh   # インストール先を変更
GX_LINK=1 ./install.sh                    # コピーではなく clone への symlink
```

### Windows — Git Bash（推奨）

[Git for Windows](https://git-scm.com/download/win) が必要です。

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

Git for Windows が必要です（`gx` は Bash 上で動作します）。

```powershell
git clone https://github.com/phamlehoan/git-express.git
cd git-express
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

`%LOCALAPPDATA%\gx\bin` にインストールし、ユーザー `PATH` に追加します。**新しいターミナルを開き**、`gx h` を実行してください。

### 確認 / 更新

```bash
gx --version
gx h

cd git-express && git pull && ./install.sh   # PowerShell: .\install.ps1
```

| 環境 | インストール |
|------|----------------|
| Linux / macOS | `git clone … && ./install.sh` |
| Windows (Git Bash) | 同上 |
| Windows (PowerShell) | `.\install.ps1` |

## プロジェクトの設定

PR / MR のリンクは **`git remote origin` から自動推定**されます（GitHub、GitLab、Bitbucket、Azure DevOps、AWS CodeCommit、Nulab Backlog）。通常はブランチエイリアス、ブラウザ、exclude だけ設定すれば十分です。

```bash
gx cfg init
gx cfg set browser chrome
gx cfg set base develop
gx cfg branch qa release          # gx pr qa → ターゲット "release"
gx cfg protect qa develop         # PR source を develop に固定（-f 以外）
gx cfg exclude add path/to/secret.json
gx cfg                            # 設定を表示
```

| ホスト | PR URL の形 |
|--------|-------------|
| GitHub | `…/compare/{target}...{source}?expand=1` |
| GitLab | `…/-/merge_requests/new?…source_branch…` |
| Bitbucket | `…/pull-requests/new?source=…&dest=…` |
| Azure DevOps | `…/pullrequestcreate?sourceRef=…` |
| AWS CodeCommit | コンソール URL（リージョンは remote から） |
| Nulab Backlog | `…/git/{PROJECT}/{repo}/pullRequests/add/{base}...{topic}` |

```bash
gx cfg set pr_template 'https://example.com/{repo}?s={source}&t={target}'
```

| トークン | 意味 |
|----------|------|
| `{source}` / `{target}` | URL エンコード済みブランチ名 |
| `{source_raw}` / `{target_raw}` | そのままのブランチ名 |
| `{repo}` | 設定の `repo_name`、またはフォルダ名 |

設定: `~/.config/gx/projects/<hash>.conf`（`GX_CONFIG_DIR` で変更可）。グローバル: `gx cfg global set <key> <value>`。

## 規約

| 概念 | 仕様 | `gx` での使い方 |
|------|------|-----------------|
| **Conventional Branch** | [conventional-branch.github.io](https://conventional-branch.github.io/) | `<type>/<TICKET-ID>`（例: `feat/ABC-123`） |
| **Conventional Commits** | [conventionalcommits.org](https://www.conventionalcommits.org/) | `gx c` → `<type>: <description> (<ticket-id>)` |
| **Semantic Versioning** | [semver.org](https://semver.org/) | タグ `<env>-vX.Y.Z.N`（＋ `.hotfixN`）を `gx t` / `tn` / `tver` |

ブランチが type とチケットの **単一の真実の源** です。短いメッセージを入力すれば残りは `gx` が導出します（camelCase → `snake_case`、スペースは保持）。

ワークフロー: **feature branch + rebase-before-PR**。任意で環境プロモーション（`gx cfg branch` / `protect`）≈ [GitLab Flow](https://docs.gitlab.com/ee/topics/gitlab_flow.html)。

## 任意の規約フック

**通常の git / VS Code·Cursor のみ**を検証します。すべての `gx` コマンドは `GX_SKIP_HOOKS=1` と必要に応じて `--no-verify` を使い、gx 経路ではフックを実行しません。

```bash
gx hooks on
gx hooks status
gx hooks off
```

| タイミング | ルール |
|------------|--------|
| `git branch` / `checkout -b` | `type/TICKET-ID` **または** allowlist（`develop`、`uat`、`qa`、`staging`、`prod`、`tmp` …） |
| 既存の base / scratch へ checkout | 常に許可 |
| Commit（VS Code / `git commit`） | `gx c -m` と同様に自動整形；現在ブランチは `type/TICKET-ID` である必要 |
| `git push` / `git tag` | 有効なブランチ；タグ `env-vX.Y.Z.N` |
| すべての `gx …` | フックをスキップ |

## 使用例

```bash
gx a
gx c -m "add contract filter"
gx cp -m "fix login timeout"
gx c                          # amend、メッセージ維持
gx c --amend -m "new wording"
gx hooks on                   # 任意
gx f
gx p
gx pr qa
gx pr qa -f
gx h
gx cfg help
```

## アンインストール

```bash
./uninstall.sh
```

`~/.config/gx` の設定は、自分で消さない限り残ります。

## 必要条件

- `git`
- Bash（Windows では Git Bash）
- 任意のクリップボード: `clip` / `pbcopy` / `xclip` / `xsel` / `wl-copy`
