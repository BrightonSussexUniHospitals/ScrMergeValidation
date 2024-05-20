SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblRADIO_ELECTRONS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblRADIO_ELECTRONS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblRADIO_ELECTRONS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblRADIO_ELECTRONS
GO
