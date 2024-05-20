SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblIMAGING_OUTCOMES SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblIMAGING_OUTCOMES] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblIMAGING_OUTCOMES 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblIMAGING_OUTCOMES
GO
