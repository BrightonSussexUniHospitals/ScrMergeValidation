SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblNON_SMALL_CELL_TYPE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblNON_SMALL_CELL_TYPE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblNON_SMALL_CELL_TYPE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblNON_SMALL_CELL_TYPE
GO
