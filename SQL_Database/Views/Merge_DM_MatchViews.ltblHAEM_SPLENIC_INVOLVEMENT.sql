SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblHAEM_SPLENIC_INVOLVEMENT SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblHAEM_SPLENIC_INVOLVEMENT] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblHAEM_SPLENIC_INVOLVEMENT 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblHAEM_SPLENIC_INVOLVEMENT
GO
