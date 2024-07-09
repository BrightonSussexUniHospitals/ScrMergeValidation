CREATE TABLE [Merge_R_Compare].[pre_scr_InterProviderTransfers]
(
[OrigSrcSysID] [tinyint] NOT NULL,
[SrcSysID] [int] NOT NULL,
[OrigTertiaryReferralID] [int] NOT NULL,
[TertiaryReferralID] [int] NULL,
[OrigCARE_ID] [int] NULL,
[CareID] [int] NULL,
[ACTION_ID] [int] NULL,
[SCR_IPTTypeCode] [int] NOT NULL,
[SCR_IPTTypeDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[LogicalIPTTypeCode] [int] NULL,
[LogicalIPTTypeDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[IPTDate] [datetime] NULL,
[IPTReferralReasonCode] [int] NULL,
[IPTReferralReasonDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[IPTReceiptReasonCode] [int] NULL,
[IPTReceiptReasonDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[ReferringOrgID] [int] NULL,
[ReferringOrgCode] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[ReferringOrgName] [nvarchar] (250) COLLATE Latin1_General_CI_AS NULL,
[TertiaryReferralOutComments] [varchar] (1000) COLLATE Latin1_General_CI_AS NULL,
[ReceivingOrgID] [int] NULL,
[ReceivingOrgCode] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[ReceivingOrgName] [nvarchar] (250) COLLATE Latin1_General_CI_AS NULL,
[IptReasonTypeCareIdIx] [int] NULL,
[CrossSiteRevIx] [int] NULL,
[IsTransferOfCare] [bit] NULL,
[LastUpdatedBy] [varchar] (50) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_IPT] ON [Merge_R_Compare].[pre_scr_InterProviderTransfers] ([TertiaryReferralID], [SCR_IPTTypeCode]) ON [PRIMARY]
GO
