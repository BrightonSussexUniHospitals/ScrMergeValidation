SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblTERTIARY_REFERRAL_PENDING_STATUS SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblTERTIARY_REFERRAL_PENDING_STATUS] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblTERTIARY_REFERRAL_PENDING_STATUS 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblTERTIARY_REFERRAL_PENDING_STATUS
GO
