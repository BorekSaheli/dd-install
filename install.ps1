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
    @{ Id='nerdfont';  N='JetBrains Mono'; Ds='nerd font + terminal';    C='DD Tools'; Sub='Config'; Order=5 }
    @{ Id='starship';  N='Starship';       Ds='cross-shell prompt';      C='DD Tools'; Sub='Config'; Order=6 }
    @{ Id='chezmoi';   N='chezmoi';        Ds='dotfiles from GitHub';    C='DD Tools'; Sub='Config'; Order=99 }
    @{ Id='git';       N='Git';            Ds='version control';         C='DD Tools'; Sub='';       Order=0 }
    @{ Id='azurecli';  N='Azure CLI';      Ds='+ DevOps extension';      C='DD Tools'; Sub='';       Order=11 }
    @{ Id='claudecode';N='Claude Code';    Ds='CLI agent';               C='DD Tools'; Sub='';       Order=12 }
    @{ Id='claudedesk';N='Claude Desktop'; Ds='desktop app';             C='DD Tools'; Sub='';       Order=13 }
    @{ Id='pwsh';      N='PowerShell 7';   Ds='default shell';           C='DD Tools'; Sub='';       Order=14 }
    @{ Id='komorebi';  N='komorebi';       Ds='tiling window manager';   C='DD Tools'; Sub='';       Order=15 }
    @{ Id='viktorcli'; N='Viktor CLI';     Ds='platform CLI';            C='DD Tools'; Sub='';       Order=16 }
    @{ Id='chrome';    N='Chrome';         Ds='browser by Google';       C='Browser';  Sub='';       Order=20 }
    @{ Id='firefox';   N='Firefox';        Ds='browser by Mozilla';      C='Browser';  Sub='';       Order=20 }
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
function Install-chezmoi {
    Run-Pkg 'twpayne.chezmoi' 'chezmoi' 'chezmoi'
    Refresh-Path
    & chezmoi init --apply BorekSaheli/dotfiles 2>&1
}
function Install-nerdfont {
    $fontZip = Join-Path $env:TEMP 'JetBrainsMono-NF.zip'
    $fontDir = Join-Path $env:TEMP 'JetBrainsMono-NF'
    Invoke-RestMethod 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip' -OutFile $fontZip
    Expand-Archive -Path $fontZip -DestinationPath $fontDir -Force
    $shell = New-Object -ComObject Shell.Application
    $fontsFolder = $shell.Namespace(0x14)
    Get-ChildItem $fontDir -Filter '*.ttf' | ForEach-Object {
        $fontsFolder.CopyHere($_.FullName, 0x10)
    }
    Remove-Item $fontZip -Force -ErrorAction SilentlyContinue
    Remove-Item $fontDir -Recurse -Force -ErrorAction SilentlyContinue

    $wtSettings = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    if (Test-Path $wtSettings) {
        $json = Get-Content $wtSettings -Raw | ConvertFrom-Json
        if (-not $json.profiles.defaults.PSObject.Properties['font']) {
            $json.profiles.defaults | Add-Member -NotePropertyName 'font' -NotePropertyValue @{} -Force
        }
        $json.profiles.defaults.font = @{ face = 'JetBrainsMono Nerd Font'; size = 12 }
        $json | ConvertTo-Json -Depth 20 | Set-Content $wtSettings -Encoding UTF8
        Write-Output "Set JetBrainsMono Nerd Font as Windows Terminal default"
    }
}
function Install-starship {
    Run-Pkg 'Starship.Starship' 'starship' 'starship'
    Refresh-Path
    $profileDir = Split-Path $PROFILE
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
    $initLine = 'Invoke-Expression (&starship init powershell)'
    if (-not (Test-Path $PROFILE) -or -not (Select-String -Path $PROFILE -Pattern 'starship init' -Quiet)) {
        Add-Content -Path $PROFILE -Value "`n$initLine"
        Write-Output "Added starship init to $PROFILE"
    }
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
function Install-pwsh {
    Run-Pkg 'Microsoft.PowerShell' 'powershell-core' 'pwsh'
    Refresh-Path
    $wtSettings = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    if (Test-Path $wtSettings) {
        $json = Get-Content $wtSettings -Raw | ConvertFrom-Json
        $pwshProfile = $json.profiles.list | Where-Object { $_.name -match 'PowerShell' -and $_.source -eq 'Windows.Terminal.PowershellCore' } | Select-Object -First 1
        if ($pwshProfile) {
            $json.defaultProfile = $pwshProfile.guid
            $json | ConvertTo-Json -Depth 20 | Set-Content $wtSettings -Encoding UTF8
            Write-Output "Set PowerShell 7 as default Windows Terminal profile"
        }
    }
}
function Install-komorebi {
    Run-Pkg 'LGUG2Z.komorebi' 'komorebi' 'komorebi'
    Run-Pkg 'LGUG2Z.whkd' 'whkd' 'whkd'
}
function Install-chrome  { Run-Pkg 'Google.Chrome'  'googlechrome' 'googlechrome' }
function Install-firefox { Run-Pkg 'Mozilla.Firefox' 'firefox'     'firefox'      }

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
