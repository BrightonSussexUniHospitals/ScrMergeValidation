SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblBREAST_PLANNED_RECONSTRUCTION SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblBREAST_PLANNED_RECONSTRUCTION] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblBREAST_PLANNED_RECONSTRUCTION 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblBREAST_PLANNED_RECONSTRUCTION
GO
