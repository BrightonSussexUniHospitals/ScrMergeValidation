SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblCHEMOTHERAPY_GYNAECOLOGY SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblCHEMOTHERAPY_GYNAECOLOGY] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblCHEMOTHERAPY_GYNAECOLOGY 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblCHEMOTHERAPY_GYNAECOLOGY
GO
