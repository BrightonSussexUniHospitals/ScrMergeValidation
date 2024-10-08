SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the MacmillanValidTransitions SCR table 

CREATE VIEW [Merge_DM_MatchViews].[MacmillanValidTransitions] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.MacmillanValidTransitions 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.MacmillanValidTransitions
GO
