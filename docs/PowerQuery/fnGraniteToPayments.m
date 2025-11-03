// Function: Standardize Granite file -> Payments schema
// Usage from folder query: invoke fnGraniteToPayments([Content], [Name])
(FileBinary as binary, FileID as text) as table =>
let
    // --------------------------------------------------------------------
    // 0) Config values from the new master workbook
    //     - CommissionMonth: your processing month (first-of-month date)
    //     - BatchId: your run label (e.g., GRANITE_2025-10)
    // --------------------------------------------------------------------
    CommissionMonth = try Date.From(Excel.CurrentWorkbook(){[Name="Config_CommissionMonth"]}[Content]{0}[Column1]) otherwise null,
    BatchId         = try Excel.CurrentWorkbook(){[Name="Config_BatchId"]}[Content]{0}[Column1] otherwise null,

    // --------------------------------------------------------------------
    // 1) Read Granite workbook binary and navigate to the "Commission Detail"
    //     (tolerant: if the sheet name changes slightly, fall back to the first table-like item)
    // --------------------------------------------------------------------
    WB        = Excel.Workbook(FileBinary, null, true),
    TryDetail = try WB{[Item="Commission Detail", Kind="Sheet"]}[Data],
    Detail    = if TryDetail[HasError] then
                    let
                        // fallback: first sheet/table with tabular data
                        FirstTab = Table.FirstN(WB, 1){0}[Data]
                    in FirstTab
                else
                    TryDetail[Value],
    Promoted  = Table.PromoteHeaders(Detail, [PromoteAllScalars = true]),
    // normalize column names (trim)
    Trimmed   = Table.TransformColumnNames(Promoted, each Text.Trim(_)),

    // --------------------------------------------------------------------
    // 2) Identify key Granite columns (tolerant if some are missing)
    // --------------------------------------------------------------------
    Cols = Table.ColumnNames(Trimmed),

    // MACNUM as AccountNo (your chosen key)
    AccountNoCol = if List.Contains(Cols, "MACNUM") then "MACNUM"
                   else if List.Contains(Cols, "Customer ID") then "Customer ID"
                   else null,

    // Customer name
    CustomerCol  = if List.Contains(Cols, "Customer") then "Customer"
                   else if List.Contains(Cols, "Customer Name") then "Customer Name"
                   else null,

    // Granite report date -> PayorRptDate
    PayorRptDateCol = if List.Contains(Cols, "Report Date") then "Report Date"
                      else if List.Contains(Cols, "ReportDate") then "ReportDate"
                      else null,

    // Commission % (if present) - we’ll pass it through for QA (not in the final output schema)
    CommPctCol   = if List.Contains(Cols, "Commission %") then "Commission %"
                   else if List.Contains(Cols, "Commission%") then "Commission%"
                   else null,

    // A memo/notes-like field (optional)
    MemoCol      = if List.Contains(Cols, "Notes") then "Notes"
                   else if List.Contains(Cols, "Memo") then "Memo"
                   else null,

    // --------------------------------------------------------------------
    // 3) Unpivot service/product columns into Product + GrossAmt
    //    We’ll look for known product columns but only unpivot ones that exist.
    // --------------------------------------------------------------------
    KnownServiceColsAll = {
        "EPIK","NI","POTS","MANAGED SERVICES","MANAGED SERVICE","MS",
        "DIA","BB","SIP","PRI","WIRELESS","Hosted Voice","UCaaS","MPLS",
        "EoC","Cable","Fiber","Internet","Voice","Other","Combined-Non Comm"
    },
    KnownServiceCols  = List.Intersect({KnownServiceColsAll, Cols}),
    // If Granite’s layout has explicit total columns like "Total Comm Amt" we leave them alone.
    BaseForUnpivot = Trimmed,

    Unpivoted =
        if List.Count(KnownServiceCols) > 0 then
            Table.Unpivot(BaseForUnpivot, KnownServiceCols, "Product", "GrossAmt")
        else
            // If we can't find service columns, fall back to a minimal table
            Table.FromRecords({[
                Product = null,
                GrossAmt = null
            ]}),

    // Keep original context + unpivoted amounts together
    MergedBack =
        if List.Count(KnownServiceCols) > 0 then
            Table.Join(
                Table.SelectColumns(BaseForUnpivot, List.Difference(Cols, KnownServiceCols), MissingField.UseNull),
                {}, // dummy join columns, we’ll re-append columns directly via Table.SelectColumns + Table.CombineColumns if needed
                #table(type table [dummy=nullable text], {}),
                {}
            )
        else BaseForUnpivot,

    // Since we unpivoted, we just proceed with Unpivoted as the facts
    FactsRaw = Unpivoted,

    // --------------------------------------------------------------------
    // 4) Select/rename to our master schema fields (tolerant of nulls)
    //    CommissionMonth  : from config (processing month)
    //    PayorRptDate     : Granite's report date (if present)
    //    Payor/Carrier    : set to "GRANITE" (you can change to a field if Granite supplies it)
    //    Customer         : best-effort from CustomerCol
    //    AccountNo        : MACNUM (preferred) or fallback
    //    Product          : from Unpivoted[Product]
    //    LineType         : "RES" (per your instruction)
    //    GrossAmt         : from Unpivoted[GrossAmt]
    //    Memo             : Notes/Memo if available
    //    FileID/BatchId   : from params/config
    // --------------------------------------------------------------------
    WithCore =
        let
            // add core fields
            AddCommissionMonth = Table.AddColumn(FactsRaw, "CommissionMonth", each CommissionMonth, type date),
            AddPayorRptDate    = if PayorRptDateCol <> null and List.Contains(Table.ColumnNames(FactsRaw), PayorRptDateCol)
                                 then Table.AddColumn(AddCommissionMonth, "PayorRptDate", each try Date.From(Record.Field(_, PayorRptDateCol)) otherwise null, type date)
                                 else Table.AddColumn(AddCommissionMonth, "PayorRptDate", each null, type date),
            AddPayor           = Table.AddColumn(AddPayorRptDate, "Payor", each "GRANITE", type text),
            AddCarrier         = Table.AddColumn(AddPayor, "Carrier", each "GRANITE", type text),
            AddCustomer        = if CustomerCol <> null and List.Contains(Table.ColumnNames(AddCarrier), CustomerCol)
                                 then Table.AddColumn(AddCarrier, "Customer", each Record.Field(_, CustomerCol), type text)
                                 else Table.AddColumn(AddCarrier, "Customer", each null, type text),
            AddAccount         = if AccountNoCol <> null and List.Contains(Table.ColumnNames(AddCustomer), AccountNoCol)
                                 then Table.AddColumn(AddCustomer, "AccountNo", each Text.From(Record.Field(_, AccountNoCol)), type text)
                                 else Table.AddColumn(AddCustomer, "AccountNo", each null, type text),
            AddLineType        = Table.AddColumn(AddAccount, "LineType", each "RES", type text),
            AddFileId          = Table.AddColumn(AddLineType, "FileID", each FileID, type text),
            AddBatch           = Table.AddColumn(AddFileId, "BatchId", each BatchId, type text),
            AddMemo            = if MemoCol <> null and List.Contains(Table.ColumnNames(AddBatch), MemoCol)
                                 then Table.AddColumn(AddBatch, "Memo", each Record.Field(_, MemoCol), type text)
                                 else Table.AddColumn(AddBatch, "Memo", each null, type text)
        in
            AddMemo,

    // Rename/ensure Product & GrossAmt from unpivot
    Normalized1 = Table.RenameColumns(WithCore, {{"Attribute", "Product"}, {"Value", "GrossAmt"}}, MissingField.Ignore),

    // --------------------------------------------------------------------
    // 5) Final typing, cleaning, and column ordering
    // --------------------------------------------------------------------
    Casted =
        Table.TransformColumnTypes(
            Normalized1,
            {
                {"CommissionMonth", type date},
                {"PayorRptDate",    type date},
                {"Payor",           type text},
                {"Carrier",         type text},
                {"Customer",        type text},
                {"AccountNo",       type text},
                {"Product",         type text},
                {"LineType",        type text},
                {"GrossAmt",        type number},
                {"Memo",            type text},
                {"FileID",          type text},
                {"BatchId",         type text}
            },
            "en-US"
        ),

    // optional: filter null/zero rows (keep zeros if you want breadcrumbs)
    Cleaned = Table.SelectRows(Casted, each [Product] <> null and [GrossAmt] <> null),

    // Column order to match the master schema
    Final =
        Table.ReorderColumns(
            Cleaned,
            {"CommissionMonth","PayorRptDate","Payor","Carrier","Customer","AccountNo","Product","LineType","GrossAmt","Memo","FileID","BatchId"},
            MissingField.UseNull
        )
in
    Final