SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblHGD_REFERRAL_ROUTE SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblHGD_REFERRAL_ROUTE] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblHGD_REFERRAL_ROUTE 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblHGD_REFERRAL_ROUTE
GO
