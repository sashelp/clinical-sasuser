Option Explicit

Const adTypeBinary = 1
Const adTypeText = 2
Const adReadAll = -1
Const adSaveCreateOverWrite = 2

Dim fso, outputPath, outputText, i, inputPath, inputCount, firstInput
Set fso = CreateObject("Scripting.FileSystemObject")

outputText = CsvLine(Array("Filename", "LineNumber", "FirstMultibyteChar", "UnicodeCodePoint")) & vbCrLf
inputCount = 0
firstInput = ""

For i = 0 To WScript.Arguments.Count - 1
    If LCase(WScript.Arguments(i)) = "--output" Then
        If i + 1 >= WScript.Arguments.Count Then
            WScript.Echo "--output requires a CSV file path."
            WScript.Quit 1
        End If
        outputPath = WScript.Arguments(i + 1)
        i = i + 1
    Else
        inputPath = WScript.Arguments(i)
        inputCount = inputCount + 1
        If firstInput = "" Then firstInput = inputPath
        If fso.FolderExists(inputPath) Then
            outputText = outputText & ScanFolder(inputPath)
        ElseIf fso.FileExists(inputPath) Then
            If LCase(fso.GetExtensionName(inputPath)) = "sas" Then
                outputText = outputText & ScanFile(inputPath)
            End If
        Else
            WScript.Echo "Input does not exist: " & inputPath
            WScript.Quit 1
        End If
    End If
Next

If inputCount = 0 Then
    firstInput = fso.GetParentFolderName(WScript.ScriptFullName)
    outputText = outputText & ScanFolder(firstInput)
End If

If outputPath = "" Then
    If inputCount = 1 And fso.FolderExists(firstInput) Then
        outputPath = fso.BuildPath(firstInput, "sas_multibyte_report.csv")
    Else
        outputPath = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), "sas_multibyte_report.csv")
    End If
End If

If outputText = CsvLine(Array("Filename", "LineNumber", "FirstMultibyteChar", "UnicodeCodePoint")) & vbCrLf Then
    MsgBox "No MBCS found!", vbInformation, "SAS MBCS Scanner"
    WScript.Quit 0
End If

WriteUtf8 outputPath, outputText
MsgBox "Report written: " & outputPath, vbInformation, "SAS MBCS Scanner"

Function ScanFolder(folderPath)
    Dim folder, file, result
    result = ""
    Set folder = fso.GetFolder(folderPath)
    For Each file In folder.Files
        If LCase(fso.GetExtensionName(file.Name)) = "sas" Then
            result = result & ScanFile(file.Path)
        End If
    Next
    ScanFolder = result
End Function

Function ScanFile(filePath)
    Dim text, lines, i, firstChar, codePoint, result
    text = ReadTextFile(filePath)
    text = Replace(text, vbCrLf, vbLf)
    text = Replace(text, vbCr, vbLf)
    lines = Split(text, vbLf)
    result = ""

    For i = 0 To UBound(lines)
        If FirstNonAscii(lines(i), firstChar, codePoint) Then
            result = result & CsvLine(Array( _
                fso.GetFileName(filePath), _
                CStr(i + 1), _
                firstChar, _
                codePoint)) & vbCrLf
        End If
    Next

    ScanFile = result
End Function

Function FirstNonAscii(lineText, ByRef firstChar, ByRef codePoint)
    Dim i, unit1, unit2, value
    FirstNonAscii = False
    firstChar = ""
    codePoint = ""

    For i = 1 To Len(lineText)
        unit1 = AscW(Mid(lineText, i, 1))
        If unit1 < 0 Then unit1 = unit1 + 65536

        If unit1 > 127 Then
            firstChar = Mid(lineText, i, 1)
            value = unit1

            If unit1 >= &HD800 And unit1 <= &HDBFF And i < Len(lineText) Then
                unit2 = AscW(Mid(lineText, i + 1, 1))
                If unit2 < 0 Then unit2 = unit2 + 65536
                If unit2 >= &HDC00 And unit2 <= &HDFFF Then
                    firstChar = Mid(lineText, i, 2)
                    value = ((unit1 - &HD800) * 1024) + (unit2 - &HDC00) + &H10000
                End If
            End If

            codePoint = "U+" & Right("0000" & Hex(value), 4)
            FirstNonAscii = True
            Exit Function
        End If
    Next
End Function

Function ReadTextFile(filePath)
    Dim bytes, byteCount, charsetName
    bytes = ReadBytes(filePath)
    byteCount = LenB(bytes)

    If byteCount >= 3 And ByteAt(bytes, 1) = &HEF And ByteAt(bytes, 2) = &HBB And ByteAt(bytes, 3) = &HBF Then
        charsetName = "utf-8"
    ElseIf byteCount >= 2 And ByteAt(bytes, 1) = &HFF And ByteAt(bytes, 2) = &HFE Then
        charsetName = "unicode"
    ElseIf byteCount >= 2 And ByteAt(bytes, 1) = &HFE And ByteAt(bytes, 2) = &HFF Then
        charsetName = "unicodeFFFE"
    ElseIf IsValidUtf8(bytes) Then
        charsetName = "utf-8"
    Else
        ReadTextFile = fso.OpenTextFile(filePath, 1, False).ReadAll
        Exit Function
    End If

    ReadTextFile = DecodeBytes(bytes, charsetName)
End Function

Function ReadBytes(filePath)
    Dim stream
    Set stream = CreateObject("ADODB.Stream")
    stream.Type = adTypeBinary
    stream.Open
    stream.LoadFromFile filePath
    ReadBytes = stream.Read
    stream.Close
    Set stream = Nothing
End Function

Function DecodeBytes(bytes, charsetName)
    Dim stream
    Set stream = CreateObject("ADODB.Stream")
    stream.Type = adTypeBinary
    stream.Open
    stream.Write bytes
    stream.Position = 0
    stream.Type = adTypeText
    stream.Charset = charsetName
    DecodeBytes = stream.ReadText(adReadAll)
    stream.Close
    Set stream = Nothing
End Function

Function IsValidUtf8(bytes)
    Dim i, n, b1, b2, b3, b4
    IsValidUtf8 = True
    n = LenB(bytes)
    i = 1

    Do While i <= n
        b1 = ByteAt(bytes, i)
        If b1 < &H80 Then
            i = i + 1
        ElseIf b1 >= &HC2 And b1 <= &HDF Then
            If i + 1 > n Then IsValidUtf8 = False: Exit Function
            b2 = ByteAt(bytes, i + 1)
            If b2 < &H80 Or b2 > &HBF Then IsValidUtf8 = False: Exit Function
            i = i + 2
        ElseIf b1 >= &HE0 And b1 <= &HEF Then
            If i + 2 > n Then IsValidUtf8 = False: Exit Function
            b2 = ByteAt(bytes, i + 1)
            b3 = ByteAt(bytes, i + 2)
            If b2 < &H80 Or b2 > &HBF Or b3 < &H80 Or b3 > &HBF Then
                IsValidUtf8 = False
                Exit Function
            End If
            i = i + 3
        ElseIf b1 >= &HF0 And b1 <= &HF4 Then
            If i + 3 > n Then IsValidUtf8 = False: Exit Function
            b2 = ByteAt(bytes, i + 1)
            b3 = ByteAt(bytes, i + 2)
            b4 = ByteAt(bytes, i + 3)
            If b2 < &H80 Or b2 > &HBF Or b3 < &H80 Or b3 > &HBF Or b4 < &H80 Or b4 > &HBF Then
                IsValidUtf8 = False
                Exit Function
            End If
            i = i + 4
        Else
            IsValidUtf8 = False
            Exit Function
        End If
    Loop
End Function

Function ByteAt(bytes, position)
    ByteAt = AscB(MidB(bytes, position, 1))
End Function

Function CsvLine(values)
    Dim i, line
    line = ""
    For i = 0 To UBound(values)
        If i > 0 Then line = line & ","
        line = line & CsvField(CStr(values(i)))
    Next
    CsvLine = line
End Function

Function CsvField(value)
    CsvField = """" & Replace(value, """", """""") & """"
End Function

Sub WriteUtf8(filePath, text)
    Dim stream
    Set stream = CreateObject("ADODB.Stream")
    stream.Type = adTypeText
    stream.Charset = "utf-8"
    stream.Open
    stream.WriteText text
    stream.Position = 0
    stream.SaveToFile filePath, adSaveCreateOverWrite
    stream.Close
    Set stream = Nothing
End Sub
