SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblChangeInLevelOfCare SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblChangeInLevelOfCare] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblChangeInLevelOfCare 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblChangeInLevelOfCare
GO
