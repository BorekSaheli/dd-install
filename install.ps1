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
$AC = "$e[38;5;75m"   # accent: soft blue
$OK = "$e[38;5;114m"  # green
$WN = "$e[38;5;222m"  # yellow
$ER = "$e[38;5;168m"  # red
$DM = "$e[38;5;243m"  # dim
$HD = "$e[38;5;252m"  # header (bright white)

$DOT_ON  = "$OK$([char]0x25CF)$R"   # ●
$DOT_OFF = "$DM$([char]0x25CB)$R"   # ○

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
function Install-chrome  { Run-Pkg 'Google.Chrome'              'googlechrome'   'googlechrome'}
function Install-firefox { Run-Pkg 'Mozilla.Firefox'            'firefox'        'firefox'     }

# ─── draw ────────────────────────────────────────────────────────────────────
$script:StartLine = 0

function Draw-List {
    [Console]::SetCursorPosition(0, $script:StartLine)
    $prevCat = ''; $prevSub = ''

    for ($i = 0; $i -lt $script:Total; $i++) {
        $p = $script:Pkgs[$i]

        if ($p.C -ne $prevCat) {
            if ($prevCat -ne '') { Write-Host "" }
            Write-Host "  ${HD}${B}$($p.C)${R}"
            Write-Host ""
            $prevCat = $p.C; $prevSub = ''
        }

        if ($p.Sub -ne '' -and $p.Sub -ne $prevSub) {
            Write-Host "    ${AC}$($p.Sub)${R}"
            $prevSub = $p.Sub
        }

        $dot = if ($script:Sel[$i]) { $DOT_ON } else { $DOT_OFF }
        $name = $p.N.PadRight(18)
        $indent = if ($p.Sub -ne '') { '      ' } else { '    ' }

        if ($i -eq $script:Cur) {
            Write-Host "${indent}${AC}>${R} ${dot} ${B}${name}${R}${DM}$($p.Ds)${R}"
        }
        else {
            Write-Host "${indent}  ${dot} ${name}${DM}$($p.Ds)${R}"
        }
    }

    $count = @($script:Sel | Where-Object { $_ -eq $true }).Count
    Write-Host ""
    if ($count -gt 0) {
        Write-Host "  ${OK}${B}$count selected${R}  ${DM}enter install ${DM}${AC}${DM}/ q quit${R}      "
    }
    else {
        Write-Host "  ${DM}space select / a all / g dd tools / enter install / q quit${R}      "
    }
}

function Reserve-Lines {
    $lines = 1
    $prevCat = ''; $prevSub = ''
    for ($i = 0; $i -lt $script:Total; $i++) {
        $p = $script:Pkgs[$i]
        if ($p.C -ne $prevCat) {
            if ($prevCat -ne '') { $lines++ }
            $lines += 2; $prevCat = $p.C; $prevSub = ''
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
    Write-Host "  ${AC}${B}dd-install${R}"
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
    for ($i = 0; $i -lt $script:Total; $i++) {
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
