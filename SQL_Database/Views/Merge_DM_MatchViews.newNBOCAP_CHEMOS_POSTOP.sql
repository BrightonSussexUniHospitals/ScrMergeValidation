SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the newNBOCAP_CHEMOS_POSTOP SCR table 
CREATE VIEW [Merge_DM_MatchViews].[newNBOCAP_CHEMOS_POSTOP] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.newNBOCAP_CHEMOS_POSTOP 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.newNBOCAP_CHEMOS_POSTOP
GO
