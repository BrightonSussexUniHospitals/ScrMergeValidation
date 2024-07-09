SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblPALLIATIVE_MDT SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblPALLIATIVE_MDT] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblPALLIATIVE_MDT 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblPALLIATIVE_MDT
GO
