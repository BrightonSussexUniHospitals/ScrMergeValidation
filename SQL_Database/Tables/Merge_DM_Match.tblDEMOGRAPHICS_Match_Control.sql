CREATE TABLE [Merge_DM_Match].[tblDEMOGRAPHICS_Match_Control]
(
[SrcSys_Major] [tinyint] NULL,
[Src_UID_Major] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[IsSCR] [bit] NOT NULL,
[SrcSys] [tinyint] NOT NULL,
[Src_UID] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[HashBytesValue] [varbinary] (64) NULL,
[ChangeLastDetected] [datetime2] NULL,
[LastProcessed] [datetime2] NULL,
[DeletedDttm] [datetime2] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_tblDEMOGRAPHICS_Match_Control_HashBytesValue] ON [Merge_DM_Match].[tblDEMOGRAPHICS_Match_Control] ([HashBytesValue]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [PK_tblDEMOGRAPHICS_Match_Control] ON [Merge_DM_Match].[tblDEMOGRAPHICS_Match_Control] ([SrcSys], [Src_UID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_tblDEMOGRAPHICS_Match_Control_Major] ON [Merge_DM_Match].[tblDEMOGRAPHICS_Match_Control] ([SrcSys_Major], [Src_UID_Major]) ON [PRIMARY]
GO
