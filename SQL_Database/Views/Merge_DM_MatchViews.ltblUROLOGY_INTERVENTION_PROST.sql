SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblUROLOGY_INTERVENTION_PROST SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblUROLOGY_INTERVENTION_PROST] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblUROLOGY_INTERVENTION_PROST 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblUROLOGY_INTERVENTION_PROST
GO
