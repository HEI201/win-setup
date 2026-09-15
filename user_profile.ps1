Import-Module Terminal-Icons
Import-Module posh-git
Import-Module PSReadLine
Import-Module PSFzf

$omp_config = Join-Path $PSScriptRoot ".\tokyo.custom.omp.json"
oh-my-posh init pwsh --config $omp_config | Invoke-Expression
$env:POSH_GIT_ENABLED = $true

# PSReadLine
# 设置预测文本来源为历史记录
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle None

# 每次回溯输入历史，光标定位于输入内容末尾
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
# 设置 Tab 为菜单补全和 Intellisense
Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete
# 设置 Ctrl+d 为退出 PowerShell
Set-PSReadlineKeyHandler -Key "Ctrl+d" -Function ViExit
# 设置 Ctrl+z 为撤销
Set-PSReadLineKeyHandler -Key "Ctrl+z" -Function Undo
# 设置向上键为后向搜索历史记录
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
# 设置向下键为前向搜索历史纪录
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
# 逐字补全
Set-PSReadLineKeyHandler -Chord "Ctrl+RightArrow" -Function ForwardWord

# Fzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

# Utilities
function which ($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}
  
function open {
    param
    (
        # 输入要打开的路径
        # 用法示例：open C:\
        # 默认路径：当前工作文件夹
        $Path = '.'
    )
    Invoke-Item $Path
}

function Set-Proxy {
    param (
        [string]$proxyProtocol = "http",
        [string]$proxyHost = "127.0.0.1",
        [int]$proxyPort = 10809
    )
    $proxy = "$proxyProtocol`://$proxyHost`:$proxyPort"
    $env:HTTP_PROXY = $proxy
    $env:HTTPS_PROXY = $proxy

    Write-Output $env:HTTP_PROXY
    Write-Output $env:HTTPS_PROXY
}

function Reset-Proxy { 
    $env:HTTP_PROXY = "" 
    $env:HTTPS_PROXY = ""

    Write-Output $env:HTTP_PROXY
    Write-Output $env:HTTPS_PROXY
}

function  monitoroff {
    nircmd.exe monitor off
}

function  togglevolume {
    nircmd.exe mutesysvolume 2
}

function  silent {
    nircmd.exe setvolume 0 0 0
}

function volumeup {
    param (
        [Parameter(Mandatory = $false)]
        [int]$amount = 6000
    )
    nircmd.exe changesysvolume $amount
}
function volumedown {
    param (
        [Parameter(Mandatory = $false)]
        [int]$amount = 6000
    )
    nircmd.exe changesysvolume -$amount
}
# Terminal tab title
# git 仓库：<emoji> {repoName}/{branchName}，若是 linked worktree 则结尾追加<emoji>
# 非 git 仓库：🧑‍💻 文件夹名
#
# 注意：Windows Terminal 的标签标题（TabHeaderControl 的 HeaderTextBlock）没有设置
# profile 字体，用的是系统 UI 字体（Segoe UI），所以 Nerd Font 私用区字形（U+E0A0 等）

function Get-TabTitle {
    param (
        # 用于计算标题的路径，默认为当前工作目录
        [string]$Path = $PWD.ProviderPath
    )

    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Container)) {
        return $null
    }

    $gitDir = & git --no-optional-locks -C $Path rev-parse --absolute-git-dir --path-format=absolute --git-common-dir 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $gitDir) {
        # 非 git 仓库：使用文件夹名
        $folder = Split-Path -Path $Path -Leaf
        if (-not $folder) { $folder = $Path.TrimEnd('\', '/') }
        elseif ($folder -match '^[A-Za-z]:[\\/]?$') { $folder = $folder.Substring(0, 2) }   # 驱动器根目录 -> C:
        return "🧑‍💻 $folder"
    }

    # --absolute-git-dir / --git-common-dir 依次输出两行
    $gitDir, $commonDir = @($gitDir)
    if (-not $commonDir) { $commonDir = $gitDir }

    $branch = & git --no-optional-locks -C $Path symbolic-ref --short -q HEAD 2>$null
    if (-not $branch) {
        # detached HEAD：使用短 hash
        $branch = & git --no-optional-locks -C $Path rev-parse --short HEAD 2>$null
    }

    # common dir 的父目录名即仓库名（worktree / submodule 也适用）
    $repoName = Split-Path -Path (Split-Path -Path $commonDir -Parent) -Leaf

    $title = "🎨 $repoName/$branch"
    if ($gitDir.TrimEnd('\', '/') -ne $commonDir.TrimEnd('\', '/')) {
        $title += " 🌿"
    }
    return $title
}

function Set-TabTitle {
    param (
        [string]$Path = $PWD.ProviderPath
    )
    $title = Get-TabTitle -Path $Path
    if (-not $title -or $Host.UI.RawUI.WindowTitle -eq $title) { return }
    try { $Host.UI.RawUI.WindowTitle = $title } catch { }
}

# 新开标签页时设置标题
Set-TabTitle

# 切换目录时同步更新（只在目录变化时查询 git，避免拖慢 prompt）
$ExecutionContext.SessionState.InvokeCommand.LocationChangedAction = { Set-TabTitle }

# Alias
Set-Alias vi nvim
Set-Alias ll ls
Set-Alias g git
Set-Alias grep findstr
Set-Alias tig "C:\Program Files\Git\usr\bin\tig.exe"
Set-Alias less "C:\Program Files\Git\usr\bin\less.exe"