SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblChemotherapyToxicitySymptoms SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblChemotherapyToxicitySymptoms] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblChemotherapyToxicitySymptoms 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblChemotherapyToxicitySymptoms
GO
