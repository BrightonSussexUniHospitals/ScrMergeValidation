SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblCOLORECTAL_TUMOUR_COMPS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblCOLORECTAL_TUMOUR_COMPS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblCOLORECTAL_TUMOUR_COMPS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblCOLORECTAL_TUMOUR_COMPS
GO
