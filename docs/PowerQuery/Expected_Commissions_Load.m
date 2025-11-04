let
    // Read the Excel Table named Expected_Commissions
    Source = Excel.CurrentWorkbook(){[Name="Expected_Commissions"]}[Content],

    // Set explicit data types
    Typed = Table.TransformColumnTypes(
        Source,
        {
            {"Payor", type text},
            {"Carrier", type text},
            {"Customer", type text},
            {"AccountNo", type text},
            {"Product", type text},
            {"StartDate", type date},
            {"EndDate", type date},
            {"ExpectedMRR", Currency.Type},       // currency
            {"ExpectedRate", Percentage.Type},    // 0–1 percentage
            {"ExpectedPayType", type text},
            {"Agent", type text},
            {"Notes", type text},
            {"EnteredBy", type text},
            {"EnteredDate", type date}
        },
        "en-US"
    ),

    // Trim key text fields
    Trimmed = Table.TransformColumns(
        Typed,
        {
            {"Payor", Text.Trim, type text},
            {"Carrier", Text.Trim, type text},
            {"Customer", Text.Trim, type text},
            {"AccountNo", Text.Trim, type text},
            {"Product", Text.Trim, type text},
            {"ExpectedPayType", Text.Trim, type text},
            {"Agent", Text.Trim, type text}
        }
    ),

    // Helpers
    U = (t as nullable text) as text => if t = null then "" else Text.Upper(Text.Trim(t)),
    D = (d as nullable date) as text => if d = null then "" else Date.ToText(d, "yyyy-MM-dd"),
    N2 = (n as nullable number) as text => if n = null then "" else Number.ToText(n, "F2", "en-US"),
    N6 = (n as nullable number) as text => if n = null then "" else Number.ToText(n, "F6", "en-US"),

    // GAK (Carrier-AccountNo)
    AddGAK = Table.AddColumn(
        Trimmed, "GAK",
        each if [Carrier] = null or [AccountNo] = null or Text.Trim([Carrier]) = "" or Text.Trim([AccountNo]) = ""
             then null else [Carrier] & "-" & [AccountNo],
        type text
    ),

    // RowKey_Expected (business fields only)
    AddRowKey = Table.AddColumn(
        AddGAK, "RowKey_Expected",
        each U([Payor]) & "|" & U([Carrier]) & "|" & U([Customer]) & "|" & U([AccountNo]) & "|" &
             U([Product]) & "|" & D([StartDate]) & "|" & D([EndDate]) & "|" &
             N2([ExpectedMRR]) & "|" & N6([ExpectedRate]) & "|" & U([ExpectedPayType]) & "|" & U([Agent]),
        type text
    ),

    // Today (for IsActive)
    Today = Date.From(DateTime.LocalNow()),

    // QA flags
    AddQA1 = Table.AddColumn(AddRowKey, "QA_MissingStartDate", each [StartDate] = null, type logical),
    AddQA2 = Table.AddColumn(AddQA1, "QA_EndBeforeStart", each [EndDate] <> null and [StartDate] <> null and [EndDate] < [StartDate], type logical),
    AddQA3 = Table.AddColumn(AddQA2, "QA_InvalidRate", each [ExpectedRate] = null or [ExpectedRate] < 0 or [ExpectedRate] > 1, type logical),
    AddQA4 = Table.AddColumn(AddQA3, "QA_MissingKeyFields", each
        ( [Payor] = null or Text.Trim([Payor]) = "" ) or
        ( [Carrier] = null or Text.Trim([Carrier]) = "" ) or
        ( [AccountNo] = null or Text.Trim([AccountNo]) = "" ), type logical),
    AddQA5 = Table.AddColumn(AddQA4, "QA_InvalidMRR", each [ExpectedMRR] = null or [ExpectedMRR] <= 0, type logical),
    AddQA6 = Table.AddColumn(AddQA5, "IsActive", each [EndDate] = null or [EndDate] >= Today, type logical)
in
    AddQA6