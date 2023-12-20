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
	Write-Host "`n# Administrator privileges are required." -f Yellow
	Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	exit
}


# Variable(s)
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"


# Function to enumerate available NICs
function Selection-Menu {
	Clear-Host; Write-Host "`n  [i] Input NIC # to modify.`n" -f Magenta
	
	$counter = 0
	$nic = Get-WmiObject Win32_NetworkAdapter | Where-Object {$_.NetConnectionID -ne $null -and $_.NetConnectionStatus -eq 2} | ForEach-Object {
		$counter++
		Write-Host "  $counter - $($_.NetConnectionID)"
		$_.NetConnectionID
	}

	Write-Host "`n  99 "-f red -nonewline; Write-Host "- Revise Networking`n" -f white
	$nicSelection = Read-Host "  "
	$nicSelection = [int]$nicSelection

	if ($nicSelection -gt 0 -and $nicSelection -le $nic.Count) {
		$NetworkAdapter = $nic[$nicSelection - 1]
		Spoof-MAC
	} elseif ($nicSelection -eq 99) {
		Clear-Host; Write-Host "`n  # Revising networking configurations..." -f Green
		{
			ipconfig /release; arp -d *; ipconfig /renew
		} *>$null
		Start-Sleep -Seconds 1
		Selection-Menu
	} else {
		Invalid-Selection
	}
}


# Function to display methods to modify MAC address
function Spoof-MAC {
	$originalMAC = Get-MAC
	Clear-Host; Write-Host "`n  # Selected NIC: "-f red -nonewline; Write-Host "$NetworkAdapter" -f white

	Write-Host "`n  1 " -f red -nonewline; Write-Host "- Randomize MAC Address" -f white
	Write-Host "`n  2 " -f red -nonewline; Write-Host "- Customize MAC Address" -f white

	$choice = Read-Host "`n  "

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
		Write-Host "`n  [!] NIC index not found. Aborting MAC spoofing." -ForegroundColor Red
		Exit-Menu
	}
	
	Clear-Host; Write-Host "`n  > Registry Path: " -f red -nonewline; Write-Host "$regPath\$nicIndex"
	Write-Host "`n  > Selected NIC: " -f red -nonewline; Write-Host "$NetworkAdapter" -f white
	Write-Host "`n  > Previous MAC: " -f red -nonewline; Write-Host "$originalMAC" -f white
	Write-Host "`n  > Modified MAC: " -f red -nonewline; Write-Host "$macAddress" -f white

	# Disable NIC, delete OriginalNetworkAddress registry entry, add NetworkAddress registry entry, enable NIC
	Disable-NetAdapter -InterfaceAlias $NetworkAdapter -Confirm:$false
	$registryPath = "$regPath\$nicIndex"

	if (Test-Path $registryPath) {
		Remove-ItemProperty -Path $registryPath -Name "OriginalNetworkAddress" -ErrorAction SilentlyContinue

		try {
			Set-ItemProperty -Path $registryPath -Name "NetworkAddress" -Value $macAddress -Force
			Restart-Service -Force -Name "winmgmt"
		} catch {
			Write-Host "`n  [!] " -f Red -nonewline Write-Host "Error setting registry property: $_"
		}
	} else {
		Write-Host "`n  [!] " -f Red -nonewline Write-Host "Registry path not found: $registryPath"
	}

	Enable-NetAdapter -InterfaceAlias $NetworkAdapter -Confirm:$false

	Write-Host "`n  # Press any key to continue..."
	$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

	Exit-Menu
}


# Function to manually set a custom MAC address
function Set-Custom-MAC {
	$originalMAC = Get-MAC
	Clear-Host; Write-Host "`n  [i] Enter a custom MAC address for `"$NetworkAdapter`" NIC. (Format: FF:FF:FF:FF:FF:FF)" -f red
	$customMAC = Read-Host "`n  "

	if ($customMAC -match '^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$') {
		$nicIndex = Get-NICIndex
		
		Clear-Host; Write-Host "`n  > Registry Path: " -f red -nonewline; Write-Host "$regPath\$nicIndex"
		Write-Host "`n  > Selected NIC: " -f red -nonewline; Write-Host "$NetworkAdapter"
		Write-Host "`n  > Previous MAC: " -f red -nonewline; Write-Host "$originalMAC"
		Write-Host "`n  > Custom MAC: " -f red -nonewline; Write-Host "$customMAC"

		# Disable NIC, delete OriginalNetworkAddress registry entry, add NetworkAddress registry entry, enable NIC
		Disable-NetAdapter -InterfaceAlias $NetworkAdapter -Confirm:$false
		Remove-ItemProperty -Path "$regPath\$nicIndex" -Name "OriginalNetworkAddress" -ErrorAction SilentlyContinue

		try {
			Set-ItemProperty -Path "$regPath\$nicIndex" -Name "NetworkAddress" -Value $customMAC -Force
			Restart-Service -Force -Name "winmgmt"
		} catch {
			Write-Host "`n  [!] " -f Red -nonewline Write-Host "Error setting registry property: $_"
		}

		Enable-NetAdapter -InterfaceAlias $NetworkAdapter -Confirm:$false

		Write-Host "`n  # Press any key to continue..."
		$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

		Exit-Menu
	} else {
		Clear-Host; Write-Host "`n  [!] Invalid MAC address format. Please enter a valid MAC address." -f Red
		Start-Sleep -Seconds 3
		Set-Custom-MAC
	}
}


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


# Function to handle invalid selection
function Invalid-Selection {
	Clear-Host; Write-Host "`n  # Invalid selection. Please choose a valid option." -f Red
	Start-Sleep -Seconds 2
	Selection-Menu
}


# Function to display exit menu
function Exit-Menu {
	Clear-Host; Write-Host "`n  1 " -f red -nonewline; Write-Host "- Selection Menu" -f white
	Write-Host "  2 " -f red -nonewline; Write-Host "- Restart Device" -f white
	Write-Host "  3 " -f red -nonewline; Write-Host "- Exit`n" -f white
	$choice = Read-Host "  "

	switch ($choice) {
		1 { Selection-Menu }
		2 { Restart-Computer -Force }
		3 { exit 1 }
		default { Invalid-Selection }
	}
}


# Main execution
Selection-Menu
