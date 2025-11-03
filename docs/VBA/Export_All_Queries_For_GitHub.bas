Attribute VB_Name = "Export_All_Queries_For_GitHub"
'===============================================
' Module: Export_PowerQuery_To_M_Files.bas
' Purpose: Export every Power Query (M) query in
'          this workbook to individual .m files.
' Author:  PSI Commission System
' Notes:   - UTF-8 output (no BOM) using ADODB.Stream (late bound)
'          - Safe filenames (removes invalid chars)
'          - Exports ALL queries (tables, functions, parameters)
'===============================================

Option Explicit

Public Sub Export_PQ_As_M_Files()
    Const DEFAULT_EXPORT_PATH As String = "C:\Users\mboye\OneDrive - Master Agent Commissions\New_Commission_System\docs\PowerQuery" ' <-- set me
    Dim exportPath As String
    exportPath = PickFolderOrDefault(DEFAULT_EXPORT_PATH)
    If Len(exportPath) = 0 Then
        MsgBox "Export cancelled.", vbInformation
        Exit Sub
    End If
    
    ' Ensure folder exists
    CreateFolderIfMissing exportPath
    
    Dim q As Object ' Excel Query object (WorkbookQuery)
    Dim filePath As String
    Dim okCount As Long, errCount As Long
    
    On Error GoTo CleanFail
    
    For Each q In ThisWorkbook.Queries
        ' Build safe filename: <QueryName>.m
        filePath = exportPath & "\" & SafeFileName(CStr(q.Name)) & ".m"
        ' Write UTF-8 text
        If WriteUtf8Text(filePath, CStr(q.Formula)) Then
            okCount = okCount + 1
        Else
            errCount = errCount + 1
        End If
    Next q
    
    MsgBox "Power Query export finished." & vbCrLf & _
           "Saved: " & okCount & " .m files" & vbCrLf & _
           IIf(errCount > 0, "Errors: " & errCount, "Errors: 0") & vbCrLf & _
           "Folder: " & exportPath, vbInformation
    Exit Sub

CleanFail:
    MsgBox "Unexpected error: " & Err.Number & " - " & Err.Description, vbExclamation
End Sub

'--- choose export folder (defaults if user cancels) ---
Private Function PickFolderOrDefault(defaultPath As String) As String
    Dim fd As FileDialog
    On Error Resume Next
    Set fd = Application.FileDialog(msoFileDialogFolderPicker)
    On Error GoTo 0
    
    If Not fd Is Nothing Then
        With fd
            .Title = "Choose export folder for .m files (or Cancel to use default)"
            If Len(Dir(defaultPath, vbDirectory)) > 0 Then
                .InitialFileName = defaultPath
            End If
            If .Show = -1 Then
                PickFolderOrDefault = .SelectedItems(1)
                Exit Function
            End If
        End With
    End If
    
    ' fall back to default
    PickFolderOrDefault = defaultPath
End Function

'--- write text as UTF-8 without BOM using ADODB.Stream (late binding) ---
Private Function WriteUtf8Text(ByVal fullPath As String, ByVal textBody As String) As Boolean
    On Error GoTo fail
    Dim stm As Object ' ADODB.Stream
    Set stm = CreateObject("ADODB.Stream")
    With stm
        .Type = 2                ' adTypeText
        .Charset = "utf-8"
        .Open
        .WriteText textBody, 0   ' adWriteChar
        .Position = 0
        ' Save to file (overwrite)
        .SaveToFile fullPath, 2  ' adSaveCreateOverWrite
        .Close
    End With
    WriteUtf8Text = True
    Exit Function
fail:
    WriteUtf8Text = False
End Function

'--- create folder if needed ---
Private Sub CreateFolderIfMissing(ByVal path As String)
    If Len(Dir(path, vbDirectory)) = 0 Then
        MkDir path
    End If
End Sub

'--- sanitize filenames for Windows ---
Private Function SafeFileName(ByVal s As String) As String
    Dim badChars As Variant, r As Variant
    badChars = Array("\", "/", ":", "*", "?", """", "<", ">", "|")
    For Each r In badChars
        s = Replace$(s, CStr(r), "_")
    Next
    ' trim and collapse spaces
    s = Trim$(s)
    Do While InStr(s, "  ") > 0
        s = Replace$(s, "  ", " ")
    Loop
    SafeFileName = s
End Function


