SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblHAEM_EXTRANODAL_SITE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblHAEM_EXTRANODAL_SITE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblHAEM_EXTRANODAL_SITE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblHAEM_EXTRANODAL_SITE
GO
