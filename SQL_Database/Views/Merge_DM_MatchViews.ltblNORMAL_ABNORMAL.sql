SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblNORMAL_ABNORMAL SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblNORMAL_ABNORMAL] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblNORMAL_ABNORMAL 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblNORMAL_ABNORMAL
GO
