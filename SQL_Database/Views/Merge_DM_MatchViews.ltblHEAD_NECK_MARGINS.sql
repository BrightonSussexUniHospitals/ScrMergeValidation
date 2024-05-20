SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblHEAD_NECK_MARGINS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblHEAD_NECK_MARGINS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblHEAD_NECK_MARGINS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblHEAD_NECK_MARGINS
GO
