CREATE TABLE [Merge_DM_MatchAudit].[tblUnlinkMatch]
(
[AuditDttm] [datetime2] NULL CONSTRAINT [DF__tblUnlink__Audit__3AF08835] DEFAULT (getdate()),
[Success] [bit] NULL,
[ErrorMessage] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[UserID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[tableName] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[SrcSys_Major] [tinyint] NULL,
[Src_UID_Major] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[SrcSys] [tinyint] NULL,
[Src_UID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
