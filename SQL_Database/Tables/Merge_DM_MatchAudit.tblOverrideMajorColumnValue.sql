CREATE TABLE [Merge_DM_MatchAudit].[tblOverrideMajorColumnValue]
(
[AuditDttm] [datetime2] NULL CONSTRAINT [DF__tblOverri__Audit__40A9618B] DEFAULT (getdate()),
[Success] [bit] NULL,
[ErrorMessage] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[UserID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[tableName] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[SrcSys_Major] [tinyint] NULL,
[Src_UID_Major] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColumnName] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[SrcSys_Donor] [tinyint] NULL,
[Src_UID_Donor] [varchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
