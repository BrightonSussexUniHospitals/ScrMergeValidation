CREATE TABLE [Merge_R_Compare].[pre_scr_comments]
(
[OrigSrcSysID] [tinyint] NOT NULL,
[SrcSysId] [int] NOT NULL,
[OrigSourceRecordId] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[SourceRecordId] [int] NULL,
[SourceTableName] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[SourceColumnName] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[OrigCARE_ID] [int] NOT NULL,
[CARE_ID] [int] NULL,
[Comment] [varchar] (1000) COLLATE Latin1_General_CI_AS NULL,
[CommentUser] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[CommentDate] [datetime] NULL,
[CommentType] [int] NOT NULL,
[CareIdIx] [int] NULL,
[CareIdRevIx] [int] NULL,
[CommentTypeCareIdIx] [int] NULL,
[CommentTypeCareIdRevIx] [int] NULL,
[ReportDate] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_comments] ON [Merge_R_Compare].[pre_scr_comments] ([SourceRecordId], [SourceTableName], [SourceColumnName]) ON [PRIMARY]
GO
