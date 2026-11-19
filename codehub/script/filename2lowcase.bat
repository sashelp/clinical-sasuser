REM 功能：将所在目录下所有的子文件夹和文件名全部改为小写字母
REM 用法：将本批处理文件复制到要改名的目录下直接运行即可

pause

FOR /R %%A IN (.) DO cd %%A && (FOR /F %%B IN ('dir /b /l') DO rename %%B %%B)

echo 重命名结束
pause