# gx — Git Express

[![English](https://img.shields.io/badge/English-0078D4?style=for-the-badge)](README.md)
[![Tiếng%20Việt](https://img.shields.io/badge/Tiếng_Việt-6c757d?style=for-the-badge)](README.vi.md)
[![日本語](https://img.shields.io/badge/日本語-6c757d?style=for-the-badge)](README.ja.md)

> **Ticket-driven Git, from branch to PR.**  
> Conventional commits. Rebase before PR.  
> One CLI. Clean history.  
> Short commands. Strict conventions.

Short subcommands for everyday Git. Install once into your `PATH` — no editing Git’s install directory.

**Full guide:** [docs/USAGE.md](docs/USAGE.md) · after install: `gx docs` · `gx docs vi` · `gx docs ja`

Per-project settings (PR URL, branch aliases, browser, excludes, …) live under `~/.config/gx/` and are managed with `gx cfg`.

## Install

Repo: [github.com/phamlehoan/git-express](https://github.com/phamlehoan/git-express)

### Linux / macOS

```bash
git clone https://github.com/phamlehoan/git-express.git
cd git-express
chmod +x install.sh bin/gx
./install.sh
```

Default: `~/.local/bin/gx`. If the shell cannot find `gx`:

```bash
# bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# zsh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

```bash
INSTALL_DIR=/usr/local/bin ./install.sh   # custom dir
GX_LINK=1 ./install.sh                    # symlink to clone instead of copy
```

### Windows — Git Bash (recommended)

Requires [Git for Windows](https://git-scm.com/download/win).

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

Still needs Git for Windows (`gx` runs under Bash).

```powershell
git clone https://github.com/phamlehoan/git-express.git
cd git-express
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Installs to `%LOCALAPPDATA%\gx\bin` and adds User `PATH`. **Open a new terminal**, then `gx h`.

### Verify / update

```bash
gx --version
gx h

cd git-express && git pull && ./install.sh   # PowerShell: .\install.ps1
```

| Environment | Install |
|-------------|---------|
| Linux / macOS | `git clone … && ./install.sh` |
| Windows (Git Bash) | same |
| Windows (PowerShell) | `.\install.ps1` |

## Configure a project

PR / MR links are **inferred from `git remote origin`** (GitHub, GitLab, Bitbucket, Azure DevOps, AWS CodeCommit, Nulab Backlog). Usually you only set branch aliases, browser, or excludes.

```bash
gx cfg init
gx cfg set browser chrome
gx cfg set base develop
gx cfg branch qa release          # gx pr qa → target "release"
gx cfg protect qa develop         # PR source forced to develop (unless -f)
gx cfg exclude add path/to/secret.json
gx cfg                            # show config
```

| Host | PR URL shape |
|------|----------------|
| GitHub | `…/compare/{target}...{source}?expand=1` |
| GitLab | `…/-/merge_requests/new?…source_branch…` |
| Bitbucket | `…/pull-requests/new?source=…&dest=…` |
| Azure DevOps | `…/pullrequestcreate?sourceRef=…` |
| AWS CodeCommit | Console PR URL (region from remote host) |
| Nulab Backlog | `…/git/{PROJECT}/{repo}/pullRequests/add/{base}...{topic}` |

```bash
gx cfg set pr_template 'https://example.com/{repo}?s={source}&t={target}'
```

| Token | Meaning |
|-------|---------|
| `{source}` / `{target}` | URL-encoded branch names |
| `{source_raw}` / `{target_raw}` | Literal branch names |
| `{repo}` | `repo_name` config, or folder basename |

Config: `~/.config/gx/projects/<hash>.conf` (`GX_CONFIG_DIR` to override). Global: `gx cfg global set <key> <value>`.

## Conventions

| Concept | Spec | How `gx` uses it |
|---------|------|------------------|
| **Conventional Branch** | [conventional-branch.github.io](https://conventional-branch.github.io/) | `<type>/<TICKET-ID>` (e.g. `feat/ABC-123`) |
| **Conventional Commits** | [conventionalcommits.org](https://www.conventionalcommits.org/) | `gx c` → `<type>: <description> (<ticket-id>)` |
| **Semantic Versioning** | [semver.org](https://semver.org/) | Tags `<env>-vX.Y.Z.N` (+ `.hotfixN`) via `gx t` / `tn` / `tver` |

Branch is the **single source of truth** for type and ticket. You type a short message; `gx` derives the rest (camelCase → `snake_case`; spaces kept).

Workflow: **feature branch + rebase-before-PR**, optional env promotion (`gx cfg branch` / `protect`) ≈ [GitLab Flow](https://docs.gitlab.com/ee/topics/gitlab_flow.html).

## Optional convention hooks

Enforced for **plain git / VS Code·Cursor only**. Every `gx` command sets `GX_SKIP_HOOKS=1` and uses `--no-verify` where supported — the gx path never runs hooks.

```bash
gx hooks on
gx hooks status
gx hooks off
```

| When | Rule |
|------|------|
| `git branch` / `checkout -b` | `type/TICKET-ID` **or** allowlist (`develop`, `uat`, `qa`, `staging`, `prod`, `tmp`, …) |
| Checkout existing bases / scratch | Always allowed |
| Commit (VS Code / `git commit`) | Auto-format like `gx c -m`; must be on `type/TICKET-ID` |
| `git push` / `git tag` | Valid branch; tags `env-vX.Y.Z.N` |
| Any `gx …` | Hooks skipped |

## Examples

```bash
gx a
gx c -m "add contract filter"
gx cp -m "fix login timeout"
gx c                          # amend, keep message
gx c --amend -m "new wording"
gx hooks on                   # optional
gx f
gx p
gx pr qa
gx pr qa -f
gx h
gx cfg help
```

## Uninstall

```bash
./uninstall.sh
```

Config under `~/.config/gx` is kept unless you delete it.

## Requirements

- `git`
- Bash (Git Bash on Windows)
- Optional clipboard: `clip` / `pbcopy` / `xclip` / `xsel` / `wl-copy`
