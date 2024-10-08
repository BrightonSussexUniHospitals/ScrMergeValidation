SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblPALLIATIVE_CONTACT_BACK_UP SCR table 

CREATE VIEW [Merge_DM_MatchViews].[tblPALLIATIVE_CONTACT_BACK_UP] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblPALLIATIVE_CONTACT_BACK_UP 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblPALLIATIVE_CONTACT_BACK_UP
GO
