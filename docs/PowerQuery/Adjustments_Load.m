let
    Source = Excel.CurrentWorkbook(){[Name="Manual_Adjustments"]}[Content],
    #"Added BatchId" = Table.AddColumn(Source, "BatchId", each Config_BatchId, type text),
    #"Changed Type" = Table.TransformColumnTypes(
        #"Added BatchId",
        {
            {"Month", type date},
            {"Payor", type text},
            {"Carrier", type text},
            {"Customer", type text},
            {"AccountNo", type text},
            {"Product", type text},
            {"AdjAmount", type number},
            {"Notes", type text},
            {"BatchId", type text}
        }
    )
in
    #"Changed Type"