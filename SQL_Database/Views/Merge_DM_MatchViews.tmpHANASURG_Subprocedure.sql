SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpHANASURG_Subprocedure SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpHANASURG_Subprocedure] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tmpHANASURG_Subprocedure 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tmpHANASURG_Subprocedure
GO
