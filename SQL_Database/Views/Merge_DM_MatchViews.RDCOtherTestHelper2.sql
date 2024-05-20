SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the RDCOtherTestHelper2 SCR table 
CREATE VIEW [Merge_DM_MatchViews].[RDCOtherTestHelper2] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.RDCOtherTestHelper2 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.RDCOtherTestHelper2
GO
