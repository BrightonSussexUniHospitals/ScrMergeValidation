SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblADMINISTRATION_SERVICE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblADMINISTRATION_SERVICE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblADMINISTRATION_SERVICE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblADMINISTRATION_SERVICE
GO
