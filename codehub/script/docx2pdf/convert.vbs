' convert.vbs — drag-drop .docx to .pdf, silent mode
On Error Resume Next

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
nodeExe = scriptDir & "\node.exe"
convertJs = scriptDir & "\convert.js"
qpdfExe  = scriptDir & "\qpdf\bin\qpdf.exe"

' If no file dragged, show help
If WScript.Arguments.Count = 0 Then
    MsgBox "Drag a .docx file onto this icon to convert to PDF." & vbCrLf & vbCrLf & "Install location: " & scriptDir, vbInformation, "docx2pdf"
    WScript.Quit
End If

' Verify convert.js exists
If Not fso.FileExists(convertJs) Then
    MsgBox "convert.js not found! Expected: " & convertJs & vbCrLf & vbCrLf & "Do not move this .vbs file. Create a shortcut instead.", vbCritical, "docx2pdf"
    WScript.Quit
End If

' Verify node.exe exists
If Not fso.FileExists(nodeExe) Then
    MsgBox "node.exe not found! Expected: " & nodeExe, vbCritical, "docx2pdf"
    WScript.Quit
End If

' Verify qpdf exists
If Not fso.FileExists(qpdfExe) Then
    answer = MsgBox("qpdf.exe not found! Fast Web View disabled. Continue?", vbYesNo + vbExclamation, "docx2pdf")
    If answer <> vbYes Then WScript.Quit
End If

inputFile = WScript.Arguments(0)
outputFile = fso.GetParentFolderName(inputFile) & "\" & fso.GetBaseName(inputFile) & ".pdf"

' Check input exists
If Not fso.FileExists(inputFile) Then
    MsgBox "File not found: " & inputFile, vbCritical, "docx2pdf"
    WScript.Quit
End If

' Check .docx extension
If LCase(fso.GetExtensionName(inputFile)) <> "docx" Then
    MsgBox "Only .docx files are supported.", vbExclamation, "docx2pdf"
    WScript.Quit
End If

' Delete old output if exists
If fso.FileExists(outputFile) Then
    fso.DeleteFile outputFile, True
End If

' Run conversion
cmd = """" & nodeExe & """ """ & convertJs & """ """ & inputFile & """ """ & outputFile & """"
returnCode = shell.Run(cmd, 0, True)

' Check result
If returnCode = 0 And fso.FileExists(outputFile) Then
    answer = MsgBox("Done! Output: " & outputFile & vbCrLf & vbCrLf & "Open PDF?", vbYesNo + vbInformation, "docx2pdf")
    If answer = vbYes Then shell.Run """" & outputFile & """"
Else
    MsgBox "Conversion failed! Return code: " & returnCode & vbCrLf & "Input: " & inputFile, vbCritical, "docx2pdf"
End If
