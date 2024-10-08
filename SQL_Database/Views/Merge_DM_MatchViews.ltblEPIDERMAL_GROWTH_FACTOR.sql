SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblEPIDERMAL_GROWTH_FACTOR SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblEPIDERMAL_GROWTH_FACTOR] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblEPIDERMAL_GROWTH_FACTOR 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblEPIDERMAL_GROWTH_FACTOR
GO
