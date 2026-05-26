#Requires -Version 5.1
param([switch]$Launched)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

# ─── style ───────────────────────────────────────────────────────────────────
$e = [char]27
$B  = "$e[1m";  $D = "$e[2m";  $R = "$e[0m"
$AC = "$e[38;5;75m"
$OK = "$e[38;5;114m"
$WN = "$e[38;5;222m"
$ER = "$e[38;5;168m"
$DM = "$e[38;5;243m"
$HD = "$e[38;5;252m"

$DOT_ON  = "$OK$([char]0x25CF)$R"
$DOT_OFF = "$DM$([char]0x25CB)$R"

# ─── packages ───────────────────────────────────────────────────────────────
$script:Pkgs = @(
    @{ Id='uv';        N='uv';             Ds='package manager';         C='DD Tools'; Sub='Python'; Order=1 }
    @{ Id='ruff';      N='Ruff';           Ds='linter / formatter';      C='DD Tools'; Sub='Python'; Order=2 }
    @{ Id='ty';        N='ty';             Ds='type checker';            C='DD Tools'; Sub='Python'; Order=3 }
    @{ Id='python313'; N='Python 3.13';    Ds='global via uv';           C='DD Tools'; Sub='Python'; Order=4 }
    @{ Id='git';       N='Git';            Ds='version control';         C='DD Tools'; Sub='';       Order=5 }
    @{ Id='azurecli';  N='Azure CLI';      Ds='+ DevOps extension';      C='DD Tools'; Sub='';       Order=6 }
    @{ Id='claudecode';N='Claude Code';    Ds='CLI agent';               C='DD Tools'; Sub='';       Order=7 }
    @{ Id='claudedesk';N='Claude Desktop'; Ds='desktop app';             C='DD Tools'; Sub='';       Order=8 }
    @{ Id='viktorcli'; N='Viktor CLI';     Ds='platform CLI';            C='DD Tools'; Sub='';       Order=9 }
    @{ Id='chrome';    N='Chrome';         Ds='browser by Google';       C='Browser';  Sub='';       Order=10 }
    @{ Id='firefox';   N='Firefox';        Ds='browser by Mozilla';      C='Browser';  Sub='';       Order=10 }
    @{ Id='curl';      N='curl';           Ds='HTTP client';             C='CLI';      Sub='';       Order=10 }
    @{ Id='wget';      N='wget';           Ds='downloader';              C='CLI';      Sub='';       Order=10 }
    @{ Id='jq';        N='jq';             Ds='JSON processor';          C='CLI';      Sub='';       Order=10 }
    @{ Id='ripgrep';   N='ripgrep';        Ds='fast search';             C='CLI';      Sub='';       Order=10 }
    @{ Id='fzf';       N='fzf';            Ds='fuzzy finder';            C='CLI';      Sub='';       Order=10 }
    @{ Id='bat';       N='bat';            Ds='better cat';              C='CLI';      Sub='';       Order=10 }
    @{ Id='eza';       N='eza';            Ds='better ls';               C='CLI';      Sub='';       Order=10 }
)

$script:NumPkgs = $script:Pkgs.Count
$script:Sel = New-Object bool[] $script:NumPkgs

# ─── build navigable rows ───────────────────────────────────────────────────
# rows: cat headers, sub headers, and packages — all navigable
# type: 'cat' | 'sub' | 'pkg'
$script:Rows = @()

function Build-Rows {
    $script:Rows = @()
    $prevCat = ''; $prevSub = ''
    for ($i = 0; $i -lt $script:NumPkgs; $i++) {
        $p = $script:Pkgs[$i]
        if ($p.C -ne $prevCat) {
            $script:Rows += ,@{ Type='cat'; Name=$p.C }
            $prevCat = $p.C; $prevSub = ''
        }
        if ($p.Sub -ne '' -and $p.Sub -ne $prevSub) {
            $script:Rows += ,@{ Type='sub'; Name=$p.Sub; Cat=$p.C }
            $prevSub = $p.Sub
        }
        $script:Rows += ,@{ Type='pkg'; Index=$i }
    }
}

Build-Rows
$script:NumRows = $script:Rows.Count
$script:Cur = 0

function Toggle-Category([string]$catName) {
    $indices = @()
    for ($i = 0; $i -lt $script:NumPkgs; $i++) {
        if ($script:Pkgs[$i].C -eq $catName) { $indices += $i }
    }
    $allOn = $true
    foreach ($i in $indices) { if (-not $script:Sel[$i]) { $allOn = $false; break } }
    foreach ($i in $indices) { $script:Sel[$i] = -not $allOn }
}

function Toggle-Sub([string]$catName, [string]$subName) {
    $indices = @()
    for ($i = 0; $i -lt $script:NumPkgs; $i++) {
        if ($script:Pkgs[$i].C -eq $catName -and $script:Pkgs[$i].Sub -eq $subName) { $indices += $i }
    }
    $allOn = $true
    foreach ($i in $indices) { if (-not $script:Sel[$i]) { $allOn = $false; break } }
    foreach ($i in $indices) { $script:Sel[$i] = -not $allOn }
}

function Get-CatSelected([string]$catName) {
    $all = $true; $any = $false
    for ($i = 0; $i -lt $script:NumPkgs; $i++) {
        if ($script:Pkgs[$i].C -eq $catName) {
            if ($script:Sel[$i]) { $any = $true } else { $all = $false }
        }
    }
    if ($all -and $any) { return 'all' }
    if ($any) { return 'some' }
    return 'none'
}

function Get-SubSelected([string]$catName, [string]$subName) {
    $all = $true; $any = $false
    for ($i = 0; $i -lt $script:NumPkgs; $i++) {
        if ($script:Pkgs[$i].C -eq $catName -and $script:Pkgs[$i].Sub -eq $subName) {
            if ($script:Sel[$i]) { $any = $true } else { $all = $false }
        }
    }
    if ($all -and $any) { return 'all' }
    if ($any) { return 'some' }
    return 'none'
}

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
    if (Get-Command uv -ErrorAction SilentlyContinue) { & uv tool install ruff 2>&1 }
    else { Run-Pkg 'Astral.Ruff' 'ruff' 'ruff' }
}
function Install-ty {
    Refresh-Path
    if (Get-Command uv -ErrorAction SilentlyContinue) { & uv tool install ty 2>&1 }
    else { throw "uv required" }
}
function Install-python313 {
    Refresh-Path
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        & uv python install 3.13 2>&1
        & uv python pin 3.13 --global 2>&1
    }
    else { throw "uv required" }
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
        Run-Pkg 'OpenJS.NodeJS.LTS' 'nodejs-lts' 'nodejs-lts'
        Refresh-Path
    }
    & npm install -g @anthropic-ai/claude-code 2>&1
}
function Install-claudedesk { Run-Pkg 'Anthropic.Claude' 'claude' 'claude' }
function Install-viktorcli {
    Refresh-Path
    if (Get-Command uv -ErrorAction SilentlyContinue) { & uv tool install viktor-cli 2>&1 }
    elseif (Get-Command pip -ErrorAction SilentlyContinue) { & pip install viktor-cli 2>&1 }
    else { throw "need uv or pip" }
}
function Install-chrome  { Run-Pkg 'Google.Chrome'  'googlechrome' 'googlechrome' }
function Install-firefox { Run-Pkg 'Mozilla.Firefox' 'firefox'     'firefox'      }
function Install-curl    { Run-Pkg 'cURL.cURL'                  'curl'    'curl'    }
function Install-wget    { Run-Pkg 'JernejSimoncic.Wget'        'wget'    'wget'    }
function Install-jq      { Run-Pkg 'jqlang.jq'                  'jq'      'jq'      }
function Install-ripgrep { Run-Pkg 'BurntSushi.ripgrep.MSVC'    'ripgrep' 'ripgrep' }
function Install-fzf     { Run-Pkg 'junegunn.fzf'               'fzf'     'fzf'     }
function Install-bat     { Run-Pkg 'sharkdp.bat'                'bat'     'bat'     }
function Install-eza     { Run-Pkg 'eza-community.eza'          'eza'     'eza'     }

# ─── draw ────────────────────────────────────────────────────────────────────
$script:StartLine = 0

function Draw-List {
    [Console]::SetCursorPosition(0, $script:StartLine)

    $prevCat = ''

    for ($r = 0; $r -lt $script:NumRows; $r++) {
        $row = $script:Rows[$r]
        $isCur = ($r -eq $script:Cur)
        $arrow = if ($isCur) { "${AC}>${R} " } else { '  ' }

        if ($row.Type -eq 'cat') {
            if ($prevCat -ne '') { Write-Host "" }
            $prevCat = $row.Name

            $st = Get-CatSelected $row.Name
            $dot = switch ($st) {
                'all'  { $DOT_ON }
                'some' { "${WN}$([char]0x25D2)${R}" }
                default { $DOT_OFF }
            }

            if ($isCur) {
                Write-Host "  ${arrow}${dot} ${HD}${B}$($row.Name)${R}"
            }
            else {
                Write-Host "  ${arrow}${dot} ${HD}${B}$($row.Name)${R}"
            }
        }
        elseif ($row.Type -eq 'sub') {
            $st = Get-SubSelected $row.Cat $row.Name
            $dot = switch ($st) {
                'all'  { $DOT_ON }
                'some' { "${WN}$([char]0x25D2)${R}" }
                default { $DOT_OFF }
            }

            if ($isCur) {
                Write-Host "    ${arrow}${dot} ${AC}$($row.Name)${R}"
            }
            else {
                Write-Host "    ${arrow}${dot} ${AC}$($row.Name)${R}"
            }
        }
        else {
            $p = $script:Pkgs[$row.Index]
            $dot = if ($script:Sel[$row.Index]) { $DOT_ON } else { $DOT_OFF }
            $name = $p.N.PadRight(18)
            $indent = if ($p.Sub -ne '') { '        ' } else { '      ' }
            $hi = if ($isCur) { $B } else { '' }

            Write-Host "${indent}${arrow}${dot} ${hi}${name}${R}${DM}$($p.Ds)${R}"
        }
    }

    $count = @($script:Sel | Where-Object { $_ -eq $true }).Count
    Write-Host ""
    if ($count -gt 0) {
        Write-Host "  ${OK}${B}$count selected${R}  ${DM}enter install / q quit${R}      "
    }
    else {
        Write-Host "  ${DM}space select / a all / enter install / q quit${R}      "
    }
}

function Reserve-Lines {
    $lines = 1
    $prevCat = ''
    for ($r = 0; $r -lt $script:NumRows; $r++) {
        $row = $script:Rows[$r]
        if ($row.Type -eq 'cat' -and $prevCat -ne '') { $lines++ }
        if ($row.Type -eq 'cat') { $prevCat = $row.Name }
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
    Write-Host "  ${AC}${B}dd-install${R}"
    Write-Host ""

    Reserve-Lines
    Draw-List

    try {
        while ($true) {
            $key = [Console]::ReadKey($true)

            switch ($key.Key) {
                'UpArrow'   { if ($script:Cur -gt 0) { $script:Cur-- } }
                'DownArrow' { if ($script:Cur -lt ($script:NumRows - 1)) { $script:Cur++ } }
                'K'         { if ($script:Cur -gt 0) { $script:Cur-- } }
                'J'         { if ($script:Cur -lt ($script:NumRows - 1)) { $script:Cur++ } }
                'Spacebar'  {
                    $row = $script:Rows[$script:Cur]
                    if ($row.Type -eq 'cat') {
                        Toggle-Category $row.Name
                    }
                    elseif ($row.Type -eq 'sub') {
                        Toggle-Sub $row.Cat $row.Name
                    }
                    else {
                        $script:Sel[$row.Index] = -not $script:Sel[$row.Index]
                    }
                    if ($script:Cur -lt ($script:NumRows - 1)) { $script:Cur++ }
                }
                'A' {
                    $anyOff = @($script:Sel | Where-Object { $_ -eq $false }).Count -gt 0
                    for ($i = 0; $i -lt $script:NumPkgs; $i++) { $script:Sel[$i] = $anyOff }
                }
                'Enter' {
                    [Console]::CursorVisible = $true
                    Write-Host ""; Write-Host ""
                    Run-Installs
                    return
                }
                'Q' {
                    [Console]::CursorVisible = $true
                    Write-Host ""; Write-Host "  ${DM}cancelled${R}"; Write-Host ""
                    return
                }
                'Escape' {
                    [Console]::CursorVisible = $true
                    Write-Host ""; Write-Host "  ${DM}cancelled${R}"; Write-Host ""
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
    for ($i = 0; $i -lt $script:NumPkgs; $i++) {
        if ($script:Sel[$i]) { $toInstall += $i }
    }

    if ($toInstall.Count -eq 0) {
        Write-Host "  ${WN}nothing selected${R}"; Write-Host ""
        return
    }

    Detect-PM

    if ($script:PM -eq 'none') {
        Write-Host "  ${ER}no package manager found${R}"
        Write-Host "  ${DM}install winget, choco, or scoop first${R}"; Write-Host ""
        return
    }

    $toInstall = $toInstall | Sort-Object { $script:Pkgs[$_].Order }
    $num = $toInstall.Count

    Write-Host "  ${AC}installing $num package(s)${R} ${DM}via $($script:PM)${R}"
    Write-Host ""

    $ok = 0; $fail = 0; $failNames = @()

    foreach ($idx in $toInstall) {
        $p = $script:Pkgs[$idx]
        $n = $ok + $fail + 1
        Write-Host "  ${DM}$n/$num${R}  $($p.N)" -NoNewline

        $log = Join-Path $env:TEMP "dd-install-$($p.Id).log"
        try {
            & "Install-$($p.Id)" *> $log
            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "exit $LASTEXITCODE" }
            Write-Host "  ${OK}done${R}"
            $ok++
        }
        catch {
            $_ | Out-File $log -Append
            Write-Host "  ${ER}failed${R}"
            $fail++
            $failNames += $p.N
        }
    }

    Write-Host ""
    if ($fail -eq 0) {
        Write-Host "  ${OK}all done${R}"
    }
    else {
        Write-Host "  ${OK}$ok done${R}  ${ER}$fail failed${R} ${DM}($($failNames -join ', '))${R}"
        Write-Host "  ${DM}logs in $env:TEMP${R}"
    }
    Write-Host ""
}

Main
