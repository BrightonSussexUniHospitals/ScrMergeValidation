SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblANN_ARBOR_BULK SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblANN_ARBOR_BULK] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblANN_ARBOR_BULK 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblANN_ARBOR_BULK
GO
