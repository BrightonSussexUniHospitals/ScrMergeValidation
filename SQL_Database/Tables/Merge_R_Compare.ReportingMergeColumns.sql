CREATE TABLE [Merge_R_Compare].[ReportingMergeColumns]
(
[ColumnIx] [smallint] NOT NULL IDENTITY(1, 1),
[SchemaName] [sys].[sysname] NOT NULL,
[TableName] [sys].[sysname] NOT NULL,
[ColumnName] [sys].[sysname] NULL,
[ColumnOrder] [int] NOT NULL,
[ColumnStart] [datetime2] NULL,
[ColumnComplete] [datetime2] NULL
) ON [PRIMARY]
GO
