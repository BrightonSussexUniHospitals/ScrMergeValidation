SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblDISEASE_CLASSIFICATION_PALLIATIVE SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblDISEASE_CLASSIFICATION_PALLIATIVE] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblDISEASE_CLASSIFICATION_PALLIATIVE 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblDISEASE_CLASSIFICATION_PALLIATIVE
GO
