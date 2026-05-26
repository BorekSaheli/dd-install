#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─── colors & symbols ───────────────────────────────────────────────────────
$script:ESC = [char]27
$script:BOLD = "$ESC[1m"
$script:DIM = "$ESC[2m"
$script:GREEN = "$ESC[32m"
$script:CYAN = "$ESC[36m"
$script:YELLOW = "$ESC[33m"
$script:RED = "$ESC[31m"
$script:MAGENTA = "$ESC[35m"
$script:RESET = "$ESC[0m"
$script:CHECK = [char]0x2713
$script:CROSS = [char]0x2717
$script:ARROW = [char]0x25B8
$script:DOT = [char]0x25CB
$script:FILLED = [char]0x25CF

# ─── package list ────────────────────────────────────────────────────────────
$script:Packages = @(
    @{ Id='python';  Name='Python';      Desc='Programming language (python3 + pip)';       Category='Dev Languages' }
    @{ Id='node';    Name='Node.js';     Desc='JavaScript runtime (LTS)';                   Category='Dev Languages' }
    @{ Id='rust';    Name='Rust';        Desc='Systems programming language (via rustup)';   Category='Dev Languages' }
    @{ Id='go';      Name='Go';          Desc="Google's programming language";               Category='Dev Languages' }
    @{ Id='git';     Name='Git';         Desc='Version control system';                      Category='Dev Tools' }
    @{ Id='ruff';    Name='Ruff';        Desc='Extremely fast Python linter & formatter';    Category='Dev Tools' }
    @{ Id='uv';      Name='uv';          Desc='Blazing fast Python package manager';         Category='Dev Tools' }
    @{ Id='docker';  Name='Docker';      Desc='Container platform (Docker Desktop)';         Category='Dev Tools' }
    @{ Id='gh';      Name='GitHub CLI';  Desc='GitHub on the command line';                  Category='Dev Tools' }
    @{ Id='code';    Name='VS Code';     Desc='Code editor by Microsoft';                    Category='Editors' }
    @{ Id='neovim';  Name='Neovim';      Desc='Hyperextensible Vim-based editor';            Category='Editors' }
    @{ Id='chrome';  Name='Google Chrome'; Desc='Web browser by Google';                     Category='Apps' }
    @{ Id='firefox'; Name='Firefox';     Desc='Web browser by Mozilla';                      Category='Apps' }
    @{ Id='curl';    Name='curl';        Desc='Command-line HTTP client';                    Category='CLI Utils' }
    @{ Id='wget';    Name='wget';        Desc='Network downloader';                          Category='CLI Utils' }
    @{ Id='jq';      Name='jq';          Desc='JSON processor for the command line';         Category='CLI Utils' }
    @{ Id='ripgrep'; Name='ripgrep';     Desc='Ultra-fast recursive search (rg)';            Category='CLI Utils' }
    @{ Id='fzf';     Name='fzf';         Desc='Fuzzy finder for the terminal';               Category='CLI Utils' }
    @{ Id='htop';    Name='htop';        Desc='Interactive process viewer (via MSYS2)';      Category='CLI Utils' }
    @{ Id='tree';    Name='tree';        Desc='Directory listing as a tree';                 Category='CLI Utils' }
    @{ Id='bat';     Name='bat';         Desc='cat clone with syntax highlighting';          Category='CLI Utils' }
    @{ Id='eza';     Name='eza';         Desc='Modern replacement for ls';                   Category='CLI Utils' }
    @{ Id='zsh';     Name='Zsh';         Desc='Z shell (via MSYS2/Git Bash)';                Category='CLI Utils' }
)

$script:NumPackages = $Packages.Count
$script:Selected = @($false) * $NumPackages
$script:Cursor = 0
$script:ScrollOffset = 0

# ─── detect package manager ─────────────────────────────────────────────────
$script:PkgManager = 'none'

function Detect-PackageManager {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $script:PkgManager = 'winget'
    }
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        $script:PkgManager = 'choco'
    }
    elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
        $script:PkgManager = 'scoop'
    }
}

function Ensure-Winget {
    if ($script:PkgManager -eq 'none') {
        Write-Host ""
        Write-Host "  ${YELLOW}No supported package manager found.${RESET}"
        Write-Host "  ${YELLOW}Please install winget (comes with App Installer from the Microsoft Store)${RESET}"
        Write-Host "  ${YELLOW}or install Chocolatey / Scoop, then re-run this script.${RESET}"
        Write-Host ""
        exit 1
    }
}

# ─── install functions ───────────────────────────────────────────────────────
function Run-Pkg {
    param([string]$WingetId, [string]$ChocoId, [string]$ScoopId)
    switch ($script:PkgManager) {
        'winget' { winget install --id $WingetId -e --accept-source-agreements --accept-package-agreements --silent 2>&1 }
        'choco'  { choco install $ChocoId -y 2>&1 }
        'scoop'  { scoop install $ScoopId 2>&1 }
    }
}

function Install-python  { Run-Pkg 'Python.Python.3.12'          'python3'           'python'   }
function Install-node    { Run-Pkg 'OpenJS.NodeJS.LTS'           'nodejs-lts'        'nodejs-lts' }
function Install-rust    {
    switch ($script:PkgManager) {
        'winget' { winget install --id Rustlang.Rustup -e --accept-source-agreements --accept-package-agreements --silent 2>&1 }
        'choco'  { choco install rustup.install -y 2>&1 }
        'scoop'  { scoop install rustup 2>&1 }
    }
}
function Install-go      { Run-Pkg 'GoLang.Go'                   'golang'            'go'       }
function Install-git     { Run-Pkg 'Git.Git'                     'git'               'git'      }
function Install-ruff    { Run-Pkg 'Astral.Ruff'                 'ruff'              'ruff'     }
function Install-uv      { Run-Pkg 'Astral.uv'                   'uv'                'uv'       }
function Install-docker  { Run-Pkg 'Docker.DockerDesktop'        'docker-desktop'    'docker'   }
function Install-gh      { Run-Pkg 'GitHub.cli'                  'gh'                'gh'       }
function Install-code    { Run-Pkg 'Microsoft.VisualStudioCode'  'vscode'            'vscode'   }
function Install-neovim  { Run-Pkg 'Neovim.Neovim'               'neovim'            'neovim'   }
function Install-chrome  { Run-Pkg 'Google.Chrome'               'googlechrome'      'googlechrome' }
function Install-firefox { Run-Pkg 'Mozilla.Firefox'             'firefox'           'firefox'  }
function Install-curl    { Run-Pkg 'cURL.cURL'                   'curl'              'curl'     }
function Install-wget    { Run-Pkg 'JernejSimoncic.Wget'         'wget'              'wget'     }
function Install-jq      { Run-Pkg 'jqlang.jq'                   'jq'                'jq'       }
function Install-ripgrep { Run-Pkg 'BurntSushi.ripgrep.MSVC'     'ripgrep'           'ripgrep'  }
function Install-fzf     { Run-Pkg 'junegunn.fzf'                'fzf'               'fzf'      }
function Install-htop    {
    switch ($script:PkgManager) {
        'winget' { winget install --id ntop.Ntop -e --accept-source-agreements --accept-package-agreements --silent 2>&1 }
        'choco'  { choco install ntop.portable -y 2>&1 }
        'scoop'  { scoop install ntop 2>&1 }
    }
}
function Install-tree    { Run-Pkg 'GnuWin32.Tree'               'tree'              'tree'     }
function Install-bat     { Run-Pkg 'sharkdp.bat'                 'bat'               'bat'      }
function Install-eza     { Run-Pkg 'eza-community.eza'           'eza'               'eza'      }
function Install-zsh     {
    switch ($script:PkgManager) {
        'winget' { Write-Host "    Zsh is available via Git Bash or MSYS2 on Windows." 2>&1 }
        'choco'  { choco install msys2 -y 2>&1; Write-Host "    Run 'pacman -S zsh' inside MSYS2." }
        'scoop'  { scoop install msys2 2>&1; Write-Host "    Run 'pacman -S zsh' inside MSYS2." }
    }
}

# ─── TUI rendering ──────────────────────────────────────────────────────────
function Get-TermHeight { [Console]::WindowHeight }

function Draw-Header {
    [Console]::SetCursorPosition(0, 0)
    Write-Host ""
    Write-Host "  ${BOLD}${CYAN}+---------------------------------------------------------+${RESET}"
    Write-Host "  ${BOLD}${CYAN}|           dd-install  ~  package installer              |${RESET}"
    Write-Host "  ${BOLD}${CYAN}+---------------------------------------------------------+${RESET}"
    Write-Host ""
    Write-Host "  ${DIM}Use ${RESET}Up/Down${DIM} to move, ${RESET}Space${DIM} to select, ${RESET}A${DIM} to toggle all, ${RESET}Enter${DIM} to install, ${RESET}Q${DIM} to quit${RESET}"
    Write-Host ""
}

$script:HeaderLines = 7

function Draw-List {
    $termH = Get-TermHeight
    $visible = $termH - $script:HeaderLines - 3
    if ($visible -lt 5) { $visible = 5 }

    if ($script:Cursor -lt $script:ScrollOffset) {
        $script:ScrollOffset = $script:Cursor
    }
    elseif ($script:Cursor -ge ($script:ScrollOffset + $visible)) {
        $script:ScrollOffset = $script:Cursor - $visible + 1
    }

    $prevCategory = ''
    $drawn = 0

    for ($i = $script:ScrollOffset; $i -lt $script:NumPackages -and $drawn -lt $visible; $i++) {
        $pkg = $script:Packages[$i]
        $row = $script:HeaderLines + $drawn
        [Console]::SetCursorPosition(0, $row)
        Write-Host "`r$(' ' * ([Console]::WindowWidth - 1))" -NoNewline
        [Console]::SetCursorPosition(0, $row)

        if ($pkg.Category -ne $prevCategory) {
            if ($drawn -gt 0) {
                Write-Host ""
                $drawn++
                $row = $script:HeaderLines + $drawn
                [Console]::SetCursorPosition(0, $row)
                Write-Host "`r$(' ' * ([Console]::WindowWidth - 1))" -NoNewline
                [Console]::SetCursorPosition(0, $row)
                if ($drawn -ge $visible) { break }
            }
            Write-Host "   ${BOLD}${MAGENTA}-- $($pkg.Category) --${RESET}"
            $drawn++
            $row = $script:HeaderLines + $drawn
            [Console]::SetCursorPosition(0, $row)
            Write-Host "`r$(' ' * ([Console]::WindowWidth - 1))" -NoNewline
            [Console]::SetCursorPosition(0, $row)
            $prevCategory = $pkg.Category
            if ($drawn -ge $visible) { break }
        }

        $marker = $script:DOT
        $color = ''
        if ($script:Selected[$i]) {
            $marker = $script:FILLED
            $color = $script:GREEN
        }

        $name = $pkg.Name.PadRight(14)
        if ($i -eq $script:Cursor) {
            Write-Host "   ${BOLD}${CYAN}${ARROW}${RESET} ${color}${marker}${RESET}  ${BOLD}${name}${RESET} ${DIM}$($pkg.Desc)${RESET}"
        }
        else {
            Write-Host "     ${color}${marker}${RESET}  ${name} ${DIM}$($pkg.Desc)${RESET}"
        }
        $drawn++
    }

    for ($j = $drawn; $j -lt $visible; $j++) {
        $row = $script:HeaderLines + $j
        [Console]::SetCursorPosition(0, $row)
        Write-Host "`r$(' ' * ([Console]::WindowWidth - 1))" -NoNewline
    }

    $count = ($script:Selected | Where-Object { $_ }).Count
    $statusRow = $script:HeaderLines + $visible
    [Console]::SetCursorPosition(0, $statusRow)
    Write-Host ""
    if ($count -gt 0) {
        Write-Host "   ${GREEN}${BOLD}$count package(s) selected${RESET}  ${DIM}-  Press Enter to install${RESET}"
    }
    else {
        Write-Host "   ${DIM}No packages selected${RESET}                                    "
    }
}

# ─── installation runner ────────────────────────────────────────────────────
function Run-Installs {
    [Console]::CursorVisible = $true
    Clear-Host

    $toInstall = @()
    for ($i = 0; $i -lt $script:NumPackages; $i++) {
        if ($script:Selected[$i]) { $toInstall += $i }
    }

    if ($toInstall.Count -eq 0) {
        Write-Host ""
        Write-Host "  ${YELLOW}Nothing selected. Exiting.${RESET}"
        Write-Host ""
        return
    }

    $total = $toInstall.Count

    Write-Host ""
    Write-Host "  ${BOLD}${CYAN}+--------------------------------------------+${RESET}"
    Write-Host "  ${BOLD}${CYAN}|  Installing $total package(s)...                  |${RESET}"
    Write-Host "  ${BOLD}${CYAN}+--------------------------------------------+${RESET}"
    Write-Host ""

    Detect-PackageManager
    Ensure-Winget

    $succeeded = 0
    $failed = 0
    $failedNames = @()

    foreach ($idx in $toInstall) {
        $pkg = $script:Packages[$idx]
        $num = $succeeded + $failed + 1
        Write-Host "  ${CYAN}[$num/$total]${RESET} Installing ${BOLD}$($pkg.Name)${RESET}..." -NoNewline

        $logFile = "$env:TEMP\dd-install-log-$($pkg.Id).txt"
        try {
            $funcName = "Install-$($pkg.Id)"
            & $funcName *> $logFile
            Write-Host " ${GREEN}${CHECK} done${RESET}"
            $succeeded++
        }
        catch {
            $_ | Out-File $logFile -Append
            Write-Host " ${RED}${CROSS} failed${RESET} ${DIM}(see $logFile)${RESET}"
            $failed++
            $failedNames += $pkg.Name
        }
    }

    Write-Host ""
    Write-Host "  ${BOLD}${CYAN}--------------------------------------------${RESET}"
    Write-Host -NoNewline "  ${GREEN}${CHECK} $succeeded succeeded${RESET}"
    if ($failed -gt 0) {
        Write-Host -NoNewline "  ${RED}${CROSS} $failed failed: $($failedNames -join ', ')${RESET}"
    }
    Write-Host ""
    Write-Host ""

    if ($failed -eq 0) {
        Write-Host "  ${GREEN}${BOLD}All done! Happy coding.${RESET}"
    }
    else {
        Write-Host "  ${YELLOW}Check the log files in $env:TEMP for details on failures.${RESET}"
    }
    Write-Host ""
}

# ─── main TUI loop ──────────────────────────────────────────────────────────
function Main {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::CursorVisible = $false
    Clear-Host
    Draw-Header
    Draw-List

    while ($true) {
        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            'UpArrow' {
                if ($script:Cursor -gt 0) { $script:Cursor-- }
            }
            'DownArrow' {
                if ($script:Cursor -lt ($script:NumPackages - 1)) { $script:Cursor++ }
            }
            'Spacebar' {
                $script:Selected[$script:Cursor] = -not $script:Selected[$script:Cursor]
            }
            'A' {
                $anyUnselected = ($script:Selected | Where-Object { -not $_ }).Count -gt 0
                $val = $anyUnselected
                for ($i = 0; $i -lt $script:NumPackages; $i++) { $script:Selected[$i] = $val }
            }
            'Enter' {
                Run-Installs
                [Console]::CursorVisible = $true
                return
            }
            'Q' {
                [Console]::CursorVisible = $true
                Clear-Host
                Write-Host ""
                Write-Host "  ${DIM}Cancelled.${RESET}"
                Write-Host ""
                return
            }
            'K' {
                if ($script:Cursor -gt 0) { $script:Cursor-- }
            }
            'J' {
                if ($script:Cursor -lt ($script:NumPackages - 1)) { $script:Cursor++ }
            }
        }

        Draw-List
    }
}

try {
    Main
}
finally {
    [Console]::CursorVisible = $true
}
