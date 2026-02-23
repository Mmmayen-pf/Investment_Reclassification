

# Investment Portfolio Reclassification & Multi-Period Reporting

## Project Overview

This project demonstrates how to reclassify complex investment asset types and generate a clean, auditable dataset for structured monthly and quarterly portfolio reporting.

The solution transforms raw position-level investment data into a standardised reporting layer designed to replace inconsistent Excel-based logic with controlled SQL-driven outputs.

---

## Dataset

The source dataset contains multi-dimensional investment position data including:

* Fund & Sub-Fund hierarchy
* Asset classifications (`AssetType_1`, `AssetType_2`, `AssetType_3`)
* Exposure values
* Market values
* Derivative indicators
* Multiple reporting periods

The raw extract is not reporting-ready and requires classification normalisation and valuation rule alignment.

---

## Objective

To produce a consistent, well-structured dataset that:

* Standardises asset classifications
* Applies correct valuation logic (Exposure vs Market Value)
* Generates clean monthly and quarterly outputs
* Supports Excel Pivot reporting without duplication
* Ensures auditability and traceability

This eliminates manual overrides and inconsistent spreadsheet calculations.

---

## SQL Architecture

The solution is built using layered CTE logic:

### Asset Reclassification CTE

* Remaps `AssetType_3` into standardised reporting categories
* Separates:

  * Derivatives
  * Derivative Offsets
  * Physical Assets
* Ensures consistent grouping across funds

---

### Revaluation Logic CTE

* Applies deterministic valuation rules:

  * Certain asset types use **Exposure**
  * Others use **Market Value**
* Prevents overstated or duplicated risk

---

### Current Month CTE

* Dynamically selects latest reporting date
* Applies valuation logic
* Produces clean monthly output

---

### Previous Month CTE

* Automatically calculates prior month
* Enables month-over-month comparison

---

### Current Quarter CTE

* Dynamically identifies quarter end
* Produces quarter-level aggregation

---

### Previous Quarter CTE

* Enables quarter-over-quarter analysis
* Supports variance reporting

---

## Output Design

The final dataset is structured for:

* Excel Pivot reporting
* Fund-level concentration analysis
* Exposure vs Market Value comparison
* Period-over-period variance review
* Audit validation

No manual intervention required.

---

##  Key Skills Demonstrated

* Advanced SQL (CTEs, CASE logic, dynamic date handling)
* Financial data modelling
* Asset classification engineering
* Valuation logic design
* Multi-period reporting architecture
* Audit-aware dataset construction

---

## Business Impact

In many investment reporting environments:

* Derivatives are misclassified
* Exposure and Market Value are inconsistently applied
* Excel-based reporting introduces control risk
* Period comparisons are manually driven

This solution enforces:

* Structured classification
* Deterministic valuation logic
* Dynamic multi-period consistency
* Controlled reporting outputs

/* =========================================================================================================

   DESIGN PRINCIPLES:
       - No hardcoded dates
       - Deterministic valuation logic
       - Audit-friendly structure
       - Excel-ready output
========================================================================================================= */

-- ========================================================================================================
-- 1. DATE PARAMETERS
-- ========================================================================================================

DECLARE @CurrentMonth DATE;

SELECT @CurrentMonth = MAX(Report_Date)
FROM [dbo].[T_Dataset_Exhaustive_Aligned];

DECLARE @PreviousMonth DATE = EOMONTH(@CurrentMonth, -1);

DECLARE @QuarterOffset INT = MONTH(@CurrentMonth) % 3;

DECLARE @CurrentQuarter DATE =
    EOMONTH(DATEADD(MONTH, -@QuarterOffset, @CurrentMonth));

DECLARE @PreviousQuarter DATE =
    EOMONTH(@CurrentQuarter, -3);


-- ========================================================================================================
-- 2. ASSET RECLASSIFICATION TABLE
-- ========================================================================================================

DECLARE @New_Assets TABLE
(
    ID INT IDENTITY(1,1),
    Asset_type_1 NVARCHAR(10),
    Asset_type_2 NVARCHAR(10),
    Asset_type_3 NVARCHAR(10),
    New_Asset_type_1 NVARCHAR(10),
    New_Asset_type_2 NVARCHAR(10),
    New_Asset_type_3 NVARCHAR(25)
);

-- Bond Futures → Offset
INSERT INTO @New_Assets VALUES
('A','Type_1','BondFuture','A','Type_1','R_Offset'),
('B','Type_2','BondFuture','B','Type_2','R_Offset'),
('C','Type_3','BondFuture','C','Type_3','R_Offset'),
('D','Type_4','BondFuture','D','Type_4','R_Offset'),
('E','Type_5','BondFuture','E','Type_5','R_Offset');

-- Derivatives
INSERT INTO @New_Assets VALUES
('A','Type_1','Option','A','Type_1','R_Derivative'),
('A','Type_1','CDS','A','Type_1','R_Derivative'),
('A','Type_1','IRS','A','Type_1','R_Derivative'),
('A','Type_1','TRS','A','Type_1','R_Derivative'),
('A','Type_1','FXForward','A','Type_1','R_Derivative');

-- Physical
INSERT INTO @New_Assets VALUES
('A','Type_1','Equity','A','Type_1','R_Physical'),
('A','Type_1','Cash','A','Type_1','R_Physical');


-- ========================================================================================================
-- 3. RECLASSIFICATION CONTROL TABLE
-- ========================================================================================================

DECLARE @Reclassify_Asset_3 TABLE
(
    ID INT IDENTITY(1,1),
    Asset_Type_3 NVARCHAR(25),
    Non_Asset_Type_3 NVARCHAR(25)
);

INSERT INTO @Reclassify_Asset_3 VALUES
('Bond Future','Bond Future'),
('Equity','Equity'),
(NULL,'FXForward'),
('Option','Option');


-- ========================================================================================================
-- 4. BASE DATASET CTE
-- ========================================================================================================

WITH Main_CTE AS
(
    SELECT
        Report_Date,
        Entity,
        Portfolio,
        Desk,
        Trader,
        Instrument_ID,
        Security_Name,
        AssetType_1,
        AssetType_2,
        AssetType_3,
        Parent_Fund,
        Sub_Fund,
        Currency,
        Country,
        Region,
        Rating,
        Accounting_Code,
        Derivative_Group,
        Derivative_Flag,
        DerivativeOffset_Flag,
        Market_Value_Base,
        Exposure_Base
    FROM dbo.T_Dataset_Exhaustive_Aligned
),

-- ========================================================================================================
-- 5. CURRENT MONTH LOGIC
-- ========================================================================================================

Current_Month_CTE AS
(
    SELECT
        A1.*,
        SUM(A1.Market_Value_Base) AS MV_Core,
        SUM(A1.Exposure_Base) AS EX_Core,

        CASE
            WHEN A1.Report_Date = @CurrentMonth
                 AND A1.AssetType_3 IN (
                     SELECT Asset_Type_3
                     FROM @Reclassify_Asset_3
                     WHERE Asset_Type_3 IS NOT NULL
                 )
            THEN SUM(A1.Exposure_Base)
            ELSE SUM(A1.Market_Value_Base)
        END AS Current_MV,

        CASE
            WHEN A1.Report_Date = @CurrentQuarter
                 AND A1.AssetType_3 IN (
                     SELECT Asset_Type_3
                     FROM @Reclassify_Asset_3
                     WHERE Asset_Type_3 IS NOT NULL
                 )
            THEN SUM(A1.Exposure_Base)
            ELSE SUM(A1.Market_Value_Base)
        END AS Current_Quarter_MV

    FROM Main_CTE A1
    GROUP BY
        Report_Date, Entity, Portfolio, Desk, Trader,
        Instrument_ID, Security_Name,
        AssetType_1, AssetType_2, AssetType_3,
        Parent_Fund, Sub_Fund,
        Currency, Country, Region, Rating,
        Accounting_Code, Derivative_Group,
        Derivative_Flag, DerivativeOffset_Flag
),

-- ========================================================================================================
-- 6. PREVIOUS MONTH LOGIC
-- ========================================================================================================

Previous_Month_CTE AS
(
    SELECT
        A1.*,

        CASE
            WHEN A1.AssetType_3 IN (
                SELECT Asset_Type_3
                FROM @Reclassify_Asset_3
                WHERE Asset_Type_3 IS NOT NULL
            )
            THEN SUM(A1.Exposure_Base)
            ELSE SUM(A1.Market_Value_Base)
        END AS Previous_MV

    FROM Main_CTE A1
    GROUP BY
        Report_Date, Entity, Portfolio, Desk, Trader,
        Instrument_ID, Security_Name,
        AssetType_1, AssetType_2, AssetType_3,
        Parent_Fund, Sub_Fund,
        Currency, Country, Region, Rating,
        Accounting_Code, Derivative_Group,
        Derivative_Flag, DerivativeOffset_Flag
)

-- ========================================================================================================
-- 7. FINAL OUTPUT
-- ========================================================================================================

SELECT
    @CurrentQuarter AS Current_Quarter,
    @PreviousQuarter AS Previous_Quarter,
    @CurrentMonth AS Current_Month,
    @PreviousMonth AS Previous_Month,
    A1.*,
    COALESCE(B1.Current_MV, 0) AS Current_MV,
    COALESCE(B1.Current_Quarter_MV, 0) AS Current_Quarter_MV,
    COALESCE(C1.Previous_MV, 0) AS Previous_MV

FROM Main_CTE A1
LEFT JOIN Current_Month_CTE B1
    ON A1.Instrument_ID = B1.Instrument_ID
LEFT JOIN Previous_Month_CTE C1
    ON A1.Instrument_ID = C1.Instrument_ID;
