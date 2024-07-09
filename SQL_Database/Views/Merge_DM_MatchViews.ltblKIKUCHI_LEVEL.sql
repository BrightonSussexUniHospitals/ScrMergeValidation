SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblKIKUCHI_LEVEL SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblKIKUCHI_LEVEL] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblKIKUCHI_LEVEL 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblKIKUCHI_LEVEL
GO
