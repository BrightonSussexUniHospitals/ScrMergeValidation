SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblCNS_SECOND_REF SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblCNS_SECOND_REF] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblCNS_SECOND_REF 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblCNS_SECOND_REF
GO
