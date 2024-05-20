SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblTREATMENT_SUMMARY_PUBLISHED_TREATMENTS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblTREATMENT_SUMMARY_PUBLISHED_TREATMENTS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblTREATMENT_SUMMARY_PUBLISHED_TREATMENTS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblTREATMENT_SUMMARY_PUBLISHED_TREATMENTS
GO
