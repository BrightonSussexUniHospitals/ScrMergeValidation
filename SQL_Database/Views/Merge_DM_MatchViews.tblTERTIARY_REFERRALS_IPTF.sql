SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the tblTERTIARY_REFERRALS_IPTF SCR table 
CREATE VIEW [Merge_DM_MatchViews].[tblTERTIARY_REFERRALS_IPTF] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM BSUH_Deduplication.dbo.tblTERTIARY_REFERRALS_IPTF 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM WSHT_Deduplication.dbo.tblTERTIARY_REFERRALS_IPTF
GO
