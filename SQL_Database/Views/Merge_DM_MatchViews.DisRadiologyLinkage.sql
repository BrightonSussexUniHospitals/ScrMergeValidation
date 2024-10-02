SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the DisRadiologyLinkage SCR table 

CREATE VIEW [Merge_DM_MatchViews].[DisRadiologyLinkage] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.DisRadiologyLinkage 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.DisRadiologyLinkage
GO
