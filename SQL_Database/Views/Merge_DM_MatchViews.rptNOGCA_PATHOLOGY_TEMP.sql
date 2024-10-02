SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the rptNOGCA_PATHOLOGY_TEMP SCR table 

CREATE VIEW [Merge_DM_MatchViews].[rptNOGCA_PATHOLOGY_TEMP] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.rptNOGCA_PATHOLOGY_TEMP 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.rptNOGCA_PATHOLOGY_TEMP
GO
