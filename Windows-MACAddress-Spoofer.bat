::--------------------------------------
:: Author: 0x00 | Scrut1ny
:: Project: Windows-MACAddress-Spoofer
:: Version: 6.0
::
:: Link: https://github.com/Scrut1ny/Windows-MACAddress-Spoofer
::--------------------------------------

@echo off
setlocal EnableDelayedExpansion

>nul 2>&1 net sess||(powershell saps '%0'-Verb RunAs&exit /b)

:START
cls

call :LOGO & call :Check_UAC & call :MENU
call :MENU2
call :NIC_Info
call :Random_MAC
call :sub_folder

cls & call :LOGO & call :Check_UAC

echo  [+] SELECTED NIC : !NetworkAdapter! & echo.
call :NIC_Info
echo  [+] CURRENT MAC  : !MAC! & echo.

netsh i set i !NetworkAdapter! a=d >nul 2>&1
REG ADD "HKLM\SYSTEM\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\!SUB1!" /v "NetworkAddress" /t REG_SZ /d !RMAC! /f >nul 2>&1
REG DELETE "HKLM\SYSTEM\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\!SUB1!" /v "OriginalNetworkAddress" /f >nul 2>&1
netsh i set i !NetworkAdapter! a=e >nul 2>&1

echo  [+] SPOOFED MAC  : !RMAC! & echo. & pause

call :MENU1

:: VARIABLES ----------------------------------------------------------------------------------------------

:MENU
echo  [?] Choose ^& Type a NIC & echo.
for /f "skip=1" %%a in ('wmic nic get NetconnectionID') do for %%b in (%%a) do echo   ^> %%b
echo.
set /p choice=[?] 
echo.
for /f "skip=1" %%a in ('wmic nic get NetconnectionID') do for %%b in (%%a) do if /i "!choice!"=="%%b" goto :MENU2
echo  [-] "!choice!" Isn't a valid option, please try again. & timeout /t 5  >nul 2>&1 & goto :START
exit /b

:: Make into 1 if loop

:MENU2
set NetworkAdapter=!choice!
exit /b

:MENU1
cls
call :LOGO
echo  [1] Run again
echo  [2] Restart System
echo  [3] Exit
echo.
set /p "choice=>> "
if "%choice%"=="1" goto :START
if "%choice%"=="2" shutdown /r
if "%choice%"=="3" exit
echo Choice "%choice%" isn't a valid option, please try again. & goto :MENU1
exit /b

:LOGO
echo   __  __   _   ___   ___                 __
echo  ^|  \/  ^| /_\ / __^| / __^|_ __  ___  ___ / _^|___ _ _
echo  ^| ^|\/^| ^|/ _ \ (__  \__ \ '_ \/ _ \/ _ \  _/ -_) '_^|
echo  ^|_^|  ^|_/_/ \_\___^| ^|___/ .__/\___/\___/_^| \___^|_^|
echo                         ^|_^|
echo.
echo  ===================================================
echo.
exit /b

:: Generate Random MACAddress
:Random_MAC
for /f "usebackq" %%a in (`powershell -c ('{0:x}' -f (Get-Random 0xFFFFFFFFFFFF^)^).padleft(12^,^"0^"^)`) do (
	set RMAC=%%a
	exit /b
)	

:: Retrieving current Caption/Index, MACAddress, Interface Name, NetCfgInstanceId
: 
for /f "tokens=2,4-5* delims=,[]" %%A in ('"wmic nic where NetConnectionId='!NetworkAdapter!' get Caption,GUID,MACAddress,NetConnectionID /format:csv"') do (
    set "Index=%%A"
    set "Index=!Index:~-4!"
    set "GUID=%%B"
    set "MAC=%%C"
    set "NIC=%%D"
)

:: Check for administrator privilages
:Check_UAC
>nul 2>&1 NET SESSION && (echo  [+] Administrator Privileges Detected. & echo.) || (echo  [-] No Administrator Privileges Detected. & echo. & pause & exit) >nul 2>&1
