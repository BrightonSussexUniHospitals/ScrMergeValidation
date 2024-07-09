SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpCOSDLiverCareIDs SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpCOSDLiverCareIDs] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tmpCOSDLiverCareIDs 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tmpCOSDLiverCareIDs
GO
