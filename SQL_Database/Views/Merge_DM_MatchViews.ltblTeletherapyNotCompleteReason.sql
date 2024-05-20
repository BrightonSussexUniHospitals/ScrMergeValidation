SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblTeletherapyNotCompleteReason SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblTeletherapyNotCompleteReason] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblTeletherapyNotCompleteReason 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblTeletherapyNotCompleteReason
GO
