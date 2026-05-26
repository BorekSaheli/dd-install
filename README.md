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
          ○ chezmoi           dotfiles manager
          ○ JetBrains Mono    nerd font + terminal
          ○ Starship          cross-shell prompt
      ○ Git                version control
      ○ Azure CLI          + DevOps extension
      ○ Claude Code        CLI agent
      ○ Claude Desktop     desktop app
      ○ Viktor CLI         platform CLI

    ○ Browser
      ○ Chrome             browser by Google
      ○ Firefox            browser by Mozilla

    ○ CLI
      ○ curl               HTTP client
      ○ wget               downloader
      ○ jq                 JSON processor
      ○ ripgrep            fast search
      ○ fzf                fuzzy finder
      ○ bat                better cat
      ○ eza                better ls

  space select / a all / enter install / q quit
```

Select a section header to toggle everything in it.

`space` toggle / `a` all / `enter` install / `q` quit

## Config sub-group

- **chezmoi** — installs chezmoi and runs `chezmoi init --apply BorekSaheli/dotfiles`
- **JetBrains Mono** — installs the Nerd Font and sets it as the default Windows Terminal font
- **Starship** — installs the prompt and adds `starship init` to your PowerShell profile

Auto-detects **winget**, **choco**, or **scoop**.
