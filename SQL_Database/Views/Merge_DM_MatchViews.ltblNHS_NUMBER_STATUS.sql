SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblNHS_NUMBER_STATUS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblNHS_NUMBER_STATUS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblNHS_NUMBER_STATUS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblNHS_NUMBER_STATUS
GO
