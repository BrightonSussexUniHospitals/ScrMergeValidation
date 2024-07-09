SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblURO_DELAY_DIAG SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblURO_DELAY_DIAG] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblURO_DELAY_DIAG 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblURO_DELAY_DIAG
GO
