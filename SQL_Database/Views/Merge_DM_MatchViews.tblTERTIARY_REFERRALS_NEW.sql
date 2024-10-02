SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblTERTIARY_REFERRALS_NEW SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblTERTIARY_REFERRALS_NEW] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblTERTIARY_REFERRALS_NEW 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblTERTIARY_REFERRALS_NEW
GO
