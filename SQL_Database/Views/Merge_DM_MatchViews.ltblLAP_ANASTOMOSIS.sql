SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblLAP_ANASTOMOSIS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblLAP_ANASTOMOSIS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblLAP_ANASTOMOSIS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblLAP_ANASTOMOSIS
GO
