SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the expNBOCAP_TREATMENT_TEMP SCR table 

CREATE VIEW [Merge_DM_MatchViews].[expNBOCAP_TREATMENT_TEMP] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.expNBOCAP_TREATMENT_TEMP 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.expNBOCAP_TREATMENT_TEMP
GO
