SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the rptNMBRA_PATHOLOGY_TEMP SCR table 
CREATE VIEW [Merge_DM_MatchViews].[rptNMBRA_PATHOLOGY_TEMP] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.rptNMBRA_PATHOLOGY_TEMP 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.rptNMBRA_PATHOLOGY_TEMP
GO
