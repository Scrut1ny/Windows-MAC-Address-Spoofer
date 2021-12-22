::--------------------------------------
:: By: 0x00 / Anonymoushacker4926
:: Windows MACAddress Spoofer
:: V3.0
::--------------------------------------

@echo off
cls
setlocal EnableDelayedExpansion

:: Privilege Escalation - Credit: https://stackoverflow.com/a/62668457 -----------------------------------

>nul 2>&1 net sess||(powershell saps '%0'-Verb RunAs&exit /b)

::-VARIABLES--------------------------------------------------------------------------------------------------------

:: Retrieving GUID/UUID
:: for /f "skip=2 tokens=2 delims=," %%a in ('wmic nicconfig where IPEnabled^=True GET SettingID /format:csv') do for %%b in (%%a) do set GUID=%%b
:: Must find and add your own GUID/UUID.
for /f %%a in ('echo {4d36e972-e325-11ce-bfc1-08002be10318}') do set GUID=%%a

:: Generate Random MACAddress - Credit: @prsgroup > https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-random-mac-addresses?CommentId=053f086f-7588-4b14-918b-7429c274671f
for /f "usebackq" %%a in (`powershell -command [BitConverter]::ToString([BitConverter]::GetBytes((Get-Random -Maximum 0xFFFFFFFFFFFF^)^)^, 0^, 6^).Replace(^':^'^, ^'-^'^)`) do set RMAC1=%%a
for /f "usebackq" %%a in (`powershell -command [BitConverter]::ToString([BitConverter]::GetBytes((Get-Random -Maximum 0xFFFFFFFFFFFF^)^)^, 0^, 6^).Replace(^':^'^, ^'-^'^)`) do set RMAC2=%%a
for /f "usebackq" %%a in (`powershell -command [BitConverter]::ToString([BitConverter]::GetBytes((Get-Random -Maximum 0xFFFFFFFFFFFF^)^)^, 0^, 6^).Replace(^':^'^, ^'-^'^)`) do set RMAC3=%%a

:: Retrieving current MACAddress, Interface Name, & GUID/UUID

for /F "skip=2 tokens=2,3,4* delims=," %%a in ('"wmic nic where (NETEnabled=True) get GUID,NetconnectionID,MACAddress /format:csv"') do (set "GUID1=%%a" & set "MAC=%%b" & set "NIC=%%c")

:: Retrieving current NIC GUID/UUID registry folder

:get_guid
for /f "tokens=6 delims=\" %%A in ('reg query "HKLM\SYSTEM\ControlSet001\Control\Class" /f "%~1" /s /t REG_SZ ^| find "Class"') do set "%~2=%%A" & exit /b
call :get_guid %GUID1% folder

::------------------------------------------------------------------------------------------------------------------

:START
call :DRAW_LOGO
>nul 2>&1 NET SESSION && (echo  [+] Administrator Privileges Detected.) || (echo  [-] No Administrator Privileges Detected. & echo. & pause & exit) >nul 2>&1

echo. & echo  [+] CURRENT NIC  : !NIC! & echo.
echo  [+] CURRENT MAC  : !MAC! & echo.

::-Spoofing MACAddress---------------------------------------------------------------------------------------------------------------------------

ipconfig/release >nul 2>&1

:: Microsoft Kernel Debug Network Adapter
REG ADD "HKLM\SYSTEM\ControlSet001\Control\Class\!folder!\0000" /v "NetworkAddress" /t REG_SZ /d !RMAC1! /f >nul 2>&1

:: Actual NIC(s)
REG ADD "HKLM\SYSTEM\ControlSet001\Control\Class\!folder!\0001" /v "NetworkAddress" /t REG_SZ /d !RMAC2! /f >nul 2>&1
REG ADD "HKLM\SYSTEM\ControlSet001\Control\Class\!folder!\0002" /v "NetworkAddress" /t REG_SZ /d !RMAC3! /f >nul 2>&1

:: Deleting OriginalNetworkAddress

REG DELETE "HKLM\SYSTEM\ControlSet001\Control\Class\!folder!\0000" /v "OriginalNetworkAddress" /f >nul 2>&1
REG DELETE "HKLM\SYSTEM\ControlSet001\Control\Class\!folder!\0001" /v "OriginalNetworkAddress" /f >nul 2>&1
REG DELETE "HKLM\SYSTEM\ControlSet001\Control\Class\!folder!\0002" /v "OriginalNetworkAddress" /f >nul 2>&1

ipconfig/renew >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1
explorer.exe >nul 2>&1

for /f "skip=3" %%a in ('getmac') do if not defined MAC1 set MAC1=%%a

::-----------------------------------------------------------------------------------------------------------------------------------------------

echo  [+] SPOOFED MAC  : !MAC1!
echo. & pause & cls

:MENU
call :DRAW_LOGO
echo   [1] Run again
echo   [2] Exit
echo.
set /p "choice=>> "
if "%choice%"=="1" goto :START
if "%choice%"=="2" exit
echo Choice "%choice%" isn't a valid option. Please try again. & goto :MENU

:DRAW_LOGO
cls
echo   __  __   _   ___   ___                 __
echo  ^|  \/  ^| /_\ / __^| / __^|_ __  ___  ___ / _^|___ _ _
echo  ^| ^|\/^| ^|/ _ \ (__  \__ \ '_ \/ _ \/ _ \  _/ -_) '_^|
echo  ^|_^|  ^|_/_/ \_\___^| ^|___/ .__/\___/\___/_^| \___^|_^|
echo                         ^|_^|
echo.
exit /b
