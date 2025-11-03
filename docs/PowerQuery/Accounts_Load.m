let
    // 1) Pull the Accounts Excel table
    Source = Excel.CurrentWorkbook(){[Name="Accounts"]}[Content],

    // 2) Tidy headers
    Trimmed = Table.TransformColumnNames(Source, each Text.Trim(_)),

    // 3) Normalize common date headers if you use EffectiveStart/End
    RenamedDates = Table.RenameColumns(
        Trimmed,
        {
            {"EffectiveStart", "StartMonth"},
            {"EffectiveEnd",   "EndMonth"}
        },
        MissingField.Ignore
    ),

    // 4) Make sure the columns we care about exist (others will pass through if present)
    //    We’ll keep these as our reference shape:
    //    GAK, Customer, Payor, Carrier, AccountNo, MACNUM, PrimaryAgent, SalesChannel, Status, StartMonth, EndMonth, Notes, FileID
    ColsToKeep = {"GAK","Customer","Payor","Carrier","AccountNo","MACNUM","PrimaryAgent","SalesChannel","Status","StartMonth","EndMonth","Notes","FileID"},
    Aligned    = Table.SelectColumns(RenamedDates, ColsToKeep, MissingField.UseNull),

    // 5) Derive GAK if missing (prefer GAK, else MACNUM, else AccountNo)
    AddGAK = 
        if List.Contains(Table.ColumnNames(Aligned), "GAK") then
            Table.AddColumn(Aligned, "GAK_final", each 
                if [GAK] <> null and Text.Trim(Text.From([GAK])) <> "" then Text.From([GAK])
                else if Record.HasFields(_, "MACNUM") and [MACNUM] <> null then Text.From([MACNUM])
                else if Record.HasFields(_, "AccountNo") and [AccountNo] <> null then Text.From([AccountNo])
                else null, type text)
        else
            Table.AddColumn(Aligned, "GAK_final", each 
                if Record.HasFields(_, "MACNUM") and [MACNUM] <> null then Text.From([MACNUM])
                else if Record.HasFields(_, "AccountNo") and [AccountNo] <> null then Text.From([AccountNo])
                else null, type text),

    // 6) Clean up GAK (trim/upper for stable joins)
    CleanGAK = Table.TransformColumns(AddGAK, {{"GAK_final", each if _ = null then null else Text.Upper(Text.Trim(_)), type text}}),

    // 7) Add BatchId
    AddBatch = Table.AddColumn(CleanGAK, "BatchId", each Config_BatchId, type text),

    // 8) Type casting
    Typed = Table.TransformColumnTypes(
        AddBatch,
        {
            {"GAK_final",   type text},
            {"Customer",    type text},
            {"Payor",       type text},
            {"Carrier",     type text},
            {"AccountNo",   type text},
            {"MACNUM",      type text},
            {"PrimaryAgent",type text},
            {"SalesChannel",type text},
            {"Status",      type text},
            {"StartMonth",  type date},
            {"EndMonth",    type date},
            {"Notes",       type text},
            {"FileID",      type text},
            {"BatchId",     type text}
        },
        "en-US"
    ),

// 9) Treat blank EndMonth as infinity
EndFixed = Table.TransformColumns(
    Typed,
    {{"EndMonth", each if _ = null then #date(9999,12,31) else _, type date}}
),

// 10) Prefer GAK_final; remove old GAK if present, then rename
DropOldGAK =
    if List.Contains(Table.ColumnNames(EndFixed), "GAK")
    then Table.RemoveColumns(EndFixed, {"GAK"})
    else EndFixed,

Reordered = Table.ReorderColumns(
    DropOldGAK,
    {"GAK_final","Customer","Payor","Carrier","PrimaryAgent","SalesChannel","Status","StartMonth","EndMonth","AccountNo","MACNUM","Notes","FileID","BatchId"},
    MissingField.UseNull
),

Final = Table.RenameColumns(Reordered, {{"GAK_final","GAK"}}, MissingField.Ignore)
in
    Final