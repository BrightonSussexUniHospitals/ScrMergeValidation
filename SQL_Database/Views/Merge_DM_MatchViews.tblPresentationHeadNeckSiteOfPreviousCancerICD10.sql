SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblPresentationHeadNeckSiteOfPreviousCancerICD10 SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblPresentationHeadNeckSiteOfPreviousCancerICD10] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblPresentationHeadNeckSiteOfPreviousCancerICD10 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblPresentationHeadNeckSiteOfPreviousCancerICD10
GO
