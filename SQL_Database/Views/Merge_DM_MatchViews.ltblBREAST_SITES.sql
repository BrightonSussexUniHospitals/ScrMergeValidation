SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblBREAST_SITES SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblBREAST_SITES] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblBREAST_SITES 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblBREAST_SITES
GO
