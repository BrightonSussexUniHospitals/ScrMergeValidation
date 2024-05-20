SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the lnkPAL_REASON_REFERRAL_NEW SCR table 
CREATE VIEW [Merge_DM_MatchViews].[lnkPAL_REASON_REFERRAL_NEW] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.lnkPAL_REASON_REFERRAL_NEW 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.lnkPAL_REASON_REFERRAL_NEW
GO
