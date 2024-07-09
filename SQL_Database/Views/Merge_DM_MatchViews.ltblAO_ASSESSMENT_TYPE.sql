SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblAO_ASSESSMENT_TYPE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblAO_ASSESSMENT_TYPE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblAO_ASSESSMENT_TYPE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblAO_ASSESSMENT_TYPE
GO
