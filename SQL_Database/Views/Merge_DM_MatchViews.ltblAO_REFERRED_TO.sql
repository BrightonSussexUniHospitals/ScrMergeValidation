SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblAO_REFERRED_TO SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblAO_REFERRED_TO] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblAO_REFERRED_TO 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblAO_REFERRED_TO
GO
