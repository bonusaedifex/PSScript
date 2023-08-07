@echo off

REM Run the PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\tjudson\OneDrive - Clayton County Water Authority\AppDevDocs\Powershell Scripts\SystemStatsWinPS.ps1"

REM Set the path to the output file
set "outputFilePath=C:\Users\tjudson\OneDrive - Clayton County Water Authority\Desktop\TextLogs\SystemStats.txt"

REM Open the file location
explorer /select,"%outputFilePath%"
