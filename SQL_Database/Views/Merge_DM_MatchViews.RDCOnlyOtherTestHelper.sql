SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the RDCOnlyOtherTestHelper SCR table 
CREATE VIEW [Merge_DM_MatchViews].[RDCOnlyOtherTestHelper] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.RDCOnlyOtherTestHelper 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.RDCOnlyOtherTestHelper
GO
