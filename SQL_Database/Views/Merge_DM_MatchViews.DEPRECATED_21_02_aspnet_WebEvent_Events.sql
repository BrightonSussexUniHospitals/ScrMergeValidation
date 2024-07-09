SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the DEPRECATED_21_02_aspnet_WebEvent_Events SCR table 
CREATE VIEW [Merge_DM_MatchViews].[DEPRECATED_21_02_aspnet_WebEvent_Events] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.DEPRECATED_21_02_aspnet_WebEvent_Events 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.DEPRECATED_21_02_aspnet_WebEvent_Events
GO
