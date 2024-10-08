SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblTOBACCO_TYPE SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblTOBACCO_TYPE] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblTOBACCO_TYPE 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblTOBACCO_TYPE
GO
