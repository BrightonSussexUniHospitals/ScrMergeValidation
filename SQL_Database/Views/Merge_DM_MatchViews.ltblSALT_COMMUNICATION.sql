SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblSALT_COMMUNICATION SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblSALT_COMMUNICATION] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblSALT_COMMUNICATION 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblSALT_COMMUNICATION
GO
