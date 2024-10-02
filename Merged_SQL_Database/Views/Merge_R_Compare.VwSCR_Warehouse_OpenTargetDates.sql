SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [Merge_R_Compare].[VwSCR_Warehouse_OpenTargetDates]
AS


SELECT [OpenTargetDatesId]
      ,[SrcSysID]
      ,[CARE_ID]
      ,[CWT_ID]
      ,[DaysToTarget]
      ,[TargetDate]
      ,[DaysToBreach]
      ,[BreachDate]
      ,[TargetType]
      ,[WaitTargetGroupDesc]
      ,[WaitTargetPriority]
      ,[ReportDate]
      ,[IxFirstOpenTargetDate]
      ,[IxLastOpenTargetDate]
      ,[IxNextFutureOpenTargetDate]
      ,[IxLastFutureOpenTargetDate]
      ,[IxFirstOpenGroupTargetDate]
      ,[IxLastOpenGroupTargetDate]
      ,[IxNextFutureOpenGroupTargetDate]
      ,[IxLastFutureOpenGroupTargetDate]
      ,[IxFirstOpenBreachDate]
      ,[IxLastOpenBreachDate]
      ,[IxNextFutureOpenBreachDate]
      ,[IxLastFutureOpenBreachDate]
      ,[IxFirstOpenGroupBreachDate]
      ,[IxLastOpenGroupBreachDate]
      ,[IxNextFutureOpenGroupBreachDate]
      ,[IxLastFutureOpenGroupBreachDate]
  FROM [SCR_Warehouse].[OpenTargetDates]

GO
