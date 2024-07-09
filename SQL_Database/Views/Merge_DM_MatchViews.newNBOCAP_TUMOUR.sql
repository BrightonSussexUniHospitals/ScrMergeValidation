SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the newNBOCAP_TUMOUR SCR table 
CREATE VIEW [Merge_DM_MatchViews].[newNBOCAP_TUMOUR] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.newNBOCAP_TUMOUR 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.newNBOCAP_TUMOUR
GO
