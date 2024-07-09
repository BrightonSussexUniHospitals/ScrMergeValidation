SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblTREATMENT_SUMMARY_AIM SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblTREATMENT_SUMMARY_AIM] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblTREATMENT_SUMMARY_AIM 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblTREATMENT_SUMMARY_AIM
GO
