SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblBARCELONA_CLINIC_STAGE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblBARCELONA_CLINIC_STAGE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblBARCELONA_CLINIC_STAGE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblBARCELONA_CLINIC_STAGE
GO
