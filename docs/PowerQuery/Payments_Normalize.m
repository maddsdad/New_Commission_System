let
    Source = Folder.Files("C:\Users\mboye\OneDrive - Master Agent Commissions\Clients\PSI\Commissions\1 - RAW\GRANITE"),
    #"Filtered Hidden Files1" = Table.SelectRows(Source, each [Attributes]?[Hidden]? <> true),
    #"Invoked Custom Function" = Table.AddColumn(#"Filtered Hidden Files1", "Table", each fnGraniteToPayments([Content], "Name")),
    #"Expanded Table" = Table.ExpandTableColumn(#"Invoked Custom Function", "Table", {"CommissionMonth", "PayorRptDate", "Payor", "Carrier", "Customer", "AccountNo", "Product", "LineType", "GrossAmt", "Memo", "FileID", "BatchId"}, {"CommissionMonth", "PayorRptDate", "Payor", "Carrier", "Customer", "AccountNo", "Product", "LineType", "GrossAmt", "Memo", "FileID", "BatchId"}),
    #"Removed Columns" = Table.RemoveColumns(#"Expanded Table",{"Content", "Name", "Extension", "Date accessed", "Date modified", "Date created", "Attributes", "Folder Path"})
in
    #"Removed Columns"