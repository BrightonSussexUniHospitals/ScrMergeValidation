SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpHANASURG_Baseline_A SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpHANASURG_Baseline_A] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tmpHANASURG_Baseline_A 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tmpHANASURG_Baseline_A
GO
