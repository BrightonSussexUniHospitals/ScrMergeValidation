CREATE TABLE [Merge_DM_Match].[Treatments_Match_Control]
(
[SrcSys] [tinyint] NOT NULL,
[Treatment] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[TreatmentID] [int] NOT NULL,
[HashBytesValue] [varbinary] (8000) NULL,
[ChangeLastDetected] [datetime2] NULL,
[LastProcessed] [datetime2] NULL,
[DeletedDttm] [datetime2] NULL,
[Migrate] [bit] NULL,
[LastValidatedDttm] [datetime2] NULL,
[LastValidatedBy] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[LastValidated_SrcSys_Major] [tinyint] NULL,
[LastValidated_Src_UID_Major] [varchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Merge_DM_Match].[Treatments_Match_Control] ADD CONSTRAINT [PK_Treatments_Match_Control] PRIMARY KEY CLUSTERED ([SrcSys], [Treatment], [TreatmentID]) ON [PRIMARY]
GO
