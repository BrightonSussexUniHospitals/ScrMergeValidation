SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblINITIAL_ASSESSMENT SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblINITIAL_ASSESSMENT] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblINITIAL_ASSESSMENT 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblINITIAL_ASSESSMENT
GO
