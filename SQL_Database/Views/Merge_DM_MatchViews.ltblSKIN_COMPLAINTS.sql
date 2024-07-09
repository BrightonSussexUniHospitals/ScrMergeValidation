SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblSKIN_COMPLAINTS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblSKIN_COMPLAINTS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblSKIN_COMPLAINTS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblSKIN_COMPLAINTS
GO
