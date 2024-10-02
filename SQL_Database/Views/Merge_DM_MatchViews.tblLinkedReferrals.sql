SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblLinkedReferrals SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblLinkedReferrals] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblLinkedReferrals 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblLinkedReferrals
GO
