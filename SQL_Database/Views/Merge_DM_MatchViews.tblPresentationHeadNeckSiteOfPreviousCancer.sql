SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblPresentationHeadNeckSiteOfPreviousCancer SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblPresentationHeadNeckSiteOfPreviousCancer] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblPresentationHeadNeckSiteOfPreviousCancer 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblPresentationHeadNeckSiteOfPreviousCancer
GO
