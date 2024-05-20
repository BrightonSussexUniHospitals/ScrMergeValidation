SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblProstateImageGuidanceType SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblProstateImageGuidanceType] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblProstateImageGuidanceType 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblProstateImageGuidanceType
GO
