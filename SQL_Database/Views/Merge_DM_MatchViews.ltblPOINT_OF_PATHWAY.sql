SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblPOINT_OF_PATHWAY SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblPOINT_OF_PATHWAY] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblPOINT_OF_PATHWAY 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblPOINT_OF_PATHWAY
GO
