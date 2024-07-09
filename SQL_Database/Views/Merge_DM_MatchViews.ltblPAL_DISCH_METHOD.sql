SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblPAL_DISCH_METHOD SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblPAL_DISCH_METHOD] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblPAL_DISCH_METHOD 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblPAL_DISCH_METHOD
GO
