# dd-install

Quick package installer for Windows.

```powershell
irm https://raw.githubusercontent.com/BorekSaheli/dd-install/main/install.ps1 | iex
```

```
  dd-install

  > ○ DD Tools
      ○ Python
          ○ uv                package manager
          ○ Ruff              linter / formatter
          ○ ty                type checker
          ○ Python 3.13       global via uv
      ○ Config
          ○ JetBrains Mono    nerd font + terminal
          ○ Starship          cross-shell prompt
          ○ chezmoi           dotfiles from GitHub
      ○ Git                version control
      ○ Azure CLI          + DevOps extension
      ○ Claude Code        CLI agent
      ○ Claude Desktop     desktop app
      ○ PowerShell 7       default shell
      ○ komorebi           tiling window manager
      ○ Viktor CLI         platform CLI

    ○ Browser
      ○ Chrome             browser by Google
      ○ Firefox            browser by Mozilla

  space select / a all / enter install / q quit
```

Select a section header to toggle everything in it.

`space` toggle / `a` all / `enter` install / `q` quit

Auto-detects **winget**, **choco**, or **scoop**.
