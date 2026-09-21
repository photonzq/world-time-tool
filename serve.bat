@echo off
setlocal enabledelayedexpansion
title World Time Tool - test server

set "PORT=8000"
set "PY=C:\ProgramData\anaconda3\python.exe"
if not exist "%PY%" set "PY=python"

rem serve this script's own folder (strip the trailing backslash from %~dp0,
rem otherwise the closing quote gets escaped and the path breaks)
set "DIR=%~dp0"
set "DIR=%DIR:~0,-1%"

rem pick the LAN address: skip loopback, skip link-local, prefer the
rem interface Windows is actually routing through
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command ^
 "(Get-NetIPAddress -AddressFamily IPv4 ^| Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' -and $_.PrefixOrigin -ne 'WellKnown' } ^| Sort-Object InterfaceMetric ^| Select-Object -First 1).IPAddress"`) do set "IP=%%i"
if "!IP!"=="" set "IP=<no network found>"

echo.
echo   serving  %DIR%
echo.
echo   this PC   http://localhost:%PORT%
echo   phone     http://!IP!:%PORT%
echo.
echo   Phone must be on the same Wi-Fi. If it will not connect, allow
echo   Python through Windows Firewall on Private networks when asked.
echo.
echo   Ctrl+C to stop.
echo.

"%PY%" -m http.server %PORT% --bind 0.0.0.0 --directory "%DIR%"
