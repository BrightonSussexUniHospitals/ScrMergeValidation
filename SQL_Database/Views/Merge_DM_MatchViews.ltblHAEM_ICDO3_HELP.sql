SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblHAEM_ICDO3_HELP SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblHAEM_ICDO3_HELP] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblHAEM_ICDO3_HELP 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblHAEM_ICDO3_HELP
GO
