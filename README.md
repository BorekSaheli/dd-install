# dd-install

Interactive terminal installer TUI. Pick what you want, it handles the rest.

![Bash](https://img.shields.io/badge/bash-5.0%2B-green)
![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue)
![Platform](https://img.shields.io/badge/platform-linux%20%7C%20macOS%20%7C%20windows-blue)

## Quick Start

**Linux / macOS:**

```bash
bash <(curl -sSL https://raw.githubusercontent.com/boreksaheli/dd-install/main/install.sh)
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/boreksaheli/dd-install/main/install.ps1 | iex
```

## What You Get

A full-screen terminal UI where you select what to install:

```
  ┌─────────────────────────────────────────────────────────┐
  │           ░█▀▄░█▀▄░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░       │
  │           ░█░█░█░█░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░       │
  │           ░▀▀░░▀▀░░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀       │
  └─────────────────────────────────────────────────────────┘
   Use ↑/↓ to move, Space to select, a to toggle all, Enter to install, q to quit

   ── Dev Languages ──
   ▸ ●  Python         Programming language (python3 + pip)
     ○  Node.js        JavaScript runtime (via NodeSource/Homebrew)
     ○  Rust           Systems programming language (via rustup)
     ○  Go             Google's programming language

   ── Dev Tools ──
     ●  Git            Version control system
     ●  Ruff           Extremely fast Python linter & formatter
     ...

   3 package(s) selected  ─  Press Enter to install
```

## Available Packages

| Category | Packages |
|----------|----------|
| **Dev Languages** | Python, Node.js, Rust, Go |
| **Dev Tools** | Git, Ruff, uv, Docker, GitHub CLI |
| **Editors** | VS Code, Neovim |
| **Apps** | Google Chrome, Firefox |
| **CLI Utils** | curl, wget, jq, ripgrep, fzf, tmux, htop, tree, bat, eza, zsh |

## Controls

| Key | Action |
|-----|--------|
| `↑` / `k` | Move up |
| `↓` / `j` | Move down |
| `Space` | Toggle selection |
| `a` | Select / deselect all |
| `Enter` | Install selected |
| `q` | Quit |

## Supported Platforms

- **Windows** (winget, Chocolatey, or Scoop)
- **macOS** (Homebrew)
- **Debian / Ubuntu** (apt)
- **Fedora** (dnf)
- **Arch Linux** (pacman)
