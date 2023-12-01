:: ==================================================
::  Windows-MAC-Address-Spoofer v8.4
:: ==================================================
::  Dev  - Scut1ny
::  Help - Mathieu, Sintrode, 
::  Link - https://github.com/Scrut1ny/Windows-MAC-Address-Spoofer
:: ==================================================


@echo off
title Windows-MAC-Address-Spoofer ^| v8.4
setlocal EnableDelayedExpansion
mode con:cols=66 lines=25


:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo( && echo   [33m# Administrator privileges are required. && echo([0m
    runas /user:Administrator "%~0" %*
    exit /b
)


:: Variable(s)
set "reg_path=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"


:SELECTION_MENU
:: Enumerate available NICs - (You can use "name" or "NetConnectionId")
set "count=0"
cls && echo( && echo   [35m[i] Input NIC # to modify.[0m && echo(
for /f "skip=2 tokens=2 delims=," %%A in ('wmic nic get NetConnectionId /format:csv') do (
	for /f "delims=" %%B in ("%%~A") do (
		set /a "count+=1"
		set "nic[!count!]=%%B"
		echo   [31m!count![0m - %%B
	)
)
:: Recieve user selection
echo( && echo   [31m99[0m - Revise Networking && echo(
set /p "nic_selection=.  [35m# [0m"
set /a "nic_selection=nic_selection"
if !nic_selection! GTR 0 (
	if !nic_selection! LEQ !count! (
		for /f "delims=" %%A in ("!nic_selection!") do set "NetworkAdapter=!nic[%%A]!"
		goto :SPOOF_MAC
		exit /b
	)
	if !nic_selection! EQU 99 (
		cls && echo( && echo   [32m# Revising networking configurations...[0m
		>nul 2>&1(
			ipconfig /release && arp -d * && ipconfig /renew
			goto :SELECTION_MENU
		)
	)
)
goto :INVALID_SELECTION


:SPOOF_MAC
cls && echo( && call :MAC_RECIEVE && call :GEN_MAC && call :NIC_INDEX
echo   [31m# Selected NIC :[0m !NetworkAdapter! && echo(
echo   [31m# Previous MAC :[0m !MAC! && echo(
echo   [31m# Spoofed MAC  :[0m !mac_address!
>nul 2>&1 (
	netsh interface set interface "!NetworkAdapter!" admin=disable
	reg delete "!reg_path!\!Index!" /v "OriginalNetworkAddress" /f
	reg add "!reg_path!\!Index!" /v "NetworkAddress" /t REG_SZ /d "!mac_address!" /f
	netsh interface set interface "!NetworkAdapter!" admin=enable
)
echo( && echo   [35m#[0m Press any key to continue... && >nul pause && (call :EXIT_MENU || exit /b)


:INVALID_SELECTION
cls && echo( && echo   [31m"!nic_selection!" is a invalid option.[0m && >nul timeout /t 2 && goto :SELECTION_MENU


:EXIT_MENU
set "count=0"
cls && echo(
echo   [31m1[0m - Selection Menu
echo   [31m2[0m - Restart
echo   [31m3[0m - Exit && echo(
set /p c=".  [35m#[0m "
if %c%==1 goto :SELECTION_MENU
if %c%==2 shutdown /r /t 0
if %c%==3 exit /b 1
exit /b


:: Generating Random MAC Address
:: The second character of the first octet of the MAC Address needs to contain A, E, 2, or 6 to properly function for certain wireless NIC's. Example: xA:xx:xx:xx:xx
:GEN_MAC
set #hex_chars=0123456789ABCDEF`AE26
if defined mac_address (
    set mac_address=
)
for /l %%A in (1,1,11) do (
    set /a "random_index=!random! %% 16"
    for %%B in (!random_index!) do (
        set mac_address=!mac_address!!#hex_chars:~%%B,1!
    )
)
set /a "random_index=!random! %% 4 + 17"
set mac_address=!mac_address:~0,1!!#hex_chars:~%random_index%,1!!mac_address:~1!
exit /b


:: Retrieving Current MAC Address
:MAC_RECIEVE
call :NIC_INDEX
for /f "tokens=3" %%A in ('reg query "!reg_path!\!Index!" ^| find "NetworkAddress"') do (
	set "MAC=%%A"
)

:: An unaltered MAC address will not be present in the registry. As a result, we retrieve it using the permanent MAC address via WMIC.
if "!MAC!"=="" (
	for /f "tokens=2 delims==" %%A in ('wmic nic where "Index='!Index!'" get MacAddress /format:value ^| find "MACAddress"') do (
		set "MAC=%%A"
	)
)
exit /b


:: Retrieving current caption & converting into a Index - (You can use "name" or "NetConnectionId")
:NIC_INDEX
for /f "tokens=2 delims=[]" %%A in ('wmic nic where "NetConnectionId='!NetworkAdapter!'" get Caption /format:value ^| find "Caption"') do (
	set "Index=%%A"
	set "Index=!Index:~-4!"
)
exit /b 0
