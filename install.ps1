#Requires -Version 5.1
param([switch]$Launched)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─── self-relaunch when piped via irm | iex ─────────────────────────────────
if (-not $Launched) {
    $tempPath = Join-Path $env:TEMP 'dd-install.ps1'
    $scriptContent = @'
{SELF}
'@
    if ($MyInvocation.MyCommand.Path) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $MyInvocation.MyCommand.Path -Launched
    }
    else {
        $selfContent = (Invoke-RestMethod 'https://raw.githubusercontent.com/BorekSaheli/dd-install/main/install.ps1')
        Set-Content -Path $tempPath -Value $selfContent -Encoding UTF8
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tempPath -Launched
        Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
    }
    return
}

# ─── colors & symbols ───────────────────────────────────────────────────────
$ESC = [char]27
$BOLD = "$ESC[1m"
$DIM = "$ESC[2m"
$RESET = "$ESC[0m"
$GREEN = "$ESC[38;5;78m"
$CYAN = "$ESC[38;5;117m"
$YELLOW = "$ESC[38;5;221m"
$RED = "$ESC[38;5;203m"
$MAGENTA = "$ESC[38;5;176m"
$BLUE = "$ESC[38;5;111m"
$BG_SELECT = "$ESC[48;5;236m"
$BG_HEADER = "$ESC[48;5;234m"
$CHECK = [char]0x2713
$CROSS = [char]0x2717
$ARROW = [char]0x25B8
$DOT = [char]0x25CB
$FILLED = [char]0x25CF
$BLOCK_FULL = [char]0x2588
$HLINE = [char]0x2500
$VLINE = [char]0x2502
$TL = [char]0x256D
$TR = [char]0x256E
$BL = [char]0x2570
$BR = [char]0x256F

# ─── package list ────────────────────────────────────────────────────────────
$script:Packages = @(
    @{ Id='python';  Name='Python';        Desc='Programming language (python3 + pip)';     Cat='Dev Languages' }
    @{ Id='node';    Name='Node.js';       Desc='JavaScript runtime (LTS)';                 Cat='Dev Languages' }
    @{ Id='rust';    Name='Rust';          Desc='Systems programming language (rustup)';     Cat='Dev Languages' }
    @{ Id='go';      Name='Go';            Desc="Google's programming language";             Cat='Dev Languages' }
    @{ Id='git';     Name='Git';           Desc='Version control system';                    Cat='Dev Tools' }
    @{ Id='ruff';    Name='Ruff';          Desc='Extremely fast Python linter & formatter';  Cat='Dev Tools' }
    @{ Id='uv';      Name='uv';            Desc='Blazing fast Python package manager';       Cat='Dev Tools' }
    @{ Id='docker';  Name='Docker';        Desc='Container platform (Docker Desktop)';       Cat='Dev Tools' }
    @{ Id='gh';      Name='GitHub CLI';    Desc='GitHub on the command line';                Cat='Dev Tools' }
    @{ Id='code';    Name='VS Code';       Desc='Code editor by Microsoft';                  Cat='Editors' }
    @{ Id='neovim';  Name='Neovim';        Desc='Hyperextensible Vim-based editor';          Cat='Editors' }
    @{ Id='chrome';  Name='Google Chrome'; Desc='Web browser by Google';                     Cat='Apps' }
    @{ Id='firefox'; Name='Firefox';       Desc='Web browser by Mozilla';                    Cat='Apps' }
    @{ Id='curl';    Name='curl';          Desc='Command-line HTTP client';                  Cat='CLI Utils' }
    @{ Id='wget';    Name='wget';          Desc='Network downloader';                        Cat='CLI Utils' }
    @{ Id='jq';      Name='jq';            Desc='JSON processor for the command line';       Cat='CLI Utils' }
    @{ Id='ripgrep'; Name='ripgrep';       Desc='Ultra-fast recursive search (rg)';          Cat='CLI Utils' }
    @{ Id='fzf';     Name='fzf';           Desc='Fuzzy finder for the terminal';             Cat='CLI Utils' }
    @{ Id='htop';    Name='htop';          Desc='Interactive process viewer (ntop)';         Cat='CLI Utils' }
    @{ Id='tree';    Name='tree';          Desc='Directory listing as a tree';               Cat='CLI Utils' }
    @{ Id='bat';     Name='bat';           Desc='cat clone with syntax highlighting';        Cat='CLI Utils' }
    @{ Id='eza';     Name='eza';           Desc='Modern replacement for ls';                 Cat='CLI Utils' }
)

$script:NumPkgs = $script:Packages.Count
$script:Selected = New-Object bool[] $script:NumPkgs
$script:Cursor = 0
$script:ScrollOffset = 0
$script:SearchText = ''

# ─── build display rows (with category headers) ─────────────────────────────
$script:Rows = @()

function Build-Rows {
    $script:Rows = @()
    $prevCat = ''
    for ($i = 0; $i -lt $script:NumPkgs; $i++) {
        $pkg = $script:Packages[$i]
        if ($pkg.Cat -ne $prevCat) {
            if ($script:Rows.Count -gt 0) {
                $script:Rows += ,@{ Type='blank' }
            }
            $script:Rows += ,@{ Type='header'; Text=$pkg.Cat }
            $prevCat = $pkg.Cat
        }
        $script:Rows += ,@{ Type='pkg'; Index=$i }
    }
}

function Get-PkgRowIndex([int]$pkgIdx) {
    for ($r = 0; $r -lt $script:Rows.Count; $r++) {
        if ($script:Rows[$r].Type -eq 'pkg' -and $script:Rows[$r].Index -eq $pkgIdx) {
            return $r
        }
    }
    return 0
}

function Get-NextPkgCursor([int]$current, [int]$dir) {
    $next = $current + $dir
    while ($next -ge 0 -and $next -lt $script:NumPkgs) {
        return $next
    }
    return $current
}

# ─── detect package manager ─────────────────────────────────────────────────
$script:PkgMgr = 'none'

function Detect-PkgMgr {
    if (Get-Command winget -ErrorAction SilentlyContinue) { $script:PkgMgr = 'winget' }
    elseif (Get-Command choco -ErrorAction SilentlyContinue) { $script:PkgMgr = 'choco' }
    elseif (Get-Command scoop -ErrorAction SilentlyContinue) { $script:PkgMgr = 'scoop' }
}

# ─── install functions ───────────────────────────────────────────────────────
function Run-Pkg([string]$WingetId, [string]$ChocoId, [string]$ScoopId) {
    switch ($script:PkgMgr) {
        'winget' { & winget install --id $WingetId -e --accept-source-agreements --accept-package-agreements --silent 2>&1 }
        'choco'  { & choco install $ChocoId -y 2>&1 }
        'scoop'  { & scoop install $ScoopId 2>&1 }
    }
}

function Install-python  { Run-Pkg 'Python.Python.3.12'         'python3'        'python'      }
function Install-node    { Run-Pkg 'OpenJS.NodeJS.LTS'          'nodejs-lts'     'nodejs-lts'  }
function Install-rust    {
    switch ($script:PkgMgr) {
        'winget' { & winget install --id Rustlang.Rustup -e --accept-source-agreements --accept-package-agreements --silent 2>&1 }
        'choco'  { & choco install rustup.install -y 2>&1 }
        'scoop'  { & scoop install rustup 2>&1 }
    }
}
function Install-go      { Run-Pkg 'GoLang.Go'                  'golang'         'go'          }
function Install-git     { Run-Pkg 'Git.Git'                    'git'            'git'         }
function Install-ruff    { Run-Pkg 'Astral.Ruff'                'ruff'           'ruff'        }
function Install-uv      { Run-Pkg 'Astral.uv'                  'uv'             'uv'          }
function Install-docker  { Run-Pkg 'Docker.DockerDesktop'       'docker-desktop' 'docker'      }
function Install-gh      { Run-Pkg 'GitHub.cli'                 'gh'             'gh'          }
function Install-code    { Run-Pkg 'Microsoft.VisualStudioCode' 'vscode'         'vscode'      }
function Install-neovim  { Run-Pkg 'Neovim.Neovim'              'neovim'         'neovim'      }
function Install-chrome  { Run-Pkg 'Google.Chrome'              'googlechrome'   'googlechrome'}
function Install-firefox { Run-Pkg 'Mozilla.Firefox'            'firefox'        'firefox'     }
function Install-curl    { Run-Pkg 'cURL.cURL'                  'curl'           'curl'        }
function Install-wget    { Run-Pkg 'JernejSimoncic.Wget'        'wget'           'wget'        }
function Install-jq      { Run-Pkg 'jqlang.jq'                  'jq'             'jq'          }
function Install-ripgrep { Run-Pkg 'BurntSushi.ripgrep.MSVC'    'ripgrep'        'ripgrep'     }
function Install-fzf     { Run-Pkg 'junegunn.fzf'               'fzf'            'fzf'         }
function Install-htop    {
    switch ($script:PkgMgr) {
        'winget' { & winget install --id ntop.Ntop -e --accept-source-agreements --accept-package-agreements --silent 2>&1 }
        'choco'  { & choco install ntop.portable -y 2>&1 }
        'scoop'  { & scoop install ntop 2>&1 }
    }
}
function Install-tree    { Run-Pkg 'GnuWin32.Tree'              'tree'           'tree'        }
function Install-bat     { Run-Pkg 'sharkdp.bat'                'bat'            'bat'         }
function Install-eza     { Run-Pkg 'eza-community.eza'          'eza'            'eza'         }

# ─── screen buffer helpers ───────────────────────────────────────────────────
function Enter-AltScreen {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Write-Host "$ESC[?1049h" -NoNewline
    [Console]::CursorVisible = $false
}

function Exit-AltScreen {
    Write-Host "$ESC[?1049l" -NoNewline
    [Console]::CursorVisible = $true
}

function Move-To([int]$row, [int]$col) {
    Write-Host "$ESC[$row;${col}H" -NoNewline
}

function Clear-FullScreen {
    Write-Host "$ESC[2J$ESC[H" -NoNewline
}

function Write-At([int]$row, [int]$col, [string]$text) {
    Move-To $row $col
    Write-Host "$ESC[2K$text" -NoNewline
}

# ─── TUI rendering ──────────────────────────────────────────────────────────
function Draw-Frame {
    $w = [Console]::WindowWidth
    $h = [Console]::WindowHeight

    Clear-FullScreen

    # top border
    Write-At 1 1 "${CYAN}${TL}$("$HLINE" * ($w - 2))${TR}${RESET}"

    # side borders for every row
    for ($r = 2; $r -lt $h; $r++) {
        Write-At $r 1 "${CYAN}${VLINE}${RESET}"
        Move-To $r $w
        Write-Host "${CYAN}${VLINE}${RESET}" -NoNewline
    }

    # bottom border
    Write-At $h 1 "${CYAN}${BL}$("$HLINE" * ($w - 2))${BR}${RESET}"

    # title
    $title = " dd-install "
    $titleRow = 3
    $cx = [Math]::Floor(($w - 40) / 2)
    if ($cx -lt 4) { $cx = 4 }

    Write-At $titleRow $cx "${BOLD}${CYAN}$BLOCK_FULL$BLOCK_FULL  dd-install  $BLOCK_FULL$BLOCK_FULL${RESET}"
    Write-At ($titleRow + 1) ($cx - 1) "${DIM}Terminal Package Installer for Windows${RESET}"

    # separator
    $sepRow = $titleRow + 3
    Write-At $sepRow 3 "${CYAN}$("$HLINE" * ($w - 4))${RESET}"

    # keybinds
    $keyRow = $sepRow + 1
    Write-At $keyRow 4 "${DIM}${RESET}${BOLD}Up/Down${RESET}${DIM} navigate  ${RESET}${BOLD}Space${RESET}${DIM} toggle  ${RESET}${BOLD}A${RESET}${DIM} all  ${RESET}${BOLD}//${RESET}${DIM} search  ${RESET}${BOLD}Enter${RESET}${DIM} install  ${RESET}${BOLD}Q${RESET}${DIM} quit${RESET}"

    # second separator
    Write-At ($keyRow + 1) 3 "${CYAN}$("$HLINE" * ($w - 4))${RESET}"
}

function Draw-List {
    $w = [Console]::WindowWidth
    $h = [Console]::WindowHeight

    $listStart = 10
    $listEnd = $h - 3
    $visible = $listEnd - $listStart

    if ($visible -lt 3) { $visible = 3 }

    # adjust scroll so cursor row is visible
    $cursorRow = Get-PkgRowIndex $script:Cursor
    if ($cursorRow -lt $script:ScrollOffset) {
        $script:ScrollOffset = $cursorRow
    }
    elseif ($cursorRow -ge ($script:ScrollOffset + $visible)) {
        $script:ScrollOffset = $cursorRow - $visible + 1
    }

    $maxCol = $w - 6
    if ($maxCol -lt 40) { $maxCol = 40 }

    for ($v = 0; $v -lt $visible; $v++) {
        $ri = $script:ScrollOffset + $v
        $row = $listStart + $v
        Move-To $row 4
        Write-Host "$ESC[2K" -NoNewline
        Move-To $row 1
        Write-Host "${CYAN}${VLINE}${RESET}" -NoNewline
        Move-To $row $w
        Write-Host "${CYAN}${VLINE}${RESET}" -NoNewline

        if ($ri -ge $script:Rows.Count) {
            continue
        }

        $item = $script:Rows[$ri]

        if ($item.Type -eq 'blank') {
            continue
        }

        if ($item.Type -eq 'header') {
            Move-To $row 5
            Write-Host "${BOLD}${MAGENTA}  $HLINE$HLINE $($item.Text) $HLINE$HLINE${RESET}" -NoNewline
            continue
        }

        $pkgIdx = $item.Index
        $pkg = $script:Packages[$pkgIdx]
        $isCursor = ($pkgIdx -eq $script:Cursor)
        $isSel = $script:Selected[$pkgIdx]

        $marker = $DOT
        $mColor = $DIM
        if ($isSel) {
            $marker = $FILLED
            $mColor = $GREEN
        }

        $arrow = '  '
        if ($isCursor) { $arrow = "${BOLD}${CYAN} ${ARROW}${RESET}" }

        $nameStr = $pkg.Name.PadRight(16)
        $descStr = $pkg.Desc

        $availWidth = $maxCol - 30
        if ($availWidth -lt 10) { $availWidth = 10 }
        if ($descStr.Length -gt $availWidth) {
            $descStr = $descStr.Substring(0, $availWidth - 3) + '...'
        }

        Move-To $row 4
        if ($isCursor) {
            Write-Host "${BG_SELECT}${arrow} ${mColor}${marker}${RESET}${BG_SELECT}  ${BOLD}${nameStr}${RESET}${BG_SELECT} ${DIM}${descStr}${RESET}$(' ' * [Math]::Max(0, $maxCol - $nameStr.Length - $descStr.Length - 8))${RESET}" -NoNewline
        }
        else {
            Write-Host "${arrow} ${mColor}${marker}${RESET}  ${nameStr} ${DIM}${descStr}${RESET}" -NoNewline
        }
    }

    # scrollbar
    if ($script:Rows.Count -gt $visible) {
        $sbHeight = [Math]::Max(1, [Math]::Floor($visible * $visible / $script:Rows.Count))
        $sbPos = [Math]::Floor($script:ScrollOffset * ($visible - $sbHeight) / [Math]::Max(1, $script:Rows.Count - $visible))
        for ($v = 0; $v -lt $visible; $v++) {
            $row = $listStart + $v
            Move-To $row ($w - 1)
            if ($v -ge $sbPos -and $v -lt ($sbPos + $sbHeight)) {
                Write-Host "${CYAN}$BLOCK_FULL${RESET}" -NoNewline
            }
            else {
                Write-Host "${DIM}$VLINE${RESET}" -NoNewline
            }
        }
    }

    # status bar
    $statusRow = $h - 1
    $selCount = @($script:Selected | Where-Object { $_ -eq $true }).Count
    Move-To $statusRow 1
    Write-Host "$ESC[2K" -NoNewline
    Move-To $statusRow 1
    Write-Host "${CYAN}${VLINE}${RESET}" -NoNewline
    Move-To $statusRow $w
    Write-Host "${CYAN}${VLINE}${RESET}" -NoNewline

    Move-To $statusRow 4

    if ($script:SearchText.Length -gt 0) {
        Write-Host "${YELLOW}/${RESET}${BOLD}$($script:SearchText)${RESET}  " -NoNewline
    }

    if ($selCount -gt 0) {
        Write-Host "${GREEN}${BOLD}$selCount package(s) selected${RESET}  ${DIM}$HLINE  Press Enter to install${RESET}" -NoNewline
    }
    else {
        Write-Host "${DIM}No packages selected${RESET}" -NoNewline
    }

    # pkg manager badge
    Detect-PkgMgr
    $badge = switch ($script:PkgMgr) {
        'winget' { "${BLUE}winget${RESET}" }
        'choco'  { "${YELLOW}choco${RESET}" }
        'scoop'  { "${MAGENTA}scoop${RESET}" }
        default  { "${RED}no pkg mgr${RESET}" }
    }
    $badgeCol = $w - 18
    if ($badgeCol -lt 40) { $badgeCol = 40 }
    Move-To $statusRow $badgeCol
    Write-Host "${DIM}using ${RESET}${BOLD}$badge" -NoNewline
}

function Draw-All {
    Draw-Frame
    Build-Rows
    Draw-List
}

# ─── search ──────────────────────────────────────────────────────────────────
function Find-NextMatch([string]$text) {
    $lower = $text.ToLower()
    for ($i = 0; $i -lt $script:NumPkgs; $i++) {
        $pkg = $script:Packages[$i]
        if ($pkg.Name.ToLower().Contains($lower) -or $pkg.Id.ToLower().Contains($lower)) {
            $script:Cursor = $i
            return
        }
    }
}

# ─── installation runner ────────────────────────────────────────────────────
function Run-Installs {
    Exit-AltScreen

    $toInstall = @()
    for ($i = 0; $i -lt $script:NumPkgs; $i++) {
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
    Write-Host "  ${BOLD}${CYAN}${TL}$("$HLINE" * 44)${TR}${RESET}"
    Write-Host "  ${BOLD}${CYAN}${VLINE}  Installing $total package(s)...                      ${VLINE}${RESET}"
    Write-Host "  ${BOLD}${CYAN}${BL}$("$HLINE" * 44)${BR}${RESET}"
    Write-Host ""

    Detect-PkgMgr

    if ($script:PkgMgr -eq 'none') {
        Write-Host "  ${RED}${BOLD}No package manager found!${RESET}"
        Write-Host ""
        Write-Host "  Install one of the following, then re-run:"
        Write-Host "    ${BOLD}winget${RESET}  ${DIM}(built into Windows 11, or get App Installer from Microsoft Store)${RESET}"
        Write-Host "    ${BOLD}choco${RESET}   ${DIM}(https://chocolatey.org/install)${RESET}"
        Write-Host "    ${BOLD}scoop${RESET}   ${DIM}(https://scoop.sh)${RESET}"
        Write-Host ""
        return
    }

    Write-Host "  ${DIM}Using ${RESET}${BOLD}$($script:PkgMgr)${RESET}${DIM} as package manager${RESET}"
    Write-Host ""

    $succeeded = 0
    $failed = 0
    $failedNames = @()

    foreach ($idx in $toInstall) {
        $pkg = $script:Packages[$idx]
        $num = $succeeded + $failed + 1
        Write-Host "  ${CYAN}[$num/$total]${RESET} Installing ${BOLD}$($pkg.Name)${RESET}..." -NoNewline

        $logFile = Join-Path $env:TEMP "dd-install-log-$($pkg.Id).txt"
        try {
            $funcName = "Install-$($pkg.Id)"
            & $funcName *> $logFile
            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE" }
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
    Write-Host "  ${CYAN}$("$HLINE" * 44)${RESET}"
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
        Write-Host "  ${YELLOW}Check log files in $env:TEMP for details.${RESET}"
    }
    Write-Host ""
}

# ─── main TUI loop ──────────────────────────────────────────────────────────
function Main {
    $searchMode = $false
    Enter-AltScreen
    Draw-All

    try {
        while ($true) {
            $key = [Console]::ReadKey($true)

            if ($searchMode) {
                if ($key.Key -eq 'Escape' -or $key.Key -eq 'Enter') {
                    $searchMode = $false
                    $script:SearchText = ''
                    Draw-List
                    continue
                }
                if ($key.Key -eq 'Backspace') {
                    if ($script:SearchText.Length -gt 0) {
                        $script:SearchText = $script:SearchText.Substring(0, $script:SearchText.Length - 1)
                    }
                    if ($script:SearchText.Length -gt 0) { Find-NextMatch $script:SearchText }
                    Draw-List
                    continue
                }
                $ch = $key.KeyChar
                if ($ch -and [char]::IsLetterOrDigit($ch)) {
                    $script:SearchText += $ch
                    Find-NextMatch $script:SearchText
                    Draw-List
                    continue
                }
                continue
            }

            switch ($key.Key) {
                'UpArrow' {
                    if ($script:Cursor -gt 0) { $script:Cursor-- }
                    Draw-List
                }
                'DownArrow' {
                    if ($script:Cursor -lt ($script:NumPkgs - 1)) { $script:Cursor++ }
                    Draw-List
                }
                'K' {
                    if (-not $key.Modifiers) {
                        if ($script:Cursor -gt 0) { $script:Cursor-- }
                        Draw-List
                    }
                }
                'J' {
                    if (-not $key.Modifiers) {
                        if ($script:Cursor -lt ($script:NumPkgs - 1)) { $script:Cursor++ }
                        Draw-List
                    }
                }
                'PageUp' {
                    $script:Cursor = [Math]::Max(0, $script:Cursor - 10)
                    Draw-List
                }
                'PageDown' {
                    $script:Cursor = [Math]::Min($script:NumPkgs - 1, $script:Cursor + 10)
                    Draw-List
                }
                'Home' {
                    $script:Cursor = 0
                    Draw-List
                }
                'End' {
                    $script:Cursor = $script:NumPkgs - 1
                    Draw-List
                }
                'Spacebar' {
                    $script:Selected[$script:Cursor] = -not $script:Selected[$script:Cursor]
                    if ($script:Cursor -lt ($script:NumPkgs - 1)) { $script:Cursor++ }
                    Draw-List
                }
                'A' {
                    $anyOff = @($script:Selected | Where-Object { $_ -eq $false }).Count -gt 0
                    for ($i = 0; $i -lt $script:NumPkgs; $i++) { $script:Selected[$i] = $anyOff }
                    Draw-List
                }
                'Enter' {
                    Run-Installs
                    return
                }
                'Q' {
                    Exit-AltScreen
                    Write-Host ""
                    Write-Host "  ${DIM}Cancelled.${RESET}"
                    Write-Host ""
                    return
                }
                'Escape' {
                    Exit-AltScreen
                    Write-Host ""
                    Write-Host "  ${DIM}Cancelled.${RESET}"
                    Write-Host ""
                    return
                }
                'Oem2' {
                    $searchMode = $true
                    $script:SearchText = ''
                    Draw-List
                }
            }
        }
    }
    finally {
        [Console]::CursorVisible = $true
    }
}

Main
