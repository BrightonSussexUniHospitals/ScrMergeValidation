SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpHANAPATH_First_Care_Plan_Agreed_At_MDT SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpHANAPATH_First_Care_Plan_Agreed_At_MDT] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tmpHANAPATH_First_Care_Plan_Agreed_At_MDT 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tmpHANAPATH_First_Care_Plan_Agreed_At_MDT
GO
