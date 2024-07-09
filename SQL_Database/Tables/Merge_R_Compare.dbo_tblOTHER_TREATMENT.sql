CREATE TABLE [Merge_R_Compare].[dbo_tblOTHER_TREATMENT]
(
[DW_tblOTHER_TREATMENT_ID] [bigint] NOT NULL IDENTITY(1, 1),
[DW_LOAD_ID] [int] NULL,
[DW_CREATION_DATE_TIME] [datetime] NULL,
[DW_MODIFIED_DATE_TIME] [datetime] NULL,
[DW_SOURCE_ID] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[DW_SOURCE_SYSTEM_ID] [int] NULL,
[DW_SOURCE_PATIENT_ID] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[DW_SOURCE_SYSTEM_CREATED_DATE_TIME] [datetime] NULL,
[DW_SOURCE_SYSTEM_MODIFIED_DATE_TIME] [datetime] NULL,
[OTHER_ID] [int] NULL,
[CARE_ID] [int] NULL,
[N16_9_DECISION_ACTIVE] [datetime] NULL,
[N16_10_START_ACTIVE] [datetime] NULL,
[N1_3_ORG_CODE_TREATMENT] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[N_SITE_CODE_DTT] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[N_TREATMENT_EVENT] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[N_TREATMENT_SETTING] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[L_TRIAL] [int] NULL,
[DEFINITIVE_TREATMENT] [int] NULL,
[CWT_PROFORMA] [int] NULL,
[L_COMMENTS] [varchar] (8000) COLLATE Latin1_General_CI_AS NULL,
[N7_2_CONSULTANT] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[PRE_TREAT_PSA] [real] NULL,
[ROOT_CAUSE_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[ACTION_ID] [int] NULL,
[ROOT_DECISION_DATE_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[HCCEmbolisation] [int] NULL,
[HCCEmbolisationModality] [int] NULL,
[TreatmentIntent] [int] NULL,
[OtherTreatmentIntent] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[AdjunctiveTherapyID] [int] NULL,
[TertiaryReferralKey] [uniqueidentifier] NULL,
[ROOT_PRIM_ADJUSTMENT_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[ROOT_SUBPRIM_ADJUSTMENT_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
