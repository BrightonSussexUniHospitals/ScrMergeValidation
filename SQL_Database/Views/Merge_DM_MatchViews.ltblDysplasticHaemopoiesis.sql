SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblDysplasticHaemopoiesis SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblDysplasticHaemopoiesis] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblDysplasticHaemopoiesis 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblDysplasticHaemopoiesis
GO
