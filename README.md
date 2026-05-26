# dd-install

Quick package installer for Windows. Paste, pick, done.

## Install

```powershell
irm https://raw.githubusercontent.com/BorekSaheli/dd-install/main/install.ps1 | iex
```

## Usage

```
  dd-install  pick your packages

  Languages
  > [x] Python         python3 + pip
    [ ] Node.js        JavaScript runtime LTS
    [ ] Rust           via rustup
    [ ] Go             by Google

  Dev Tools
    [x] Git            version control
    [x] Ruff           Python linter/formatter
    ...

  2 selected  Enter=install  q=quit
```

Arrow keys to move, Space to toggle, A for all, Enter to install, Q to quit.

## Packages

| Category | Packages |
|----------|----------|
| Languages | Python, Node.js, Rust, Go |
| Dev Tools | Git, Ruff, uv, Docker, GitHub CLI |
| Editors | VS Code, Neovim |
| Apps | Chrome, Firefox |
| CLI | curl, wget, jq, ripgrep, fzf, htop, bat, eza |

Auto-detects **winget**, **choco**, or **scoop**.
