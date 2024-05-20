SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the newNBOCAP_TUMOURS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[newNBOCAP_TUMOURS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.newNBOCAP_TUMOURS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.newNBOCAP_TUMOURS
GO
