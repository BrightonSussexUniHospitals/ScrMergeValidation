SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblSURGERY_GYNAECOLOGY SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblSURGERY_GYNAECOLOGY] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblSURGERY_GYNAECOLOGY 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblSURGERY_GYNAECOLOGY
GO
