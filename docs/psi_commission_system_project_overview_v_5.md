# PSI Commission System – Project Overview (v5)

_Last updated: November 3, 2025_

---

## 0. Table of Contents

1. Purpose and Overview Summary  
2. Scope of Work  
3. Technical Overview and Current Status  
4. Testing and Validation Plan  
5. Future Carrier Integration (Vigilant and OBFM)  
6. Design Principles and Next Steps  
7. Order Tracking / **Expected_Commissions** (Build **Step 11**)  
8. Project History and Revision Log  
9. Project Governance and Version Control  
10. QA Dashboard (Data Integrity) (Build **Step 10**)  
Appendix A: Field Reference Table

> **Note on numbering:** Section numbers are for this document’s layout. “Build Steps” (10, 11, etc.) refer to the implementation order inside the workbook/Power Query project.

| Stage                            | Objective                                                                  | Key Deliverables                                                                                      | Current Status | Go / No-Go  |
| -------------------------------- | -------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | -------------- | ----------- |
| **00_Config**                    | Set global run controls (`BatchId`, `CommissionMonth`)                     | `Config_BatchId`, `Config_CommissionMonth`                                                            | ✅ Complete     | Go          |
| **10_Load**                      | Ingest all source data (Payments, Adjustments, Splits, Accounts, Expected) | `Payments_Normalize`, `Adjustments_Load`, `Splits_Load`, `Accounts_Load`, `Expected_Commissions_Load` | ✅ Complete     | Go          |
| **20_Model**                     | Join and calculate unified facts                                           | `Payments_With_Accounts`, `Payments_With_Splits`, `Adj_As_Lines`, `Fact_AllLines`                     | ✅ Complete     | Go          |
| **30_Output**                    | Generate final Excel outputs                                               | `Statements_Build` → `Agent_Statements` table                                                         | ✅ Complete     | Go          |
| **11_Expected vs Actual**        | Expand expected data monthly and match vs actual payments                  | `Expected_ExpandMonthly`, `Expected_vs_Actual_Match`                                                  | 🟨 In Progress | Hold for QA |
| **90_QA**                        | Validate data integrity before reconciliation                              | `QA_RowCounts`, `QA_Checks` (to be built)                                                             | ⏳ Not Started  | Blocker     |
| **Carrier Functions**            | Normalize carrier-specific inputs to standard schema                       | `fnGraniteToPayments`                                                                                 | ✅ Complete     | Go          |
| **Helper – Shared File Imports** | Common import scaffolding used by Power Query                              | (Transform, Sample, Parameter queries)                                                                | ✅ Complete     | Go          |



---

## 1. Purpose and Overview Summary

The PSI Commission System is an end-to-end, automated, and scalable commission management platform for master agencies. It improves accuracy and efficiency in processing **expected vs. actual** commissions, speeds up detection of missed commissions, and raises agent transparency. Using Microsoft Excel, Power Query, and lightweight VBA, the system targets enterprise-grade precision with accessible, low-cost tools.

---

## 2. Scope of Work

**In scope**  
• Power Query–based ETL to ingest carrier payments, agent splits, manual adjustments, and account data.  
• A unified data model producing clean agent statements (Excel table output).  
• VBA automations for exports and validations.  
• Clear SOPs for Virtual Assistants (VAs).

**Out of scope (current phase)**  
• Web portals, external API integrations.  
• Database back ends / cloud migration / Power BI dashboards.  
• Productization packaging (to be considered post‑validation).

---

## 3. Technical Overview and Current Status

### 3.1 Architecture

Power Query groups:
- **00_Config** – Control cells for `BatchId` and `CommissionMonth`.
- **10_Load** – Imports: Payments, Adjustments, Splits, Accounts, Expected_Commissions.
- **20_Model** – Core joins (Payments ↔ Accounts ↔ Splits) and calculated fact tables.
- **30_Output** – `Agent_Statements` generation to Excel table.
- **11_Expected vs Actual**
- **90_QA** – Automated validation checks and counts feeding the QA Dashboard.
- **Carrier Functions**
- **Helper - Shared File Imports**

### 3.2 Completed Components

✅ `Config_BatchId` and `Config_CommissionMonth` (global run controls)  
✅ `fnGraniteToPayments` – normalizes Granite raw files  
✅ `Payments_Normalize` – folder import pipeline for Granite  
✅ `Adjustments_Load` – integrates `Manual_Adjustments` table  
✅ `Splits_Load` – effective-date splits  
✅ `Accounts_Load` – derives Global Account Key (GAK)  
✅ `Payments_With_Accounts` – joins w/ QA flags  
✅ `Payments_With_Splits` – applies agent splits  
✅ `Adj_As_Lines` + `Fact_AllLines` – unify payments + manual adjustments  
✅ `Statements_Build` – outputs `Agent_Statements` table  
✅ 'Expected_Commissions_Load` (new) – added to model; used by Step 11 comparisons  
🟨 'Expected_ExpandedMonthly` (new) – 
🟨 `QA_Checks` (new) – feeds QA Dashboard (Step 10)

---

## 4. Testing and Validation Plan

Run after **Step 10 (QA Dashboard)** and **Step 11 (Expected vs Actual)** are in place.

1) **Granite Commission Validation** – Compare generated results vs. legacy manual calculations.  
2) **Vigilant Integration Validation** – Normalize, import, compare outputs.  
3) **OBFM Integration Validation** – Normalize, import, compare outputs.  
4) **Cross‑Carrier Regression** – Confirm combined statements remain accurate.  
5) **Export + VA Workflow** – Validate VBA exports and VA SOPs end‑to‑end.

**Acceptance criteria (examples):**  
• 100% of carrier lines accounted for; no orphan payments.  
• ±$0 tolerance on totals per carrier per month.  
• Statement-level diffs explained (rate, timing, chargeback).  
• All QA checks = **PASS**, or explicit, documented exceptions.

---

## 5. Future Carrier Integration (Vigilant and OBFM)

Create new normalizers following the Granite schema:
- `fnVigilantToPayments`
- `fnOBFMToPayments`

Each outputs the shared **Payments** schema so downstream model logic remains unchanged. Validate each carrier individually, then run a cross‑carrier regression.

---

## 6. Design Principles and Next Steps

**Principles**  
1. **Simplicity** – Excel + Power Query + light VBA.  
2. **Transparency** – Full traceability from raw files to agent statements.  
3. **Scalability** – Build once, reuse across carriers.

**Immediate next steps**  
• Finish **Step 10**: implement QA checks + dashboard cards.  
• Finish **Step 11**: Expected vs Actual comparison queries + exception outputs.  
• Validate with live Granite data; then integrate Vigilant/OBFM.  
• Produce final VA SOPs and export macros.

---

## 7. Order Tracking / **Expected_Commissions** (Build **Step 11**)

### Purpose
Captures “should be getting” data so PSI can reconcile **Expected vs Actual** at a detailed level and surface missed, delayed, or short‑paid commissions early.

### Maintainers
VAs and Operations staff enter/update order information as deals are sold or services change.

### Location
Excel worksheet: **Expected_Commissions**  
Named table: **tblExpected_Commissions**

### Core Fields
| Field | Description |
|---|---|
| **Carrier** | Network or payor providing the service. |
| **Customer** | End customer name. |
| **AccountNo** | Carrier or internal billing account. |
| **Product** | Product or service sold. |
| **ServiceID** | Circuit/location/service identifier (if known). |
| **StartDate** | Date billing begins. |
| **ExpectedMRR** | Monthly recurring revenue expected. |
| **ExpectedRate** | Commission rate as decimal (e.g., 0.18). |
| **ExpectedPayType** | RES, SPF, BON, etc. |
| **ExpectedStartMonth** | First month Expected applies (1st of month). |
| **ExpectedEndMonth** *(optional)* | Month Expected ends if term‑bound. |
| **Notes** | Context (promo, term, special clauses). |
| **EnteredBy** | Person entering the record. |
| **EnteredDate** | Entry date. |

### Data Flow
1. VAs populate **tblExpected_Commissions**.  
2. Power Query `Expected_Commissions_Load` ingests the table.  
3. `Expected_vs_Actual_Match` compares Expected rows to Actual Payments by **(GAK/AccountNo, Product/ServiceID, Month)** with fuzzy fallbacks (e.g., ProductCode lookup).  
4. Results classify each Expected row: **Not Found**, **Amount Variance**, **Rate Variance**, **Timing Variance**.

### Outputs
- **Expected_vs_Actual_Exceptions** (query) – key exception list for review.  
- **Expected_Aging** (query) – shows how long an Expected line has had no matching payment.

### Governance
Any change to fields or logic is documented here **and** reflected in VA SOPs. Use versioned commits/messages describing the reason and impact.

---

## 8. Project History and Revision Log

| Version | Date / Author | Notes / Description |
|---|---|---|
| v1 | 2025‑10‑25 / ChatGPT & User | Initial architecture and Phase 1 field standardization. |
| v2 | 2025‑10‑27 / ChatGPT & User | Granite integrated; automated `Agent_Statements` built. |
| v3 | 2025‑10‑28 / ChatGPT & User | Added Order Tracking, Field Reference, testing plan, governance. |
| **v4** | **2025‑10‑29 / ChatGPT & User** | Added **QA Dashboard (Step 10)** and **Expected_Commissions (Step 11)**; clarified build vs section numbering; expanded Appendix A and matching rules. |
| ------- | ------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **v5**  | **2025-11-03 / ChatGPT & User** | Re-aligned PQ architecture; added month boundaries to Expected Commissions; exported queries to GitHub; reset baseline. |


---

## 9. Project Governance and Version Control

**Purpose**  
Ensure all files, logic, and documentation remain versioned, auditable, and recoverable.

**Practices**  
• Store Power Query M scripts, VBA modules, and Excel templates in GitHub (or equivalent).  
• Use clear commit messages: _component: short change summary (why/impact)_.  
• Tag major milestones (`v4`, `v5`) or keep versioned files in `/Archive/`.  
• Reflect significant logic/field edits here and in VA SOPs.

**Collaboration**  
• Only verified logic is merged to `main`.  
• Use feature branches + PR review for updates.  
• This document is the authoritative design reference.

---

## 10. QA Dashboard (Data Integrity) (Build **Step 10**)

### Purpose
Provide internal **data‑quality validation** so joins and transforms are correct before financial reconciliation begins.

### Checks (examples)
- **Row counts** – loaded vs modeled per table.  
- **Required fields not null** – `Carrier`, `AccountNo`, `Month`, `Amount`.  
- **Orphan joins** – e.g., payments without accounts or splits.  
- **Effective‑date validity** – overlaps/gaps in splits; invalid statement dates.  
- **Duplicate keys** – same `(GAK, ServiceID, Month, PayType)` repeated unexpectedly.  
- **Rate sanity** – `GrossRate` in [0, 1]; SPIFF presence matches `PayType`.

### Implementation
- Queries: `QA_RowCounts`, `QA_RequiredFields`, `QA_Orphans`, `QA_Dates`, `QA_Duplicates`, `QA_RateSanity`.  
- Union into `QA_Checks` with columns: `CheckName`, `Status (PASS|FAIL)`, `Count`, `SampleLink/FilterToken`.  
- Excel Dashboard: pivot + conditional formatting; slicer on `Status`.

> **Outcome:** Proceed to reconciliation only when **all PASS** or exceptions are understood and documented.

---

## Appendix A: Field Reference Table

This master table standardizes fields used across the workbook for joins and validation.

| Field | Tabs Appearing On | Description / Purpose | Type / Format |
|---|---|---|---|
| **AccountNo** | All tabs | Carrier/internal account number identifying the customer’s billing account. | Text |
| **ActiveInactive** | Accounts | Tracks whether the account is active or inactive. | Text |
| **AdjustmentType** | Manual_Adjustments | Type of manual adjustment (credit, chargeback, bonus, etc.). | Text |
| **Agent** | Agent_Splits, Agent_Statements | Sub‑agent or PSI house receiving part of the commission. | Text |
| **AgentComm** | Agent_Statements | Agent’s portion of residual commission (`GrossComm × AgentRate`). | Currency |
| **AgentNetPay** | Agent_Statements | Total pay to agent after commissions, adjustments, bonuses. | Currency |
| **AgentRate** | Agent_Statements | Percent of PSI commission assigned to agent or house for that line. | Percent |
| **AgentRateRES** | Agent_Splits | Default agent rate for residual commissions (0–1). | Percent |
| **AgentRateSPF** | Agent_Splits | Default agent rate for SPIFFs (0–1). | Percent |
| **AgentSPIFF** | Agent_Statements | Dollar SPIFF to agent (`GrossSPIFF × AgentSPIFFRate`). | Currency |
| **AgentSPIFFRate** | Agent_Statements | Percent of SPIFF payout owed to agent. | Percent |
| **Amount** | Manual_Adjustments | Dollar value of manual adjustment (positive adds, negative reduces). | Currency |
| **AppliesTo** | Manual_Adjustments | Account, invoice, or item that this manual adjustment affects. | Text |
| **BasisMRR** | Commission_Payments, Agent_Statements | MRR billed that earns commission. | Currency |
| **BatchId** | Agent_Statements | Overall import batch ID (e.g., `2025‑10_Granite_v1`). | Text |
| **Carrier** | All tabs | Network/carrier providing service to the customer. | Text |
| **CarrierAdjust** | Commission_Payments, Agent_Statements | Carrier credits/true‑ups. | Currency |
| **CarrierNotes** | Commission_Payments | Notes from carrier file (credit/adjustment details). | Text |
| **Customer** | All tabs | End‑customer. | Text |
| **EffectiveEnd** | Agent_Splits | Date split stops applying. | Date |
| **EffectiveStart** | Agent_Splits | Date split begins applying. | Date |
| **EndDate** | Accounts | Date the account was disconnected/closed. | Date |
| **EnteredBy** | Manual_Adjustments, Expected_Commissions | Person entering the record. | Text |
| **EnteredDate** | Manual_Adjustments, Expected_Commissions | Date the record was entered. | Date |
| **ExpectedMRR** | Expected_Commissions | Expected monthly recurring revenue. | Currency |
| **ExpectedPayType** | Expected_Commissions | Expected payment type (RES, SPF, BON…). | Text |
| **ExpectedRate** | Expected_Commissions | Expected commission rate (0–1). | Percent |
| **ExpectedStartMonth** | Expected_Commissions | First month the expectation applies (first of month). | Date |
| **ExpectedEndMonth** | Expected_Commissions | Optional end month if term‑bound. | Date |
| **FileID** | All tabs | File name or unique load identifier. | Text |
| **GAK** | Accounts, Agent_Splits, Agent_Statements | Global Account Key (Carrier + AccountNo). | Text |
| **GrossComm** | Commission_Payments, Agent_Statements | PSI gross commission before splits/bonuses. | Currency |
| **GrossRate** | Commission_Payments, Agent_Statements | PSI commission rate applied to `BasisMRR`. | Percent |
| **GrossSPIFF** | Commission_Payments, Agent_Statements | Promotional bonus from carrier. | Currency |
| **InvoiceNo** | Commission_Payments | Carrier invoice/report reference. | Text |
| **IsHouse** | Agent_Splits | `Y` if PSI house; `N` if sub‑agent. | Text |
| **IsPrimary** | Agent_Splits | `Y` marks the primary agent on the account. | Text |
| **Month** | Commission_Payments, Manual_Adjustments | Month the commission/adjustment applies (first day). | Date |
| **Notes** | All tabs | Comments/context. | Text |
| **Payor** | All tabs except Accounts | Entity paying PSI commissions (e.g., Granite, OBFM). | Text |
| **PayorDefault** | Accounts | Default payor for this account when not in source data. | Text |
| **PayType** | Agent_Statements | Payment type (RES, SPF, BON, ADJ). | Text |
| **PrimaryAgent** | Accounts | Default primary agent assigned to account. | Text |
| **Product** | Commission_Payments, Agent_Statements, Expected_Commissions | Product/service name. | Text |
| **ProductCode** | Commission_Payments | Short code for the product/service. | Text |
| **PSIAdjust** | Agent_Statements | Internal PSI‑funded adjustment/bonus. | Currency |
| **ServiceID** | Commission_Payments, Agent_Statements, Expected_Commissions | Service/circuit/location ID. | Text |
| **SourceType** | Manual_Adjustments | `CarrierProvided` or `ManualEntry`. | Text |
| **StartDate** | Accounts | Account activation/billing start date. | Date |
| **StatementDate** | Commission_Payments | Carrier statement/report date. | Date |

