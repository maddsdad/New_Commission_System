let
  Src = Adjustments_Load,

  // CommissionMonth comes from your Config cell
  AddCM = Table.AddColumn(Src, "CommissionMonth", each try Date.From(Config_CommissionMonth) otherwise null, type date),

  // PayorRptDate is usually not in manual adj; leave null
  AddPRD = Table.AddColumn(AddCM, "PayorRptDate", each null, type date),

  // Normalize GAK from AccountNo (upper/trim)
  AddGAK = Table.AddColumn(AddPRD, "GAK",
            each let a=[AccountNo] in if a=null then null else Text.Upper(Text.Trim(Text.From(a))), type text),

  // Standard fields: ADJ lines carry AdjAmount as GrossAmt
  AddLT  = Table.AddColumn(AddGAK, "LineType", each "ADJ", type text),
  AddGA  = Table.AddColumn(AddLT, "GrossAmt", each [AdjAmount], type number),

  // Ensure required columns exist
  KeepCols = Table.SelectColumns(
              AddGA,
              {"CommissionMonth","PayorRptDate","Payor","Carrier","Customer","AccountNo","GAK",
               "Product","LineType","GrossAmt","Memo","FileID","BatchId"},
              MissingField.UseNull
            )
in
  KeepCols