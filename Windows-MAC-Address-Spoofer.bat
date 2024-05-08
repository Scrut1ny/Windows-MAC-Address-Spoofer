@echo off
title Windows-MAC-Address-Spoofer ^| v8.4
setlocal EnableDelayedExpansion
mode con:cols=66 lines=25

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo( && echo   [36m# Administrator privileges are required. && echo([0m
    runas /user:Administrator "%~0" %*
    exit /b
)

:: Variable(s)
set "reg_path=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"

:SELECTION_MENU
:: Enumerate available NICs - (You can use "name" or "NetConnectionId")
set "count=0"
cls && echo( && echo   [33m[i] Input NIC # to modify or type 'exit' to quit.[0m && echo(
for /f "skip=2 tokens=2 delims=," %%A in ('wmic nic get NetConnectionId /format:csv') do (
    for /f "delims=" %%B in ("%%~A") do (
        set /a "count+=1"
        set "nic[!count!]=%%B"
        echo   [36m!count![0m - %%B
    )
)
:: Receive user selection
echo( && echo(
set /p "nic_selection=Enter the number of the NIC you want to modify: "
if /i "%nic_selection%"=="exit" goto :EXIT
set /a "nic_selection=nic_selection"
if !nic_selection! GTR 0 (
    if !nic_selection! LEQ !count! (
        for /f "delims=" %%A in ("!nic_selection!") do set "NetworkAdapter=!nic[%%A]!"
        goto :ACTION_MENU
    )
)
echo Invalid selection. Please enter a number between 1 and !count! or type 'exit' to quit.
goto :SELECTION_MENU

:ACTION_MENU
cls && echo(
echo   [36m1[0m - Spoof MAC
echo   [36m2[0m - Revert to Original MAC
echo   [36m3[0m - Set Custom MAC
echo   [36m4[0m - Exit && echo(
set /p c=Enter the number of the action you want to perform: 
if %c%==1 goto :SPOOF_MAC
if %c%==2 goto :REVERT_MAC
if %c%==3 goto :CUSTOM_MAC
if %c%==4 goto :EXIT
echo Invalid selection. Please enter a number between 1 and 4.
goto :ACTION_MENU

:EXIT
exit /b

:CUSTOM_MAC
cls && echo( && call :MAC_RECIEVE && call :NIC_INDEX
echo   [31m# Selected NIC :[0m !NetworkAdapter! && echo(
echo   [31m# Current MAC :[0m !MAC! && echo(
:: Ask for the custom MAC address
set /p "mac_address=Enter the custom MAC address (without colons): "
:: Validate the MAC address
if not "!mac_address:~12,1!"=="" (
    echo Invalid MAC address. Please enter a 12-digit hexadecimal number.
    goto :CUSTOM_MAC
)
:: Add colons after every two characters for printing
set "mac_address_print=!mac_address:~0,2!:!mac_address:~2,2!:!mac_address:~4,2!:!mac_address:~6,2!:!mac_address:~8,2!:!mac_address:~10,2!"
echo   [31m# New MAC  :[0m !mac_address_print!
>nul 2>&1 (
    netsh interface set interface "!NetworkAdapter!" admin=disable
    reg delete "!reg_path!\!Index!" /v "NetworkAddress" /f
    reg add "!reg_path!\!Index!" /v "NetworkAddress" /t REG_SZ /d "!mac_address!" /f
    netsh interface set interface "!NetworkAdapter!" admin=enable
)
echo( && echo   [35m#[0m Press any key to continue... && >nul pause && goto :SELECTION_MENU

:SPOOF_MAC
cls && echo( && call :MAC_RECIEVE && call :GEN_MAC && call :NIC_INDEX
echo   [31m# Selected NIC :[0m !NetworkAdapter! && echo(
echo   [31m# Previous MAC :[0m !MAC! && echo(
echo   [31m# Spoofed MAC  :[0m !mac_address_print!
>nul 2>&1 (
    netsh interface set interface "!NetworkAdapter!" admin=disable
    reg delete "!reg_path!\!Index!" /v "NetworkAddress" /f
    reg add "!reg_path!\!Index!" /v "NetworkAddress" /t REG_SZ /d "!mac_address!" /f
    netsh interface set interface "!NetworkAdapter!" admin=enable
)
echo( && echo   [35m#[0m Press any key to continue... && >nul pause && goto :SELECTION_MENU

:REVERT_MAC
cls && echo( && call :MAC_RECIEVE && call :NIC_INDEX
echo   [31m# Selected NIC :[0m !NetworkAdapter! && echo(
echo   [31m# Current MAC :[0m !MAC! && echo(
:: Save the current MAC address
set "SavedMAC=!MAC!"
>nul 2>&1 (
    netsh interface set interface "!NetworkAdapter!" admin=disable
    reg delete "!reg_path!\!Index!" /v "NetworkAddress" /f
    netsh interface set interface "!NetworkAdapter!" admin=enable
)
:: Retrieve the MAC address after resetting the NIC
call :MAC_RECIEVE
echo   [31m# MAC after reset :[0m !MAC! && echo(
:: Compare the saved MAC with the MAC after reset
if "!SavedMAC!"=="!MAC!" (
    echo   [35m# The MAC address did not change after the reset.[0m
) else (
    echo   [35m# The MAC address was successfully reverted to the original.[0m
)
echo( && echo   [35m#[0m Press any key to continue... && >nul pause && goto :SELECTION_MENU

:INVALID_SELECTION
cls && echo( && echo   [31m"!nic_selection!" is a invalid option.[0m && >nul timeout /t 2 && goto :SELECTION_MENU

:: Generating Random MAC Address
:: The second character of the first octet of the MAC Address needs to contain A, E, 2, or 6 to properly function for certain wireless NIC's. Example: xA:xx:xx:xx:xx
:GEN_MAC
set #hex_chars=0123456789ABCDEF`AE26
set mac_address=
for /l %%A in (1,1,11) do (
    set /a "random_index=!random! %% 16"
    for %%B in (!random_index!) do (
        set mac_address=!mac_address!!#hex_chars:~%%B,1!
    )
)
set /a "random_index=!random! %% 4 + 17"
set mac_address=!mac_address:~0,1!!#hex_chars:~%random_index%,1!!mac_address:~1!

:: Add colons after every two characters for printing
set mac_address_print=!mac_address:~0,2!:!mac_address:~2,2!:!mac_address:~4,2!:!mac_address:~6,2!:!mac_address:~8,2!:!mac_address:~10,2!
exit /b

:: Retrieving Current MAC Address
:MAC_RECIEVE
call :NIC_INDEX

:: Always retrieve the MAC address from the wmic command
for /f "tokens=2 delims==" %%A in ('wmic nic where "Index='!Index!'" get MacAddress /format:value ^| find "MACAddress"') do (
    set "MAC=%%A"
)

exit /b

:: Retrieving current caption & converting into a Index - (You can use "name" or "NetConnectionId")
:NIC_INDEX
for /f "tokens=2 delims=[]" %%A in ('wmic nic where "NetConnectionId='!NetworkAdapter!'" get Caption /format:value ^| find "Caption"') do (
    set "Index=%%A"
    set "Index=!Index:~-4!"
)
exit /b 0
