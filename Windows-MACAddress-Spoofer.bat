::--------------------------------------
:: By: 0x00 / Anonymoushacker4926
:: Windows MACAddress Spoofer
:: V3.0
::--------------------------------------

@echo off
cls
setlocal EnableDelayedExpansion

::-VARIABLES--------------------------------------------------------------------------------------------------------

:: Retrieving GUID/UUID
for /f "skip=2 tokens=2 delims=," %%a in ('wmic nicconfig where IPEnabled^=True GET SettingID /format:csv') do for %%b in (%%a) do set GUID=%%b

:: Generate Random MACAddress
for /f "usebackq" %%a in (`powershell -command [BitConverter]::ToString([BitConverter]::GetBytes((Get-Random -Maximum 0xFFFFFFFFFFFF^)^)^, 0^, 6^).Replace(^':^'^, ^'-^'^)`) do (set "RMAC=%%a")

:: Retrieving Current MACAddress
for /f "skip=5" %%a in ('getmac') do set "MAC=%%a"

:: Retrieving Interface Name
for /f "skip=2 tokens=3*" %%a in ('netsh interface show interface') do (netsh interface set interface name="%%b" admin=disabled & netsh interface set interface name="%%b" admin=enabled)

::------------------------------------------------------------------------------------------------------------------

:START
call :DRAW_LOGO
>nul 2>&1 NET SESSION && (echo  [+] Administrator Privileges Detected.) || (echo  [-] No Administrator Privileges Detected. & echo. & pause & exit)

echo. & echo  [+] Active NIC's : & echo.
wmic nicconfig where (IPEnabled=True) GET Description,SettingID,MACAddress
echo. & echo  [+] CURRENT MAC: !MAC! & echo.

::-Spoofing MACAddress---------------------------------------------------------------------------------------------------------------------------

:: Microsoft Kernel Debug Network Adapter
REG ADD "HKLM\SYSTEM\ControlSet001\Control\Class\!GUID!\0000" /v "NetworkAddress" /t REG_SZ /d !MAC! /f >nul 2>&1

:: Actual NIC
REG ADD "HKLM\SYSTEM\ControlSet001\Control\Class\!GUID!\0001" /v "NetworkAddress" /t REG_SZ /d !RMAC! /f >nul 2>&1
REG ADD "HKLM\SYSTEM\ControlSet001\Control\Class\!GUID!\0002" /v "NetworkAddress" /t REG_SZ /d !RMAC! /f >nul 2>&1

:: Deleting OriginalNetworkAddress

REG DELETE "HKLM\SYSTEM\ControlSet001\Control\Class\!GUID!\0000" /v "OriginalNetworkAddress" /f >nul 2>&1
REG DELETE "HKLM\SYSTEM\ControlSet001\Control\Class\!GUID!\0001" /v "OriginalNetworkAddress" /f >nul 2>&1
REG DELETE "HKLM\SYSTEM\ControlSet001\Control\Class\!GUID!\0002" /v "OriginalNetworkAddress" /f >nul 2>&1

::-----------------------------------------------------------------------------------------------------------------------------------------------

echo  [+] SPOOFED MAC: !RMAC! & echo. & echo  [+] Applying... Please wait. & echo.)

echo  [+] DISABLING NIC...
echo.
taskkill /f /im explorer.exe >nul 2>&1
explorer.exe >nul 2>&1
echo  [+] ENABLING NIC...
echo.
echo  [+] Completed!
echo.
pause

:MENU
call :DRAW_LOGO
echo   [1] Run again
echo   [2] Exit
echo.
set /p "choice=>> "
if "%choice%"=="1" goto :START
if "%choice%"=="2" exit
echo Choice "%choice%" isn't a valid option. Please try again.
goto :MENU

:DRAW_LOGO
cls
echo   __  __   _   ___   ___                 __
echo  ^|  \/  ^| /_\ / __^| / __^|_ __  ___  ___ / _^|___ _ _
echo  ^| ^|\/^| ^|/ _ \ (__  \__ \ '_ \/ _ \/ _ \  _/ -_) '_^|
echo  ^|_^|  ^|_/_/ \_\___^| ^|___/ .__/\___/\___/_^| \___^|_^|
echo                         ^|_^|
echo.
exit /b