SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the CarePlanCompletedBy SCR table 

CREATE VIEW [Merge_DM_MatchViews].[CarePlanCompletedBy] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.CarePlanCompletedBy 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.CarePlanCompletedBy
GO
