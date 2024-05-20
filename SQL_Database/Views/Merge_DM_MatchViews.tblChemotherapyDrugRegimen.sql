SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblChemotherapyDrugRegimen SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblChemotherapyDrugRegimen] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblChemotherapyDrugRegimen 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblChemotherapyDrugRegimen
GO
