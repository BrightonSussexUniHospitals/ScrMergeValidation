SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblSymptomSiteReferralLetter SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblSymptomSiteReferralLetter] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblSymptomSiteReferralLetter 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblSymptomSiteReferralLetter
GO
