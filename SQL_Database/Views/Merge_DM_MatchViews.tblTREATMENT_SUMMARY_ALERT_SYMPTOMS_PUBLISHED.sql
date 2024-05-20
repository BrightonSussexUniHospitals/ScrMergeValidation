SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblTREATMENT_SUMMARY_ALERT_SYMPTOMS_PUBLISHED SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblTREATMENT_SUMMARY_ALERT_SYMPTOMS_PUBLISHED] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblTREATMENT_SUMMARY_ALERT_SYMPTOMS_PUBLISHED 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblTREATMENT_SUMMARY_ALERT_SYMPTOMS_PUBLISHED
GO
