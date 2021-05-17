## Powershell file buffering script
## needs administrator privileges
## v0.6

$bfr_folder = 'D:\Crypto\Chia\PlotsBuffer' # SSD buffer folder
$farm_hdd_destinations = @('K:\Plots','L:\Plots','I:\Plots') # DestinationFarming folders

$global:hdd_current_index = 0; # start with the first path in $farm_hdd_destinations
$farm_hdd_destinations_count = $farm_hdd_destinations.count

function CheckEnoughSpace {
	Param(
        $path
    );

    $free = Get-WmiObject Win32_Volume -Filter "DriveType=3" |
            Where-Object { $path -like "$($_.Name)*" } |
            Sort-Object Name -Desc |
            Select-Object -First 1 FreeSpace |
            ForEach-Object { $_.FreeSpace / (1024*1024) }
	
	if ([int]$free -lt 110) {
		Write-Host WARNING! Path $path has [int]$free free
		return $false
	}
	Write-Host Path $path has $free free
	return $true
}

function RotateFarmDest ([REF]$cur_index) {
	if ($cur_index.Value -ne $farm_hdd_destinations_count - 1) {
		$cur_index.Value = $cur_index.Value + 1
	} else {
		$cur_index.Value = 0
	}
	Write-Host Rotating to next farming path: $farm_hdd_destinations[$global:hdd_current_index]
}

while ($true)
{   
    $check_interval = 30 # in seconds
	
    $chia_running = ((get-process -Name chia).path | findstr unpacked).count
    $current_time = (Get-Date -f HH:mm)
    $current_date_time = (Get-Date -f MM-dd-HH:mm:ss)
    $count = (Get-ChildItem -Path $bfr_folder -Force | Where-Object {$_.Extension -eq '.plot'}).count
	

    if ($count -gt 0)
    {
        Write-Host $current_time $count new plots found. Beginning Transfer
		if (CheckEnoughSpace $farm_hdd_destinations[$global:hdd_current_index]) {
			robocopy $bfr_folder $farm_hdd_destinations[$global:hdd_current_index] /MOV /XX *.plot
		} else {
			Write-Host Not enough space on $farm_hdd_destinations[$global:hdd_current_index]. Moving to the next one
			RotateFarmDest ([REF]$global:hdd_current_index)
		}
		RotateFarmDest ([REF]$global:hdd_current_index)
    }
    else
    {   
        Write-Host $current_date_time":" "There are" $chia_running "Chia plotters running."
        Write-Host $current_date_time":" $count "plot files found."
        [int]$Time = $check_interval
        $Length = $Time / 100
        For ($Time; $Time -gt 0; $Time--) {
			$min = [int](([string]($Time/60)).split('.')[0])
			$text = " " + $min + " minutes " + ($Time % 60) + " seconds left"
			Write-Progress -Activity "No new files... Watiting for..." -Status $Text -PercentComplete ($Time / $Length)
			Start-Sleep 1  ## countdown timer for checking folder activity, default = plot interval, line 31
		}
	}
}


