SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblUGI_PROCEDURE_TYPE SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblUGI_PROCEDURE_TYPE] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblUGI_PROCEDURE_TYPE 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblUGI_PROCEDURE_TYPE
GO
