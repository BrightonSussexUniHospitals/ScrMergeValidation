SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblFAVOURABLE_UNFAVOURABLE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblFAVOURABLE_UNFAVOURABLE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblFAVOURABLE_UNFAVOURABLE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblFAVOURABLE_UNFAVOURABLE
GO
