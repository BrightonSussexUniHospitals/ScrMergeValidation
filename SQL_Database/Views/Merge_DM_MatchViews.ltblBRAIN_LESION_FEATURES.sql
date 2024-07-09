SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblBRAIN_LESION_FEATURES SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblBRAIN_LESION_FEATURES] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblBRAIN_LESION_FEATURES 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblBRAIN_LESION_FEATURES
GO
