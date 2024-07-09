SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the lnkAO_ASSESSED_BY_CNS_MSCC SCR table 
CREATE VIEW [Merge_DM_MatchViews].[lnkAO_ASSESSED_BY_CNS_MSCC] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.lnkAO_ASSESSED_BY_CNS_MSCC 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.lnkAO_ASSESSED_BY_CNS_MSCC
GO
