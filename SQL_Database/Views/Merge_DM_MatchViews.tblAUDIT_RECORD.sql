SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblAUDIT_RECORD SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblAUDIT_RECORD] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblAUDIT_RECORD 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblAUDIT_RECORD
GO
