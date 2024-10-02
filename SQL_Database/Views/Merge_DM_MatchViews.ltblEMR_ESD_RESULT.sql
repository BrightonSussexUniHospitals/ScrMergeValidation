SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblEMR_ESD_RESULT SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblEMR_ESD_RESULT] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblEMR_ESD_RESULT 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblEMR_ESD_RESULT
GO
