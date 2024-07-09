SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the expCUP_CARE_PLAN SCR table 
CREATE VIEW [Merge_DM_MatchViews].[expCUP_CARE_PLAN] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.expCUP_CARE_PLAN 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.expCUP_CARE_PLAN
GO
