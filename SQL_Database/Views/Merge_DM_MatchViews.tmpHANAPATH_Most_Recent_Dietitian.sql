SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpHANAPATH_Most_Recent_Dietitian SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpHANAPATH_Most_Recent_Dietitian] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tmpHANAPATH_Most_Recent_Dietitian 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tmpHANAPATH_Most_Recent_Dietitian
GO
