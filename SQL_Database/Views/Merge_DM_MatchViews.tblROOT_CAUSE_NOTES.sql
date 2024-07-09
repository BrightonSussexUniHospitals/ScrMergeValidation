SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblROOT_CAUSE_NOTES SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblROOT_CAUSE_NOTES] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblROOT_CAUSE_NOTES 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblROOT_CAUSE_NOTES
GO
