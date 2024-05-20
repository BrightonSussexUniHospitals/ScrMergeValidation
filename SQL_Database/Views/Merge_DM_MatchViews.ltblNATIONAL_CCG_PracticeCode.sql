SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblNATIONAL_CCG_PracticeCode SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblNATIONAL_CCG_PracticeCode] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblNATIONAL_CCG_PracticeCode 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblNATIONAL_CCG_PracticeCode
GO
