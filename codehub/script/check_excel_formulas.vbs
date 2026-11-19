'此脚本用于检测指定文件夹下的所有Excel文件中的单元格值是否为公式, 如是, 将返回第一个值为公式单元格的位置
Option Explicit

Dim folderPath, outputCsv, outputXlsx
folderPath = "雾剂-I期\02-raw_dataset\03-non_ecrf_data\Ib期\正式"
outputCsv = folderPath & "\FormulaCheckResults.csv"
outputXlsx = folderPath & "\FormulaCheckResults.xlsx"

Dim fso, csvFile, excelApp
Set fso = CreateObject("Scripting.FileSystemObject")

If Not fso.FolderExists(folderPath) Then
    WScript.Echo "指定的文件夹不存在：" & folderPath
    WScript.Quit 1
End If

Set csvFile = fso.CreateTextFile(outputCsv, True, True)

csvFile.WriteLine "文件路径,工作表,单元格,公式内容"

Set excelApp = CreateObject("Excel.Application")
excelApp.Visible = False
excelApp.DisplayAlerts = False

Dim folder, file, ext, fullPath, result
Set folder = fso.GetFolder(folderPath)

For Each file In folder.Files
    ext = LCase(fso.GetExtensionName(file.Name))
    If ext = "xls" Or ext = "xlsx" Or ext = "xlsm" Then
        Set result = CheckWorkbook(file.Path, excelApp)

        csvFile.WriteLine _
            EscapeCsv(result("File")) & "," & _
            EscapeCsv(result("Sheet")) & "," & _
            EscapeCsv(result("Address")) & "," & _
            EscapeCsv(result("Formula"))
    End If
Next

csvFile.Close

CreateResultWorkbook outputXlsx, outputCsv, excelApp

excelApp.Quit
Set excelApp = Nothing
Set fso = Nothing

WScript.Echo "检查完成。"
WScript.Echo "CSV 输出：" & outputCsv
WScript.Echo "Excel 输出：" & outputXlsx

Function CheckWorkbook(path, excelApp)
    Dim dict, wb, ws, usedRange, r, c, hasFormula, cell
    Set dict = CreateObject("Scripting.Dictionary")
    dict.Add "File", path
    dict.Add "Sheet", ""
    dict.Add "Address", ""
    dict.Add "Formula", ""

    On Error Resume Next
    Set wb = excelApp.Workbooks.Open(path, 0, True)
    If Err.Number <> 0 Then
        Err.Clear
        Set CheckWorkbook = dict
        Exit Function
    End If
    On Error GoTo 0

    For Each ws In wb.Worksheets
        Set usedRange = ws.UsedRange
        If Not usedRange Is Nothing Then
            For r = usedRange.Row To usedRange.Row + usedRange.Rows.Count - 1
                For c = usedRange.Column To usedRange.Column + usedRange.Columns.Count - 1
                    Set cell = ws.Cells(r, c)
                    hasFormula = False
                    On Error Resume Next
                    hasFormula = cell.HasFormula
                    On Error GoTo 0
                    If hasFormula Then
                        dict("Sheet") = ws.Name
                        dict("Address") = cell.Address(False, False)
                        dict("Formula") = cell.Formula
                        Exit For
                    End If
                Next
                If dict("Sheet") <> "" Then Exit For
            Next
        End If
        If dict("Sheet") <> "" Then Exit For
    Next

    wb.Close False
    Set CheckWorkbook = dict
End Function

Function EscapeCsv(text)
    Dim result
    result = CStr(text)
    If InStr(result, """") > 0 Then
        result = Replace(result, """", """""")
    End If
    If InStr(result, ",") > 0 Or InStr(result, vbCrLf) > 0 Or InStr(result, vbLf) > 0 Then
        result = """" & result & """"
    End If
    EscapeCsv = result
End Function

Sub CreateResultWorkbook(xlsxPath, csvPath, excelApp)
    Dim wb, ws, fso2, line, arr, rowIndex, ts
    Set fso2 = CreateObject("Scripting.FileSystemObject")

    Set wb = excelApp.Workbooks.Add()
    Set ws = wb.Worksheets(1)

    Set ts = fso2.OpenTextFile(csvPath, 1, False, -1)
    rowIndex = 1
    Do While Not ts.AtEndOfStream
        line = ts.ReadLine
        arr = ParseCsvLine(line)
        Dim i
        For i = 0 To UBound(arr)
            ws.Cells(rowIndex, i + 1).Value = arr(i)
        Next
        rowIndex = rowIndex + 1
    Loop
    ts.Close

    On Error Resume Next
    wb.SaveAs xlsxPath, 51
    If Err.Number <> 0 Then
        WScript.Echo "保存 Excel 文件失败：" & Err.Description
        Err.Clear
    End If
    On Error GoTo 0
    wb.Close False
End Sub

Function ParseCsvLine(line)
    Dim values(), current, inQuotes, i, ch
    ReDim values(0)
    current = ""
    inQuotes = False

    For i = 1 To Len(line)
        ch = Mid(line, i, 1)
        If ch = """" Then
            If inQuotes And i < Len(line) And Mid(line, i + 1, 1) = """" Then
                current = current & """"
                i = i + 1
            Else
                inQuotes = Not inQuotes
            End If
        ElseIf ch = "," And Not inQuotes Then
            values(UBound(values)) = current
            ReDim Preserve values(UBound(values) + 1)
            current = ""
        Else
            current = current & ch
        End If
    Next
    values(UBound(values)) = current
    ParseCsvLine = values
End Function