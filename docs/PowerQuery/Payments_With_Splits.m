let
  // 1) Sources
  Payments = Payments_With_Accounts,
  Splits   = Splits_Load,

  // 2) Add a stable row id to payments
  PaymentsWithID = Table.AddIndexColumn(Payments, "PayRowID", 1, 1, Int64.Type),

  // 3) Join splits on GAK
  Merged = Table.NestedJoin(
      PaymentsWithID, {"GAK"},
      Splits,         {"GAK"},
      "SplitRows",
      JoinKind.LeftOuter
  ),

  // 4) Expand candidate split rows
  Expanded = Table.ExpandTableColumn(
      Merged,
      "SplitRows",
      {"Agent","AgentRateRES","AgentRateSPF","StartMonth","EndMonth"},
      {"Split_Agent","Split_AgentRateRES","Split_AgentRateSPF","Split_StartMonth","Split_EndMonth"}
  ),

  // 5) Keep only ACTIVE splits for the payment's CommissionMonth
  //    Guard all date conversions to avoid errors when null.
  WithIsActive = Table.AddColumn(
      Expanded,
      "IsActive",
      each
        let
          cm = try Date.From([CommissionMonth]) otherwise null,
          s  = [Split_StartMonth],
          e  = [Split_EndMonth]
        in
          cm <> null and s <> null and e <> null and cm >= s and cm <= e,
      type logical
  ),
  ActiveOnly = Table.SelectRows(WithIsActive, each [IsActive] = true),

  // 6) Choose AgentRate by LineType (RES vs SPF)
  WithAgentRate = Table.AddColumn(
      ActiveOnly,
      "AgentRate",
      each if [LineType] = "SPF" then [Split_AgentRateSPF] else [Split_AgentRateRES],
      type number
  ),

  // 7) Keep only real allocation rows (must have agent and rate)
  AllocOnly = Table.SelectRows(WithAgentRate, each [Split_Agent] <> null and [AgentRate] <> null),

  // 8) Project final columns
  Projected = Table.SelectColumns(
      AllocOnly,
      {
        "CommissionMonth","PayorRptDate","Payor","Carrier","Customer","AccountNo","GAK",
        "Product","LineType","GrossAmt","Memo","FileID","BatchId",
        "Split_Agent","AgentRate","PayRowID"
      }
  ),

  // 9) Rename Split_Agent -> Agent
  Final = Table.RenameColumns(Projected, {{"Split_Agent","Agent"}})
in
  Final