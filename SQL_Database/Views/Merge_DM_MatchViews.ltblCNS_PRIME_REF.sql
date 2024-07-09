SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblCNS_PRIME_REF SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblCNS_PRIME_REF] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblCNS_PRIME_REF 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblCNS_PRIME_REF
GO
