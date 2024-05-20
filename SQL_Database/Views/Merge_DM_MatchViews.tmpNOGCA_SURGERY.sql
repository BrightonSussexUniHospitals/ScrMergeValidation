SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpNOGCA_SURGERY SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpNOGCA_SURGERY] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tmpNOGCA_SURGERY 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tmpNOGCA_SURGERY
GO
