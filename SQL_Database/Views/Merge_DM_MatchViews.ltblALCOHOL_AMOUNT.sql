SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblALCOHOL_AMOUNT SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblALCOHOL_AMOUNT] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblALCOHOL_AMOUNT 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblALCOHOL_AMOUNT
GO
