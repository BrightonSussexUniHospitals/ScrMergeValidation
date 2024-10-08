SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblCOMPLICATIONS_COLORECTAL SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblCOMPLICATIONS_COLORECTAL] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblCOMPLICATIONS_COLORECTAL 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblCOMPLICATIONS_COLORECTAL
GO
