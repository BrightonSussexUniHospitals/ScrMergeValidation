SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblTREATMENT_SUMMARY_PUBLISHED_CNS_REFERRALS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblTREATMENT_SUMMARY_PUBLISHED_CNS_REFERRALS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblTREATMENT_SUMMARY_PUBLISHED_CNS_REFERRALS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblTREATMENT_SUMMARY_PUBLISHED_CNS_REFERRALS
GO
