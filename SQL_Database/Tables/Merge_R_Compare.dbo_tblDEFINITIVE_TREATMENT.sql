CREATE TABLE [Merge_R_Compare].[dbo_tblDEFINITIVE_TREATMENT]
(
[DW_tblDEFINITIVE_TREATMENT_ID] [bigint] NOT NULL IDENTITY(1, 1),
[DW_LOAD_ID] [int] NULL,
[DW_CREATION_DATE_TIME] [datetime] NULL,
[DW_MODIFIED_DATE_TIME] [datetime] NULL,
[DW_SOURCE_ID] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[DW_SOURCE_SYSTEM_ID] [int] NULL,
[DW_SOURCE_PATIENT_ID] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[DW_SOURCE_SYSTEM_CREATED_DATE_TIME] [datetime] NULL,
[DW_SOURCE_SYSTEM_MODIFIED_DATE_TIME] [datetime] NULL,
[TREATMENT_ID] [int] NULL,
[CARE_ID] [int] NULL,
[PATHWAY_ID] [varchar] (20) COLLATE Latin1_General_CI_AS NULL,
[DECISION_DATE] [smalldatetime] NULL,
[ORG_CODE_DTT] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[START_DATE] [smalldatetime] NULL,
[TREATMENT] [char] (2) COLLATE Latin1_General_CI_AS NULL,
[ORG_CODE] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[TREATMENT_EVENT] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[TREATMENT_SETTING] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[RT_PRIORITY] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[RT_INTENT] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[SPECIALIST] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[TRIAL] [int] NULL,
[ADJ_DAYS] [int] NULL,
[ADJ_CODE] [int] NULL,
[DELAY_CODE] [int] NULL,
[TREAT_NO] [int] NULL,
[TREAT_ID] [int] NULL,
[CHEMO_RT] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[VALIDATED] [int] NULL,
[DELAY_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[DEPRECATED_21_01_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[DEPRECATED_21_01_ALL_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[ROOT_TCI_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[ROOT_DTT_DATE_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[TREATMENT_ADJ_DATE] [smalldatetime] NULL
) ON [PRIMARY]
GO
