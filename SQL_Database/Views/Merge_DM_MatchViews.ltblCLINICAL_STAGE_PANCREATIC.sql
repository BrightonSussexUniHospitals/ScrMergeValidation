SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblCLINICAL_STAGE_PANCREATIC SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblCLINICAL_STAGE_PANCREATIC] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblCLINICAL_STAGE_PANCREATIC 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblCLINICAL_STAGE_PANCREATIC
GO
