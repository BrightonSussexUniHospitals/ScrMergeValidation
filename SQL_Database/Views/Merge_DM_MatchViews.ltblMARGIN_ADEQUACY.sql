SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblMARGIN_ADEQUACY SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblMARGIN_ADEQUACY] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblMARGIN_ADEQUACY 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblMARGIN_ADEQUACY
GO
