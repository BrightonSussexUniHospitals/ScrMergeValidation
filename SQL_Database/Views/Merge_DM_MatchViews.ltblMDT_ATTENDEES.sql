SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblMDT_ATTENDEES SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblMDT_ATTENDEES] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblMDT_ATTENDEES 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblMDT_ATTENDEES
GO
