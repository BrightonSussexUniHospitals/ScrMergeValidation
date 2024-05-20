SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the ltblTEMP_NHS_NUMBERS SCR table 
CREATE VIEW [Merge_DM_MatchViews].[ltblTEMP_NHS_NUMBERS] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.ltblTEMP_NHS_NUMBERS 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.ltblTEMP_NHS_NUMBERS
GO
