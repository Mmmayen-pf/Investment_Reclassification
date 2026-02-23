--================================================================================================================================================
--Build an MI Monthly and Quarterly Report
--Date parameters for the report

DECLARE @CurrentMonth AS DATE;
SELECT @CurrentMonth = MAX(Report_Date)
FROM [dbo].[T_Dataset_Exhaustive_Aligned];

DECLARE @PreviousMonth AS DATE ;
SET @PreviousMonth = EOMONTH(@CurrentMonth, -1);

DECLARE @CurrentQuarter AS DATE ;
DECLARE @QuarterOffset AS INT ;
SET @QuarterOffset = MONTH(@CurrentMonth)% 3
SET @CurrentQuarter = EOMONTH( DATEADD(MONTH, -@QuarterOffset ,@CurrentMonth))

DECLARE @PreviousQuarter AS DATE ;
SET @PreviousQuarter = EOMONTH(@CurrentQuarter ,-3)

--================================================================================================================================================
--Reclassifying asset types 
DECLARE @New_Assets TABLE 
(
ID INT IDENTITY(1,1), 
Asset_type_1 NVARCHAR(10), 
Asset_type_2 NVARCHAR(10), 
Asset_type_3 NVARCHAR(10),
New_Asset_type_1 NVARCHAR(10), 
New_Asset_type_2 NVARCHAR(10), 
New_Asset_type_3 NVARCHAR(25)
)
INSERT INTO @New_Assets
VALUES
('A','Type_1','BondFuture', 'A','Type_1','R_Offset'),
('B','Type_2','BondFuture', 'B','Type_2','R_Offset'),
('C','Type_3','BondFuture', 'C','Type_3','R_Offset'),
('D','Type_4','BondFuture', 'D','Type_4','R_Offset'),
('E','Type_5','BondFuture', 'E','Type_5','R_Offset'),

('A','Type_1','Option', 'A','Type_1','R_Derivative'),
('B','Type_2','Option', 'B','Type_2','R_Derivative'),
('C','Type_3','Option', 'C','Type_3','R_Derivative'),
('D','Type_4','Option', 'D','Type_4','R_Derivative'),
('E','Type_5','Option', 'E','Type_5','R_Derivative'),

('A','Type_1','CDS', 'A','Type_1','R_Derivative'),
('B','Type_2','CDS', 'B','Type_2','R_Derivative'),
('C','Type_3','CDS', 'C','Type_3','R_Derivative'),
('D','Type_4','CDS', 'D','Type_4','R_Derivative'),
('E','Type_5','CDS', 'E','Type_5','R_Derivative'),

('A','Type_1','IRS', 'A','Type_1','R_Derivative'),
('B','Type_2','IRS', 'B','Type_2','R_Derivative'),
('C','Type_3','IRS', 'C','Type_3','R_Derivative'),
('D','Type_4','IRS', 'D','Type_4','R_Derivative'),
('E','Type_5','IRS', 'E','Type_5','R_Derivative'),

('A','Type_1','Equity', 'A','Type_1','R_Physical'),
('B','Type_2','Equity', 'B','Type_2','R_Physical'),
('C','Type_3','Equity', 'C','Type_3','R_Physical'),
('D','Type_4','Equity', 'D','Type_4','R_Physical'),
('E','Type_5','Equity', 'E','Type_5','R_Physical'),

('A','Type_1','TRS', 'A','Type_1','R_Derivative'),
('B','Type_2','TRS','B','Type_2','R_Derivative'),
('C','Type_3','TRS', 'C','Type_3','R_Derivative'),
('D','Type_4','TRS', 'D','Type_4','R_Derivative'),
('E','Type_5','TRS', 'E','Type_5','R_Derivative'),

('A','Type_1','Cash', 'A','Type_1','R_Physical'),
('B','Type_2','Cash', 'B','Type_2','R_Physical'),
('C','Type_3','Cash', 'C','Type_3','R_Physical'),
('D','Type_4','Cash', 'D','Type_4','R_Physical'),
('E','Type_5','Cash', 'E','Type_5','R_Physical'),

('A','Type_1','FXForward','A','Type_1','R_Derivative'),
('B','Type_2','FXForward', 'B','Type_2','R_Derivative'),
('C','Type_3','FXForward', 'C','Type_3','R_Derivative'),
('D','Type_4','FXForward', 'D','Type_4','R_Derivative'),
('E','Type_5','FXForward', 'E','Type_5','R_Derivative')

DECLARE @Reclassify_Asset_3	
TABLE 
(
ID INT IDENTITY(1,1),
[Asset_Type_3] NVARCHAR (25),
[Non_Asset_Type_3] NVARCHAR (25)
)
INSERT INTO @Reclassify_Asset_3	
--New classification vs old classification based on the dataset 
VALUES 
('Bond Future', 'Bond Future'),
('Equity', 'Equity'),
(NULL, 'FXForward'),
('Option', 'Option');

--================================================================================================================================================
--Building the feilds in the dataset and mirroring the existing dataset
WITH Main_CTE (
	[Report_Date],
	[Entity],	
	[Portfolio],
	[Desk],
	[Trader],
	[Instrument_ID],
	[Security_Name],
	[AssetType_1],
	[AssetType_2],
	[AssetType_3],
	[Parent_Fund],
	[Sub_Fund],
	[Currency],	
	[Country],
	[Region],
	[Rating],
	[Accounting_Code],
	[Derivative_Group],
	[Derivative_Flag],
	[DerivativeOffset_Flag],
	[Market_Value_Base],
	[Exposure_Base]
				)
	AS 
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
	FROM [dbo].[T_Dataset_Exhaustive_Aligned]
					),

--Reclassifying the valuation for asset type 3 for the current month 
Current_Month_CTE AS(
 SELECT 
	A1.[Report_Date],
	A1.[Entity],	
	A1.[Portfolio],
	A1.[Desk],
	A1.[Trader],
	A1.[Instrument_ID],
	A1.[Security_Name],
	A1.[AssetType_1],
	A1.[AssetType_2],
	A1.[AssetType_3],
	A1.[Parent_Fund],
	A1.[Sub_Fund],
	A1.[Currency],	
	A1.[Country],
	A1.[Region],
	A1.[Rating],
	A1.[Accounting_Code],
	A1.[Derivative_Group],
	A1.[Derivative_Flag],
	A1.[DerivativeOffset_Flag],
	SUM(A1.Market_Value_Base) AS MV_Core,
	SUM(A1.Exposure_Base) AS EX_Core,
	CASE 
		WHEN A1.[Report_Date] = @CurrentMonth AND A1.[AssetType_3] IN (SELECT [Asset_Type_3] FROM @Reclassify_Asset_3 WHERE [Asset_Type_3] IS NOT NULL)
		THEN SUM(A1.Exposure_Base)
		ELSE SUM(A1.Market_Value_Base)
	END AS 'Current_MV',
	CASE 
		WHEN A1.[Report_Date] = @CurrentMonth AND A1.[AssetType_3] IN (SELECT [Asset_Type_3] FROM @Reclassify_Asset_3 WHERE [Asset_Type_3] IS NOT NULL)
		THEN SUM(A1.Exposure_Base)
		ELSE SUM(A1.Market_Value_Base)
	END AS 'Current_EXV',
	CASE 
		WHEN A1.[Report_Date] = @CurrentQuarter AND A1.[AssetType_3] IN (SELECT [Asset_Type_3] FROM @Reclassify_Asset_3 WHERE [Asset_Type_3] IS NOT NULL)
		THEN SUM(A1.Exposure_Base)
		ELSE SUM(A1.Market_Value_Base)
	END AS 'Current_Quarter_MV',
	CASE 
		WHEN A1.[Report_Date] = @CurrentQuarter AND A1.[AssetType_3] IN (SELECT [Asset_Type_3] FROM @Reclassify_Asset_3 WHERE [Asset_Type_3] IS NOT NULL)
		THEN SUM(A1.Exposure_Base)
		ELSE SUM(A1.Market_Value_Base)
	END AS 'Current_Quarter_EXV'



FROM Main_CTE A1


GROUP BY
	A1.[Report_Date],
	A1.[Entity],	
	A1.[Portfolio],
	A1.[Desk],
	A1.[Trader],
	A1.[Instrument_ID],
	A1.[Security_Name],
	A1.[AssetType_1],
	A1.[AssetType_2],
	A1.[AssetType_3],
	A1.[Parent_Fund],
	A1.[Sub_Fund],
	A1.[Currency],	
	A1.[Country],
	A1.[Region],
	A1.[Rating],
	A1.[Accounting_Code],
	A1.[Derivative_Group],
	A1.[Derivative_Flag],
	A1.[DerivativeOffset_Flag]
),

--Reclassifying the valuation for asset type 3 for the previous month 
Previous_Month_CTE AS(
 SELECT 
	A1.[Report_Date],
	A1.[Entity],	
	A1.[Portfolio],
	A1.[Desk],
	A1.[Trader],
	A1.[Instrument_ID],
	A1.[Security_Name],
	A1.[AssetType_1],
	A1.[AssetType_2],
	A1.[AssetType_3],
	A1.[Parent_Fund],
	A1.[Sub_Fund],
	A1.[Currency],	
	A1.[Country],
	A1.[Region],
	A1.[Rating],
	A1.[Accounting_Code],
	A1.[Derivative_Group],
	A1.[Derivative_Flag],
	A1.[DerivativeOffset_Flag],
	SUM(A1.Market_Value_Base) AS MV_Core,
	SUM(A1.Exposure_Base) AS EX_Core,
	CASE 
		WHEN A1.[AssetType_3] IN (SELECT [Asset_Type_3] FROM @Reclassify_Asset_3 WHERE [Asset_Type_3] IS NOT NULL)
		THEN SUM(A1.Exposure_Base)
		ELSE SUM(A1.Market_Value_Base)
	END AS 'Previous_MV',
	CASE 
		WHEN A1.[AssetType_3] IN (SELECT [Asset_Type_3] FROM @Reclassify_Asset_3 WHERE [Asset_Type_3] IS NOT NULL)
		THEN SUM(A1.Exposure_Base)
		ELSE SUM(A1.Market_Value_Base)
	END AS 'Previous_EXV',
	CASE 
		WHEN A1.[Report_Date] = @PreviousQuarter AND A1.[AssetType_3] IN (SELECT [Asset_Type_3] FROM @Reclassify_Asset_3 WHERE [Asset_Type_3] IS NOT NULL)
		THEN SUM(A1.Exposure_Base)
		ELSE SUM(A1.Market_Value_Base)
	END AS 'Previous_Quarter_MV',
	CASE 
		WHEN A1.[Report_Date] = @PreviousQuarter AND A1.[AssetType_3] IN (SELECT [Asset_Type_3] FROM @Reclassify_Asset_3 WHERE [Asset_Type_3] IS NOT NULL)
		THEN SUM(A1.Exposure_Base)
		ELSE SUM(A1.Market_Value_Base)
	END AS 'Previous_Quarter_EXV'

FROM Main_CTE A1

GROUP BY
	A1.[Report_Date],
	A1.[Entity],	
	A1.[Portfolio],
	A1.[Desk],
	A1.[Trader],
	A1.[Instrument_ID],
	A1.[Security_Name],
	A1.[AssetType_1],
	A1.[AssetType_2],
	A1.[AssetType_3],
	A1.[Parent_Fund],
	A1.[Sub_Fund],
	A1.[Currency],	
	A1.[Country],
	A1.[Region],
	A1.[Rating],
	A1.[Accounting_Code],
	A1.[Derivative_Group],
	A1.[Derivative_Flag],
	A1.[DerivativeOffset_Flag]
)
--================================================================================================================================================
--Join the CTE's
 SELECT 
	@CurrentQuarter AS'Current_Quarter',
	@PreviousQuarter AS 'Previous_Quarter', 
	@CurrentMonth AS 'Current_Month',
	@PreviousMonth AS 'Previous_Month', 
	A1.[Entity],	
	A1.[Portfolio],
	A1.[Desk],
	A1.[Trader],
	A1.[Instrument_ID],
	A1.[Security_Name],
	A1.[AssetType_1],
	A1.[AssetType_2],
	A1.[AssetType_3],
	A1.[Parent_Fund],
	A1.[Sub_Fund],
	A1.[Currency],	
	A1.[Country],
	A1.[Region],
	A1.[Rating],
	A1.[Accounting_Code],
	A1.[Derivative_Group],
	A1.[Derivative_Flag],
	A1.[DerivativeOffset_Flag],
	B1.MV_Core,
	B1.EX_Core,
	COALESCE(B1.Current_MV, 0) AS Current_MV,
	COALESCE(B1.Current_EXV, 0) AS Current_EXV,
	COALESCE(B1.Current_Quarter_MV, 0) AS Current_Quarter_MV,
	COALESCE(B1.Current_Quarter_EXV, 0) AS Current_Quarter_EXV,
	COALESCE(C1.Previous_MV, 0) AS Previous_MV,
	COALESCE(C1.Previous_EXV, 0) AS Previous_EXV,
	COALESCE(C1.Previous_Quarter_MV, 0) AS Previous_Quarter_MV,
	COALESCE(C1.Previous_Quarter_EXV, 0) AS Previous_Quarter_EXV
FROM Main_CTE A1
LEFT JOIN Current_Month_CTE B1
ON 
	A1.[Entity] = B1.[Entity] AND
	A1.[Portfolio] = B1.[Portfolio] AND
	A1.[Desk] = B1.[Desk] AND 
	A1.[Trader] = B1.[Trader] AND 
	A1.[Instrument_ID] = B1.[Instrument_ID] AND
	A1.[Security_Name] = B1.[Security_Name] AND
	A1.[AssetType_1] = B1.[AssetType_1] AND
	A1.[AssetType_2] = B1.[AssetType_2] AND
	A1.[AssetType_3] = B1.[AssetType_3] AND
	A1.[Parent_Fund] = B1.[Parent_Fund] AND
	A1.[Sub_Fund] = B1.[Sub_Fund] AND
	A1.[Currency] = B1.[Currency] AND
	A1.[Country] = B1.[Country] AND
	A1.[Region] = B1.[Region] AND 
	A1.[Rating] = B1.[Rating] AND
	A1.[Accounting_Code] = B1.[Accounting_Code]
LEFT JOIN Previous_Month_CTE C1
ON 
	A1.[Entity] = C1.[Entity] AND
	A1.[Portfolio] = C1.[Portfolio] AND
	A1.[Desk] = C1.[Desk] AND 
	A1.[Trader] = C1.[Trader] AND 
	A1.[Instrument_ID] = C1.[Instrument_ID] AND
	A1.[Security_Name] = C1.[Security_Name] AND
	A1.[AssetType_1] = C1.[AssetType_1] AND
	A1.[AssetType_2] = C1.[AssetType_2] AND
	A1.[AssetType_3] = C1.[AssetType_3] AND
	A1.[Parent_Fund] = C1.[Parent_Fund] AND
	A1.[Sub_Fund] = C1.[Sub_Fund] AND
	A1.[Currency] = C1.[Currency] AND
	A1.[Country] = C1.[Country] AND
	A1.[Region] = C1.[Region] AND 
	A1.[Rating] = C1.[Rating] AND
	A1.[Accounting_Code] = C1.[Accounting_Code]
LEFT JOIN @New_Assets D1
ON
A1.[AssetType_1] = D1.[New_Asset_type_1] AND 
A1.[AssetType_2] = D1.[New_Asset_type_2] AND 
A1.[AssetType_3] = D1.[New_Asset_type_3] 
