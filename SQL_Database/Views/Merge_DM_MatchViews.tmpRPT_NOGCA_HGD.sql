SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpRPT_NOGCA_HGD SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpRPT_NOGCA_HGD] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tmpRPT_NOGCA_HGD 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tmpRPT_NOGCA_HGD
GO
