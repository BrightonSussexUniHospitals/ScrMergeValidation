SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the expNOGCA_TUMOUR_TEMP SCR table 

CREATE VIEW [Merge_DM_MatchViews].[expNOGCA_TUMOUR_TEMP] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.expNOGCA_TUMOUR_TEMP 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.expNOGCA_TUMOUR_TEMP
GO
