SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the bktblINITIAL_PAEDIATRICS SCR table 

CREATE VIEW [Merge_DM_MatchViews].[bktblINITIAL_PAEDIATRICS] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.bktblINITIAL_PAEDIATRICS 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.bktblINITIAL_PAEDIATRICS
GO
