Option Explicit
' ============================================================
' 将文件名变更为小写
' 用法：在资源管理器中选中多个文件，拖拽到此脚本图标上
' ============================================================
Dim fso, shell, arg, filePath, folder, oldName, newName, cmdLine

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

For Each arg In WScript.Arguments
    filePath = Trim(arg)
    If Len(filePath) > 0 And fso.FileExists(filePath) Then
        folder = fso.GetParentFolderName(filePath)
        oldName = fso.GetFileName(filePath)
        newName = LCase(fso.GetBaseName(oldName))

        If Len(fso.GetExtensionName(oldName)) > 0 Then
            newName = newName & "." & LCase(fso.GetExtensionName(oldName))
        End If

        If StrComp(oldName, newName, vbBinaryCompare) <> 0 Then
            cmdLine = "%COMSPEC% /d /c cd /d """ & folder & """ && ren """ & oldName & """ """ & newName & """"
            shell.Run cmdLine, 0, True
        End If
    End If
Next
