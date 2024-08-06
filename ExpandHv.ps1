Param
(
    [Parameter(Mandatory=$true)]
    $Path,
    [Parameter(Mandatory=$true)]
    $Out,
    $limit=4
)


Push-Location

Set-Location $PSScriptRoot

$arguments = "-F:{0}", $Path, $Out
$arguments_list = @()

foreach($comp in (Get-Content -Path .\components.txt))
{
    $arguments_list += $arguments -f $comp
}

$arguments_list | Foreach-Object -ThrottleLimit $limit -Parallel {
    Wait-Process -Id (Start-Process -PassThru -FilePath "expand.exe" -ArgumentList $_ -NoNewWindow -RedirectStandardOutput ".\NUL").Id
}

Pop-Location
