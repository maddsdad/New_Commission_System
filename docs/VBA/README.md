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
