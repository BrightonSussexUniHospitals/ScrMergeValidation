CREATE TABLE [Merge_R_Compare].[pre_OpenTargetDates]
(
[OpenTargetDatesId] [int] NOT NULL,
[OrigSrcSysID] [tinyint] NOT NULL,
[SrcSysID] [int] NOT NULL,
[OrigCARE_ID] [int] NOT NULL,
[CARE_ID] [int] NULL,
[CWT_ID] [varchar] (2559) COLLATE Latin1_General_CI_AS NULL,
[DaysToTarget] [int] NULL,
[TargetDate] [datetime] NULL,
[DaysToBreach] [int] NULL,
[BreachDate] [datetime] NULL,
[TargetType] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[WaitTargetGroupDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[WaitTargetPriority] [int] NULL,
[ReportDate] [datetime] NULL,
[IxFirstOpenTargetDate] [int] NULL,
[IxLastOpenTargetDate] [int] NULL,
[IxNextFutureOpenTargetDate] [int] NULL,
[IxLastFutureOpenTargetDate] [int] NULL,
[IxFirstOpenGroupTargetDate] [int] NULL,
[IxLastOpenGroupTargetDate] [int] NULL,
[IxNextFutureOpenGroupTargetDate] [int] NULL,
[IxLastFutureOpenGroupTargetDate] [int] NULL,
[IxFirstOpenBreachDate] [int] NULL,
[IxLastOpenBreachDate] [int] NULL,
[IxNextFutureOpenBreachDate] [int] NULL,
[IxLastFutureOpenBreachDate] [int] NULL,
[IxFirstOpenGroupBreachDate] [int] NULL,
[IxLastOpenGroupBreachDate] [int] NULL,
[IxNextFutureOpenGroupBreachDate] [int] NULL,
[IxLastFutureOpenGroupBreachDate] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_OpenTargetDatesId] ON [Merge_R_Compare].[pre_OpenTargetDates] ([CWT_ID], [TargetType]) ON [PRIMARY]
GO
