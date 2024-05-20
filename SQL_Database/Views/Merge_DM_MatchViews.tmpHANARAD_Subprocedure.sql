SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpHANARAD_Subprocedure SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpHANARAD_Subprocedure] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tmpHANARAD_Subprocedure 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tmpHANARAD_Subprocedure
GO
