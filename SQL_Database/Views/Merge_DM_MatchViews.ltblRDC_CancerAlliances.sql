SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblRDC_CancerAlliances SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblRDC_CancerAlliances] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblRDC_CancerAlliances 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblRDC_CancerAlliances
GO
