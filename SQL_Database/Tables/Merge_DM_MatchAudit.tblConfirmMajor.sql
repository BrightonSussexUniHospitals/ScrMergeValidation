CREATE TABLE [Merge_DM_MatchAudit].[tblConfirmMajor]
(
[AuditDttm] [datetime2] NULL CONSTRAINT [DF__tblConfir__Audit__3DCCF4E0] DEFAULT (getdate()),
[Success] [bit] NULL,
[ErrorMessage] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[UserID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[tableName] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[SrcSys_Major] [tinyint] NULL,
[Src_UID_Major] [varchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
