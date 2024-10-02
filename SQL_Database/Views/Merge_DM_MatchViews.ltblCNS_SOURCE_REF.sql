SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblCNS_SOURCE_REF SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblCNS_SOURCE_REF] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblCNS_SOURCE_REF 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblCNS_SOURCE_REF
GO
