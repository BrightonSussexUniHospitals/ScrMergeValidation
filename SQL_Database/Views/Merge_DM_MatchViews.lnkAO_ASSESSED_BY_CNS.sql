SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the lnkAO_ASSESSED_BY_CNS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[lnkAO_ASSESSED_BY_CNS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.lnkAO_ASSESSED_BY_CNS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.lnkAO_ASSESSED_BY_CNS
GO
