SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblNonPrimaryMetastases SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblNonPrimaryMetastases] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblNonPrimaryMetastases 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblNonPrimaryMetastases
GO
