SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblGYNAE_EXTENSION SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblGYNAE_EXTENSION] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblGYNAE_EXTENSION 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblGYNAE_EXTENSION
GO
