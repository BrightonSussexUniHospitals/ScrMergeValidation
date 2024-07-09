SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblRADIO_TECHNIQUE SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblRADIO_TECHNIQUE] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.ltblRADIO_TECHNIQUE 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.ltblRADIO_TECHNIQUE
GO
