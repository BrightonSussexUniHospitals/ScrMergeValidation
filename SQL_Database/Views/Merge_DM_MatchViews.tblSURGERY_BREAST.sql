SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblSURGERY_BREAST SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblSURGERY_BREAST] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblSURGERY_BREAST 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblSURGERY_BREAST
GO
