SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblPAT_RECEIVED_TREATMENT_SUMMARY SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblPAT_RECEIVED_TREATMENT_SUMMARY] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblPAT_RECEIVED_TREATMENT_SUMMARY 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblPAT_RECEIVED_TREATMENT_SUMMARY
GO
