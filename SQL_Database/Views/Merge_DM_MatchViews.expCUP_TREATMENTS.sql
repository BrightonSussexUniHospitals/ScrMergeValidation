SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the expCUP_TREATMENTS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[expCUP_TREATMENTS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.expCUP_TREATMENTS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.expCUP_TREATMENTS
GO
