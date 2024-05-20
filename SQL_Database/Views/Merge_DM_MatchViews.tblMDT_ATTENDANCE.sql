SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblMDT_ATTENDANCE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblMDT_ATTENDANCE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.tblMDT_ATTENDANCE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.tblMDT_ATTENDANCE
GO
