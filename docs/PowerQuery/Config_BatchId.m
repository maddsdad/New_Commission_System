let
  // Read the named range “Config_BatchId” from the workbook
  Source = Excel.CurrentWorkbook(),
  Pick   = Table.SelectRows(Source, each [Name] = "Config_BatchId"),
  // Grab the text value from the cell (first row, column "Content", first record)
  Value  = Pick{0}[Content]{0}[Column1]
in
  Value