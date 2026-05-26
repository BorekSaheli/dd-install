#Requires -Version 5.1
param([switch]$Launched)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─── self-relaunch when piped via irm | iex ─────────────────────────────────
if (-not $Launched) {
    $tempPath = Join-Path $env:TEMP 'dd-install.ps1'
    $scriptFile = $null
    if ($MyInvocation.MyCommand -and $MyInvocation.MyCommand.PSObject.Properties['Path']) {
        $scriptFile = $MyInvocation.MyCommand.Path
    }
    if ($scriptFile) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptFile -Launched
    }
    else {
        Invoke-RestMethod 'https://raw.githubusercontent.com/BorekSaheli/dd-install/main/install.ps1' -OutFile $tempPath
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tempPath -Launched
        Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
    }
    return
}

# ─── colors ──────────────────────────────────────────────────────────────────
$e = [char]27
$B  = "$e[1m";   $D  = "$e[2m";  $R  = "$e[0m"
$GR = "$e[32m";  $CY = "$e[36m"; $YL = "$e[33m"
$RD = "$e[31m";  $MG = "$e[35m"

# tree glyphs
$T_V = [char]0x2502  # │
$T_T = [char]0x251C  # ├
$T_L = [char]0x2514  # └
$T_H = [char]0x2500  # ─

# ─── packages ───────────────────────────────────────────────────────────────
# Cat = top category, Sub = sub-folder (or '' for none), Order = install order
$script:Pkgs = @(
    @{ Id='uv';        N='uv';             Ds='package manager';         C='DD Tools'; Sub='Python'; Order=1 }
    @{ Id='ruff';      N='Ruff';           Ds='linter/formatter (uv)';   C='DD Tools'; Sub='Python'; Order=2 }
    @{ Id='ty';        N='ty';             Ds='type checker (uv)';       C='DD Tools'; Sub='Python'; Order=3 }
    @{ Id='python313'; N='Python 3.13';    Ds='global via uv';           C='DD Tools'; Sub='Python'; Order=4 }
    @{ Id='git';       N='Git';            Ds='version control';         C='DD Tools'; Sub='';       Order=5 }
    @{ Id='azurecli';  N='Azure CLI';      Ds='+ DevOps extension';      C='DD Tools'; Sub='';       Order=6 }
    @{ Id='claudecode';N='Claude Code';    Ds='CLI agent';               C='DD Tools'; Sub='';       Order=7 }
    @{ Id='claudedesk';N='Claude Desktop'; Ds='desktop app';             C='DD Tools'; Sub='';       Order=8 }
    @{ Id='viktorcli'; N='Viktor CLI';     Ds='platform CLI';            C='DD Tools'; Sub='';       Order=9 }
    @{ Id='node';      N='Node.js';        Ds='JavaScript runtime LTS';  C='Languages';Sub='';       Order=10 }
    @{ Id='rust';      N='Rust';           Ds='via rustup';              C='Languages';Sub='';       Order=10 }
    @{ Id='golang';    N='Go';             Ds='by Google';               C='Languages';Sub='';       Order=10 }
    @{ Id='code';      N='VS Code';        Ds='editor';                  C='Editors';  Sub='';       Order=10 }
    @{ Id='neovim';    N='Neovim';         Ds='vim-based editor';        C='Editors';  Sub='';       Order=10 }
    @{ Id='chrome';    N='Chrome';         Ds='browser';                 C='Apps';     Sub='';       Order=10 }
    @{ Id='firefox';   N='Firefox';        Ds='browser';                 C='Apps';     Sub='';       Order=10 }
    @{ Id='curl';      N='curl';           Ds='HTTP client';             C='CLI';      Sub='';       Order=10 }
    @{ Id='wget';      N='wget';           Ds='downloader';              C='CLI';      Sub='';       Order=10 }
    @{ Id='jq';        N='jq';             Ds='JSON processor';          C='CLI';      Sub='';       Order=10 }
    @{ Id='ripgrep';   N='ripgrep';        Ds='fast search (rg)';        C='CLI';      Sub='';       Order=10 }
    @{ Id='fzf';       N='fzf';            Ds='fuzzy finder';            C='CLI';      Sub='';       Order=10 }
    @{ Id='bat';       N='bat';            Ds='better cat';              C='CLI';      Sub='';       Order=10 }
    @{ Id='eza';       N='eza';            Ds='better ls';               C='CLI';      Sub='';       Order=10 }
)

$script:Total = $script:Pkgs.Count
$script:Sel = New-Object bool[] $script:Total
$script:Cur = 0

# ─── detect package manager ─────────────────────────────────────────────────
$script:PM = 'none'
function Detect-PM {
    if (Get-Command winget -ErrorAction SilentlyContinue) { $script:PM = 'winget' }
    elseif (Get-Command choco -ErrorAction SilentlyContinue) { $script:PM = 'choco' }
    elseif (Get-Command scoop -ErrorAction SilentlyContinue) { $script:PM = 'scoop' }
}

# ─── install functions ───────────────────────────────────────────────────────
function Run-Pkg([string]$W, [string]$Ch, [string]$Sc) {
    switch ($script:PM) {
        'winget' { & winget install --id $W -e --accept-source-agreements --accept-package-agreements --silent 2>&1 }
        'choco'  { & choco install $Ch -y 2>&1 }
        'scoop'  { & scoop install $Sc 2>&1 }
    }
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
}

function Install-uv {
    powershell -ExecutionPolicy Bypass -c "irm https://astral.sh/uv/install.ps1 | iex" 2>&1
    Refresh-Path
}

function Install-ruff {
    Refresh-Path
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        & uv tool install ruff 2>&1
    }
    else { Run-Pkg 'Astral.Ruff' 'ruff' 'ruff' }
}

function Install-ty {
    Refresh-Path
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        & uv tool install ty 2>&1
    }
    else { Write-Output "uv required for ty"; throw "uv required" }
}

function Install-python313 {
    Refresh-Path
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        & uv python install 3.13 2>&1
        & uv python pin 3.13 --global 2>&1
    }
    else { Write-Output "uv required"; throw "uv required" }
}

function Install-git      { Run-Pkg 'Git.Git' 'git' 'git' }

function Install-azurecli {
    Run-Pkg 'Microsoft.AzureCLI' 'azure-cli' 'azure-cli'
    Refresh-Path
    & az extension add --name azure-devops --yes 2>&1
}

function Install-claudecode {
    Refresh-Path
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Output "Installing Node.js first..."
        Run-Pkg 'OpenJS.NodeJS.LTS' 'nodejs-lts' 'nodejs-lts'
        Refresh-Path
    }
    & npm install -g @anthropic-ai/claude-code 2>&1
}

function Install-claudedesk { Run-Pkg 'Anthropic.Claude' 'claude' 'claude' }

function Install-viktorcli {
    Refresh-Path
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        & uv tool install viktor-cli 2>&1
    }
    elseif (Get-Command pip -ErrorAction SilentlyContinue) {
        & pip install viktor-cli 2>&1
    }
    else { Write-Output "need uv or pip"; throw "no installer" }
}

function Install-node    { Run-Pkg 'OpenJS.NodeJS.LTS'          'nodejs-lts'     'nodejs-lts'  }
function Install-rust    {
    switch ($script:PM) {
        'winget' { & winget install --id Rustlang.Rustup -e --accept-source-agreements --accept-package-agreements --silent 2>&1 }
        'choco'  { & choco install rustup.install -y 2>&1 }
        'scoop'  { & scoop install rustup 2>&1 }
    }
}
function Install-golang  { Run-Pkg 'GoLang.Go'                  'golang'         'go'          }
function Install-code    { Run-Pkg 'Microsoft.VisualStudioCode' 'vscode'         'vscode'      }
function Install-neovim  { Run-Pkg 'Neovim.Neovim'              'neovim'         'neovim'      }
function Install-chrome  { Run-Pkg 'Google.Chrome'              'googlechrome'   'googlechrome'}
function Install-firefox { Run-Pkg 'Mozilla.Firefox'            'firefox'        'firefox'     }
function Install-curl    { Run-Pkg 'cURL.cURL'                  'curl'           'curl'        }
function Install-wget    { Run-Pkg 'JernejSimoncic.Wget'        'wget'           'wget'        }
function Install-jq      { Run-Pkg 'jqlang.jq'                  'jq'             'jq'          }
function Install-ripgrep { Run-Pkg 'BurntSushi.ripgrep.MSVC'    'ripgrep'        'ripgrep'     }
function Install-fzf     { Run-Pkg 'junegunn.fzf'               'fzf'            'fzf'         }
function Install-bat     { Run-Pkg 'sharkdp.bat'                'bat'            'bat'         }
function Install-eza     { Run-Pkg 'eza-community.eza'          'eza'            'eza'         }

# ─── figure out tree structure for rendering ─────────────────────────────────
function Get-TreeInfo {
    # for each package, figure out what tree prefix to draw
    # returns array of @{ Prefix; IsLastInCat; IsLastInSub } parallel to $Pkgs
    $info = @()
    for ($i = 0; $i -lt $script:Total; $i++) {
        $p = $script:Pkgs[$i]
        $nextP = if ($i + 1 -lt $script:Total) { $script:Pkgs[$i + 1] } else { $null }

        $isLastInCat = (-not $nextP) -or ($nextP.C -ne $p.C)
        $isLastInSub = $false
        if ($p.Sub -ne '') {
            $isLastInSub = (-not $nextP) -or ($nextP.Sub -ne $p.Sub) -or ($nextP.C -ne $p.C)
        }

        $hasMoreAfterSub = $false
        if ($p.Sub -ne '') {
            for ($j = $i + 1; $j -lt $script:Total; $j++) {
                if ($script:Pkgs[$j].C -ne $p.C) { break }
                if ($script:Pkgs[$j].Sub -ne $p.Sub) { $hasMoreAfterSub = $true; break }
            }
        }

        $info += ,@{ IsLastInCat=$isLastInCat; IsLastInSub=$isLastInSub; HasMoreAfterSub=$hasMoreAfterSub }
    }
    return $info
}

# ─── draw the list inline ───────────────────────────────────────────────────
$script:StartLine = 0

function Draw-List {
    [Console]::SetCursorPosition(0, $script:StartLine)

    $treeInfo = Get-TreeInfo
    $prevCat = ''
    $prevSub = ''

    for ($i = 0; $i -lt $script:Total; $i++) {
        $p = $script:Pkgs[$i]
        $ti = $treeInfo[$i]

        # category header
        if ($p.C -ne $prevCat) {
            if ($prevCat -ne '') { Write-Host "" }
            Write-Host "  ${MG}${B}$($p.C)${R}"
            $prevCat = $p.C
            $prevSub = ''
        }

        # sub-folder header
        if ($p.Sub -ne '' -and $p.Sub -ne $prevSub) {
            $subBranch = if ($ti.IsLastInCat -and $ti.IsLastInSub) { $T_L } else { $T_T }
            Write-Host "  ${D}${subBranch}${T_H}${T_H}${R} ${CY}${B}$($p.Sub)${R}"
            $prevSub = $p.Sub
        }

        # build prefix
        $box = if ($script:Sel[$i]) { "${GR}[x]${R}" } else { "[ ]" }
        $arrow = if ($i -eq $script:Cur) { "${CY}${B}>${R} " } else { "  " }
        $name = $p.N.PadRight(16)
        $hi = if ($i -eq $script:Cur) { $B } else { '' }

        if ($p.Sub -ne '') {
            $vert = if ($ti.HasMoreAfterSub -or -not $ti.IsLastInSub) { $T_V } else { ' ' }
            $branch = if ($ti.IsLastInSub) { $T_L } else { $T_T }
            Write-Host "  ${D}${vert}   ${branch}${T_H}${R} ${arrow}${box} ${hi}${name}${R} ${D}$($p.Ds)${R}"
        }
        else {
            $branch = if ($ti.IsLastInCat) { $T_L } else { $T_T }
            Write-Host "  ${D}${branch}${T_H}${R} ${arrow}${box} ${hi}${name}${R} ${D}$($p.Ds)${R}"
        }
    }

    $count = @($script:Sel | Where-Object { $_ -eq $true }).Count
    Write-Host ""
    if ($count -gt 0) {
        Write-Host "  ${GR}${B}$count selected${R}  ${D}Enter=install  q=quit${R}    "
    }
    else {
        Write-Host "  ${D}Space=toggle  a=all  g=DD Tools  Enter=install  q=quit${R}    "
    }
}

function Reserve-Lines {
    $lines = 2
    $prevCat = ''; $prevSub = ''
    for ($i = 0; $i -lt $script:Total; $i++) {
        $p = $script:Pkgs[$i]
        if ($p.C -ne $prevCat) {
            if ($prevCat -ne '') { $lines++ }
            $lines++; $prevCat = $p.C; $prevSub = ''
        }
        if ($p.Sub -ne '' -and $p.Sub -ne $prevSub) {
            $lines++; $prevSub = $p.Sub
        }
        $lines++
    }
    for ($j = 0; $j -lt $lines; $j++) { Write-Host "" }
    $script:StartLine = [Console]::CursorTop - $lines
}

# ─── main ────────────────────────────────────────────────────────────────────
function Main {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::CursorVisible = $false

    Write-Host ""
    Write-Host "  ${B}${CY}dd-install${R}  ${D}pick your packages${R}"
    Write-Host ""

    Reserve-Lines
    Draw-List

    try {
        while ($true) {
            $key = [Console]::ReadKey($true)

            switch ($key.Key) {
                'UpArrow'   { if ($script:Cur -gt 0) { $script:Cur-- } }
                'DownArrow' { if ($script:Cur -lt ($script:Total - 1)) { $script:Cur++ } }
                'K'         { if ($script:Cur -gt 0) { $script:Cur-- } }
                'J'         { if ($script:Cur -lt ($script:Total - 1)) { $script:Cur++ } }
                'Spacebar'  {
                    $script:Sel[$script:Cur] = -not $script:Sel[$script:Cur]
                    if ($script:Cur -lt ($script:Total - 1)) { $script:Cur++ }
                }
                'A' {
                    $anyOff = @($script:Sel | Where-Object { $_ -eq $false }).Count -gt 0
                    for ($i = 0; $i -lt $script:Total; $i++) { $script:Sel[$i] = $anyOff }
                }
                'G' {
                    $allOn = $true
                    for ($i = 0; $i -lt $script:Total; $i++) {
                        if ($script:Pkgs[$i].C -eq 'DD Tools' -and -not $script:Sel[$i]) { $allOn = $false; break }
                    }
                    for ($i = 0; $i -lt $script:Total; $i++) {
                        if ($script:Pkgs[$i].C -eq 'DD Tools') { $script:Sel[$i] = -not $allOn }
                    }
                }
                'Enter' {
                    [Console]::CursorVisible = $true
                    Write-Host ""
                    Run-Installs
                    return
                }
                'Q' {
                    [Console]::CursorVisible = $true
                    Write-Host ""
                    Write-Host "  ${D}Cancelled.${R}"
                    Write-Host ""
                    return
                }
                'Escape' {
                    [Console]::CursorVisible = $true
                    Write-Host ""
                    Write-Host "  ${D}Cancelled.${R}"
                    Write-Host ""
                    return
                }
            }

            Draw-List
        }
    }
    finally {
        [Console]::CursorVisible = $true
    }
}

function Run-Installs {
    $toInstall = @()
    for ($i = 0; $i -lt $script:Total; $i++) {
        if ($script:Sel[$i]) { $toInstall += $i }
    }

    if ($toInstall.Count -eq 0) {
        Write-Host "  ${YL}Nothing selected.${R}"
        Write-Host ""
        return
    }

    Detect-PM

    if ($script:PM -eq 'none') {
        Write-Host "  ${RD}${B}No package manager found.${R}"
        Write-Host "  Install ${B}winget${R}, ${B}choco${R}, or ${B}scoop${R} first."
        Write-Host ""
        return
    }

    $toInstall = $toInstall | Sort-Object { $script:Pkgs[$_].Order }

    $num = $toInstall.Count
    Write-Host "  ${CY}Installing $num package(s) via ${B}$($script:PM)${R}${CY}...${R}"
    Write-Host ""

    $ok = 0; $fail = 0; $failNames = @()

    foreach ($idx in $toInstall) {
        $p = $script:Pkgs[$idx]
        $n = $ok + $fail + 1
        Write-Host "  ${D}[$n/$num]${R} $($p.N)..." -NoNewline

        $log = Join-Path $env:TEMP "dd-install-$($p.Id).log"
        try {
            & "Install-$($p.Id)" *> $log
            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "exit $LASTEXITCODE" }
            Write-Host " ${GR}ok${R}"
            $ok++
        }
        catch {
            $_ | Out-File $log -Append
            Write-Host " ${RD}failed${R}"
            $fail++
            $failNames += $p.N
        }
    }

    Write-Host ""
    if ($fail -eq 0) {
        Write-Host "  ${GR}${B}All $ok done.${R}"
    }
    else {
        Write-Host "  ${GR}$ok ok${R}, ${RD}$fail failed ($($failNames -join ', '))${R}"
        Write-Host "  ${D}Logs in $env:TEMP${R}"
    }
    Write-Host ""
}

Main
