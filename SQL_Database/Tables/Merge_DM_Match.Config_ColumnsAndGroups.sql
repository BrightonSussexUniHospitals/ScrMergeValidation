CREATE TABLE [Merge_DM_Match].[Config_ColumnsAndGroups]
(
[TableName] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[ShowInReport] [bit] NULL,
[ColumnName] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[ColumnDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColumnGroup] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColumnSort] [smallint] NULL,
[ColumnGroupSort] [tinyint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [Merge_DM_Match].[Config_ColumnsAndGroups] ADD CONSTRAINT [PK_Config_ColumnsAndGroups] PRIMARY KEY CLUSTERED ([TableName], [ColumnName]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Config_ColumnsAndGroups_Show] ON [Merge_DM_Match].[Config_ColumnsAndGroups] ([ShowInReport] DESC) ON [PRIMARY]
GO
