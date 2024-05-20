SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the BACKUP_ltblNBOCAP_PREFERRED_SURGERY_V18_02 SCR table 
CREATE VIEW [Merge_DM_MatchViews].[BACKUP_ltblNBOCAP_PREFERRED_SURGERY_V18_02] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.BACKUP_ltblNBOCAP_PREFERRED_SURGERY_V18_02 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.BACKUP_ltblNBOCAP_PREFERRED_SURGERY_V18_02
GO
