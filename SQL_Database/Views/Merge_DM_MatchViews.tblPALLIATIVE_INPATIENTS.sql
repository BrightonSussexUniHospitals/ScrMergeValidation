SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblPALLIATIVE_INPATIENTS SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblPALLIATIVE_INPATIENTS] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblPALLIATIVE_INPATIENTS 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblPALLIATIVE_INPATIENTS
GO
