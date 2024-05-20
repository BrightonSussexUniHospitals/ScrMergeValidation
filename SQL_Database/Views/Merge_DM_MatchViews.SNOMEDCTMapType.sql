SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the SNOMEDCTMapType SCR table 
CREATE VIEW [Merge_DM_MatchViews].[SNOMEDCTMapType] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.SNOMEDCTMapType 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.SNOMEDCTMapType
GO
