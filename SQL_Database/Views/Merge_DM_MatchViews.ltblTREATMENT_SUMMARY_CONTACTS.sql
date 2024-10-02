SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblTREATMENT_SUMMARY_CONTACTS SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblTREATMENT_SUMMARY_CONTACTS] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblTREATMENT_SUMMARY_CONTACTS 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblTREATMENT_SUMMARY_CONTACTS
GO
