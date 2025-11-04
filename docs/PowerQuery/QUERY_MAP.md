# Power Query – Query Map (v5 baseline)

| Group | Query | File |
|---|---|---|
| 00_Config | Config_BatchId | 00_Config.Config_BatchId.m |
| 00_Config | Config_CommissionMonth | 00_Config.Config_CommissionMonth.m |
| 10_Load | Payments_Normalize | 10_Load.Payments_Normalize.m |
| 10_Load | Adjustments_Load | 10_Load.Adjustments_Load.m |
| 10_Load | Splits_Load | 10_Load.Splits_Load.m |
| 10_Load | Accounts_Load | 10_Load.Accounts_Load.m |
| 10_Load | Expected_Commissions_Load | 10_Load.Expected_Commissions_Load.m |
| 20_Model | Payments_With_Accounts | 20_Model.Payments_With_Accounts.m |
| 20_Model | Payments_With_Splits | 20_Model.Payments_With_Splits.m |
| 20_Model | Adj_As_Lines | 20_Model.Adj_As_Lines.m |
| 20_Model | Fact_AllLines | 20_Model.Fact_AllLines.m |
| 30_Output | Statements_Build | 30_Output.Statements_Build.m |
| 11_Expected vs Actual | Expected_ExpandMonthly | 11_Expected vs Actual.Expected_ExpandMonthly.m |
| 90_QA | QA_RowCounts | 90_QA.QA_RowCounts.m |
| 90_QA | QA_Checks | 90_QA.QA_Checks.m |
| Carrier Functions | fnGraniteToPayments | Carrier Functions.fnGraniteToPayments.m |
