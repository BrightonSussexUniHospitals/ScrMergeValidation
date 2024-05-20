SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblUROLOGY_SPARING SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblUROLOGY_SPARING] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblUROLOGY_SPARING 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblUROLOGY_SPARING
GO
