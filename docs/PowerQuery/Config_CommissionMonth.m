let
  Source = Excel.CurrentWorkbook(),
  Pick   = Table.SelectRows(Source, each [Name] = "Config_CommissionMonth"),
  Value  = Pick{0}[Content]{0}[Column1]
in
  Value