SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblPATHOLOGY_SARCOMA SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblPATHOLOGY_SARCOMA] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblPATHOLOGY_SARCOMA 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblPATHOLOGY_SARCOMA
GO
