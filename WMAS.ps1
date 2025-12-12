# ==================================================
#  Windows-MAC-Address-Spoofer v2.0
# ==================================================
#  Devs - Scut1ny & Ammar S.A.A
#  Help - 
#  Link - https://github.com/Scrut1ny/Windows-MAC-Address-Spoofer
# ==================================================


# Check for admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
	Write-Host "`n  [92m# Administrator privileges are required.[0m"
	Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	exit
}


# Variable(s)
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"


# Main selection menu
function Selection-Menu {
    Clear-Host; Write-Host "`n  [104;97m[i][0m Input NIC # to modify.`n"
    
    $counter = 0
    $nic = Get-CimInstance Win32_NetworkAdapter | Where-Object {$_.NetConnectionID -ne $null} | ForEach-Object {
        $counter++
        Write-Host "  $counter - $($_.NetConnectionID)"
        $_.NetConnectionID
    }

    Write-Host "`n  [92m99[0m - Revise Networking`n"
    $nicSelection = Read-Host "  "
    $nicSelection = [int]$nicSelection

    if ($nicSelection -gt 0 -and $nicSelection -le $nic.Count) {
        $NetworkAdapter = $nic[$nicSelection - 1]
        Spoof-MAC
    } elseif ($nicSelection -eq 99) {
        Clear-Host; Write-Host "`n  [92m# Revising networking configurations...[0m"
        {
            ipconfig /release
            arp -d *
            ipconfig /renew
        } *> $null
        Start-Sleep -Seconds 1
        Selection-Menu
    } else {
        Invalid-Selection
    }
}


# Function to display methods to modify MAC address
function Spoof-MAC {
    $originalMAC = Get-MAC
	Clear-Host; Write-Host "`n  [91m# Selected NIC:[0m $NetworkAdapter"
	Write-Host "`n  [91m1[0m - Randomize MAC Address"
	Write-Host "`n  [91m2[0m - Customize MAC Address"
    $choice = Read-Host "`n  "

    switch ($choice) {
        1 { 
			Clear-Host
            $useVendorPreset = Read-Host "`n  # Apply custom vendor preset? (Y/N)"
            if ($useVendorPreset -eq 'Y' -or $useVendorPreset -eq 'y') {
                Spoof-Vendor-Preset
            } else {
                Spoof-Random-MAC
            }
        }
        2 { Set-Custom-MAC }
        default { Invalid-Selection }
    }
}


function Spoof-Vendor-Preset {
    $vendors = @(
        @{ Name = "Apple, Inc."; Prefixes = @("001A2B", "F8FFC2", "D8A25E") },
        @{ Name = "Samsung Electronics Co., Ltd"; Prefixes = @("00163E", "28CC01", "7825AD") },
        @{ Name = "Dell Inc."; Prefixes = @("00155D", "A41F72", "F8BC12") },
        @{ Name = "Cisco Systems, Inc"; Prefixes = @("001B2F", "0090D9", "2C3ECF") },
        @{ Name = "Huawei Technologies Co., Ltd"; Prefixes = @("001E10", "00E0FC", "58A839") },
        @{ Name = "Intel Corporate"; Prefixes = @("001B21", "4E360C", "AC7BA1") },
        @{ Name = "LG Electronics (Mobile Communications)"; Prefixes = @("001C62", "789F70", "60AF6D") },
        @{ Name = "Hewlett Packard"; Prefixes = @("001A4B", "3CD92B", "643150") },
        @{ Name = "Lenovo Group Limited"; Prefixes = @("001A6B", "60EB69", "F4B72A") },
        @{ Name = "Sony Group Corporation"; Prefixes = @("001D0D", "EC98C1", "2CDEA3") },
        @{ Name = "Google LLC"; Prefixes = @("A4E031", "001A11", "6C2E85") },
        @{ Name = "Microsoft Corporation"; Prefixes = @("00262B", "50F2D5", "7C2EDD") },
        @{ Name = "Motorola Mobility LLC, a Lenovo Company"; Prefixes = @("001DD0", "144D67", "5C45EF") },
        @{ Name = "Xiaomi Communications Co Ltd"; Prefixes = @("A0B437", "F48B32", "7812B8") },
        @{ Name = "ASUSTek COMPUTER INC."; Prefixes = @("C08C60", "10BF48", "247C4C") },
        @{ Name = "TP-Link Technologies Co., Ltd."; Prefixes = @("14CC20", "D4EE07", "50C7BF") },
        @{ Name = "Netgear"; Prefixes = @("20E52A", "44650D", "2C3033") },
        @{ Name = "ARRIS Group, Inc."; Prefixes = @("0015D1", "E0B7B1", "DCA4CA") },
        @{ Name = "Qualcomm Inc."; Prefixes = @("E8BA70", "20AA4B", "0024E8") },
        @{ Name = "Broadcom Inc."; Prefixes = @("001018", "008077", "00A0C6") }
    )
	
	# Display vendor list
	Clear-Host; Write-Host "`n  [104;97m[i][0m Select a vendor for the MAC address prefix:`n"
	$vendors | ForEach-Object { $index = [Array]::IndexOf($vendors, $_) + 1; Write-Host "  $index - $($_.Name)" }
	
	# Get user selection
	$selectedVendorIndex = Read-Host "`n  #"
	$selectedVendorIndex = [int]$selectedVendorIndex - 1 # Adjust for zero-based indexing
	
	if ($selectedVendorIndex -ge 0 -and $selectedVendorIndex -lt $vendors.Length) {
        $selectedVendor = $vendors[$selectedVendorIndex]
        # Select a random prefix from the selected vendor
        $randomPrefixIndex = Get-Random -Minimum 0 -Maximum $selectedVendor.Prefixes.Length
        $randomPrefix = $selectedVendor.Prefixes[$randomPrefixIndex]
        $randomMac = $randomPrefix + ('{0:X}' -f (Get-Random -Minimum 0 -Maximum 0xFFFFFF)).PadLeft(6, '0')
	} else {
		Clear-Host; Write-Host "`n  [101;97m[!][0m Invalid selection, please try again."
		Start-Sleep -Seconds 3
		Spoof-Vendor-Preset
	}
	
	$nicIndex = Get-NICIndex
	Clear-Host; Write-Host "`n  [91m> Registry Path:[0m $regPath\$nicIndex"
	Write-Host "`n  [91m> Selected NIC:[0m $NetworkAdapter"
	Write-Host "`n  [91m> Previous MAC:[0m $originalMAC"
	Write-Host "`n  [91m> Modified MAC:[0m $randomMac"
	
	# Disable NIC, delete OriginalNetworkAddress registry entry, add NetworkAddress registry entry, enable NIC
	Disable-NetAdapter -InterfaceAlias "$NetworkAdapter" -Confirm:$false
	$registryPath = "$regPath\$nicIndex"
	
	if (Test-Path $registryPath) {
		Remove-ItemProperty -Path "$registryPath" -Name "OriginalNetworkAddress" -ErrorAction SilentlyContinue
	
		try {
			Set-ItemProperty -Path "$registryPath" -Name "NetworkAddress" -Value "$randomMac" -Force
			Restart-Service -Force -Name "winmgmt"
		} catch {
			Write-Host "`n  [101;97m[!][0m Error setting registry property: $_"
		}
	} else {
		Write-Host "`n  [101;97m[!][0m Registry path not found: $registryPath"
	}
	
	Enable-NetAdapter -InterfaceAlias "$NetworkAdapter" -Confirm:$false
	
	Write-Host "`n  # Press any key to continue..."
	$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	
	Exit-Menu
}


# Function to spoof a random MAC address
function Spoof-Random-MAC {
	$randomMac = Generate-MAC
	$nicIndex = Get-NICIndex

	if (-not $nicIndex) {
		Write-Host "`n  [101;97m[!][0m NIC index not found. Aborting MAC spoofing."
		Exit-Menu
	}
	
	Clear-Host; Write-Host "`n  [91m> Registry Path:[0m $regPath\$nicIndex"
	Write-Host "`n  [91m> Selected NIC:[0m $NetworkAdapter"
	Write-Host "`n  [91m> Previous MAC:[0m $originalMAC"
	Write-Host "`n  [91m> Modified MAC:[0m $randomMac"

	# Disable NIC, delete OriginalNetworkAddress registry entry, add NetworkAddress registry entry, enable NIC
	Disable-NetAdapter -InterfaceAlias "$NetworkAdapter" -Confirm:$false
	$registryPath = "$regPath\$nicIndex"

	if (Test-Path $registryPath) {
		Remove-ItemProperty -Path "$registryPath" -Name "OriginalNetworkAddress" -ErrorAction SilentlyContinue

		try {
			Set-ItemProperty -Path "$registryPath" -Name "NetworkAddress" -Value "$randomMac" -Force
			Restart-Service -Force -Name "winmgmt"
		} catch {
			Write-Host "`n  [101;97m[!][0m Error setting registry property: $_"
		}
	} else {
		Write-Host "`n  [101;97m[!][0m Registry path not found: $registryPath"
	}

	Enable-NetAdapter -InterfaceAlias "$NetworkAdapter" -Confirm:$false

	Write-Host "`n  # Press any key to continue..."
	$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

	Exit-Menu
}


# Function to manually set a custom MAC address
function Set-Custom-MAC {
	$originalMAC = Get-MAC
	Clear-Host; Write-Host "`n  [104;97m[i][0m Enter a custom MAC address for `"$NetworkAdapter`" NIC. (Format: FF:FF:FF:FF:FF:FF)"
	$customMAC = Read-Host "`n  "

	if ($customMAC -match '^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$') {
		$nicIndex = Get-NICIndex
		
		Clear-Host; Write-Host "`n  [91m> Registry Path:[0m $regPath\$nicIndex"
		Write-Host "`n  [91m> Selected NIC:[0m $NetworkAdapter"
		Write-Host "`n  [91m> Previous MAC:[0m $originalMAC"
		Write-Host "`n  [91m> Custom MAC:[0m $customMAC"

		# Disable NIC, delete OriginalNetworkAddress registry entry, add NetworkAddress registry entry, enable NIC
		Disable-NetAdapter -InterfaceAlias "$NetworkAdapter" -Confirm:$false
		Remove-ItemProperty -Path "$regPath\$nicIndex" -Name "OriginalNetworkAddress" -ErrorAction SilentlyContinue

		try {
			Set-ItemProperty -Path "$regPath\$nicIndex" -Name "NetworkAddress" -Value "$customMAC" -Force
			Restart-Service -Force -Name "winmgmt"
		} catch {
			Write-Host "`n  [101;97m[!][0m Error setting registry property: $_"
		}

		Enable-NetAdapter -InterfaceAlias "$NetworkAdapter" -Confirm:$false

		Write-Host "`n  # Press any key to continue..."
		$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

		Exit-Menu
	} else {
		Clear-Host; Write-Host "`n  [101;97m[!][0m Invalid MAC address format. Please enter a valid MAC address."
		Start-Sleep -Seconds 3
		Set-Custom-MAC
	}
}


# Function to retrieve current MAC address
function Get-MAC {
	$nicIndex = Get-NICIndex
	$macAddress = (Get-ItemProperty -Path "$regPath\$nicIndex" -Name "NetworkAddress" -ErrorAction SilentlyContinue).NetworkAddress

	if (-not $macAddress) {
		$macAddress = (Get-CimInstance -Class Win32_NetworkAdapter | Where-Object { $_.NetConnectionId -eq "$NetworkAdapter" }).MacAddress
	}

	return $macAddress
}


# Function to retrieve NIC index
function Get-NICIndex {
	$nicCaption = (Get-CimInstance -Class Win32_NetworkAdapter | Where-Object { $_.NetConnectionId -eq "$NetworkAdapter" }).Caption
	$nicIndex = $nicCaption -replace ".*\[", "" -replace "\].*"
	$nicIndex = $nicIndex.Substring($nicIndex.Length - 4)
	return $nicIndex
}


# Function to generate random MAC address
function Generate-MAC {
    $randomMac = ('{0:X}' -f (Get-Random 0xFFFFFFFFFFFF)).PadLeft(12, "0")
    $replacementChar = Get-Random -InputObject @('A', 'E', '2', '6')
    $randomMac = $randomMac.Substring(0, 1) + $replacementChar + $randomMac.Substring(2)
    return $randomMac
}


# Function to handle invalid selection
function Invalid-Selection {
	Clear-Host; Write-Host "`n  [101;97m[!][0m Invalid selection, please choose a valid option."
	Start-Sleep -Seconds 2
	Selection-Menu
}


# Function to display exit menu
function Exit-Menu {
	Clear-Host; Write-Host "`n  [91m1[0m - Selection Menu"
	Write-Host "  [91m2[0m - Restart Device"
	Write-Host "  [91m3[0m - Exit`n"
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
