SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblPresentationHeadNeckSiteOfPreviousCancer SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblPresentationHeadNeckSiteOfPreviousCancer] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblPresentationHeadNeckSiteOfPreviousCancer 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblPresentationHeadNeckSiteOfPreviousCancer
GO
