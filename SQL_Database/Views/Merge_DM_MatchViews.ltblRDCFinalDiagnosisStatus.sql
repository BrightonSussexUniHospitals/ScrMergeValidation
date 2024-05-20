SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblRDCFinalDiagnosisStatus SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblRDCFinalDiagnosisStatus] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblRDCFinalDiagnosisStatus 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblRDCFinalDiagnosisStatus
GO
