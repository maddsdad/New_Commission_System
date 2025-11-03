let
    Source = Excel.Workbook(Parameter1, null, true),
    #"Agent Order Detail Report_Sheet" = Source{[Item="Agent Order Detail Report",Kind="Sheet"]}[Data],
    #"Promoted Headers" = Table.PromoteHeaders(#"Agent Order Detail Report_Sheet", [PromoteAllScalars=true])
in
    #"Promoted Headers"