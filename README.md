

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

