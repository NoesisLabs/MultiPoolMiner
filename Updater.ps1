using module .\Include.psm1

param([String]$MPMVersion, [String]$PSVersion, [String]$NFVersion)

if ($script:MyInvocation.MyCommand.Path) {Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)}

$ProgressPreferenceBackup = $ProgressPreference

$Name = "MultiPoolMiner"
try {
    $ProgressPreference = "SilentlyContinue"
    New-Alias -Name git -Value "$Env:ProgramFiles\Git\bin\git.exe"
    $TagName = git describe --abbrev=0 --tags
    $Version = ($TagName -replace '^v')

    if ($Version -ne $MPMVersion) {
        $ProgressPreference = $ProgressPreferenceBackup
        Write-Progress -Activity "Updater" -Status $Name -CurrentOperation "Pulling changes from git"
        $PullResult = git pull
        Write-Progress -Activity "Updater" -Status $Name -CurrentOperation $PullResult
        $ProgressPreference = "SilentlyContinue"
        Write-Warning "$Name is out of date; current version is $MPMVersion and version $Version is available. "
    }
}
catch {
    Write-Warning "The software ($Name) failed to update. "
}

$Name = "PowerShell"
try {
    $ProgressPreference = "SilentlyContinue"
    $Request = Invoke-RestMethod -Uri "https://api.github.com/repos/powershell/$Name/releases/latest" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    $Version = ($Request.tag_name -replace '^v')
    $URI = $Request.assets | Where-Object Name -EQ "$($Name)-$($Version)-win-x64.msi" | Select-Object -ExpandProperty browser_download_url

    if ($Version -ne $PSVersion) {
        $ProgressPreference = $ProgressPreferenceBackup
        Write-Progress -Activity "Updater" -Status $Name -CurrentOperation "Acquiring Online ($URI)"
        $ProgressPreference = "SilentlyContinue"
        Expand-WebRequest $URI -ErrorAction Stop
    }
}
catch {
    Write-Warning "The software ($Name) failed to update. "
}

$ProgressPreference = $ProgressPreferenceBackup

Write-Progress -Activity "Updater" -Completed
