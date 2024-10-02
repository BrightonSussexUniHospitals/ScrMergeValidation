SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblREFERRAL_PAEDIATRICS SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblREFERRAL_PAEDIATRICS] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblREFERRAL_PAEDIATRICS 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblREFERRAL_PAEDIATRICS
GO
