SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblHGD_TREATMENT_MODALITY SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblHGD_TREATMENT_MODALITY] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblHGD_TREATMENT_MODALITY 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblHGD_TREATMENT_MODALITY
GO
