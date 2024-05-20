SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the expPALDCCURRYEAR SCR table 
CREATE VIEW [Merge_DM_MatchViews].[expPALDCCURRYEAR] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.expPALDCCURRYEAR 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.expPALDCCURRYEAR
GO
