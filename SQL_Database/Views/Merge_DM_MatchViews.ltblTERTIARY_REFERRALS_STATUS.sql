SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblTERTIARY_REFERRALS_STATUS SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblTERTIARY_REFERRALS_STATUS] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblTERTIARY_REFERRALS_STATUS 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblTERTIARY_REFERRALS_STATUS
GO
