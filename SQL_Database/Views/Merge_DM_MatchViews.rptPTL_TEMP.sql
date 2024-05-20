SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the rptPTL_TEMP SCR table 
CREATE VIEW [Merge_DM_MatchViews].[rptPTL_TEMP] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.rptPTL_TEMP 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.rptPTL_TEMP
GO
