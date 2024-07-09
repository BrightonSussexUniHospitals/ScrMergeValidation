SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpNOGCA_ONCOLOGY SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpNOGCA_ONCOLOGY] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tmpNOGCA_ONCOLOGY 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tmpNOGCA_ONCOLOGY
GO
