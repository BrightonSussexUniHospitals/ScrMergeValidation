SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [Merge_R_Compare].[VwSCR_Warehouse_SCR_Assessments]
AS

SELECT [SrcSysID]
      ,[ASSESSMENT_ID]
      ,[CARE_ID]
      ,[TEMP_ID]
      ,[ASSESSMENT_DATE]
      ,[AssessmentIx]
      ,[AssessmentRevIx]
      ,[ACTION_ID]
      ,[FollowUpCode]
      ,[FollowUpDesc]
      ,[StratifiedFollowupTypeCode]
      ,[StratifiedFollowupTypeDesc]
      ,[SurveillanceFlag]
      ,[SurveillanceIx]
      ,[SurveillanceRevIx]
      ,[FollowUpPeriod]
      ,[FollowUpEndDate]
      ,[LastUpdatedBy]
      ,[LastUpdateDate]
      ,[ReportDate]
FROM [SCR_Warehouse].[SCR_Assessments]

GO
