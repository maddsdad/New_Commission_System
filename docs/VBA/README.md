# VBA Scripts – New Commission System

## Expected_Commissions_Time_Stamp_Module.bas

**Purpose**  
Automatically stamps the `EnteredBy` and `EnteredDate` fields on the **Expected_Commissions** worksheet when a new row is added or edited.  
This ensures each expected commission record keeps a permanent audit trail of who entered it and when.

**How It Works**  
- Trigger: Runs automatically whenever any cell in the **Expected_Commissions** table is changed.  
- If the row has data but no existing `EnteredDate`, it:
  - Inserts today’s date (`Date`) into `EnteredDate`.
  - Fills `EnteredBy` with the current Windows username (`Environ("Username")`).
- The stamp only occurs once — it never overwrites existing values.

**Installation**  
1. Open the Excel workbook (`PSI_Commission_System.xlsm`).  
2. Press **Alt + F11** to open the VBA Editor.  
3. In *Project Explorer*, double-click the sheet **Expected_Commissions** under “Microsoft Excel Objects”.  
4. Paste the contents of this `.bas` file (or import it via *File → Import File…*).  
5. Save the workbook as `.xlsm`.

**File Location in Repo**  
/docs/VBA/Expected_Commissions_Time_Stamp_Module.bas
---

## Export_All_Queries_For_GitHub.bas

**Purpose**  
Exports all Power Query (M) code from the Excel workbook into individual text files, enabling version control and easy review of query logic in GitHub.

**How It Works**  
- Iterates through every Power Query object (via the Workbook’s `Queries` collection).  
- Writes each query’s M code into a separate `.txt` file, using the query’s name as the filename.  
- Files are saved in the designated GitHub folder path (typically under `/queries/` or `/docs/queries/` in the repository).  
- Can be run manually whenever queries are updated, or incorporated into a periodic export process.

**Usage Instructions**  
1. Open the VBA Editor (**Alt + F11**).  
2. Confirm the macro is stored in a **standard module** (e.g., `mod_QueryExport`).  
3. Adjust the export folder path in the script as needed.  
4. Run the macro `Export_All_Queries_For_GitHub` from the VBA editor or from the Macros dialog (**Alt + F8**).  
5. Commit the exported `.txt` files to GitHub.

**File Location in Repo**  
/docs/VBA/Export_All_Queries_For_GitHub.bas


**Version History**  
| Date | Author | Notes |
|------|---------|-------|
| 2025-11-03 | ChatGPT & M. Boye | Initial version added to export all Power Query M scripts for version control. |
Push