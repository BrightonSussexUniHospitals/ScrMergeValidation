SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpNBOCAP_PATIENT SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpNBOCAP_PATIENT] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tmpNBOCAP_PATIENT 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tmpNBOCAP_PATIENT
GO
