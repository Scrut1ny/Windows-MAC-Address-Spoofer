:: Author: Scrut1ny
:: Project: Windows-MAC-Address-Spoofer
:: Version: 7.0
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
cls&echo(&echo [31m  Choice "!nic_selection!": Invalid selection.[0m
>nul timeout /t 2
goto :SELECTION

:SPOOF
cls&echo(
call :MAC
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
	netsh i set i !NetworkAdapter! a=e
)
call :NIC_Info&echo   [31m# Spoofed MAC  :[0m !RMAC!&echo(&echo   [31m#[0m Press any key to continue...&>nul pause&(call :EXITMENU || exit /b)

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
cls&echo(&echo   [31mChoice "%c%": Invalid option.[0m&>nul timeout /t 2&goto :EXITMENU
exit /b

:: Generate Random MAC Address
:RMAC
for /f "usebackq" %%a in (`powershell -c [BitConverter]::ToString([BitConverter]::GetBytes((Get-Random -Maximum 0xFFFFFFFFFFFF^)^)^,0^,6^).Replace(^'-^'^, ^':^'^)`) do (
	set "RMAC=%%a"
	exit /b
)

:: Retrieving Current MAC Address
:MAC
call :NIC_Info
for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\!Index!" ^| find "NetworkAddress"') do (
    set "MAC=%%a"
    exit /b
)

:: Retrieving current Caption/Index
:NIC_Info
for /f "skip=1delims=[] " %%a in ('"wmic nic where NetConnectionId="!NetworkAdapter!" get Caption"') do (
    set "Index=%%a"
    set "Index=!Index:~-4!"
	exit /b
)
