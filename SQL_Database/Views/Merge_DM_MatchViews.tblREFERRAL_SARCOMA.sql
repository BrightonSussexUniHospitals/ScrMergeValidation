SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblREFERRAL_SARCOMA SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblREFERRAL_SARCOMA] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblREFERRAL_SARCOMA 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblREFERRAL_SARCOMA
GO
