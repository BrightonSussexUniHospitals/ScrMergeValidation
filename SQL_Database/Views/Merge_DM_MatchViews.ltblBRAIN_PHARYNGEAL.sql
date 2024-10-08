SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblBRAIN_PHARYNGEAL SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblBRAIN_PHARYNGEAL] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblBRAIN_PHARYNGEAL 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblBRAIN_PHARYNGEAL
GO
