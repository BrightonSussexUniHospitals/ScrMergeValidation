CREATE TABLE [Merge_R_Compare].[dbo_tblTERTIARY_REFERRALS]
(
[DW_tblTERTIARY_REFERRALS_ID] [bigint] NOT NULL IDENTITY(1, 1),
[DW_LOAD_ID] [int] NULL,
[DW_CREATION_DATE_TIME] [datetime] NULL,
[DW_MODIFIED_DATE_TIME] [datetime] NULL,
[DW_SOURCE_ID] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[DW_SOURCE_SYSTEM_ID] [int] NULL,
[DW_SOURCE_PATIENT_ID] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[DW_SOURCE_SYSTEM_CREATED_DATE_TIME] [datetime] NULL,
[DW_SOURCE_SYSTEM_MODIFIED_DATE_TIME] [datetime] NULL,
[TertiaryReferralID] [int] NULL,
[CareID] [int] NULL,
[ReferringOrgID] [int] NULL,
[ReceivingOrgID] [int] NULL,
[ReasonID] [int] NULL,
[Comments] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[ACTION_ID] [int] NULL,
[IsTransferOfCare] [bit] NULL,
[PayloadID] [int] NULL
) ON [PRIMARY]
GO
