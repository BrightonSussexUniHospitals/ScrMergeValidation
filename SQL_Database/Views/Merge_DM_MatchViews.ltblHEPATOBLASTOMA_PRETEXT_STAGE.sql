SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblHEPATOBLASTOMA_PRETEXT_STAGE SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblHEPATOBLASTOMA_PRETEXT_STAGE] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblHEPATOBLASTOMA_PRETEXT_STAGE 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblHEPATOBLASTOMA_PRETEXT_STAGE
GO
