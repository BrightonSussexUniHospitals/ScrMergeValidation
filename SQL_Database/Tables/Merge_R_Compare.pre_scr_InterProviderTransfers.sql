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
[SCR_IPTTypeDesc] [varchar] (100) NULL,
[LogicalIPTTypeCode] [int] NULL,
[LogicalIPTTypeDesc] [varchar] (100) NULL,
[IPTDate] [datetime] NULL,
[IPTReferralReasonCode] [int] NULL,
[IPTReferralReasonDesc] [varchar] (100) NULL,
[IPTReceiptReasonCode] [int] NULL,
[IPTReceiptReasonDesc] [varchar] (100) NULL,
[ReferringOrgID] [int] NULL,
[ReferringOrgCode] [varchar] (5) NULL,
[ReferringOrgName] [nvarchar] (250) NULL,
[TertiaryReferralOutComments] [varchar] (1000) NULL,
[ReceivingOrgID] [int] NULL,
[ReceivingOrgCode] [varchar] (5) NULL,
[ReceivingOrgName] [nvarchar] (250) NULL,
[IptReasonTypeCareIdIx] [int] NULL,
[IptPPI_Ix] [int] NULL,
[IptPPI_RevIx] [int] NULL,
[IptChainRevIx] [int] NULL,
[IptErrorCode] [tinyint] NULL,
[IptErrorDesc] [varchar] (255) NULL,
[BreakChain] [bit] NULL,
[IncludeInChain] [bit] NULL,
[IsTransferOfCare] [bit] NULL,
[LastUpdatedBy] [varchar] (50) NULL
)
GO
CREATE NONCLUSTERED INDEX [ix_IPT] ON [Merge_R_Compare].[pre_scr_InterProviderTransfers] ([TertiaryReferralID], [SCR_IPTTypeCode])
GO
