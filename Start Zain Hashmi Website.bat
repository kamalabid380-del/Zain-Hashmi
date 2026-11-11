@echo off
rem Starts the Zain Hashmi offline site at http://127.0.0.1:3000/
start "" powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0serve-zain-hashmi.ps1"
exit
