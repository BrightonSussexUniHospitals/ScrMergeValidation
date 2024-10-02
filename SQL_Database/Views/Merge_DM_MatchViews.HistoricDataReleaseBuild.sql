SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the HistoricDataReleaseBuild SCR table 

CREATE VIEW [Merge_DM_MatchViews].[HistoricDataReleaseBuild] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.HistoricDataReleaseBuild 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.HistoricDataReleaseBuild
GO
