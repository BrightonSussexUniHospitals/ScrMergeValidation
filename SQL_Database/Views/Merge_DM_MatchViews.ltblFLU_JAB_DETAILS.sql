SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblFLU_JAB_DETAILS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblFLU_JAB_DETAILS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblFLU_JAB_DETAILS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblFLU_JAB_DETAILS
GO
