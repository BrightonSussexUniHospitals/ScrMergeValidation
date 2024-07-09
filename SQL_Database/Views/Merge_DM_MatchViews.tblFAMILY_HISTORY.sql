SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblFAMILY_HISTORY SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblFAMILY_HISTORY] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblFAMILY_HISTORY 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblFAMILY_HISTORY
GO
