SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the expROOT_HELPER_1 SCR table 
CREATE VIEW [Merge_DM_MatchViews].[expROOT_HELPER_1] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.expROOT_HELPER_1 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.expROOT_HELPER_1
GO
