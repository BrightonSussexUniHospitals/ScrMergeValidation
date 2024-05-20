CREATE TABLE [Merge_DM_MatchAudit].[tblMakeMajor]
(
[AuditDttm] [datetime2] NULL CONSTRAINT [DF__tblMakeMa__Audit__38141B8A] DEFAULT (getdate()),
[Success] [bit] NULL,
[ErrorMessage] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[UserID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[tableName] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[SrcSys_Major_Curr] [tinyint] NULL,
[Src_UID_Major_Curr] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[SrcSys_Major_New] [tinyint] NULL,
[Src_UID_Major_New] [varchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
