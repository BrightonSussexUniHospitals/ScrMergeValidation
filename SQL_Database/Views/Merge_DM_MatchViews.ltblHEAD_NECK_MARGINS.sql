SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblHEAD_NECK_MARGINS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblHEAD_NECK_MARGINS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblHEAD_NECK_MARGINS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblHEAD_NECK_MARGINS
GO
