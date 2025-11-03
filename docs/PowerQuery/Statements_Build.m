let
  // Base fact (agentized payments + ADJ)
  Src = Fact_AllLines,

  // Normalize key fields
  Base = Table.TransformColumnTypes(
    Src,
    {
      {"CommissionMonth", type date},
      {"PayorRptDate", type date},
      {"Payor", type text},
      {"Carrier", type text},
      {"Agent", type text},
      {"Customer", type text},
      {"AccountNo", type text},
      {"GAK", type text},
      {"Product", type text},
      {"LineType", type text},
      {"GrossAmt", type number},
      {"AgentRate", type number},
      {"Memo", type text},
      {"FileID", type text},
      {"BatchId", type text}
    },
    "en-US"
  ),

  // Split RES vs SPF into statement columns
  AddGrossComm     = Table.AddColumn(Base, "GrossComm", each if [LineType] = "RES" then [GrossAmt] else null, type number),
  AddAgentComm     = Table.AddColumn(AddGrossComm, "AgentComm", each if [LineType] = "RES" and [AgentRate] <> null and [GrossAmt] <> null then Number.Round([GrossAmt] * [AgentRate], 2) else null, type number),

  AddGrossSPIFF    = Table.AddColumn(AddAgentComm, "GrossSPIFF", each if [LineType] = "SPF" then [GrossAmt] else null, type number),
  AddAgentSPFRate  = Table.AddColumn(AddGrossSPIFF, "AgentSPIFFRate", each if [LineType] = "SPF" then [AgentRate] else null, type number),
  AddAgentSPIFF    = Table.AddColumn(AddAgentSPFRate, "AgentSPIFF", each if [LineType] = "SPF" and [AgentRate] <> null and [GrossAmt] <> null then Number.Round([GrossAmt] * [AgentRate], 2) else null, type number),

  // Placeholder columns (to be wired later if/when you want them automated)
  AddServiceID     = Table.AddColumn(AddAgentSPIFF, "ServiceID", each null, type text),
  AddBasisMRR      = Table.AddColumn(AddServiceID, "BasisMRR", each null, type number),
  AddGrossRate     = Table.AddColumn(AddBasisMRR, "GrossRate", each null, type number),
  AddCarrierAdj    = Table.AddColumn(AddGrossRate, "CarrierAdjust", each null, type number),
  AddPSIAdj        = Table.AddColumn(AddCarrierAdj, "PSIAdjust", each null, type number),
  AddPaidGross     = Table.AddColumn(AddPSIAdj, "PaidGross", each null, type number),
  AddPaidNet       = Table.AddColumn(AddPaidGross, "PaidNet", each null, type number),

  // Month (your “Month” column) + display formatting lives in Excel; we keep real date here
  RenameMonth      = Table.RenameColumns(AddPaidNet, {{"CommissionMonth","Month"}}),

  // PayType & Notes mapping
  AddPayType       = Table.RenameColumns(RenameMonth, {{"LineType","PayType"}}),
  AddNotes         = Table.RenameColumns(AddPayType, {{"Memo","Notes"}}),

  // AgentNetPay (current v1 = AgentComm + AgentSPIFF; adjust later if Carrier/PSI adjusts should feed in)
  AddAgentNetPay   = Table.AddColumn(AddNotes, "AgentNetPay",
                        each Number.Round(
                          (try [AgentComm] otherwise 0) + (try [AgentSPIFF] otherwise 0),
                          2
                        ),
                        type number
                      ),

  // Final projection in your exact order
  Project = Table.SelectColumns(
    AddAgentNetPay,
    {
      "GAK",
      "Month",
      "Agent",
      "Payor",
      "Carrier",
      "Customer",
      "AccountNo",
      "ServiceID",
      "PayType",
      "Product",
      "BasisMRR",
      "GrossRate",
      "GrossComm",
      "AgentRate",
      "AgentComm",
      "GrossSPIFF",
      "AgentSPIFFRate",
      "AgentSPIFF",
      "CarrierAdjust",
      "PSIAdjust",
      "AgentNetPay",
      "Notes",
      "PaidGross",
      "PaidNet",
      "BatchId",
      "FileID"
    },
    MissingField.UseNull
  ),

  // RowHash for reconciliation (stable, upper/trim on key text fields)
  AddHash = Table.AddColumn(
    Project,
    "RowHash",
    each Text.Upper(
           Text.Combine(
             {
               Date.ToText([Month], "yyyy-MM"),
               nullToBlank([Agent]),
               nullToBlank([Customer]),
               nullToBlank([PayType]),
               nullToBlank([Product]),
               Number.ToText(try [BasisMRR] otherwise null, "G"),
               Number.ToText(try [GrossRate] otherwise null, "G"),
               Number.ToText(try [GrossComm] otherwise null, "G"),
               Number.ToText(try [AgentRate] otherwise null, "G"),
               Number.ToText(try [AgentComm] otherwise null, "G"),
               Number.ToText(try [GrossSPIFF] otherwise null, "G"),
               Number.ToText(try [AgentSPIFFRate] otherwise null, "G"),
               Number.ToText(try [AgentSPIFF] otherwise null, "G"),
               nullToBlank([FileID])
             },
             "|"
           )
         ),
    type text
  ),

  // Type casting for currency-like fields
  Typed = Table.TransformColumnTypes(
    AddHash,
    {
      {"BasisMRR", Currency.Type},
      {"GrossRate", type number},
      {"GrossComm", Currency.Type},
      {"AgentRate", type number},
      {"AgentComm", Currency.Type},
      {"GrossSPIFF", Currency.Type},
      {"AgentSPIFFRate", type number},
      {"AgentSPIFF", Currency.Type},
      {"CarrierAdjust", Currency.Type},
      {"PSIAdjust", Currency.Type},
      {"AgentNetPay", Currency.Type},
      {"PaidGross", Currency.Type},
      {"PaidNet", Currency.Type}
    },
    "en-US"
  )
in
  Typed

// helper function within the same query (Power Query lets you define it after 'in' only if separate query; 
// so please add this tiny function as a separate query if needed):