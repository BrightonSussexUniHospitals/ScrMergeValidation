SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblPALLIATIVE_CONSENT_SECONDARY SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblPALLIATIVE_CONSENT_SECONDARY] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblPALLIATIVE_CONSENT_SECONDARY 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblPALLIATIVE_CONSENT_SECONDARY
GO
