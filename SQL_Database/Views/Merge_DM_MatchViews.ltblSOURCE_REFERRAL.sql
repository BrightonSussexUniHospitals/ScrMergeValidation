SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblSOURCE_REFERRAL SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblSOURCE_REFERRAL] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblSOURCE_REFERRAL 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblSOURCE_REFERRAL
GO
