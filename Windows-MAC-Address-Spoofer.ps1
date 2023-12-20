#####################################################################################################
#																									#
# File Name: Windows-MAC-Address-Spoofer.ps1	# Output:											#
# Author: Ammar S.A.A							# Changes the MAC address of the active				#
# Version: 1.4									# network adapter on Windows via registry.			#
#																									#
#####################################################################################################
#						https://github.com/ammarsaa/Windows-MAC-Address-Spoofer						#
#####################################################################################################

# Check for admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
	Write-Host "`n# Administrator privileges are required." -ForegroundColor Yellow
	Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	exit
}

# Variable(s)
$regPath = "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"

# Function to retrieve current MAC address
function Get-MAC {
	$nicIndex = Get-NICIndex
	$macAddress = (Get-ItemProperty -Path "$regPath\$nicIndex" -Name "NetworkAddress" -ErrorAction SilentlyContinue).NetworkAddress

	if (-not $macAddress) {
		$macAddress = (Get-WmiObject -Class Win32_NetworkAdapter | Where-Object { $_.NetConnectionId -eq $NetworkAdapter }).MacAddress
	}

	return $macAddress
}

# Function to generate random MAC address
function Generate-MAC {
	$hexChars = "0123456789ABCDEF`AE26"
	$macAddress = ""

	for ($i = 1; $i -le 11; $i++) {
		$randomIndex = Get-Random -Minimum 0 -Maximum 16
		$macAddress += $hexChars[$randomIndex]
	}

	$randomIndex = Get-Random -Minimum 17 -Maximum 21
	$macAddress = $macAddress.Substring(0, 1) + $hexChars[$randomIndex] + $macAddress.Substring(1)
	return $macAddress
}

# Function to retrieve NIC index
function Get-NICIndex {
	$nicCaption = (Get-WmiObject -Class Win32_NetworkAdapter | Where-Object { $_.NetConnectionId -eq $NetworkAdapter }).Caption
	$nicIndex = $nicCaption -replace ".*\[", "" -replace "\].*"
	$nicIndex = $nicIndex.Substring($nicIndex.Length - 4)
	return $nicIndex
}

# Function to spoof MAC address
function Spoof-MAC {
	$originalMAC = Get-MAC
	Write-Host "`n# Selected NIC: "-f red -nonewline; Write-Host "$NetworkAdapter" -f white
	Write-Host "# Previous MAC: "-f red -nonewline; Write-Host "$originalMAC" -f white
	
	Write-Host "`n1 "-f red -nonewline; Write-Host "- Use Random MAC Address" -f white
	Write-Host "2 "-f red -nonewline; Write-Host "- Enter Custom MAC Address" -f white
	
	$choice = Read-Host "# Choose an option"
	
	switch ($choice) {
		1 { Spoof-Random-MAC }
		2 { Set-Custom-MAC }
		default { Invalid-Selection }
	}
}

# Function to spoof a random MAC address
function Spoof-Random-MAC {
	$macAddress = Generate-MAC
	$nicIndex = Get-NICIndex

	if (-not $nicIndex) {
		Write-Host "`n# NIC index not found. Aborting MAC spoofing." -ForegroundColor Red
		Exit-Menu
	}

	Write-Host "# Spoofed MAC:" -f red -nonewline; Write-Host " $macAddress" -f white

	# Disable NIC, delete OriginalNetworkAddress registry entry, add NetworkAddress registry entry, enable NIC
	Disable-NetAdapter -InterfaceAlias $NetworkAdapter
	$registryPath = "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\$nicIndex"

	if (Test-Path $registryPath) {
		Remove-ItemProperty -Path $registryPath -Name "OriginalNetworkAddress" -ErrorAction SilentlyContinue

		Write-Host "`n# Registry Path: $registryPath"
		Write-Host "# NIC Index: $nicIndex"

		try {
			Set-ItemProperty -Path $registryPath -Name "NetworkAddress" -Value $macAddress
		} catch {
			Write-Host "Error setting registry property: $_" -ForegroundColor Red
			# Log the error if needed
		}
	} else {
		Write-Host "`n# Registry path not found: $registryPath" -ForegroundColor Red
		# Log the error if needed
	}

	Enable-NetAdapter -InterfaceAlias $NetworkAdapter

	Write-Host "`n# Press any key to continue..."
	$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

	Exit-Menu
}

# Function to handle invalid selection
function Invalid-Selection {
	Write-Host "`n# Invalid selection. Please choose a valid option." -ForegroundColor Red
	Start-Sleep -Seconds 2
	Selection-Menu
}

# Function to manually set a custom MAC address
function Set-Custom-MAC {
	$originalMAC = Get-MAC
	$customMAC = Read-Host "`n# Enter the custom MAC address for $NetworkAdapter (format: 12:34:56:78:90:AB):"

	if ($customMAC -match '^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$') {
		$nicIndex = Get-NICIndex

		Write-Host "`n# Selected NIC:"-f red -nonewline; Write-Host " $NetworkAdapter"
		Write-Host "# Previous MAC:"-f red -nonewline; Write-Host " $originalMAC"
		Write-Host "# Custom MAC:"-f red -nonewline; Write-Host " $customMAC"

		# Disable NIC, delete OriginalNetworkAddress registry entry, add NetworkAddress registry entry, enable NIC
		Disable-NetAdapter -InterfaceAlias $NetworkAdapter
		Remove-ItemProperty -Path "$regPath\$nicIndex" -Name "OriginalNetworkAddress" -ErrorAction SilentlyContinue

		Write-Host "`n# Registry Path: $regPath\$nicIndex"
		Write-Host "# NIC Index: $nicIndex"

		try {
			Set-ItemProperty -Path "$regPath\$nicIndex" -Name "NetworkAddress" -Value $customMAC
		} catch {
			Write-Host "Error setting registry property: $_" -ForegroundColor Red
		}

		Enable-NetAdapter -InterfaceAlias $NetworkAdapter

		Write-Host "`n# Press any key to continue..."
		$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

		Exit-Menu
	} else {
		Write-Host "`n# Invalid MAC address format. Please enter a valid MAC address." -ForegroundColor Red
		Set-Custom-MAC
	}
}

# Function to display selection menu
function Selection-Menu {
	Clear-Host
	Write-Host "`n[i] Input Network Interface Controller(NIC) # to modify.`n" -ForegroundColor Magenta
	$nic = Get-WmiObject -Class Win32_NetworkAdapter | Select-Object -ExpandProperty NetConnectionId
	$count = 1

	$nic | ForEach-Object {
		Write-Host "$count "-f red -nonewline; 
		Write-Host "- $_" -f White
		$count++
	}

	Write-Host "`n99 "-f red -nonewline; Write-Host "- Revise Networking`n" -f white
	$nicSelection = Read-Host "# "
	$nicSelection = [int]$nicSelection

	if ($nicSelection -gt 0 -and $nicSelection -le $nic.Count) {
		$NetworkAdapter = $nic[$nicSelection - 1]
		Spoof-MAC
	} elseif ($nicSelection -eq 99) {
		Clear-Host
		Write-Host "# Revising networking configurations..." -ForegroundColor Green
		ipconfig /release
		arp -d *
		ipconfig /renew
		Start-Sleep -Seconds 2
		Selection-Menu
	} else {
		Invalid-Selection
	}
}

# Function to display exit menu
function Exit-Menu {
	Clear-Host
	Write-Host "`n1 "-f red -nonewline; Write-Host "- Selection Menu" -f white
	Write-Host "2 "-f red -nonewline; Write-Host "- Restart Device" -f white
	Write-Host "3 "-f red -nonewline; Write-Host "- Exit`n" -f white
	$choice = Read-Host "# "

	switch ($choice) {
		1 { Selection-Menu }
		2 { Restart-Computer -Force }
		3 { exit 1 }
	}
}

# Main execution
Selection-Menu
