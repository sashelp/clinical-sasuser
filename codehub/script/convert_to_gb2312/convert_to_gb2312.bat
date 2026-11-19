@echo off
rem 将文件拖放到本批处理文件上以将 UTF-8 转为 GB2312
setlocal

if "%~1"=="" (
    echo 请将要转换的文件拖放到此批处理文件上。
    pause
    exit /b 1
)

set "PS1=%~dp0convert_to_gb2312.ps1"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
pause