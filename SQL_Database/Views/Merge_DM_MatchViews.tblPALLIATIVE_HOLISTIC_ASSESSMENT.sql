SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblPALLIATIVE_HOLISTIC_ASSESSMENT SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblPALLIATIVE_HOLISTIC_ASSESSMENT] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblPALLIATIVE_HOLISTIC_ASSESSMENT 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblPALLIATIVE_HOLISTIC_ASSESSMENT
GO
