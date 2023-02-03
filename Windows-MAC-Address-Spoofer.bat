:: ==================================================
::  Windows-MAC-Address-Spoofer v8.0
:: ==================================================
::  Dev  - Scut1ny
::  Help - Mathieu, Sintrode, 
::  Link - https://github.com/Scrut1ny/Windows-MAC-Address-Spoofer
:: ==================================================


@echo off
title Windows-MAC-Address-Spoofer ^| v8.0
setlocal EnableDelayedExpansion
mode con:cols=66 lines=25


fltmc >nul 2>&1 || (
    echo( && echo   [33m# Administrator privileges are required. && echo([0m
    PowerShell Start -Verb RunAs '%0' 2> nul || (
        echo   [33m# Right-click on the script and select "Run as administrator".[0m
        >nul pause && exit 1
    )
    exit 0
)


:: Variables
set "reg_path=HKLM\SYSTEM\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"


:SELECTION
:: Enumerate available NICs
set "count=0"
cls && echo( && echo   [35mSelect NIC # to spoof.[0m && echo(
for /f "skip=2 tokens=2 delims=," %%A in ('wmic nic get netconnectionid /format:csv') do (
	for /f "delims=" %%B in ("%%~A") do (
		set /a "count+=1"
		set "nic[!count!]=%%B"
		echo   [31m!count![0m - %%B
	)
)
:: Recieve user selection
echo( && echo   [31m99[0m - Revise Networking && echo(
set /p "nic_selection=.  [35m# [0m"
set /a "nic_selection=nic_selection" %= //Super rudimentary integer validation =%
if !nic_selection! GTR 0 (
	if !nic_selection! LEQ !count! (
		for /f "delims=" %%A in ("!nic_selection!") do set "NetworkAdapter=!nic[%%A]!"
		goto :SPOOF
		exit /b
	)
	if !nic_selection! EQU 99 (
		cls && echo( && echo   [32mRevising networking configurations...[0m
		>nul 2>&1(
			ipconfig /release && ipconfig /flushdns && arp -d * && ipconfig /renew
			goto :SELECTION
		)
	)
)
goto :INVALID_SELECTION


:SPOOF
cls && echo( && call :MAC_Recieve && call :generateMAC && call :NIC_Index
echo   [31m# Selected NIC :[0m !NetworkAdapter! && echo(
echo   [31m# Current MAC  :[0m !MAC! && echo(
echo   [31m# Spoofed MAC  :[0m !new_MAC!
>nul 2>&1 (
	netsh interface set interface !NetworkAdapter! admin=disable
	reg delete "!reg_path!\!Index!" /v "OriginalNetworkAddress" /f && arp -d *
	reg add "!reg_path!\!Index!" /v "NetworkAddress" /t REG_SZ /d "!new_MAC!" /f
	netsh interface set interface !NetworkAdapter! admin=enable
)
echo( && echo   [31m#[0m Press any key to continue... && >nul pause && (call :EXITMENU || exit /b)


:INVALID_SELECTION
cls && echo( && echo   [31m"!nic_selection!" is a invalid option.[0m && >nul timeout /t 2 && goto :SELECTION


:EXITMENU
set "count=0"
cls && echo(
echo   [31m1[0m - Run again
echo   [31m2[0m - Restart System
echo   [31m3[0m - Exit && echo(
set /p c=".  [35m#[0m "
if %c%==1 goto :SELECTION
if %c%==2 shutdown /r
if %c%==3 exit /b 1
exit /b


:: Generating Random MAC Address
:generateMAC
set "new_MAC=02"
for /L %%A in (1,1,5) do (
	set /a "rnd=!RANDOM!%%256"
	call :toHex !rnd! octet
	set "new_MAC=!new_MAC!:!octet!"
)
exit /b
:toHex
set /a "dec=%~1"
set "hex="
set "map=0123456789ABCDEF"
for /L %%N in (1,1,8) do (
    set /a "d=dec&15,dec>>=4"
    for %%D in (!d!) do set "hex=!map:~%%D,1!!hex!"
)
set "hex=%hex:~-2%"
set "%~2=%hex%"
exit /b


:: Retrieving Current MAC Address
:MAC_Recieve
call :NIC_Index
for /f "tokens=3" %%a in ('reg query "!reg_path!\!Index!" ^| find "NetworkAddress"') do set "MAC=%%a"

:: An unmodified MAC address will not be listed in the registry, so get the default MAC address with WMIC.
if "!MAC!"=="" (
	set /a raw_index=1!index!-10000
	for /f "delims=" %%A in ('"wmic nic where Index="!raw_index!" get MacAddress /format:value"') do (
		for /f "tokens=2 delims==" %%B in ("%%~A") do set "MAC=%%B"
	)
)
exit /b


:: Retrieving current Caption/Index
:NIC_Index
for /f "delims=" %%a in ('"wmic nic where NetConnectionId="!NetworkAdapter!" get Caption /format:value"') do (
	for /f "tokens=2 delims=[]" %%A in ("%%~a") do (
		set "Index=%%A"
		set "Index=!Index:~-4!"
	)
)
exit /b 0
