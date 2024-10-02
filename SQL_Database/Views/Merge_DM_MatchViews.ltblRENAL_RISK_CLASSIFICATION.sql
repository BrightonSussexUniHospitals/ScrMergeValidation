SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblRENAL_RISK_CLASSIFICATION SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblRENAL_RISK_CLASSIFICATION] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblRENAL_RISK_CLASSIFICATION 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblRENAL_RISK_CLASSIFICATION
GO
