CREATE TABLE [Merge_DM_Match].[tblDEMOGRAPHICS_Match_EntityPairs_Unique]
(
[SrcSys_A] [tinyint] NOT NULL,
[Src_UID_A] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[SrcSys_B] [tinyint] NOT NULL,
[Src_UID_B] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[BestIntention] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[UnlinkDttm] [datetime2] NULL,
[LastUnlinkedBy] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[UnlinkProcessed] [bit] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [PK_tblDEMOGRAPHICS_Match_EntityPairs_Unique] ON [Merge_DM_Match].[tblDEMOGRAPHICS_Match_EntityPairs_Unique] ([SrcSys_A], [Src_UID_A], [SrcSys_B], [Src_UID_B]) ON [PRIMARY]
GO
