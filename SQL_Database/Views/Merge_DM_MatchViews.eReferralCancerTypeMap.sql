SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the eReferralCancerTypeMap SCR table 
CREATE VIEW [Merge_DM_MatchViews].[eReferralCancerTypeMap] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.eReferralCancerTypeMap 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.eReferralCancerTypeMap
GO
