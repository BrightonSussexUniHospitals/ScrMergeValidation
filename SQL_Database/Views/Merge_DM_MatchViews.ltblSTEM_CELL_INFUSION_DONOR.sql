SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblSTEM_CELL_INFUSION_DONOR SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblSTEM_CELL_INFUSION_DONOR] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblSTEM_CELL_INFUSION_DONOR 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblSTEM_CELL_INFUSION_DONOR
GO
