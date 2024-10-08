SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblROOT_CAUSE_EVENTS SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblROOT_CAUSE_EVENTS] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblROOT_CAUSE_EVENTS 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblROOT_CAUSE_EVENTS
GO
