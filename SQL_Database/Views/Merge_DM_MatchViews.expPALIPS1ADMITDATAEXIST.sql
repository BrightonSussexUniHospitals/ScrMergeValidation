SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the expPALIPS1ADMITDATAEXIST SCR table 
CREATE VIEW [Merge_DM_MatchViews].[expPALIPS1ADMITDATAEXIST] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.expPALIPS1ADMITDATAEXIST 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.expPALIPS1ADMITDATAEXIST
GO
