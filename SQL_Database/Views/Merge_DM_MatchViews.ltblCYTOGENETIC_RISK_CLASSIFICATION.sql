SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblCYTOGENETIC_RISK_CLASSIFICATION SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblCYTOGENETIC_RISK_CLASSIFICATION] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblCYTOGENETIC_RISK_CLASSIFICATION 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblCYTOGENETIC_RISK_CLASSIFICATION
GO
