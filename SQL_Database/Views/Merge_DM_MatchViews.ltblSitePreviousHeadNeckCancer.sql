SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblSitePreviousHeadNeckCancer SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblSitePreviousHeadNeckCancer] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblSitePreviousHeadNeckCancer 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblSitePreviousHeadNeckCancer
GO
