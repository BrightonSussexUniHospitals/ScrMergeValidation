CREATE TABLE [Merge_R_Compare].[ReportingMergeDifferences]
(
[MerCare_ID] [int] NULL,
[MerRecordID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[PreSrcSysID] [tinyint] NULL,
[PreCare_ID] [int] NULL,
[PreRecordID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColumnIx] [smallint] NULL,
[DiffType] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[PreValue] [sql_variant] NULL,
[MerValue] [sql_variant] NULL
) ON [PRIMARY]
GO
