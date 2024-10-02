SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblSYMPTOMS_HEAD_NECK SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblSYMPTOMS_HEAD_NECK] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblSYMPTOMS_HEAD_NECK 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblSYMPTOMS_HEAD_NECK
GO
