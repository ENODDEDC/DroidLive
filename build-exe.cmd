@echo off
title Build DroidLive.exe
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0build-exe.ps1"
pause
