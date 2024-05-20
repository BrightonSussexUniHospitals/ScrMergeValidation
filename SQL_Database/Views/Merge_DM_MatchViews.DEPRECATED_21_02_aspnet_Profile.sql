SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the DEPRECATED_21_02_aspnet_Profile SCR table 
CREATE VIEW [Merge_DM_MatchViews].[DEPRECATED_21_02_aspnet_Profile] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.DEPRECATED_21_02_aspnet_Profile 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.DEPRECATED_21_02_aspnet_Profile
GO
