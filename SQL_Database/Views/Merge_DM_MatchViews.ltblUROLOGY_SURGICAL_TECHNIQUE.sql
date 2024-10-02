SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblUROLOGY_SURGICAL_TECHNIQUE SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblUROLOGY_SURGICAL_TECHNIQUE] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblUROLOGY_SURGICAL_TECHNIQUE 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblUROLOGY_SURGICAL_TECHNIQUE
GO
