SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpHANAPATH_First_Dietitian_Before_TX SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tmpHANAPATH_First_Dietitian_Before_TX] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tmpHANAPATH_First_Dietitian_Before_TX 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tmpHANAPATH_First_Dietitian_Before_TX
GO
