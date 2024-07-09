SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the RDCOtherTestHelper1 SCR table 
CREATE VIEW [Merge_DM_MatchViews].[RDCOtherTestHelper1] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.RDCOtherTestHelper1 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.RDCOtherTestHelper1
GO
