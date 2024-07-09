CREATE TABLE [Merge_DM_Match].[MDT_mvw_UH]
(
[Ref_SrcSys_Minor] [tinyint] NOT NULL,
[Ref_Src_UID_Minor] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[SrcSysID] [tinyint] NOT NULL,
[tableName] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[table_UID] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[FrontEndStatus] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[PATIENT_ID] [int] NULL,
[CARE_ID] [int] NULL,
[MDT_MDT_ID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MeetingList_MDT_ID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MeetingList_MDT_ID_DONE] [int] NULL,
[CarePlan_TEMP_ID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[PLAN_ID] [int] NULL,
[MEETING_ID] [int] NULL,
[MDT_DATE] [smalldatetime] NULL,
[MeetingList_MDT_DATE] [smalldatetime] NULL,
[CarePlan_MDT_DATE] [smalldatetime] NULL,
[MDT_MDT_SITE] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[MeetingList_SITE] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[CarePlan_SITE] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[OTHER_SITE] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[CancerSite] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[MeetingTemplateID] [int] NULL,
[MDTLocation] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[CarePlanLocation] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[TemplateLocation] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[MDT_Comments] [varchar] (8000) COLLATE Latin1_General_CI_AS NULL,
[MeetingList_Comments] [varchar] (8000) COLLATE Latin1_General_CI_AS NULL,
[CarePlan_Comments] [varchar] (8000) COLLATE Latin1_General_CI_AS NULL,
[SubSite] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[SubSiteSaysSpecialist] [bit] NULL,
[MdtMeetingsNetworkFlag] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[CarePlanNetworkFlag] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[LastUpdated] [datetime2] NULL,
[HashBytesValue] [varbinary] (8000) NULL
) ON [PRIMARY]
GO
ALTER TABLE [Merge_DM_Match].[MDT_mvw_UH] ADD CONSTRAINT [PK_MDT_mvw_UH] PRIMARY KEY CLUSTERED ([SrcSysID], [tableName], [table_UID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [MDT_mvw_UH_CarePlan_MDT_DATE] ON [Merge_DM_Match].[MDT_mvw_UH] ([CarePlan_MDT_DATE]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [MDT_mvw_UH_FrontEndStatus] ON [Merge_DM_Match].[MDT_mvw_UH] ([FrontEndStatus]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [MDT_mvw_UH_HashBytesValue] ON [Merge_DM_Match].[MDT_mvw_UH] ([HashBytesValue]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [MDT_mvw_UH_LastUpdated] ON [Merge_DM_Match].[MDT_mvw_UH] ([LastUpdated]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [MDT_mvw_UH_MDT_DATE] ON [Merge_DM_Match].[MDT_mvw_UH] ([MDT_DATE]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [MDT_mvw_UH_MeetingList_MDT_DATE] ON [Merge_DM_Match].[MDT_mvw_UH] ([MeetingList_MDT_DATE]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [MDT_mvw_UH_Minor] ON [Merge_DM_Match].[MDT_mvw_UH] ([Ref_SrcSys_Minor], [Ref_Src_UID_Minor]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [MDT_mvw_UH_table_UID] ON [Merge_DM_Match].[MDT_mvw_UH] ([table_UID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [MDT_mvw_UH_tableName] ON [Merge_DM_Match].[MDT_mvw_UH] ([tableName]) ON [PRIMARY]
GO
