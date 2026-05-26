# dd-install

Interactive full-screen terminal installer for Windows. Pick what you want, it handles the rest.

![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue)
![Platform](https://img.shields.io/badge/platform-windows-0078D4)

## Quick Start

Paste this into PowerShell:

```powershell
irm https://raw.githubusercontent.com/BorekSaheli/dd-install/main/install.ps1 | iex
```

## What You Get

A full-screen TUI (like vim) where you browse and select packages to install:

```
╭──────────────────────────────────────────────────────────────╮
│                                                              │
│                  ██  dd-install  ██                           │
│              Terminal Package Installer for Windows           │
│                                                              │
│──────────────────────────────────────────────────────────────│
│  Up/Down navigate  Space toggle  A all  / search  Enter go   │
│──────────────────────────────────────────────────────────────│
│                                                              │
│    ── Dev Languages ──                                       │
│  ▸ ●  Python           Programming language (python3 + pip)  │
│    ○  Node.js          JavaScript runtime (LTS)              │
│    ○  Rust             Systems programming language           │
│    ○  Go               Google's programming language          │
│                                                              │
│    ── Dev Tools ──                                            │
│    ●  Git              Version control system                │
│    ●  Ruff             Extremely fast Python linter           │
│    ...                                                       │
│                                                              │
│  3 package(s) selected  ─  Press Enter to install    winget  │
╰──────────────────────────────────────────────────────────────╯
```

## Available Packages

| Category | Packages |
|----------|----------|
| **Dev Languages** | Python, Node.js, Rust, Go |
| **Dev Tools** | Git, Ruff, uv, Docker, GitHub CLI |
| **Editors** | VS Code, Neovim |
| **Apps** | Google Chrome, Firefox |
| **CLI Utils** | curl, wget, jq, ripgrep, fzf, htop, tree, bat, eza |

## Controls

| Key | Action |
|-----|--------|
| `Up` / `k` | Move up |
| `Down` / `j` | Move down |
| `Space` | Toggle selection |
| `A` | Select / deselect all |
| `/` | Search packages |
| `PgUp` / `PgDn` | Scroll fast |
| `Home` / `End` | Jump to top / bottom |
| `Enter` | Install selected |
| `Q` / `Esc` | Quit |

## Package Managers

dd-install auto-detects and uses whichever you have:

- **winget** (built into Windows 11, or install App Installer from the Microsoft Store)
- **Chocolatey** (https://chocolatey.org/install)
- **Scoop** (https://scoop.sh)
