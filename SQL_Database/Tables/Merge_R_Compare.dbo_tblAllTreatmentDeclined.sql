CREATE TABLE [Merge_R_Compare].[dbo_tblAllTreatmentDeclined]
(
[DW_tblAllTreatmentDeclined_ID] [bigint] NOT NULL IDENTITY(1, 1),
[DW_LOAD_ID] [int] NULL,
[DW_CREATION_DATE_TIME] [datetime] NULL,
[DW_MODIFIED_DATE_TIME] [datetime] NULL,
[DW_SOURCE_ID] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[DW_SOURCE_SYSTEM_ID] [int] NULL,
[DW_SOURCE_PATIENT_ID] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[DW_SOURCE_SYSTEM_CREATED_DATE_TIME] [datetime] NULL,
[DW_SOURCE_SYSTEM_MODIFIED_DATE_TIME] [datetime] NULL,
[AllTreatmentDeclinedID] [int] NULL,
[CARE_ID] [int] NULL,
[DECISION_DATE] [smalldatetime] NULL,
[ORG_CODE_DTT] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[START_DATE] [smalldatetime] NULL,
[ORG_CODE_TREATMENT] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[N_TREATMENT_EVENT] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[N_TREATMENT_SETTING] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[L_TRIAL] [int] NULL,
[L_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[ACTION_ID] [int] NULL,
[DEFINITIVE_TREATMENT] [int] NULL,
[CWT_PROFORMA] [int] NULL,
[TertiaryReferralKey] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
