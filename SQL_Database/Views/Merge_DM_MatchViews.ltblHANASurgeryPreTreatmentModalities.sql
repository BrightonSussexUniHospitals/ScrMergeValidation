SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblHANASurgeryPreTreatmentModalities SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblHANASurgeryPreTreatmentModalities] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblHANASurgeryPreTreatmentModalities 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblHANASurgeryPreTreatmentModalities
GO
