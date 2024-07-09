SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblAHP_OTHER_ROLES SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblAHP_OTHER_ROLES] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblAHP_OTHER_ROLES 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblAHP_OTHER_ROLES
GO
