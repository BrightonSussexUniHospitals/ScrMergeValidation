SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpHANAPATH_First_Palliative SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpHANAPATH_First_Palliative] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tmpHANAPATH_First_Palliative 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tmpHANAPATH_First_Palliative
GO
