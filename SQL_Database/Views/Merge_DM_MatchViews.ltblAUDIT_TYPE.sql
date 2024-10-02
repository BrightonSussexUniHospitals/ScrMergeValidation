SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblAUDIT_TYPE SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblAUDIT_TYPE] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblAUDIT_TYPE 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblAUDIT_TYPE
GO
