SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpBAUS_Surgery_IDs SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpBAUS_Surgery_IDs] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tmpBAUS_Surgery_IDs 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tmpBAUS_Surgery_IDs
GO
