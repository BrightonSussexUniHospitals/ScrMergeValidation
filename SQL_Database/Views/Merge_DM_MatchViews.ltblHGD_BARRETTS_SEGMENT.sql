SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblHGD_BARRETTS_SEGMENT SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblHGD_BARRETTS_SEGMENT] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblHGD_BARRETTS_SEGMENT 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblHGD_BARRETTS_SEGMENT
GO
