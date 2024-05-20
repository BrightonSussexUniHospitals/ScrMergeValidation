SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [Merge_R_Compare].[VwSCR_Warehouse_OpenTargetDates]
AS


SELECT pre.[OpenTargetDatesId]
      ,pre.SrcSysID AS OrigSrcSysID
	  ,5 AS [SrcSysID]
      ,pre.[CARE_ID] AS OrigCARE_ID
	  ,dwref.[CARE_ID]
	  ,cwt.CWT_ID
      ,pre.[DaysToTarget]
      ,pre.[TargetDate]
      ,pre.[DaysToBreach]
      ,pre.[BreachDate]
      ,pre.[TargetType]
      ,pre.[WaitTargetGroupDesc]
      ,pre.[WaitTargetPriority]
      ,pre.[ReportDate]
      ,pre.[IxFirstOpenTargetDate]
      ,pre.[IxLastOpenTargetDate]
      ,pre.[IxNextFutureOpenTargetDate]
      ,pre.[IxLastFutureOpenTargetDate]
      ,pre.[IxFirstOpenGroupTargetDate]
      ,pre.[IxLastOpenGroupTargetDate]
      ,pre.[IxNextFutureOpenGroupTargetDate]
      ,pre.[IxLastFutureOpenGroupTargetDate]
      ,pre.[IxFirstOpenBreachDate]
      ,pre.[IxLastOpenBreachDate]
      ,pre.[IxNextFutureOpenBreachDate]
      ,pre.[IxLastFutureOpenBreachDate]
      ,pre.[IxFirstOpenGroupBreachDate]
      ,pre.[IxLastOpenGroupBreachDate]
      ,pre.[IxNextFutureOpenGroupBreachDate]
      ,pre.[IxLastFutureOpenGroupBreachDate]

FROM [SCR_Warehouse].[OpenTargetDates] pre

LEFT JOIN	SCR_DW.SCR.dbo_tblMAIN_REFERRALS dwref
											ON	pre.CARE_ID = dwref.DW_SOURCE_ID
											AND pre.SrcSysID = dwref.DW_SOURCE_SYSTEM_ID

LEFT JOIN	CancerReporting_PREMERGE.Merge_R_Compare.VwSCR_Warehouse_SCR_CWT cwt
																		ON pre.CWT_ID = cwt.OrigCWT_ID

GO
