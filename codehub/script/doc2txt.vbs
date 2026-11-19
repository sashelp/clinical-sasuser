'此脚本用于将单个 DOC/DOCX 文档另存为同名 TXT 文档
'只需要将单个 DOC/DOCX 文档拖放到此脚本上，然后等待同一目录下生成同名 TXT 文档


'1. 确保用户拖放了一个文件
If WScript.Arguments.Count <> 1 Then
    MsgBox "使用方法：将单个 .docx 文件拖放到此脚本上"
    WScript.Quit 1
End If


'2. 获取参数值
Set fso=CreateObject("Scripting.FileSystemObject")
inFile=WScript.Arguments.Item(0)


'3. 检查文件扩展名是否为 doc 或 docx
If LCase(fso.GetExtensionName(inFile)) <> "doc"  and LCase(fso.GetExtensionName(inFile)) <> "docx" Then
    MsgBox "仅支持 DOC/DOCX 文件"
    WScript.Quit 1
End If


'4. 构造输出文件名
parentFolder=fso.GetParentFolderName(inFile)
If parentFolder="" Then parentFolder="."
baseName=fso.GetBaseName(inFile)
outFile=parentFolder & "\" & baseName & ".txt"


'5. 启动 Word 应用
Set Word=CreateObject("Word.Application")
If Err.Number <> 0 Then
    MsgBox "无法启动 Microsoft Word"
    WScript.Quit 1
End If
Word.Visible=False
Word.ScreenUpdating=False


'6. 打开 DOC/DOCX 文档
Set Doc=Word.Documents.Open(inFile,,,False)
If Err.Number <> 0 Then
    MsgBox "打开文件失败"
    Err.Clear
    Word.Quit
    WScript.Quit 1
End If


'7. 另存为 .txt 并退出脚本
Doc.SaveAs outFile,2,,,False
Doc.Close False
Word.Quit
Set Word=Nothing
Set fso=Nothing
MsgBox baseName & ".txt 转换完成" , vbInformation, "doc2txt.vbs"