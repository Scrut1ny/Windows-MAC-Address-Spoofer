@shift /0
@ECHO OFF
title Oblivion MAC
 SETLOCAL ENABLEDELAYEDEXPANSION
 SETLOCAL ENABLEEXTENSIONS

 ::Generate and implement a random MAC address
 FOR /F "tokens=1" %%a IN ('wmic nic where physicaladapter^=true get deviceid ^| findstr [0-9]') DO (
 CALL :MAC
 FOR %%b IN (0 00 000) DO (
 REG QUERY HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\%%b%%a >NUL 2>NUL && REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\%%b%%a /v NetworkAddress /t REG_SZ /d !MAC!  /f >NUL 2>NUL
 )
 )

 ::Disable power saving mode for network adapters
 FOR /F "tokens=1" %%a IN ('wmic nic where physicaladapter^=true get deviceid ^| findstr [0-9]') DO (
 FOR %%b IN (0 00 000) DO (
 REG QUERY HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\%%b%%a >NUL 2>NUL && REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\%%b%%a /v PnPCapabilities /t REG_DWORD /d 24 /f >NUL 2>NUL
 )
 )

 ::Reset NIC adapters so the new MAC address is implemented and the power saving mode is disabled.
 FOR /F "tokens=2 delims=, skip=2" %%a IN ('"wmic nic where (netconnectionid like '%%') get netconnectionid,netconnectionstatus /format:csv"') DO (
 netsh interface set interface name="%%a" disable >NUL 2>NUL
 netsh interface set interface name="%%a" enable >NUL 2>NUL
 )

 GOTO :EOF
 :MAC
 ::Generates semi-random value of a length according to the "if !COUNT!"  line, minus one, and from the characters in the GEN variable
 SET COUNT=0
 SET GEN=ABCDEF0123456789
 SET GEN2=26AE
 SET MAC=
 :MACLOOP
 SET /a COUNT+=1
 SET RND=%random%
 ::%%n, where the value of n is the number of characters in the GEN variable minus one.  So if you have 15 characters in GEN, set the number as 14
 SET /A RND=RND%%16
 SET RNDGEN=!GEN:~%RND%,1!
 SET /A RND2=RND%%4
 SET RNDGEN2=!GEN2:~%RND2%,1!
 IF "!COUNT!"  EQU "2" (SET MAC=!MAC!!RNDGEN2!) ELSE (SET MAC=!MAC!!RNDGEN!)
 IF !COUNT!  LEQ 11 GOTO MACLOOP 