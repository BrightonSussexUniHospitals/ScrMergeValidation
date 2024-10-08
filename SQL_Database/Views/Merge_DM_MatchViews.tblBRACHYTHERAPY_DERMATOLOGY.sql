SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblBRACHYTHERAPY_DERMATOLOGY SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblBRACHYTHERAPY_DERMATOLOGY] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblBRACHYTHERAPY_DERMATOLOGY 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblBRACHYTHERAPY_DERMATOLOGY
GO
