SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblREASON_PROSTATECTOMY SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblREASON_PROSTATECTOMY] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblREASON_PROSTATECTOMY 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblREASON_PROSTATECTOMY
GO
