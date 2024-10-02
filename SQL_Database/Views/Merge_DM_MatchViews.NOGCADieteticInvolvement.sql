SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the NOGCADieteticInvolvement SCR table 

CREATE VIEW [Merge_DM_MatchViews].[NOGCADieteticInvolvement] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.NOGCADieteticInvolvement 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.NOGCADieteticInvolvement
GO
