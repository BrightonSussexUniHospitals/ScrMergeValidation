CREATE TABLE [Merge_DM_MatchAudit].[tblDropOrKeep]
(
[AuditDttm] [datetime2] NULL CONSTRAINT [DF_tblDropOrKeep_AuditDttm] DEFAULT (getdate()),
[Success] [bit] NULL,
[ErrorMessage] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[UserID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[tableName] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[SrcSys] [tinyint] NULL,
[RecordID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[RecordVariant] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Migrate] [bit] NULL
) ON [PRIMARY]
GO
