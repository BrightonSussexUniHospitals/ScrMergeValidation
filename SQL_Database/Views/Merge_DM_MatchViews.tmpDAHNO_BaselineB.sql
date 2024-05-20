SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tmpDAHNO_BaselineB SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tmpDAHNO_BaselineB] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tmpDAHNO_BaselineB 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tmpDAHNO_BaselineB
GO
