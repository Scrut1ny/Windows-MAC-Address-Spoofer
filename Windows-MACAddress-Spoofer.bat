::--------------------------------------
:: By: 0x00 | Scrut1ny
:: https://github.com/Scrut1ny
:: Windows MACAddress Spoofer
:: V5.0
::--------------------------------------

@echo off
cls
setlocal EnableDelayedExpansion

:: Privilege Escalation - Credit: https://stackoverflow.com/a/62668457 -----------------------------------

>nul 2>&1 net sess||(powershell saps '%0'-Verb RunAs&exit /b)

::--------------------------------------------------------------------------------------------------------

:START
call :LOGO
>nul 2>&1 NET SESSION && (echo  [+] Administrator Privileges Detected.) || (echo  [-] No Administrator Privileges Detected. & echo. & pause & exit) >nul 2>&1

call :NIC_Info
echo. & echo  [+] CURRENT NIC  : !NIC! & echo.
call :NIC_Info
echo  [+] CURRENT MAC  : !MAC! & echo.

:: Spoofing MACAddress -----------------------------------------------------------------------------------

:: Default Windows Network Adapter - ClassGuid = {4d36e972-e325-11ce-bfc1-08002be10318}

call :NIC_Info
netsh i set i n="!NIC!" a=d >nul 2>&1
ipconfig/release >nul 2>&1

:: Actual NIC(s)
call :Random_MAC
call :Class_GUID !GUID! folder
REG ADD "HKLM\SYSTEM\ControlSet001\Control\Class\!folder!\0001" /v "NetworkAddress" /t REG_SZ /d !RMAC! /f >nul 2>&1
call :Random_MAC
call :Class_GUID !GUID! folder
REG ADD "HKLM\SYSTEM\ControlSet001\Control\Class\!folder!\0002" /v "NetworkAddress" /t REG_SZ /d !RMAC! /f >nul 2>&1

:: Deleting OriginalNetworkAddress
call :Class_GUID !GUID! folder
REG DELETE "HKLM\SYSTEM\ControlSet001\Control\Class\!folder!\0001" /v "OriginalNetworkAddress" /f >nul 2>&1
call :Class_GUID !GUID! folder
REG DELETE "HKLM\SYSTEM\ControlSet001\Control\Class\!folder!\0002" /v "OriginalNetworkAddress" /f >nul 2>&1

call :NIC_Info
netsh i set i n="!NIC!" a=e >nul 2>&1
ipconfig/renew >nul 2>&1

::---------------------------------------------------------------------------------------------------------

call :NIC_Info
echo  [+] SPOOFED MAC  : !MAC!
echo. & pause & cls

:: VARIABLES ----------------------------------------------------------------------------------------------

:MENU
call :LOGO
echo   [1] Run again
echo   [2] Restart
echo   [3] Exit
echo.
set /p "choice=>> "
if "%choice%"=="1" goto :START
if "%choice%"=="2" shutdown /r
if "%choice%"=="3" exit
echo Choice "%choice%" isn't a valid option, please try again. & goto :MENU
exit /b

:LOGO
cls
echo   __  __   _   ___   ___                 __
echo  ^|  \/  ^| /_\ / __^| / __^|_ __  ___  ___ / _^|___ _ _
echo  ^| ^|\/^| ^|/ _ \ (__  \__ \ '_ \/ _ \/ _ \  _/ -_) '_^|
echo  ^|_^|  ^|_/_/ \_\___^| ^|___/ .__/\___/\___/_^| \___^|_^|
echo                         ^|_^|
echo.
exit /b

:: Generate Random MACAddress - Credit: @prsgroup > https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-random-mac-addresses?CommentId=053f086f-7588-4b14-918b-7429c274671f
:Random_MAC
for /f "usebackq" %%a in (`powershell -command [BitConverter]::ToString([BitConverter]::GetBytes((Get-Random -Maximum 0xFFFFFFFFFFFF^)^)^, 0^, 6^).Replace(^':^'^, ^'-^'^)`) do set RMAC=%%a
exit /b

:: Retrieving current MACAddress, Interface Name, NetCfgInstanceId
:NIC_Info
for /f "skip=2 tokens=2,3,4* delims=," %%a in ('"wmic nic where (NETEnabled=True) get GUID,NetconnectionID,MACAddress /format:csv"') do (set "GUID=%%a" & set "MAC=%%b" & set "NIC=%%c")
exit /b

:: Retrieving "Class GUID"
:Class_GUID
for /f "tokens=6 delims=\" %%A in ('reg query "HKLM\SYSTEM\ControlSet001\Control\Class" /f "%~1" /s /t REG_SZ ^| find "Class"') do set "%~2=%%A"
exit /b

::---------------------------------------------------------------------------------------------------------
