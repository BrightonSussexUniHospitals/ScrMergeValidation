CREATE TABLE [Merge_R_Compare].[pre_scr_assessments]
(
[OrigSrcSysID] [tinyint] NOT NULL,
[SrcSysID] [int] NOT NULL,
[OrigASSESSMENT_ID] [int] NOT NULL,
[ASSESSMENT_ID] [int] NULL,
[OrigCARE_ID] [int] NOT NULL,
[CARE_ID] [int] NULL,
[TEMP_ID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ASSESSMENT_DATE] [smalldatetime] NULL,
[AssessmentIx] [int] NULL,
[AssessmentRevIx] [int] NULL,
[ACTION_ID] [int] NULL,
[FollowUpCode] [int] NULL,
[FollowUpDesc] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[StratifiedFollowupTypeCode] [int] NULL,
[StratifiedFollowupTypeDesc] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[SurveillanceFlag] [int] NOT NULL,
[SurveillanceIx] [int] NULL,
[SurveillanceRevIx] [int] NULL,
[FollowUpPeriod] [varchar] (25) COLLATE Latin1_General_CI_AS NULL,
[FollowUpEndDate] [smalldatetime] NULL,
[OrigLastUpdatedBy] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[LastUpdatedBy] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[LastUpdateDate] [datetime] NULL,
[ReportDate] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_Assessment_ID] ON [Merge_R_Compare].[pre_scr_assessments] ([SrcSysID], [ASSESSMENT_ID]) ON [PRIMARY]
GO
