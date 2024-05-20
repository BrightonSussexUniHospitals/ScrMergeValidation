SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblAO_UKONS_SCORE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblAO_UKONS_SCORE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblAO_UKONS_SCORE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblAO_UKONS_SCORE
GO
