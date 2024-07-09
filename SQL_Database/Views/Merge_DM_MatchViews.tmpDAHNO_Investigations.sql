SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpDAHNO_Investigations SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpDAHNO_Investigations] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tmpDAHNO_Investigations 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tmpDAHNO_Investigations
GO
