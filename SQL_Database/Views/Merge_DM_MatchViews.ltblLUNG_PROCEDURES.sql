SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblLUNG_PROCEDURES SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblLUNG_PROCEDURES] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblLUNG_PROCEDURES 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblLUNG_PROCEDURES
GO
