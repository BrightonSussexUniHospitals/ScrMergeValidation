SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblCHEMO_GIVEN SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblCHEMO_GIVEN] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblCHEMO_GIVEN 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblCHEMO_GIVEN
GO
