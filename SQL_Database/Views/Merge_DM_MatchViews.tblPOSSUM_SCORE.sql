SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblPOSSUM_SCORE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblPOSSUM_SCORE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblPOSSUM_SCORE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblPOSSUM_SCORE
GO
