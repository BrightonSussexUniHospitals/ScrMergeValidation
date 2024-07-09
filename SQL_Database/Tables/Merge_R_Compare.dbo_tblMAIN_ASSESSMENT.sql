CREATE TABLE [Merge_R_Compare].[dbo_tblMAIN_ASSESSMENT]
(
[DW_tblMAIN_ASSESSMENT_ID] [bigint] NOT NULL IDENTITY(1, 1),
[DW_LOAD_ID] [int] NULL,
[DW_CREATION_DATE_TIME] [datetime] NULL,
[DW_MODIFIED_DATE_TIME] [datetime] NULL,
[DW_SOURCE_ID] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[DW_SOURCE_SYSTEM_ID] [int] NULL,
[DW_SOURCE_PATIENT_ID] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[DW_SOURCE_SYSTEM_CREATED_DATE_TIME] [datetime] NULL,
[DW_SOURCE_SYSTEM_MODIFIED_DATE_TIME] [datetime] NULL,
[ASSESSMENT_ID] [int] NULL,
[CARE_ID] [int] NULL,
[TEMP_ID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[N14_1_ASSESSMENT_DATE] [smalldatetime] NULL,
[N14_2_TUMOUR_STATUS] [int] NULL,
[N14_3_NODE_STATUS] [int] NULL,
[N14_4_METS_STATUS] [int] NULL,
[N14_5_MARKER_RESPONSE] [int] NULL,
[N14_6_WHO_STATUS] [int] NULL,
[N14_7_MORBIDITY_TYPE] [int] NULL,
[N14_8_MORBIDITY_CODE] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[N14_9_FOLLOW_UP] [int] NULL,
[N14_10_CHEMO_MORBIDITY] [int] NULL,
[N14_11_RADIO_MORBIDITY] [int] NULL,
[N14_12_COMB_MORBIDITY] [int] NULL,
[N_SK24_TUMOUR_STATUS] [int] NULL,
[N_L21_RECEIVED_PCI] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[N_L30_PLAN] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[N_L31_FAILURE] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[R_ORG_CODE] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[R_ALIVE_DATE] [smalldatetime] NULL,
[R_ABROAD_DATE] [smalldatetime] NULL,
[R_MODE_FOLLOWUP] [int] NULL,
[L_OTHER_MODE] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[R_RECURRENCE_BY] [int] NULL,
[R_DATE_RECURRENCE] [smalldatetime] NULL,
[R_POTENCY] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[R_CONTINENCE] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[R_INTERVENTION] [int] NULL,
[R_OTHER_INTERVENTION] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[R_COMPLICATIONS] [int] NULL,
[R_OTHER_COMPLICATIONS] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[R_CURRENT_STATUS] [int] NULL,
[R_DATE_STATUS] [smalldatetime] NULL,
[R_STATUS] [int] NULL,
[R_OTHER_TRACT] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[R_SERUM] [real] NULL,
[R_FBC] [bit] NULL,
[R_LFT] [bit] NULL,
[R_CT] [bit] NULL,
[R_USS] [bit] NULL,
[R_CXR] [bit] NULL,
[R_OTHER_TESTS] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[R_PSA] [real] NULL,
[R_DATE_METATASECTOMY] [smalldatetime] NULL,
[L_HEIGHT] [real] NULL,
[L_WEIGHT] [real] NULL,
[L_FOLLOWUP] [varchar] (25) COLLATE Latin1_General_CI_AS NULL,
[L_REF_ONCOLOGIST] [bit] NULL,
[L_WHOLE_IMAGED] [bit] NULL,
[L_COLO_REQUEST] [bit] NULL,
[L_BA_REQUEST] [bit] NULL,
[L_ASYMPTOMATIC] [bit] NULL,
[L_SYMPTOMATIC] [bit] NULL,
[L_DETAILS] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[L_RECURRENCE] [bit] NULL,
[L_REC_SITE] [varchar] (15) COLLATE Latin1_General_CI_AS NULL,
[L_REC_SITE_2] [varchar] (15) COLLATE Latin1_General_CI_AS NULL,
[L_ERECTILE] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[L_BLADDER] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[L_RESOLUTION_ERECTILE] [varchar] (25) COLLATE Latin1_General_CI_AS NULL,
[L_RESOLUTION_BLADDER] [varchar] (25) COLLATE Latin1_General_CI_AS NULL,
[L_CT_REQUEST] [bit] NULL,
[L_MRI_REQUEST] [bit] NULL,
[L_INCISIONAL_HERNIA] [bit] NULL,
[L_STRICTURE] [bit] NULL,
[L_SCREENING] [bit] NULL,
[L_LOCATION] [int] NULL,
[L_REASON] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[L_MAMMOGRAM] [int] NULL,
[L_OUTSIDE_FOLLOWUP] [int] NULL,
[L_OUTSIDE_DETAILS] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[L_METS] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[L_PLANNED] [int] NULL,
[L_LYMPHOEDEMA] [int] NULL,
[L_DIARY] [int] NULL,
[L_SEIZURES] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[L_OUTCOME] [int] NULL,
[L_OTHER_OUTCOME] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[L_RE_BX] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[L_DISCHARGE] [int] NULL,
[L_OTHER_DISCHARGE] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[L_SALT_ASSESSMENT] [int] NULL,
[L_SALT_ASSESSMENT_DATE] [smalldatetime] NULL,
[L_INVESTIGATIONS] [text] COLLATE Latin1_General_CI_AS NULL,
[L_COMPLICATIONS] [text] COLLATE Latin1_General_CI_AS NULL,
[L_PLAN] [text] COLLATE Latin1_General_CI_AS NULL,
[ACTION_ID] [int] NULL,
[StratifiedFollowupType] [int] NULL
) ON [PRIMARY]
GO
