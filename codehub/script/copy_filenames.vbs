Option Explicit

' ============================================================
' 复制文件名到剪贴板
' 用法：在资源管理器中选中多个文件，拖拽到此脚本图标上
'       文件名按资源管理器当前显示顺序复制，换行分隔
' ============================================================

Dim objShell, objArgs, fso
Dim i, fileName, strText, tempFile, outFile
Dim countCopied

Set objShell = CreateObject("WScript.Shell")
Set objArgs = WScript.Arguments
Set fso = CreateObject("Scripting.FileSystemObject")

' --- 没有拖入文件时给出提示 ---
If objArgs.Count = 0 Then
    MsgBox "请将文件拖拽到此脚本图标上。", vbInformation, "复制文件名"
    WScript.Quit
End If

' --- 提取每个文件的文件名（不含路径） ---
strText = ""
countCopied = 0

For i = 0 To objArgs.Count - 1
    ' 跳过文件夹，只处理文件（如需要也复制文件夹名，可删除此判断）
    If fso.FileExists(objArgs(i)) Or fso.FolderExists(objArgs(i)) Then
        fileName = fso.GetFileName(objArgs(i))
        If countCopied > 0 Then
            strText = strText & vbCrLf
        End If
        strText = strText & fileName
        countCopied = countCopied + 1
    End If
Next

If countCopied = 0 Then
    MsgBox "未识别到任何有效文件。", vbExclamation, "复制文件名"
    WScript.Quit
End If

' --- 写入临时文件，通过 clip.exe 复制到剪贴板 ---
tempFile = objShell.ExpandEnvironmentStrings("%TEMP%") & "\vbs_copy_filenames.tmp"

' CreateTextFile(path, overwrite, unicode): unicode=True → UTF-16 LE
Set outFile = fso.CreateTextFile(tempFile, True, True)
outFile.Write strText
outFile.Close

' clip.exe 重定向方式支持 UTF-16 LE（Windows 内部标准 Unicode 编码）
objShell.Run "cmd /c clip < """ & tempFile & """", 0, True

' 清理临时文件
fso.DeleteFile tempFile, True

' --- 简洁通知（可删除下面这行来关闭提示） ---
MsgBox "已复制 " & countCopied & " 个文件名到剪贴板。" & vbCrLf & vbCrLf & strText, _
       vbInformation, "复制完成"
