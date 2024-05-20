SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblSitePreviousHeadNeckCancerICD10 SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblSitePreviousHeadNeckCancerICD10] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblSitePreviousHeadNeckCancerICD10 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblSitePreviousHeadNeckCancerICD10
GO
