SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblDERM_DETERMINED SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblDERM_DETERMINED] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblDERM_DETERMINED 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblDERM_DETERMINED
GO
