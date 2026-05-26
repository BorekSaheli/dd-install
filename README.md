# dd-install

Quick package installer for Windows. Paste, pick, done.

## Install

```powershell
irm https://raw.githubusercontent.com/BorekSaheli/dd-install/main/install.ps1 | iex
```

## Usage

```
  dd-install  pick your packages

  DD Tools
  ├── Python
  │   ├─ > [x] uv               package manager
  │   ├─   [x] Ruff             linter/formatter (uv)
  │   ├─   [x] ty               type checker (uv)
  │   └─   [x] Python 3.13      global via uv
  ├─   [x] Git                  version control
  ├─   [x] Azure CLI            + DevOps extension
  ├─   [x] Claude Code          CLI agent
  ├─   [x] Claude Desktop       desktop app
  └─   [x] Viktor CLI           platform CLI

  Languages
  ├─   [ ] Node.js              JavaScript runtime LTS
  ├─   [ ] Rust                 via rustup
  └─   [ ] Go                   by Google

  ...

  9 selected  Enter=install  q=quit
```

| Key | Action |
|-----|--------|
| `Up/Down` `j/k` | Navigate |
| `Space` | Toggle |
| `g` | Toggle all DD Tools |
| `a` | Toggle everything |
| `Enter` | Install |
| `q` / `Esc` | Quit |

## DD Tools install order

1. **uv** — installed first via official installer
2. **Ruff** — `uv tool install ruff`
3. **ty** — `uv tool install ty`
4. **Python 3.13** — `uv python install 3.13` + set as global
5. **Git** — via winget/choco/scoop
6. **Azure CLI** — via winget/choco/scoop + `az extension add --name azure-devops`
7. **Claude Code** — via npm (auto-installs Node.js if needed)
8. **Claude Desktop** — via winget/choco/scoop
9. **Viktor CLI** — `uv tool install viktor-cli`

## All packages

| Category | Packages |
|----------|----------|
| DD Tools > Python | uv, Ruff, ty, Python 3.13 |
| DD Tools | Git, Azure CLI, Claude Code, Claude Desktop, Viktor CLI |
| Languages | Node.js, Rust, Go |
| Editors | VS Code, Neovim |
| Apps | Chrome, Firefox |
| CLI | curl, wget, jq, ripgrep, fzf, bat, eza |

Auto-detects **winget**, **choco**, or **scoop**.
