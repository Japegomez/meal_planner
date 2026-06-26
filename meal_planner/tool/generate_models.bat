@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0generate_models.ps1"
exit /b %ERRORLEVEL%
