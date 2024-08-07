SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblREASON_PROSTATECTOMY_SURVEILLANCE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblREASON_PROSTATECTOMY_SURVEILLANCE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblREASON_PROSTATECTOMY_SURVEILLANCE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblREASON_PROSTATECTOMY_SURVEILLANCE
GO
