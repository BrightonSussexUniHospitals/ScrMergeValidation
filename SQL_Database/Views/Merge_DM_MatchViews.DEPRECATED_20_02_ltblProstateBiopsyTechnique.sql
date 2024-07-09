SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the DEPRECATED_20_02_ltblProstateBiopsyTechnique SCR table 
CREATE VIEW [Merge_DM_MatchViews].[DEPRECATED_20_02_ltblProstateBiopsyTechnique] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.DEPRECATED_20_02_ltblProstateBiopsyTechnique 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.DEPRECATED_20_02_ltblProstateBiopsyTechnique
GO
