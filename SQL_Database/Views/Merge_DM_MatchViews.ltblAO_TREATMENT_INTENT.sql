SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblAO_TREATMENT_INTENT SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblAO_TREATMENT_INTENT] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblAO_TREATMENT_INTENT 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblAO_TREATMENT_INTENT
GO
