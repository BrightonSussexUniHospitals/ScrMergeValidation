SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the CancerWaitingTimes SCR table 

CREATE VIEW [Merge_DM_MatchViews].[CancerWaitingTimes] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.CancerWaitingTimes 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.CancerWaitingTimes
GO
