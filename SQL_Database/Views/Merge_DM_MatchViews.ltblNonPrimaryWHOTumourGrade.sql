SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblNonPrimaryWHOTumourGrade SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblNonPrimaryWHOTumourGrade] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblNonPrimaryWHOTumourGrade 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblNonPrimaryWHOTumourGrade
GO
