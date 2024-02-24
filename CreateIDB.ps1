Param(
    [Parameter(Mandatory=$true)]
    [String] $Primary, #binary files(primary) location
    [Parameter(Mandatory=$true)]
    [String] $Secondary, #binary files(secondary) location
    [Parameter(Mandatory=$true)]
    [String] $IDA,
    $Arch="amd64"
)


function New-IDB($Bin)
{
	if($Arch -eq "amd64")
	{
		$IDA = Join-Path $IDA "idat64.exe"
	}
	else
	{
		$IDA = Join-Path $IDA "idat.exe"
	}
	foreach($b in $Bin)
	{
		if($b['primary'].Extension -eq ".exe" -or $b['primary'].Extension -eq ".dll" -or $b['primary'].Extension -eq ".sys")
		{
			Write-Host ("primary {0} vs secondary {1}" -f $b['primary'].Name, $b['secondary'].Name)
			$path = $b['primary'].FullName
			$arg = "-B $path"

			$p = (Start-Process $IDA -ArgumentList $arg -PassThru -WindowStyle Hidden).Id

			$path = $b['secondary'].FullName
			$arg = "-B $path"
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
		if((Get-FileHash -Path $p.FullName) -eq (Get-FileHash -Path $s.FullName))
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


$diffs = Get-DiffBins -primary (Get-ChildItem -Path $Primary) -secondary (Get-ChildItem -Path $Secondary)

New-IDB -Bin $diffs