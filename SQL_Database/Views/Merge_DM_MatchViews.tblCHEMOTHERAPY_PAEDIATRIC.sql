SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblCHEMOTHERAPY_PAEDIATRIC SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblCHEMOTHERAPY_PAEDIATRIC] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblCHEMOTHERAPY_PAEDIATRIC 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblCHEMOTHERAPY_PAEDIATRIC
GO
