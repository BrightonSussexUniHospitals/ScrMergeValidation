SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the expPALCCS3ADMITDATAEXISTING SCR table 

CREATE VIEW [Merge_DM_MatchViews].[expPALCCS3ADMITDATAEXISTING] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.expPALCCS3ADMITDATAEXISTING 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.expPALCCS3ADMITDATAEXISTING
GO
