SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the lnkReferralSymptoms SCR table 
CREATE VIEW [Merge_DM_MatchViews].[lnkReferralSymptoms] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.lnkReferralSymptoms 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.lnkReferralSymptoms
GO
