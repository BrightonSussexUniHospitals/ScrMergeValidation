SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblPAL_REF_PRIORITY SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblPAL_REF_PRIORITY] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblPAL_REF_PRIORITY 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblPAL_REF_PRIORITY
GO
