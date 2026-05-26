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
$RD = "$e[31m";  $MG = "$e[35m"; $BG = "$e[7m"

# ─── packages ───────────────────────────────────────────────────────────────
$script:Pkgs = @(
    @{ Id='python';  N='Python';        Ds='python3 + pip';            C='Languages' }
    @{ Id='node';    N='Node.js';       Ds='JavaScript runtime LTS';   C='Languages' }
    @{ Id='rust';    N='Rust';          Ds='via rustup';               C='Languages' }
    @{ Id='go';      N='Go';            Ds='by Google';                C='Languages' }
    @{ Id='git';     N='Git';           Ds='version control';          C='Dev Tools' }
    @{ Id='ruff';    N='Ruff';          Ds='Python linter/formatter';  C='Dev Tools' }
    @{ Id='uv';      N='uv';            Ds='Python package manager';   C='Dev Tools' }
    @{ Id='docker';  N='Docker';        Ds='containers';               C='Dev Tools' }
    @{ Id='gh';      N='GitHub CLI';    Ds='gh';                       C='Dev Tools' }
    @{ Id='code';    N='VS Code';       Ds='editor';                   C='Editors' }
    @{ Id='neovim';  N='Neovim';        Ds='vim-based editor';         C='Editors' }
    @{ Id='chrome';  N='Chrome';        Ds='browser';                  C='Apps' }
    @{ Id='firefox'; N='Firefox';       Ds='browser';                  C='Apps' }
    @{ Id='curl';    N='curl';          Ds='HTTP client';              C='CLI' }
    @{ Id='wget';    N='wget';          Ds='downloader';               C='CLI' }
    @{ Id='jq';      N='jq';            Ds='JSON processor';           C='CLI' }
    @{ Id='ripgrep'; N='ripgrep';       Ds='fast search (rg)';         C='CLI' }
    @{ Id='fzf';     N='fzf';           Ds='fuzzy finder';             C='CLI' }
    @{ Id='htop';    N='htop';          Ds='process viewer';           C='CLI' }
    @{ Id='bat';     N='bat';           Ds='better cat';               C='CLI' }
    @{ Id='eza';     N='eza';           Ds='better ls';                C='CLI' }
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

function Install-python  { Run-Pkg 'Python.Python.3.12'         'python3'        'python'      }
function Install-node    { Run-Pkg 'OpenJS.NodeJS.LTS'          'nodejs-lts'     'nodejs-lts'  }
function Install-rust    {
    switch ($script:PM) {
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
    switch ($script:PM) {
        'winget' { & winget install --id ntop.Ntop -e --accept-source-agreements --accept-package-agreements --silent 2>&1 }
        'choco'  { & choco install ntop.portable -y 2>&1 }
        'scoop'  { & scoop install ntop 2>&1 }
    }
}
function Install-bat     { Run-Pkg 'sharkdp.bat'                'bat'            'bat'         }
function Install-eza     { Run-Pkg 'eza-community.eza'          'eza'            'eza'         }

# ─── draw the list inline ───────────────────────────────────────────────────
$script:StartLine = 0

function Draw-List {
    [Console]::SetCursorPosition(0, $script:StartLine)
    $prevCat = ''

    for ($i = 0; $i -lt $script:Total; $i++) {
        $p = $script:Pkgs[$i]

        if ($p.C -ne $prevCat) {
            if ($prevCat -ne '') { Write-Host "" }
            Write-Host "  ${MG}${B}$($p.C)${R}"
            $prevCat = $p.C
        }

        $box = if ($script:Sel[$i]) { "${GR}[x]${R}" } else { "[ ]" }
        $arrow = if ($i -eq $script:Cur) { "${CY}${B}>${R} " } else { "  " }
        $name = $p.N.PadRight(14)
        $hi = if ($i -eq $script:Cur) { $B } else { '' }

        Write-Host "  ${arrow}${box} ${hi}${name}${R} ${D}$($p.Ds)${R}"
    }

    $count = @($script:Sel | Where-Object { $_ -eq $true }).Count
    Write-Host ""
    if ($count -gt 0) {
        Write-Host "  ${GR}${B}$count selected${R}  ${D}Enter=install  q=quit${R}    "
    }
    else {
        Write-Host "  ${D}Space=toggle  a=all  Enter=install  q=quit${R}    "
    }
}

function Reserve-Lines {
    $lines = 2
    $prevCat = ''
    for ($i = 0; $i -lt $script:Total; $i++) {
        if ($script:Pkgs[$i].C -ne $prevCat) {
            if ($prevCat -ne '') { $lines++ }
            $lines++
            $prevCat = $script:Pkgs[$i].C
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
