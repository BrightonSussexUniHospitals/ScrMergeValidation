SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the NBCA_MAPPING_ADDITIONS SCR table 

CREATE VIEW [Merge_DM_MatchViews].[NBCA_MAPPING_ADDITIONS] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.NBCA_MAPPING_ADDITIONS 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.NBCA_MAPPING_ADDITIONS
GO
