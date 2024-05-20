SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblGERM_CELL_NON_CNS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblGERM_CELL_NON_CNS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblGERM_CELL_NON_CNS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblGERM_CELL_NON_CNS
GO
