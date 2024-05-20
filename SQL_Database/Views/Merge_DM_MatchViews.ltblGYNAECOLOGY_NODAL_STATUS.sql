SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblGYNAECOLOGY_NODAL_STATUS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblGYNAECOLOGY_NODAL_STATUS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblGYNAECOLOGY_NODAL_STATUS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblGYNAECOLOGY_NODAL_STATUS
GO
