SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblSCORE_BARTHEL SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblSCORE_BARTHEL] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblSCORE_BARTHEL 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblSCORE_BARTHEL
GO
