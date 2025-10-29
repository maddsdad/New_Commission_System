# PSI Commission System - Project Overview (v3)

## 0\. Table of Contents

- 1\. Purpose and Overview Summary
- 2\. Scope of Work
- 3\. Technical Overview and Current Status
- 4\. Testing and Validation Plan
- 5\. Future Carrier Integration (Vigilant and OBFM)
- 6\. Design Principles and Next Steps
- 7\. Order Tracking / Expected Commissions Tab
- 8\. Project History and Revision Log
- 9\. Project Governance and Version Control
- 10\. QA Dashboard (Data Integrity) (Step 10)
- Appendix A: Field Reference Table

## 1\. Purpose and Overview Summary

The PSI Commission System (New Commission System Project) is designed to create an end-to-end, automated, and scalable commission management platform for master agencies. Its purpose is to dramatically improve accuracy and efficiency in processing expected vs. actual commissions while enabling faster detection of missed commissions and improving agent reporting transparency. By leveraging Microsoft Excel, Power Query, VBA, and simple automation tools, the system aims to deliver enterprise-level precision using accessible, low-cost technology.

## 2\. Scope of Work

The scope of this project includes the full design, development, and testing of an automated commission processing system for PSI Network that will later be productized for use by other master agents. The solution integrates carrier payment data, agent splits, manual adjustments, and account data into one unified data model that produces clean, accurate agent statements.

In-scope components include: Power Query-based ETL (Extract, Transform, Load) processes, structured Excel-based data tables, VBA automation for exports and validations, and process documentation for low-cost virtual assistants (VAs).

Out of scope for this phase are: custom web portals, external API integrations, database back-end development, or migration to Power BI or cloud-based systems. These may be considered in future productization phases.

## 3\. Technical Overview and Current Status

### 3.1 System Architecture

The architecture is modular and organized into Power Query groups:  
\- 00_Config: Control cells for BatchId and CommissionMonth.  
\- 10_Load: Data import (Payments, Adjustments, Splits, Accounts).  
\- 20_Model: Core logic joins (Payments ↔ Accounts ↔ Splits) and calculated fact tables.  
\- 30_Output: Agent_Statements generation (final output to Excel sheet).  
\- 90_QA: Planned for automated validation and dashboard reporting.

### 3.2 Completed Components

✅ Config_BatchId and Config_CommissionMonth - global run controls.  
✅ fnGraniteToPayments - normalizes Granite's raw reports.  
✅ Payments_Normalize - folder import pipeline for Granite data.  
✅ Adjustments_Load - integrates Manual_Adjustments tab.  
✅ Splits_Load - loads and normalizes agent split data.  
✅ Accounts_Load - imports account references and derives Global Account Key (GAK).  
✅ Payments_With_Accounts - joins payments and accounts with QA flags.  
✅ Payments_With_Splits - applies effective-date agent splits.  
✅ Adj_As_Lines and Fact_AllLines - combine payments and manual adjustments.  
✅ Statements_Build - generates automated Agent_Statements table.

## 4\. Testing and Validation Plan

Testing will be performed after Step 10 (QA dashboard) to validate system accuracy and data integrity. The plan includes the following phases:

1\. Granite Commission Validation - Compare system-generated results to PSI's legacy manual calculations.  
2\. Vigilant Integration Validation - Normalize existing M code, import, and validate outputs.  
3\. OBFM Integration Validation - Normalize existing M code, import, and validate outputs.  
4\. Cross-Carrier Regression Test - Ensure all carriers produce accurate combined agent statements.  
5\. Export and VA Workflow Testing - Verify VBA export macros and VA instructions function correctly.

## 5\. Future Carrier Integration (Vigilant and OBFM)

Future development will involve integrating the Vigilant and OBFM carriers using new Power Query functions fnVigilantToPayments and fnOBFMToPayments. These will follow the same schema as Granite, ensuring consistency across all carriers. Once normalized, these carriers will feed the same shared data model, enabling a unified agent statement output.

## 6\. Design Principles and Next Steps

The project adheres to three key design principles:  
1\. Simplicity - Use familiar, low-cost Microsoft tools (Excel, Power Query, VBA).  
2\. Transparency - Maintain traceability from raw carrier files to final agent statements.  
3\. Scalability - Build once, reuse across carriers.

Next steps include completing the QA dashboard, validating results with real Granite data, and extending carrier integration to Vigilant and OBFM. Once validated, documentation and process guides for VAs will follow.

## 7\. Order Tracking / Expected_Commissions

### Purpose
This module captures the “should be getting” data—expected orders and commissions—so PSI can reconcile **Expected vs. Actual** at a detailed level.  
It allows early detection of missed, delayed, or short-paid commissions.

### Maintainers
Virtual Assistants (VAs) and internal Operations staff maintain this sheet by entering or updating order information as new deals are sold or existing services change.

### Location
Excel worksheet: **Expected_Commissions**  
Named Excel table: **tblExpected_Commissions**

### Core Fields
| Field | Description |
|--------|-------------|
| Carrier | Network or payor providing the service |
| Customer | End customer name |
| AccountNo | Carrier or internal billing account |
| Product | Product or service sold |
| StartDate | Date billing begins |
| ExpectedMRR | Monthly recurring revenue expected |
| ExpectedRate | Commission rate (as a decimal, e.g., 0.18) |
| ExpectedPayType | Type (RES, SPF, BON, etc.) |
| Notes | Free-form comments or context |
| EnteredBy | Person entering the record |
| EnteredDate | Entry date |

### Data Flow
1. VAs enter or update rows in **Expected_Commissions**.  
2. Power Query loads `tblExpected_Commissions` into the model.  
3. The model compares Expected lines to Actual Payments (by GAK/AccountNo, Product/ServiceID, and Month).  
4. Differences are flagged as *Not Found*, *Amount Variance*, *Rate Variance*, or *Timing Variance*.

### Outputs
- **Expected vs Actual Exceptions** – highlights missing or mismatched items.  
- **Aging Report** – shows how long an order has existed with no matching payment.

### Governance
Any change to fields or logic must be documented here and reflected in the VA instruction guide.


## 8\. Project History and Revision Log

| Version | Date / Author | Notes / Description |
| --- | --- | --- |
| v1  | 2025-10-25 / ChatGPT & User | Initial system architecture and Phase 1 field standardization completed. |
| v2  | 2025-10-27 / ChatGPT & User | Granite carrier data integrated; automated Agent_Statements built. |
| v3  | 2025-10-28 / ChatGPT & User | Added Order Tracking, Field Reference Table, testing plan, and governance structure. |
| v4 | 2025-10-29 / ChatGPT & User | Added Expected_Commissions (Step 10) and QA Dashboard (Step 11); updated TOC. |

## 9. Project Governance and Version Control

### Purpose
To ensure all PSI Commission System files, logic, and documentation remain versioned, auditable, and recoverable.

### Practices
- All Power Query M scripts, VBA modules, and Excel templates are stored in this GitHub repository.  
- Each change should include a clear commit message describing what changed and why.  
- Major milestones are saved as versioned files (for example, `_v3`, `_v4`) or tagged commits.  
- Prior versions can be retained in an `/Archive/` folder for historical reference.  
- Significant edits to logic or fields must also be reflected in this Project Overview and in VA Instructions.

### Collaboration
- Only verified logic should be merged into the `main` branch.  
- Feature updates should use a branch and pull request for review.  
- The Project Overview document serves as the authoritative design reference.


## 10. QA Dashboard (Data Integrity) (Step 10)

### Purpose
The QA Dashboard provides internal **data-quality validation** to confirm that all source tables join and transform correctly before financial reconciliation begins.

### Typical Checks
- Row-count comparison (loaded vs modeled)  
- Required fields not null (Carrier, AccountNo, Month, Amount)  
- Orphan joins (e.g., payments without accounts or splits)  
- Invalid or missing dates (effective-date ranges, statement dates)

### Outputs
Power Query generates a simple **QA_Checks** table (PASS/FAIL by check).  
Conditional formatting and an optional slicer in Excel make failed checks easy to review.

> *Note:* The QA Dashboard ensures data integrity only. The actual Expected vs Actual reconciliation occurs in the **Expected_Commissions** module (Step 10).


## Appendix A: Field Reference Table

This table lists all standardized fields used throughout the PSI Commission System workbook. It serves as a master reference for data design, Power Query joins, and validation logic.

| Field | Tabs Appearing On | Description / Purpose | Type / Format |
| --- | --- | --- | --- |
| AccountNo | All tabs | Carrier or internal account number identifying the customer's billing account. | Text |
| ActiveInactive | Accounts | Tracks whether the account is active or inactive. | Text |
| AdjustmentType | Manual_Adjustments | Describes the type of manual adjustment (credit, chargeback, bonus, etc.). | Text |
| Agent | Agent_Splits, Agent_Statements | The sub-agent or PSI house account receiving part of the commission. | Text |
| AgentComm | Agent_Statements | Agent's portion of residual commission (GrossComm × AgentRate). | Currency |
| AgentNetPay | Agent_Statements | Total pay to agent after commissions, adjustments, and bonuses. | Currency |
| AgentRate | Agent_Statements | Percent of PSI commission assigned to agent or house for that line. | Percent |
| AgentRateRES | Agent_Splits | Default agent rate for residual commissions (0-1). | Percent |
| AgentRateSPF | Agent_Splits | Default agent rate for SPIFFs (0-1). | Percent |
| AgentSPIFF | Agent_Statements | Dollar SPIFF paid to agent (GrossSPIFF × AgentSPIFFRate). | Currency |
| AgentSPIFFRate | Agent_Statements | Percent of the SPIFF payout owed to agent (may differ from residual rate). | Percent |
| Amount | Manual_Adjustments | Dollar value of manual adjustment (positive adds, negative reduces pay). | Currency |
| AppliesTo | Manual_Adjustments | Account, invoice, or item that this manual adjustment affects. | Text |
| BasisMRR | Commission_Payments, Agent_Statements | Monthly recurring revenue billed that earns commission. | Currency |
| BatchId | Agent_Statements | Overall import batch ID (e.g., 2025-10_Granite_v1). | Text |
| Carrier | All tabs | The actual network or carrier providing service to the customer. | Text |
| CarrierAdjust | Commission_Payments, Agent_Statements | Dollar amount of carrier credits or true-ups. | Currency |
| CarrierNotes | Commission_Payments | Notes column from carrier file, includes credit or adjustment details. | Text |
| Customer | All tabs | The business or end customer associated with the commission line. | Text |
| EffectiveEnd | Agent_Splits | Date split stops applying. | Date |
| EffectiveStart | Agent_Splits | Date split begins applying. | Date |
| EndDate | Accounts | Date the account was disconnected or closed. | Date |
| EnteredBy | Manual_Adjustments | Person who entered the manual adjustment. | Text |
| EnteredDate | Manual_Adjustments | Date the adjustment was entered. | Date |
| FileID | All tabs | File name or unique load identifier for each import. | Text |
| GAK | Accounts, Agent_Splits, Agent_Statements | Global Account Key - unique ID combining Carrier + AccountNo. | Text |
| GrossComm | Commission_Payments, Agent_Statements | PSI's gross commission earned before splits or bonuses. | Currency |
| GrossRate | Commission_Payments, Agent_Statements | Total PSI commission rate applied to BasisMRR. | Percent |
| GrossSPIFF | Commission_Payments, Agent_Statements | Special promotional bonus from carrier. | Currency |
| InvoiceNo | Commission_Payments | Carrier invoice or report reference number. | Text |
| IsHouse | Agent_Splits | Y if split belongs to PSI house; N if to sub-agent. | Text |
| IsPrimary | Agent_Splits | Y marks this agent as primary on the account. | Text |
| Month | Commission_Payments, Manual_Adjustments | Month the commission or adjustment applies to (first day of month). | Date |
| Notes | All tabs | Comments or context for this record (carrier, agent, or internal notes). | Text |
| Payor | All tabs except Accounts | Entity paying PSI commissions (e.g., Granite, OBFM). | Text |
| PayorDefault | Accounts | Default payor for this account when not in source data. | Text |
| PayType | Agent_Statements | Payment type (RES, SPF, BON, ADJ). | Text |
| PrimaryAgent | Accounts | Default primary agent assigned to account. | Text |
| Product | Commission_Payments, Agent_Statements | Human-readable product or service name. | Text |
| ProductCode | Commission_Payments | Short code for the specific product or service. | Text |
| PSIAdjust | Agent_Statements | Internal PSI-funded adjustment or bonus for this line. | Currency |
| ServiceID | Commission_Payments, Agent_Statements | Service, circuit, or location ID from carrier data. | Text |
| SourceType | Manual_Adjustments | Where the adjustment originated (CarrierProvided or ManualEntry). | Text |
| StartDate | Accounts | Date the account was activated or began billing. | Date |
| StatementDate | Commission_Payments | Date of the carrier's commission statement or report. | Date |