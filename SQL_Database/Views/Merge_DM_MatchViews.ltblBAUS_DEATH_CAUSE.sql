SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblBAUS_DEATH_CAUSE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblBAUS_DEATH_CAUSE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblBAUS_DEATH_CAUSE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblBAUS_DEATH_CAUSE
GO
