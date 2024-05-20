SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblCOLO_LOCAL_INVASION SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblCOLO_LOCAL_INVASION] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblCOLO_LOCAL_INVASION 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblCOLO_LOCAL_INVASION
GO
