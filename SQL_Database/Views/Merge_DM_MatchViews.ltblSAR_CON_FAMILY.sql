SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblSAR_CON_FAMILY SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblSAR_CON_FAMILY] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblSAR_CON_FAMILY 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblSAR_CON_FAMILY
GO
