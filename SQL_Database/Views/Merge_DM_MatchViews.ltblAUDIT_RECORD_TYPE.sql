SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblAUDIT_RECORD_TYPE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblAUDIT_RECORD_TYPE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblAUDIT_RECORD_TYPE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblAUDIT_RECORD_TYPE
GO
