SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblNATIONAL_CCG_INFO SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblNATIONAL_CCG_INFO] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblNATIONAL_CCG_INFO 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblNATIONAL_CCG_INFO
GO
