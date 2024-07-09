SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblUrologyBiopsyResult SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblUrologyBiopsyResult] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblUrologyBiopsyResult 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblUrologyBiopsyResult
GO
