SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblUGI_PAL_TREAT_REASON SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblUGI_PAL_TREAT_REASON] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblUGI_PAL_TREAT_REASON 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblUGI_PAL_TREAT_REASON
GO
