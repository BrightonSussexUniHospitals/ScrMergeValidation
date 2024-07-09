SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblLUNG_METS_SUB_STAGE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblLUNG_METS_SUB_STAGE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblLUNG_METS_SUB_STAGE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblLUNG_METS_SUB_STAGE
GO
