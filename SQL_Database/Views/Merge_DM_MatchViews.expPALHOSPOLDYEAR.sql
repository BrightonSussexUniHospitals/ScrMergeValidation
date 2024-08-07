SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the expPALHOSPOLDYEAR SCR table 
CREATE VIEW [Merge_DM_MatchViews].[expPALHOSPOLDYEAR] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.expPALHOSPOLDYEAR 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.expPALHOSPOLDYEAR
GO
