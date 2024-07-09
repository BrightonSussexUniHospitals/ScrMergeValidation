SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblPALLIATIVE_TEACHING_NEW SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblPALLIATIVE_TEACHING_NEW] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblPALLIATIVE_TEACHING_NEW 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblPALLIATIVE_TEACHING_NEW
GO
