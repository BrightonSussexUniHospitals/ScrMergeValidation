SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblPAEDIATRIC_MDT SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblPAEDIATRIC_MDT] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblPAEDIATRIC_MDT 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblPAEDIATRIC_MDT
GO
