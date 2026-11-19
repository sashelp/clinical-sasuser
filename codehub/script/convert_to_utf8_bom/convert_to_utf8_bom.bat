@echo off
rem 批处理包装器：支持将文件拖放到此 .bat 上以转换为 UTF-8 带 BOM
setlocal

if "%~1"=="" (
    echo 请将要转换的文件拖放到此批处理文件上。
    pause
    exit /b 1
)

rem 将所有参数原样转发给 PowerShell 脚本（使用 %* 保持引号和空格）
set "PS1=%~dp0convert_to_utf8_bom.ps1"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
pause