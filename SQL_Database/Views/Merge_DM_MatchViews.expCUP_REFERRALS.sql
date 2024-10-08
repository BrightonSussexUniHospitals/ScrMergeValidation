SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the expCUP_REFERRALS SCR table 

CREATE VIEW [Merge_DM_MatchViews].[expCUP_REFERRALS] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.expCUP_REFERRALS 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.expCUP_REFERRALS
GO
