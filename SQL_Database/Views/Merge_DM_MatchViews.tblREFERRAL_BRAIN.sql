SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblREFERRAL_BRAIN SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblREFERRAL_BRAIN] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblREFERRAL_BRAIN 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblREFERRAL_BRAIN
GO
