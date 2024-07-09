SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblDERM_LYMPHOMA SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblDERM_LYMPHOMA] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblDERM_LYMPHOMA 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblDERM_LYMPHOMA
GO
