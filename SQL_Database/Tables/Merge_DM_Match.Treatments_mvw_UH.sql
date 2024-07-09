CREATE TABLE [Merge_DM_Match].[Treatments_mvw_UH]
(
[Ref_SrcSys_Minor] [tinyint] NOT NULL,
[Ref_Src_UID_Minor] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[TreatmentDate] [smalldatetime] NULL,
[Treatment] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[TreatmentSite] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[TreatmentID] [int] NOT NULL,
[LastUpdated] [datetime2] NULL,
[HashBytesValue] [varbinary] (8000) NULL,
[NonNullColumnCount] [smallint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [Merge_DM_Match].[Treatments_mvw_UH] ADD CONSTRAINT [PK_Treatments_mvw_UH] PRIMARY KEY CLUSTERED ([Ref_SrcSys_Minor], [Treatment], [TreatmentID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Treatments_mvw_UH_HashBytesValue] ON [Merge_DM_Match].[Treatments_mvw_UH] ([HashBytesValue]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Treatments_mvw_UH_LastUpdated] ON [Merge_DM_Match].[Treatments_mvw_UH] ([LastUpdated]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Treatments_mvw_UH_Minor] ON [Merge_DM_Match].[Treatments_mvw_UH] ([Ref_SrcSys_Minor], [Ref_Src_UID_Minor]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Treatments_mvw_UH_TreatmentDate] ON [Merge_DM_Match].[Treatments_mvw_UH] ([TreatmentDate]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Treatments_mvw_UH_TreatmentSite] ON [Merge_DM_Match].[Treatments_mvw_UH] ([TreatmentSite]) ON [PRIMARY]
GO
