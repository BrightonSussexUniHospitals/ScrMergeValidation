SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblDENTAL_TREATMENT SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblDENTAL_TREATMENT] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblDENTAL_TREATMENT 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblDENTAL_TREATMENT
GO
