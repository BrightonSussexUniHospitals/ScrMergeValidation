SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the expSWCIS_TRIAL_TEMP SCR table 
CREATE VIEW [Merge_DM_MatchViews].[expSWCIS_TRIAL_TEMP] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.expSWCIS_TRIAL_TEMP 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.expSWCIS_TRIAL_TEMP
GO
