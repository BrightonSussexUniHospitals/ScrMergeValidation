SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblPADUA_EXOPHYTIC SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblPADUA_EXOPHYTIC] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblPADUA_EXOPHYTIC 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblPADUA_EXOPHYTIC
GO
