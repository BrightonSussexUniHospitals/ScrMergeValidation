SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblSYMPTOMS_UPPER_GI SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblSYMPTOMS_UPPER_GI] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblSYMPTOMS_UPPER_GI 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblSYMPTOMS_UPPER_GI
GO
