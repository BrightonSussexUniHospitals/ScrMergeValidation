SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblSelectedMDTsToOutput SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblSelectedMDTsToOutput] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblSelectedMDTsToOutput 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblSelectedMDTsToOutput
GO
