@echo off

REM Kill the Windows Explorer process to reset the taskbar
taskkill /f /im explorer.exe

REM Wait for 2 seconds
timeout /t 2 /nobreak > NUL

REM Start Windows Explorer again
start explorer.exe

REM Wait another 2 seconds to ensure explorer has time to initialize
timeout /t 2 /nobreak > NUL

REM Exit the batch script
exit 0