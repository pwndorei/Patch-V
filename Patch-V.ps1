Param
(
    [Parameter(Mandatory=$true)]
    $Path,
    $Out=".\patched",
    $SkipRev=$false
)
function Get-HvDirs($Dir)
{
    return (Get-ChildItem -Path $Dir -Filter "amd64*hyper*") #amd64_hyperv or amd64_microsoft....hyper-v
}

function Get-LocalHvBins($Dir)
{
    $result = @{}
    foreach($d in $Dir)
    {
        $bin = Get-ChildItem -Path $d.FullName -Attributes Archive
        foreach($b in $bin)
        {
            if($b.Extension -ne ".exe" -and $b.Extension -ne ".dll" -and $b.Extension -ne ".sys")
            {
                continue
            }
            $tmp = @{}
            $parent = $b.FullName | Split-Path
            $tmp['bin'] = $b.FullName
            $tmp['f'] = Join-Path $parent (Join-Path "f" $b.Name)
            $tmp['r'] = Join-Path $parent (Join-Path "r" $b.Name)
            $result[$b.Name] = $tmp
        }
    }
    return $result
}


function Get-Patch($Dir)
{
    $patch_info = @{}
    foreach($d in $Dir)
    {
        if(!(Test-Path (Join-Path $d.FullName "f")))
        {
            continue
        }
        foreach($forward in Get-ChildItem -Path (Join-Path $d.FullName "f"))
        {
            $patch_info[$forward.Name] = $forward.FullName
        }
    }
    return $patch_info
}

function Get-BaseFile()
{

    if(!(Test-Path ".\base\"))
    {
        New-Item -Path ".\base" -ItemType Directory
    }


    $Src = "C:\Windows\WinSxS"

    Write-Host ("Find all hyper-v directory from {0}" -f $Src)
    $local = Get-HvDirs -Dir $Src

    Write-Host ("Hyper-V directory found from local:{0}" -f $local.length)

    $bin = Get-LocalHvBins -Dir $local

    foreach($b in $bin.GetEnumerator())
    {
        $bin_name = $b.name
        $patch_info = $bin[$b.Name]

        if(!(Test-Path $patch_info['r']))
        {
            Write-Host ("{0} has no reverse patch, is it already initial version?" -f $bin_name)
            Copy-Item -Path $patch_info['bin'] -Destination (Join-Path ".\base" $bin_name)
        }
        else
        {
            $arg = "delta_patch.py -i {0} -o {1} {2}" -f $patch_info['bin'], (Join-Path ".\base" $bin_name), $patch_info['r']
            Wait-Process -Id (Start-Process "python" -PassThru -ArgumentList $arg -NoNewWindow).Id
        }

    }
}

function Start-ForwardPatch($Patch)
{
    $Base = Get-ChildItem -Path ".\base"

    if(!(Test-Path $Out))
    {
        New-Item -Path $Out -ItemType Directory
    }

    foreach($b in $Base)
    {
        if($null -eq $Patch[$b.Name])
        {
            Write-Host ("{0} not found from patch" -f $b.Name)
            continue
        }

        $arg = "delta_patch.py -i {0} -o {1} {2}" -f $b.FullName, (Join-Path $Out $b.Name), $Patch[$b.Name]
        Wait-Process -Id (Start-Process "python" -PassThru -ArgumentList $arg -NoNewWindow).Id
    }
}

Push-Location
Set-location -Path $PSScriptRoot

if((Test-Path ".\base") -and (Get-ChildItem -Path ".\base").length -ne 0)
{
    $SkipRev = (Read-Host -Prompt "base dir is not empty, skip reverse patching?[y/n]") -like "y*"
}

if(!$SkipRev)
{
    Get-BaseFile
}

$forwards = Get-Patch -Dir (Get-HvDirs -Dir $Path)

Start-ForwardPatch -Patch $forwards

Pop-Location