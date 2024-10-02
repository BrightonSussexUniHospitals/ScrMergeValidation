SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblDeathCauseLaterDate SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblDeathCauseLaterDate] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblDeathCauseLaterDate 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblDeathCauseLaterDate
GO
