'此脚本用于对单个 RTF 文档插入目录、清除页眉页脚、设置字体，最终另存为同名 DOCX 文档
'只需要将单个 RTF 文档拖放到此脚本上，然后等待同一目录下生成同名 DOCX 文档

startTime=Timer

'1. 确保用户拖放了一个文件
If WScript.Arguments.Count <> 1 Then
    MsgBox "使用方法：将单个 .rtf 文件拖放到此脚本上"
    WScript.Quit 1
End If


'2. 获取参数值
Set fso=CreateObject("Scripting.FileSystemObject")
inFile=WScript.Arguments.Item(0)


'3. 检查文件扩展名是否为 rtf
If LCase(fso.GetExtensionName(inFile)) <> "rtf" Then
    MsgBox "仅支持 RTF 文件"
    WScript.Quit 1
End If


'4. 构造输出文件名
parentFolder=fso.GetParentFolderName(inFile)
If parentFolder="" Then parentFolder="."
baseName=fso.GetBaseName(inFile)
outFile=parentFolder & "\" & baseName & ".docx"


'5. 启动 Word 应用
Set Word=CreateObject("Word.Application")
If Err.Number <> 0 Then
    MsgBox "无法启动 Microsoft Word"
    WScript.Quit 1
End If
Word.Visible=False
Word.ScreenUpdating=False


'6. 打开 RTF 文档
Set Doc=Word.Documents.Open(inFile,,,False)
If Err.Number <> 0 Then
    MsgBox "打开文件失败"
    Err.Clear
    Word.Quit
    WScript.Quit 1
End If


'7. 插入目录
Call Doc.TablesOfContents.Add(Doc.Range(0,0),False,,,False,,,,,True,,True)
Word.Selection.InsertBreak 2
Word.Selection.HomeKey 6,1
Word.Selection.ParagraphFormat.CharacterUnitLeftIndent=0
Word.Selection.ParagraphFormat.LeftIndent=0

Set insertRange=Doc.Range(0,0)
insertRange.InsertAfter("Table of Content" & vbCrLf)
insertRange.ParagraphFormat.Alignment=1
insertRange.ParagraphFormat.LineSpacingRule=1
insertRange.ParagraphFormat.CharacterUnitLeftIndent=0
insertRange.ParagraphFormat.LeftIndent=0
insertRange.Font.Size=14


'8. 全文调整为宋体+Times New Roman 字体
Doc.Content.Font.NameFarEast="SimSun"
Doc.Content.Font.NameAscii="Times New Roman"


'9. 另存为 .docx 并退出脚本
Doc.SaveAs outFile,16,,,False
Doc.Close False
Word.Quit
Set Word=Nothing
Set fso=Nothing
Duration=Timer-startTime
MsgBox baseName & ".docx 转换完成"  & vbCrLf & "耗时(s): " & round(Duration,3), vbInformation, "rtf2docx.vbs"