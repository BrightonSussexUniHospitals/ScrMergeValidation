SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblREFERRAL_HEAD_NECK_SYMP_SITE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblREFERRAL_HEAD_NECK_SYMP_SITE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblREFERRAL_HEAD_NECK_SYMP_SITE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblREFERRAL_HEAD_NECK_SYMP_SITE
GO
