SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblHN_PROCEDURE_SITE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblHN_PROCEDURE_SITE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblHN_PROCEDURE_SITE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblHN_PROCEDURE_SITE
GO
