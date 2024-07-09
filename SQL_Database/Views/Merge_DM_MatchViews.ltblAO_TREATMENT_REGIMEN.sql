SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblAO_TREATMENT_REGIMEN SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblAO_TREATMENT_REGIMEN] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblAO_TREATMENT_REGIMEN 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblAO_TREATMENT_REGIMEN
GO
