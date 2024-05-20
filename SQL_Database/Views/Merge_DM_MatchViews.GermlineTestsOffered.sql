SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the GermlineTestsOffered SCR table 
CREATE VIEW [Merge_DM_MatchViews].[GermlineTestsOffered] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.GermlineTestsOffered 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.GermlineTestsOffered
GO
