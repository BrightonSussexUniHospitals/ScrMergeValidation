SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblUSER_DEPARTMENT SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblUSER_DEPARTMENT] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblUSER_DEPARTMENT 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblUSER_DEPARTMENT
GO
