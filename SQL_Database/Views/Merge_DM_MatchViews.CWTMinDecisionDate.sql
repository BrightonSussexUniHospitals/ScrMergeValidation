SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the CWTMinDecisionDate SCR table 
CREATE VIEW [Merge_DM_MatchViews].[CWTMinDecisionDate] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.CWTMinDecisionDate 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.CWTMinDecisionDate
GO
