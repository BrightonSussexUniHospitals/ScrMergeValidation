SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblNUTRITIONAL_PROCEDURES SCR table 

CREATE VIEW [Merge_DM_MatchViews].[ltblNUTRITIONAL_PROCEDURES] AS 

 

SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblNUTRITIONAL_PROCEDURES 

 

UNION ALL 

 

SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblNUTRITIONAL_PROCEDURES
GO
