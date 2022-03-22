::--------------------------------------
:: Author: 0x00 | Scrut1ny
:: Project: Windows-MAC-Address-Spoofer
:: Version: 6.0
::
:: Link: https://github.com/Scrut1ny/Windows-MAC-Address-Spoofer
::--------------------------------------

@echo off
title Windows-MAC-Address-Spoofer ^| v7.0
setlocal EnableDelayedExpansion
mode con:cols=66 lines=17

fltmc >nul 2>&1 || (
    echo(&echo   [33m# Administrator privileges are required.&echo([0m
    PowerShell Start -Verb RunAs '%0' 2> nul || (
        echo   [33m# Right-click on the script and select "Run as administrator".[0m
        >nul pause&exit 1
    )
    exit 0
)

:SELECTION
cls&echo(&echo   [35mSelect NIC #.[0m&echo(
set "count=0"
for /f "skip=2 tokens=2 delims=," %%A in ('wmic nic get netconnectionid /format:csv') do (
	for /f "delims=" %%B in ("%%~A") do (
		set /a count+=1
		set "nic[!count!]=%%B"
		echo   [31m!count![0m - %%B
	)
)
echo(
set /p "nic_selection=.  [35m# [0m"
set /a "nic_selection=nic_selection" %= //Super rudimentary integer validation =%
if !nic_selection! GTR 0 (
	if !nic_selection! LEQ !count! (
		for /f "delims=" %%A in ("!nic_selection!") do set "NetworkAdapter=!nic[%%A]!"
		goto :SPOOF
		exit /b
	)
)
cls&echo(&echo [31m  "!nic_selection!" invalid selection.[0m
>nul timeout /t 2
goto :SELECTION

:SPOOF
cls&echo(
call :RMAC
call :NIC_Info
echo   [31m# Selected NIC :[0m !NetworkAdapter!
echo(
echo   [31m# Current MAC  :[0m !MAC!
echo(
>nul 2>&1(
	netsh i set i !NetworkAdapter! a=d
	reg delete "HKLM\SYSTEM\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\!Index!" /v "OriginalNetworkAddress" /f
	reg add "HKLM\SYSTEM\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\!Index!" /v "NetworkAddress" /t REG_SZ /d "!RMAC!" /f
	reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit" /va /f
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Regedit" /va /f
	arp -d *
	netsh i set i !NetworkAdapter! a=e
	ipconfig/release&ipconfig/renew&ipconfig/flushdns
)
call :NIC_Info&echo   [31m# Spoofed MAC  :[0m !RMAC!&echo(&>nul pause&(call :EXITMENU || exit /b)

:EXITMENU
cls
echo(
echo   [31m1[0m - Run again
echo   [31m2[0m - Restart System
echo   [31m3[0m - Exit
echo(
set /p c=".  [35m#[0m "
if %c%==1 goto :SELECTION
if %c%==2 shutdown /r
if %c%==3 exit /b 1
echo Choice "%c%" isn't a valid option, please try again.&goto :EXITMENU
exit /b

:: Generate Random MAC Address
:RMAC
for /f "usebackq" %%a in (`powershell ('{0:x}' -f (Get-Random 0xFFFFFFFFFFFF^)^).padleft(12^,^"0^"^)`) do (
    set "RMAC=%%a"
    exit /b
)

:: Retrieving current Caption/Index, MACAddress, Interface Name, NetCfgInstanceId
:NIC_Info
for /f "tokens=2,4-5* delims=,[]" %%a in ('"wmic nic where NetConnectionId="!NetworkAdapter!" get Caption,GUID,MACAddress,NetConnectionID /format:csv | find ",""') do (
    set "Index=%%a"
    set "Index=!Index:~-4!"
    set "GUID=%%b"
    set "MAC=%%c"
    set "NIC=%%d"
	exit /b
)
