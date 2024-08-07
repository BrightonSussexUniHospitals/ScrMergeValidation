SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblAO_FUNCTION_OUTCOME SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblAO_FUNCTION_OUTCOME] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblAO_FUNCTION_OUTCOME 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblAO_FUNCTION_OUTCOME
GO
