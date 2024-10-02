SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblConduitNecrosisFailure SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblConduitNecrosisFailure] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblConduitNecrosisFailure 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblConduitNecrosisFailure
GO
