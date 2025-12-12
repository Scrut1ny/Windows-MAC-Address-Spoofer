::  ==================================================
::  Windows-MAC-Address-Spoofer v10.0
:: ==================================================
::  Developer: Scrut1ny
::  Contributors: Mathieu, Sintrode, Mustafachyi
::  https://github.com/Scrut1ny/Windows-MAC-Address-Spoofer
:: ==================================================

@echo off
title MAC Address Spoofer ^| v10.0
setlocal EnableDelayedExpansion
mode con:cols=66 lines=25

:: Administrator?
net session >nul 2>&1 || (
    echo( & echo   [33m# Administrator privileges are required. & echo([0m
    runas /user:Administrator "%~0" %*
    exit /b
)

:: Variables
set "reg_path=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"

:SELECTION_MENU
set "count=0"
cls & echo( & echo   [35m[i] Input NIC # to modify.[0m & echo(
for /f "skip=2 tokens=2 delims=," %%A in ('wmic nic get NetConnectionId /format:csv') do (
    for /f "delims=" %%B in ("%%~A") do (
        set /a "count+=1"
        set "nic[!count!]=%%B"
        echo   [36m!count![0m - %%B
    )
)
echo( & echo   [36m99[0m - Revise Networking & echo(
set /p "nic_selection=.  [35m# [0m"
set /a "nic_selection=nic_selection"

if !nic_selection! EQU 99 (
    cls & echo( & echo   [32m# Revising networking configurations...[0m
    ipconfig /release >nul 2>&1 && arp -d * >nul 2>&1 && ipconfig /renew >nul 2>&1
    goto :SELECTION_MENU
)
if !nic_selection! GTR 0 if !nic_selection! LEQ !count! (
    for /f "delims=" %%A in ("!nic_selection!") do set "NetworkAdapter=!nic[%%A]!"
    goto :ACTION_MENU
)
call :SHOW_ERROR "Option '!nic_selection!' is invalid." && goto :SELECTION_MENU

:ACTION_MENU
cls & echo( & echo   [35m[i] Input action # to perform.[0m & echo(
echo   [36m^> Selected NIC :[0m !NetworkAdapter! & echo(
echo   [36m1[0m - Randomize MAC address
echo   [36m2[0m - Customize MAC address
echo   [36m3[0m - Revert MAC address to original
echo( & echo   [36m0[0m ^< Menu & echo(
set /p "c=.  [35m#[0m "
if "%c%"=="1" goto :SPOOF_MAC
if "%c%"=="2" goto :CUSTOM_MAC
if "%c%"=="3" goto :REVERT_MAC
if "%c%"=="0" goto :SELECTION_MENU
call :SHOW_ERROR "Option '%c%' is invalid." && goto :ACTION_MENU

:SPOOF_MAC
cls & echo( && call :MAC_RECEIVE && call :GEN_MAC && call :NIC_INDEX
echo   [36m^> Selected NIC :[0m !NetworkAdapter! & echo(
echo   [36m^> Previous MAC :[0m !MAC! & echo(
echo   [36m^> Modified MAC :[0m !mac_address_print!
call :APPLY_MAC
echo( & echo   [35m[i] MAC address successfully spoofed.[0m
call :PAUSE_CONTINUE && goto :ACTION_MENU

:CUSTOM_MAC
cls & echo( && call :MAC_RECEIVE && call :NIC_INDEX
echo   [36m^> Selected NIC :[0m !NetworkAdapter! & echo(
echo   [36m^> Current MAC  :[0m !MAC! & echo(
echo   [35m[i] Enter a custom MAC address (exclude colons).
echo   Remember, only use hex characters: 0-9 A-F[0m & echo(
set /p "mac_address=.  [35m#[0m "

:: Validate MAC address
set "valid=1"
if "!mac_address!"=="" set "valid=0"
if "!mac_address:~11,1!"=="" set "valid=0"
if not "!mac_address:~12,1!"=="" set "valid=0"
if "!valid!"=="1" (
    set "valid_chars=0123456789ABCDEFabcdef"
    for /l %%i in (0,1,11) do (
        set "char=!mac_address:~%%i,1!"
        echo !valid_chars! | find "!char!" >nul || set "valid=0"
    )
)
if "!valid!"=="0" (
    call :SHOW_ERROR "Enter a valid 12-character hexadecimal MAC address." 4
    goto :CUSTOM_MAC
)

call :FORMAT_MAC
echo( & echo   [36m^> Modified MAC :[0m !mac_address_print!
call :APPLY_MAC
call :PAUSE_CONTINUE && goto :ACTION_MENU

:REVERT_MAC
cls & echo( && call :MAC_RECEIVE && call :NIC_INDEX
echo   [36m^> Selected NIC :[0m !NetworkAdapter! & echo(
echo   [36m^> Modified MAC :[0m !MAC! & echo(
set "SavedMAC=!MAC!"
>nul 2>&1 (
    netsh interface set interface "!NetworkAdapter!" admin=disable
    reg delete "!reg_path!\!Index!" /v "NetworkAddress" /f
    netsh interface set interface "!NetworkAdapter!" admin=enable
    powershell -NoProfile -Command "Restart-Service -Force -Name winmgmt"
)
call :MAC_RECEIVE
echo   [36m^> Reverted MAC :[0m !MAC! & echo(
if "!SavedMAC!"=="!MAC!" (
    echo   [35m[i] Original MAC address already set.[0m
) else (
    echo   [35m[i] MAC address successfully reverted to original.[0m
)
call :PAUSE_CONTINUE && goto :ACTION_MENU

::  ==================== HELPER FUNCTIONS ====================

:GEN_MAC
set "#hex=0123456789ABCDEFAE26"
set "mac_address="
for /l %%A in (1,1,11) do (
    set /a "ri=!random! %% 16"
    for %%B in (!ri!) do set "mac_address=!mac_address!!#hex:~%%B,1!"
)
set /a "ri=!random! %% 4 + 17"
set "mac_address=!mac_address:~0,1!!#hex:~%ri%,1!!mac_address:~1!"
call :FORMAT_MAC
exit /b

:FORMAT_MAC
set "mac_address_print=!mac_address:~0,2!:!mac_address:~2,2!:!mac_address:~4,2!:!mac_address:~6,2!:!mac_address:~8,2!:!mac_address:~10,2!"
exit /b

:MAC_RECEIVE
call :NIC_INDEX
for /f "tokens=2 delims==" %%A in ('wmic nic where "Index='!Index!'" get MacAddress /format:value ^| find "MACAddress"') do set "MAC=%%A"
exit /b

:NIC_INDEX
for /f "tokens=2 delims=[]" %%A in ('wmic nic where "NetConnectionId='!NetworkAdapter!'" get Caption /format:value ^| find "Caption"') do (
    set "Index=%%A"
    set "Index=!Index:~-4!"
)
exit /b

:APPLY_MAC
>nul 2>&1 (
    netsh interface set interface "!NetworkAdapter!" admin=disable
    reg add "!reg_path!\!Index!" /v "NetworkAddress" /t REG_SZ /d "!mac_address!" /f
    netsh interface set interface "!NetworkAdapter!" admin=enable
)
exit /b

:SHOW_ERROR
cls & echo( & echo   [31m[i] %~1[0m
set "delay=%~2"
if "%delay%"=="" set "delay=2"
>nul timeout /t %delay%
exit /b

:PAUSE_CONTINUE
echo( & echo   [35m# Press any key to continue...[0m && >nul pause

exit /b

