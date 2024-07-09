SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the RDCCheckReportHelperSS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[RDCCheckReportHelperSS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.RDCCheckReportHelperSS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.RDCCheckReportHelperSS
GO
