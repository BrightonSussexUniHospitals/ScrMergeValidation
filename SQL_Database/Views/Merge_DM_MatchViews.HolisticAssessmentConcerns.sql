SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create a view to union the data for the HolisticAssessmentConcerns SCR table 
CREATE VIEW [Merge_DM_MatchViews].[HolisticAssessmentConcerns] AS 
 
SELECT CAST(2 AS TINYINT) AS SrcSysID, * FROM CancerRegister_BSUH.dbo.HolisticAssessmentConcerns 
 
UNION ALL 
 
SELECT CAST(1 AS TINYINT) AS SrcSysID, * FROM CancerRegister_WSHT.dbo.HolisticAssessmentConcerns
GO
