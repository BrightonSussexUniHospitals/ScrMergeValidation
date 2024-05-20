CREATE TABLE [Merge_DM_Match].[tblMAIN_REFERRALS_Match_EntityPairs_All]
(
[IsSCR_A] [bit] NOT NULL,
[SrcSys_A] [tinyint] NOT NULL,
[Src_UID_A] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[IsSCR_B] [bit] NOT NULL,
[SrcSys_B] [tinyint] NOT NULL,
[Src_UID_B] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[MatchType] [tinyint] NOT NULL,
[MatchIntention] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [PK_tblMAIN_REFERRALS_Match_EntityPairs_All] ON [Merge_DM_Match].[tblMAIN_REFERRALS_Match_EntityPairs_All] ([SrcSys_A], [Src_UID_A], [SrcSys_B], [Src_UID_B], [MatchType]) ON [PRIMARY]
GO
