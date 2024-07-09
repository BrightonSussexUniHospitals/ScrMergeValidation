SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpHANAPATH_Last_TX_B4_Chemo SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpHANAPATH_Last_TX_B4_Chemo] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tmpHANAPATH_Last_TX_B4_Chemo 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tmpHANAPATH_Last_TX_B4_Chemo
GO
