SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblIMAGING_MOD_GROUP SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblIMAGING_MOD_GROUP] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblIMAGING_MOD_GROUP 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblIMAGING_MOD_GROUP
GO
