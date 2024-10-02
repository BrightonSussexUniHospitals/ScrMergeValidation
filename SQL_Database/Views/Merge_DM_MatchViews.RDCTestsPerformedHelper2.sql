SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the RDCTestsPerformedHelper2 SCR table 

CREATE VIEW [Merge_DM_MatchViews].[RDCTestsPerformedHelper2] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.RDCTestsPerformedHelper2 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.RDCTestsPerformedHelper2
GO
