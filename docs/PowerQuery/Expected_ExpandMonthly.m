let
  // ---- Inputs --------------------------------------------------------------
  // Assumes you already have these queries:
  //   - Expected_Commissions  (the manual-entry table)
  //   - Config_CommissionMonth (single value = target month control)
  Source0 = Expected_Commissions_Load,

  // If EndDate isn't in Expected_Commissions, add a nullable EndDate column.
  Source =
    if Table.HasColumns(Source0, {"EndDate"})
    then Source0
    else Table.AddColumn(Source0, "EndDate", each null, type nullable date),

  // Pull the control month; ensure it's the first day of the month.
  ControlMonthRaw =
    try Date.From(#"Config_CommissionMonth"{0}[CommissionMonth])
    otherwise Date.From(#"Config_CommissionMonth"{0}[Value]),
  ControlMonth = Date.StartOfMonth(ControlMonthRaw),

  // ---- Type enforcement (safe: only applies to columns that exist) --------
  DesiredTypes = {
      {"Payor",             type text},
      {"Carrier",           type text},
      {"Customer",          type text},
      {"AccountNo",         type text},
      {"Product",           type text},
      {"StartDate",         type date},
      {"EndDate",           type nullable date},
      {"ExpectedRate",      type number},    // percent (e.g., 0.08 for 8%)
      {"ExpectedMRR",       type number},    // currency-compatible number
      {"ExpectedPayType",   type text},
      {"Notes",             type text},
      {"EnteredBy",         type text},
      {"EnteredDate",       type date}
  },
  ExistingCols      = Table.ColumnNames(Source),
  TypesToApply      = List.Select(DesiredTypes, (t) => List.Contains(ExistingCols, t{0})),
  Typed             = Table.TransformColumnTypes(Source, TypesToApply, "en-US"),

  // ---- Normalize dates and compute EffectiveEnd per row --------------------
  Add_EffectiveEnd = Table.AddColumn(
      Typed,
      "EffectiveEnd",
      (r) =>
        let
          s0 = try Date.From(r[StartDate]) otherwise null,
          e0 = try Date.From(r[EndDate])   otherwise null,
          s  = if s0 = null then null else Date.StartOfMonth(s0),
          // If EndDate is null, cap at ControlMonth.
          // If EndDate is after ControlMonth, also cap at ControlMonth.
          eA = if e0 = null then ControlMonth else Date.StartOfMonth(e0),
          e  = if s = null then null else if eA > ControlMonth then ControlMonth else eA
        in
          e,
      type nullable date
  ),

  // ---- Build a month list per row (Start..EffectiveEnd, monthly) -----------
  Add_MonthList = Table.AddColumn(
      Add_EffectiveEnd,
      "MonthList",
      (r) =>
        let
          s = try Date.StartOfMonth(Date.From(r[StartDate])) otherwise null,
          e = try Date.StartOfMonth(Date.From(r[EffectiveEnd])) otherwise null
        in
          if s = null or e = null or s > e
          then {} // no months to expand
          else List.Generate(() => s, (d) => d <= e, (d) => Date.AddMonths(d, 1)),
      type list
  ),

  // ---- Expand to one row per CommissionMonth -------------------------------
  Expand_Months     = Table.ExpandListColumn(Add_MonthList, "MonthList"),
  Rename_Months     = Table.RenameColumns(Expand_Months, {{"MonthList", "CommissionMonth"}}),

  // ---- Compute ExpectedComm (ExpectedMRR × ExpectedRate) -------------------
  Add_ExpectedComm  = Table.AddColumn(
      Rename_Months,
      "ExpectedComm",
      each
        let
          mrr  = try Number.From([ExpectedMRR]) otherwise null,
          rate = try Number.From([ExpectedRate]) otherwise null
        in if mrr = null or rate = null then null else mrr * rate,
      type number
  ),

  // ---- Final column order (only keeps what exists) -------------------------
  PreferredOrder = {
      "Payor","Carrier","Customer","AccountNo","Product",
      "StartDate","EndDate","CommissionMonth",
      "ExpectedMRR","ExpectedRate","ExpectedPayType","ExpectedComm",
      "Notes","EnteredBy","EnteredDate"
  },
  KeepCols = List.Intersect({PreferredOrder, Table.ColumnNames(Add_ExpectedComm)}),
  Reordered = Table.ReorderColumns(Add_ExpectedComm, KeepCols, MissingField.Ignore),

  // ---- Final type polish ----------------------------------------------------
  FinalTypes = {
      {"CommissionMonth", type date},
      {"ExpectedComm",    type number}
  },
  Final = Table.TransformColumnTypes(Reordered, FinalTypes, "en-US")
in
  Final