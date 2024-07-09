SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblUGI_TUMOUR_TYPE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblUGI_TUMOUR_TYPE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblUGI_TUMOUR_TYPE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblUGI_TUMOUR_TYPE
GO
