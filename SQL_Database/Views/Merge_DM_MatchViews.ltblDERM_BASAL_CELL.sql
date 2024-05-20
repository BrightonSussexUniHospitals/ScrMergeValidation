SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblDERM_BASAL_CELL SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblDERM_BASAL_CELL] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblDERM_BASAL_CELL 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblDERM_BASAL_CELL
GO
