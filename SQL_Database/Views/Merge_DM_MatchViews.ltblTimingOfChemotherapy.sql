SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblTimingOfChemotherapy SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblTimingOfChemotherapy] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblTimingOfChemotherapy 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblTimingOfChemotherapy
GO
