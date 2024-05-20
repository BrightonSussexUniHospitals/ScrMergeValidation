SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblUGI_REC_DIAG SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblUGI_REC_DIAG] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblUGI_REC_DIAG 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblUGI_REC_DIAG
GO
