SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblEXTRA_NODAL_METS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblEXTRA_NODAL_METS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblEXTRA_NODAL_METS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblEXTRA_NODAL_METS
GO
