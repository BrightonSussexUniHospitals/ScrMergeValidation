SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblSURGICAL_ACCESS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblSURGICAL_ACCESS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblSURGICAL_ACCESS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblSURGICAL_ACCESS
GO
