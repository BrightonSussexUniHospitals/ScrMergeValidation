SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblPresentationHeadNeckActualSiteOfSymptoms SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblPresentationHeadNeckActualSiteOfSymptoms] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblPresentationHeadNeckActualSiteOfSymptoms 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblPresentationHeadNeckActualSiteOfSymptoms
GO
