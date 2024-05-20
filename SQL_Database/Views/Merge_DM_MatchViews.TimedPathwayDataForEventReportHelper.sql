SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the TimedPathwayDataForEventReportHelper SCR table 
CREATE VIEW [Merge_DM_MatchViews].[TimedPathwayDataForEventReportHelper] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.TimedPathwayDataForEventReportHelper 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.TimedPathwayDataForEventReportHelper
GO
