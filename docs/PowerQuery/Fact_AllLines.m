let
  // Sources
  PayAgent = Payments_With_Splits,   // already per-agent rows
  AdjBase  = Adj_As_Lines,
  Splits   = Splits_Load,

  // --- Agentize ADJ by residual split (v1 simple rule) ---
  // Add a temporary RowID to adjustments to keep grouping intact
  AdjWithID = Table.AddIndexColumn(AdjBase, "AdjRowID", 1, 1, Int64.Type),

  // Join splits by GAK
  Adj_Merged = Table.NestedJoin(
                 AdjWithID, {"GAK"},
                 Splits,    {"GAK"},
                 "SplitRows",
                 JoinKind.LeftOuter
               ),

  // Expand candidate splits
  Adj_Exp = Table.ExpandTableColumn(
              Adj_Merged, "SplitRows",
              {"Agent","AgentRateRES","StartMonth","EndMonth"},
              {"Split_Agent","Split_AgentRateRES","Split_StartMonth","Split_EndMonth"}
            ),

  // Keep only active splits for the run month
  Adj_Active = Table.SelectRows(
                 Adj_Exp,
                 each
                   let cm = try Date.From([CommissionMonth]) otherwise null,
                       s  = [Split_StartMonth],
                       e  = [Split_EndMonth]
                   in cm <> null and s <> null and e <> null and cm >= s and cm <= e
               ),

  // Use residual split for ADJ allocation
  Adj_WithRate = Table.AddColumn(Adj_Active, "AgentRate", each [Split_AgentRateRES], type number),

  // Keep only real allocation rows
  Adj_Alloc = Table.SelectRows(Adj_WithRate, each [Split_Agent] <> null and [AgentRate] <> null),

  // Project to the same “agentized” shape as payments
  Adj_Agentized = Table.RenameColumns(
                    Table.SelectColumns(
                      Adj_Alloc,
                      {
                        "CommissionMonth","PayorRptDate","Payor","Carrier","Customer","AccountNo","GAK",
                        "Product","LineType","GrossAmt","Memo","FileID","BatchId",
                        "Split_Agent","AgentRate"
                      }
                    ),
                    {{"Split_Agent","Agent"}}
                  ),

  // --- Combine payments + adjustments ---
  Combined = Table.Combine({PayAgent, Adj_Agentized}),

  // Final typing (light)
  Final = Table.TransformColumnTypes(
            Combined,
            {
              {"CommissionMonth", type date},
              {"PayorRptDate",    type date},
              {"GrossAmt",        type number},
              {"AgentRate",       type number}
            },
            "en-US"
          )
in
  Final