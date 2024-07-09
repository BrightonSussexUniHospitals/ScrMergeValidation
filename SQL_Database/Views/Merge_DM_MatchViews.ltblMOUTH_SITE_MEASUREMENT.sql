SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblMOUTH_SITE_MEASUREMENT SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblMOUTH_SITE_MEASUREMENT] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblMOUTH_SITE_MEASUREMENT 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblMOUTH_SITE_MEASUREMENT
GO
