

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
   PROJECT: Investment Portfolio Reclassification & Multi-Period Reporting
   FILE: mi_monthly_quarterly_report.sql

   PURPOSE:
   - Reclassify AssetType_3 into reporting categories
   - Apply deterministic valuation logic (Exposure vs Market Value)
   - Produce Current Month, Previous Month, Current Quarter, Previous Quarter outputs
   - Deliver pivot-ready, audit-safe dataset

   DESIGN:
   - No hardcoded dates
   - Period-filtered CTEs (no conditional CASE by date)
   - Single reporting grain
   - Clean valuation separation
========================================================================================================= */


-- ========================================================================================================
-- 1. DATE PARAMETERS
-- ========================================================================================================

DECLARE @CurrentMonth DATE;

SELECT @CurrentMonth = MAX(Report_Date)
FROM dbo.T_Dataset_Exhaustive_Aligned;

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
    Asset_type_1 NVARCHAR(10),
    Asset_type_2 NVARCHAR(10),
    Asset_type_3 NVARCHAR(25),
    New_Asset_type_3 NVARCHAR(25)
);

INSERT INTO @New_Assets VALUES
('A','Type_1','BondFuture','R_Offset'),
('A','Type_1','Option','R_Derivative'),
('A','Type_1','CDS','R_Derivative'),
('A','Type_1','IRS','R_Derivative'),
('A','Type_1','TRS','R_Derivative'),
('A','Type_1','FXForward','R_Derivative'),
('A','Type_1','Equity','R_Physical'),
('A','Type_1','Cash','R_Physical');



-- ========================================================================================================
-- 3. BASE DATASET WITH RECLASSIFICATION + VALUATION FLAG
-- ========================================================================================================

WITH Base_Data AS
(
    SELECT
        A.Report_Date,
        A.Entity,
        A.Portfolio,
        A.Desk,
        A.Trader,
        A.Instrument_ID,
        A.Security_Name,
        A.AssetType_1,
        A.AssetType_2,
        A.AssetType_3,
        A.Parent_Fund,
        A.Sub_Fund,
        A.Currency,
        A.Country,
        A.Region,
        A.Rating,
        A.Accounting_Code,
        A.Derivative_Group,
        A.Derivative_Flag,
        A.DerivativeOffset_Flag,
        A.Market_Value_Base,
        A.Exposure_Base,

        COALESCE(N.New_Asset_type_3, 'Unmapped') AS Reporting_Asset_Type,

        CASE
            WHEN A.AssetType_3 IN ('Bond Future','Option')
                THEN 1
            ELSE 0
        END AS Use_Exposure_Flag

    FROM dbo.T_Dataset_Exhaustive_Aligned A
    LEFT JOIN @New_Assets N
        ON A.AssetType_1 = N.Asset_type_1
        AND A.AssetType_2 = N.Asset_type_2
        AND A.AssetType_3 = N.Asset_type_3
),



-- ========================================================================================================
-- 4. CURRENT MONTH
-- ========================================================================================================

CM AS
(
    SELECT
        Entity, Portfolio, Desk, Trader,
        Instrument_ID, Security_Name,
        AssetType_1, AssetType_2, AssetType_3,
        Parent_Fund, Sub_Fund,
        Currency, Country, Region, Rating,
        Accounting_Code,
        Reporting_Asset_Type,

        SUM(Market_Value_Base) AS CM_MV_Core,
        SUM(Exposure_Base) AS CM_EX_Core,

        SUM(CASE
                WHEN Use_Exposure_Flag = 1
                    THEN Exposure_Base
                ELSE Market_Value_Base
            END) AS CM_Report_Value

    FROM Base_Data
    WHERE Report_Date = @CurrentMonth
    GROUP BY
        Entity, Portfolio, Desk, Trader,
        Instrument_ID, Security_Name,
        AssetType_1, AssetType_2, AssetType_3,
        Parent_Fund, Sub_Fund,
        Currency, Country, Region, Rating,
        Accounting_Code,
        Reporting_Asset_Type
),



-- ========================================================================================================
-- 5. PREVIOUS MONTH
-- ========================================================================================================

PM AS
(
    SELECT
        Entity, Portfolio, Desk, Trader,
        Instrument_ID, Security_Name,
        AssetType_1, AssetType_2, AssetType_3,
        Parent_Fund, Sub_Fund,
        Currency, Country, Region, Rating,
        Accounting_Code,
        Reporting_Asset_Type,

        SUM(Market_Value_Base) AS PM_MV_Core,
        SUM(Exposure_Base) AS PM_EX_Core,

        SUM(CASE
                WHEN Use_Exposure_Flag = 1
                    THEN Exposure_Base
                ELSE Market_Value_Base
            END) AS PM_Report_Value

    FROM Base_Data
    WHERE Report_Date = @PreviousMonth
    GROUP BY
        Entity, Portfolio, Desk, Trader,
        Instrument_ID, Security_Name,
        AssetType_1, AssetType_2, AssetType_3,
        Parent_Fund, Sub_Fund,
        Currency, Country, Region, Rating,
        Accounting_Code,
        Reporting_Asset_Type
),



-- ========================================================================================================
-- 6. CURRENT QUARTER
-- ========================================================================================================

CQ AS
(
    SELECT
        Entity, Portfolio, Desk, Trader,
        Instrument_ID, Security_Name,
        AssetType_1, AssetType_2, AssetType_3,
        Parent_Fund, Sub_Fund,
        Currency, Country, Region, Rating,
        Accounting_Code,
        Reporting_Asset_Type,

        SUM(CASE
                WHEN Use_Exposure_Flag = 1
                    THEN Exposure_Base
                ELSE Market_Value_Base
            END) AS CQ_Report_Value

    FROM Base_Data
    WHERE Report_Date = @CurrentQuarter
    GROUP BY
        Entity, Portfolio, Desk, Trader,
        Instrument_ID, Security_Name,
        AssetType_1, AssetType_2, AssetType_3,
        Parent_Fund, Sub_Fund,
        Currency, Country, Region, Rating,
        Accounting_Code,
        Reporting_Asset_Type
),



-- ========================================================================================================
-- 7. PREVIOUS QUARTER
-- ========================================================================================================

PQ AS
(
    SELECT
        Entity, Portfolio, Desk, Trader,
        Instrument_ID, Security_Name,
        AssetType_1, AssetType_2, AssetType_3,
        Parent_Fund, Sub_Fund,
        Currency, Country, Region, Rating,
        Accounting_Code,
        Reporting_Asset_Type,

        SUM(CASE
                WHEN Use_Exposure_Flag = 1
                    THEN Exposure_Base
                ELSE Market_Value_Base
            END) AS PQ_Report_Value

    FROM Base_Data
    WHERE Report_Date = @PreviousQuarter
    GROUP BY
        Entity, Portfolio, Desk, Trader,
        Instrument_ID, Security_Name,
        AssetType_1, AssetType_2, AssetType_3,
        Parent_Fund, Sub_Fund,
        Currency, Country, Region, Rating,
        Accounting_Code,
        Reporting_Asset_Type
)



-- ========================================================================================================
-- 8. FINAL OUTPUT (CURRENT MONTH UNIVERSE)
-- ========================================================================================================

SELECT
    @CurrentMonth AS Current_Month,
    @PreviousMonth AS Previous_Month,
    @CurrentQuarter AS Current_Quarter,
    @PreviousQuarter AS Previous_Quarter,

    CM.*,

    COALESCE(PM.PM_Report_Value,0) AS Previous_Month_Value,
    COALESCE(CQ.CQ_Report_Value,0) AS Current_Quarter_Value,
    COALESCE(PQ.PQ_Report_Value,0) AS Previous_Quarter_Value

FROM CM
LEFT JOIN PM
    ON CM.Instrument_ID = PM.Instrument_ID
LEFT JOIN CQ
    ON CM.Instrument_ID = CQ.Instrument_ID
LEFT JOIN PQ
    ON CM.Instrument_ID = PQ.Instrument_ID;
