SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblCHILD_PUGH_SCORE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblCHILD_PUGH_SCORE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblCHILD_PUGH_SCORE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblCHILD_PUGH_SCORE
GO
