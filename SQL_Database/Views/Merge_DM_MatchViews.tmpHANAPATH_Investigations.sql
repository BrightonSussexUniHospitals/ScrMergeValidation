SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpHANAPATH_Investigations SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tmpHANAPATH_Investigations] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tmpHANAPATH_Investigations 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tmpHANAPATH_Investigations
GO
