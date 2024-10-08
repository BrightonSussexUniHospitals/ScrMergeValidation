SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblASSESSMENT_GYNAECOLOGY SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblASSESSMENT_GYNAECOLOGY] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblASSESSMENT_GYNAECOLOGY 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblASSESSMENT_GYNAECOLOGY
GO
