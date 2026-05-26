# dd-install

Quick package installer for Windows.

```powershell
irm https://raw.githubusercontent.com/BorekSaheli/dd-install/main/install.ps1 | iex
```

```
  dd-install

  DD Tools

    Python
      > ○ uv                package manager
        ○ Ruff              linter / formatter
        ○ ty                type checker
        ○ Python 3.13       global via uv

    ○ Git                version control
    ○ Azure CLI          + DevOps extension
    ○ Claude Code        CLI agent
    ○ Claude Desktop     desktop app
    ○ Viktor CLI         platform CLI

  Browser

    ○ Chrome             browser by Google
    ○ Firefox            browser by Mozilla

  space select / a all / g dd tools / enter install / q quit
```

`space` toggle / `a` all / `g` dd tools / `enter` install / `q` quit

Auto-detects **winget**, **choco**, or **scoop**.
