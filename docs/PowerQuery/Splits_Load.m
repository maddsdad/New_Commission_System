let
    Source = Excel.CurrentWorkbook(){[Name="Agent_Splits"]}[Content],

    // Tidy headers
    Trimmed = Table.TransformColumnNames(Source, each Text.Trim(_)),

    // Standardize column names we use downstream
    Renamed =
        Table.RenameColumns(
            Trimmed,
            {
                {"EffectiveStart", "StartMonth"},
                {"EffectiveEnd",   "EndMonth"}
            },
            MissingField.Ignore
        ),

    // Ensure required columns exist (create nulls if missing so PQ doesn't break)
    WithRequired =
        Table.TransformColumnTypes(
            Table.DemoteHeaders(
                Table.FromRows(
                    {},
                    type table[
                        GAK=nullable text,
                        Customer=nullable text,
                        Payor=nullable text,
                        Carrier=nullable text,
                        Agent=nullable text,
                        AgentRateRES=nullable number,
                        AgentRateSPF=nullable number,
                        IsHouse=nullable logical,
                        StartMonth=nullable date,
                        EndMonth=nullable date,
                        IsPrimary=nullable logical,
                        Notes=nullable text,
                        FileID=nullable text
                    ]
                )
            ),
            {}
        ),
    Aligned = Table.SelectColumns(
        Table.Combine({WithRequired, Renamed}),
        {"GAK","Customer","Payor","Carrier","Agent","AgentRateRES","AgentRateSPF","IsHouse","StartMonth","EndMonth","IsPrimary","Notes","FileID"},
        MissingField.UseNull
    ),

    // Add BatchId
    AddBatch = Table.AddColumn(Aligned, "BatchId", each Config_BatchId, type text),

    // Type columns
    Typed =
        Table.TransformColumnTypes(
            AddBatch,
            {
                {"GAK", type text},
                {"Customer", type text},
                {"Payor", type text},
                {"Carrier", type text},
                {"Agent", type text},
                {"AgentRateRES", type number},
                {"AgentRateSPF", type number},
                {"IsHouse", type logical},
                {"StartMonth", type date},
                {"EndMonth", type date},
                {"IsPrimary", type logical},
                {"Notes", type text},
                {"FileID", type text},
                {"BatchId", type text}
            },
            "en-US"
        ),

    // Accept either 70 (percent entered as whole number) or 0.7
    NormalizeRates =
        Table.TransformColumns(
            Typed,
            {
                {"AgentRateRES", each if _ = null then null else if _ > 1 then _/100 else _, type number},
                {"AgentRateSPF", each if _ = null then null else if _ > 1 then _/100 else _, type number}
            }
        ),

// Treat blank EndMonth as infinity (9999-12-31) in place
FillEnd = Table.TransformColumns(
    NormalizeRates,
    {{"EndMonth", each if _ = null then #date(9999,12,31) else _, type date}}
)
in
    FillEnd