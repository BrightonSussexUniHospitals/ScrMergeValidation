SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblGYNAECOLOGY_MDT SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblGYNAECOLOGY_MDT] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblGYNAECOLOGY_MDT 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblGYNAECOLOGY_MDT
GO
