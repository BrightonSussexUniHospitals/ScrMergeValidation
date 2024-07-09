SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblTELETHERAPY_DERMATOLOGY SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblTELETHERAPY_DERMATOLOGY] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblTELETHERAPY_DERMATOLOGY 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblTELETHERAPY_DERMATOLOGY
GO
