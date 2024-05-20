SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblGYNAE_LATERAL SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblGYNAE_LATERAL] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblGYNAE_LATERAL 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblGYNAE_LATERAL
GO
