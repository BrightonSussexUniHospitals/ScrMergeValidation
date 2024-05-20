SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblLAPAROSCOPIC SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblLAPAROSCOPIC] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblLAPAROSCOPIC 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblLAPAROSCOPIC
GO
