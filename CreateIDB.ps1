Param(
    [Parameter(Mandatory=$true)]
    [String] $Primary, #binary files(primary) location
    [Parameter(Mandatory=$true)]
    [String] $Secondary, #binary files(secondary) location
    [Parameter(Mandatory=$true)]
    [String] $IDA,
    $Arch="amd64",
	$PrimaryOut=$Primary,
	$SecondaryOut=$Secondary
)


function New-IDB($Bin)
{
	$cmd = "-A -S{0} -o{1} {2}"
	$db_format = ".i64"
	if($Arch -eq "amd64")
	{
		$IDA = Join-Path $IDA "idat64.exe"
		$db_format = ".i64"
	}
	else
	{
		$IDA = Join-Path $IDA "idat.exe"
		$db_format = ".idb"
	}
	foreach($b in $Bin)
	{
		if($b['primary'].Extension -eq ".exe" -or $b['primary'].Extension -eq ".dll" -or $b['primary'].Extension -eq ".sys")
		{
			Write-Host ("primary {0} vs secondary {1}" -f $b['primary'].Name, $b['secondary'].Name)
			$path = $b['primary'].FullName
			$idb = $b['primary'].Name + $db_format

			$arg = $cmd -f (Join-Path $PSScriptRoot "analysis.idc"), (Join-Path $PrimaryOut $idb), $path

			Write-Verbose $arg

			$p = (Start-Process $IDA -ArgumentList $arg -PassThru -WindowStyle Hidden).Id

			$path = $b['secondary'].FullName
			$idb = $b['secondary'].Name + $db_format

			$arg = $cmd -f (Join-Path $PSScriptRoot "analysis.idc"), (Join-Path $SecondaryOut $idb), $path
			Write-Verbose $arg

			$s = (Start-Process $IDA -ArgumentList $arg -PassThru -WindowStyle Hidden).Id

			Wait-Process -Id $p, $s
		}
	}

}


function Get-DiffBins($primary, $secondary)
{
	$result = @()# [[primary_bin1, $secondary_bin1]. [primary_bin2, secondary_bin2], ...]
	foreach($p in $primary)
	{
		$s = $secondary.Where({$_.Name -eq $p.Name})
		if($null -eq $s)
		{
			continue
		}
		if((Get-FileHash -Path $p.FullName).Hash -eq (Get-FileHash -Path $s.FullName).Hash)
		{
			continue
		}

		$tmp = @{}
		$tmp['primary'] = $p
		$tmp['secondary'] = $s[0]
		$result += $tmp
	}
	return $result
}


Push-Location

Set-Location -Path $PSScriptRoot

$diffs = Get-DiffBins -primary (Get-ChildItem -Path $Primary) -secondary (Get-ChildItem -Path $Secondary)

New-IDB -Bin $diffs

Pop-Location