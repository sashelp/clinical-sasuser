@echo off
title docx2pdf - Converting...

echo ========================================
echo   docx2pdf - docx to pdf converter
echo ========================================
echo.

REM Use bundled node.exe
set NODE=%~dp0node.exe
if not exist "%NODE%" (
    echo [ERROR] node.exe not found
    pause
    exit /b 1
)

REM Check input
if "%~1"=="" (
    echo Drag a .docx file onto this bat icon.
    pause
    exit /b 1
)

echo Input: %~nx1
echo.

REM Convert
"%NODE%" "%~dp0convert.js" "%~1" "%~dpn1.pdf"

REM Done
if errorlevel 1 (
    echo.
    echo [FAILED] See errors above.
) else (
    echo.
    echo [OK] Output: %~dpn1.pdf
)
echo.
pause
