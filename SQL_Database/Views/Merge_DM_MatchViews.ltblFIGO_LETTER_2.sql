SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblFIGO_LETTER_2 SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblFIGO_LETTER_2] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblFIGO_LETTER_2 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblFIGO_LETTER_2
GO
