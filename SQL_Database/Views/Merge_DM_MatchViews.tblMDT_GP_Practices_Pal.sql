SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblMDT_GP_Practices_Pal SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblMDT_GP_Practices_Pal] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblMDT_GP_Practices_Pal 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblMDT_GP_Practices_Pal
GO
