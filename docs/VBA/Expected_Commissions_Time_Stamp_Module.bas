VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Sheet3"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
' Automatically stamps EnteredDate and EnteredBy once when a new row is edited
Private Sub Worksheet_Change(ByVal Target As Range)
    On Error GoTo CleanExit
    Dim tbl As ListObject, hit As Range
    Set tbl = Me.ListObjects("Expected_Commissions")
    Set hit = Intersect(Target, tbl.DataBodyRange)
    If hit Is Nothing Then Exit Sub

    Application.EnableEvents = False
    Dim colED As Long: colED = tbl.ListColumns("EnteredDate").Index
    Dim colEB As Long: colEB = tbl.ListColumns("EnteredBy").Index

    Dim r As Range
    For Each r In hit.Rows
        With r.EntireRow
            If .Cells(1, colED).Value = "" And Application.WorksheetFunction.CountA(.Cells) > 0 Then
                .Cells(1, colED).Value = Date
                If .Cells(1, colEB).Value = "" Then .Cells(1, colEB).Value = Environ("Username")
            End If
        End With
    Next r
CleanExit:
    Application.EnableEvents = True
End Sub

