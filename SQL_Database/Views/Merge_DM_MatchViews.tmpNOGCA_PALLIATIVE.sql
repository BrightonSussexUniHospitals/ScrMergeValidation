SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpNOGCA_PALLIATIVE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpNOGCA_PALLIATIVE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tmpNOGCA_PALLIATIVE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tmpNOGCA_PALLIATIVE
GO
