SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpHANARAD_Baseline_A SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpHANARAD_Baseline_A] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tmpHANARAD_Baseline_A 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tmpHANARAD_Baseline_A
GO
