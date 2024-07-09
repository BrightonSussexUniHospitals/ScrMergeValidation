SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblSURGERY_UPPER_GI SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblSURGERY_UPPER_GI] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblSURGERY_UPPER_GI 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblSURGERY_UPPER_GI
GO
