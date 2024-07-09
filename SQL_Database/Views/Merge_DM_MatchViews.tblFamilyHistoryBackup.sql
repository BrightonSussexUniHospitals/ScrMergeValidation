SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblFamilyHistoryBackup SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblFamilyHistoryBackup] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblFamilyHistoryBackup 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblFamilyHistoryBackup
GO
