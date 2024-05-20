SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblCLINICIAN_GRADE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblCLINICIAN_GRADE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblCLINICIAN_GRADE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblCLINICIAN_GRADE
GO
