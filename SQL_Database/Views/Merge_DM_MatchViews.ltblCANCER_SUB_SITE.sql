SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblCANCER_SUB_SITE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblCANCER_SUB_SITE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblCANCER_SUB_SITE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblCANCER_SUB_SITE
GO
