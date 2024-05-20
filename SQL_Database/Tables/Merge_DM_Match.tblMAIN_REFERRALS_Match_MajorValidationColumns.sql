CREATE TABLE [Merge_DM_Match].[tblMAIN_REFERRALS_Match_MajorValidationColumns]
(
[SrcSys_Major] [tinyint] NOT NULL,
[Src_UID_Major] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[FieldName] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[SrcSys] [tinyint] NOT NULL,
[Src_UID] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [PK_tblMAIN_REFERRALS_Match_MajorValidationColumns] ON [Merge_DM_Match].[tblMAIN_REFERRALS_Match_MajorValidationColumns] ([SrcSys_Major], [Src_UID_Major], [FieldName]) ON [PRIMARY]
GO
