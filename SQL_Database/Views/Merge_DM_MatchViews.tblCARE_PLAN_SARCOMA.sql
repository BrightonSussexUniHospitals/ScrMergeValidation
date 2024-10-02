SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblCARE_PLAN_SARCOMA SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblCARE_PLAN_SARCOMA] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblCARE_PLAN_SARCOMA 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblCARE_PLAN_SARCOMA
GO
