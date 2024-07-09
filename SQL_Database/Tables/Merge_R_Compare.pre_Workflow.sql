CREATE TABLE [Merge_R_Compare].[pre_Workflow]
(
[OrigSrcSysID] [tinyint] NOT NULL,
[SrcSysID] [int] NOT NULL,
[OrigIdentityTypeRecordId] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[IdentityTypeRecordId] [varchar] (2559) COLLATE Latin1_General_CI_AS NULL,
[IdentityTypeId] [int] NOT NULL,
[WorkflowID] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_workflow] ON [Merge_R_Compare].[pre_Workflow] ([IdentityTypeRecordId], [IdentityTypeId], [WorkflowID]) ON [PRIMARY]
GO
