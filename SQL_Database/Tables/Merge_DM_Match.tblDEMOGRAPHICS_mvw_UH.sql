CREATE TABLE [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH]
(
[IsSCR] [bit] NULL,
[IsMostRecent] [bit] NULL,
[SrcSys] [tinyint] NOT NULL,
[Src_UID] [nvarchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[OriginalNhsNo] [nvarchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[NhsNumber] [nvarchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[OriginalPasId] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[PasId] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[CasenoteId] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[DoB] [datetime] NULL,
[DoD] [date] NULL,
[Surname] [nvarchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Forename] [nvarchar] (141) COLLATE Latin1_General_CI_AS NULL,
[Postcode] [nvarchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[Sex] [nvarchar] (25) COLLATE Latin1_General_CI_AS NULL,
[Address1] [varchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[Address2] [varchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[Address3] [varchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[Address4] [varchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[Address5] [nvarchar] (150) COLLATE Latin1_General_CI_AS NULL,
[DeathStatus] [int] NULL,
[Title] [nvarchar] (256) COLLATE Latin1_General_CI_AS NULL,
[Ethnicity] [nvarchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[ReligionCode] [varchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[LastUpdated] [datetime] NULL,
[UpdateByPas] [int] NOT NULL,
[HashBytesValue] [varbinary] (8000) NULL,
[PATIENT_ID] [int] NULL,
[N1_1_NHS_NUMBER] [nvarchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[NHS_NUMBER_STATUS] [varchar] (3) COLLATE Latin1_General_CI_AS NULL,
[L_RA3_RID] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[L_RA7_RID] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[L_RVJ01_RID] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[TEMP_ID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[L_NSTS_STATUS] [int] NULL,
[N1_2_HOSPITAL_NUMBER] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[L_TITLE] [int] NULL,
[N1_5_SURNAME] [nvarchar] (60) COLLATE Latin1_General_CI_AS NULL,
[N1_6_FORENAME] [nvarchar] (141) COLLATE Latin1_General_CI_AS NULL,
[N1_7_ADDRESS_1] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[N1_7_ADDRESS_2] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[N1_7_ADDRESS_3] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[N1_7_ADDRESS_4] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[N1_7_ADDRESS_5] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[N1_8_POSTCODE] [nvarchar] (10) COLLATE Latin1_General_CI_AS NULL,
[N1_9_SEX] [nvarchar] (25) COLLATE Latin1_General_CI_AS NULL,
[N1_10_DATE_BIRTH] [datetime] NULL,
[N1_11_GP_CODE] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[N1_12_GP_PRACTICE_CODE] [varchar] (15) COLLATE Latin1_General_CI_AS NULL,
[N1_13_PCT] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[N1_14_SURNAME_BIRTH] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[N1_15_ETHNICITY] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[PAT_PREF_NAME] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[PAT_OCCUPATION] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[PAT_SOCIAL_CLASS] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[PAT_LIVES_ALONE] [bit] NULL,
[MARITAL_STATUS] [char] (1) COLLATE Latin1_General_CI_AS NULL,
[PAT_PREF_LANGUAGE] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[PAT_PREF_CONTACT] [int] NULL,
[L_DEATH_STATUS] [int] NULL,
[N15_1_DATE_DEATH] [date] NULL,
[N15_2_DEATH_LOCATION] [int] NULL,
[N15_3_DEATH_CAUSE] [int] NULL,
[N15_4_DEATH_CANCER] [int] NULL,
[N15_5_DEATH_CODE_1] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[N15_6_DEATH_CODE_2] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[N15_7_DEATH_CODE_3] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[N15_8_DEATH_CODE_4] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[N15_9_DEATH_DISCREPANCY] [int] NULL,
[N_CC4_TOWN] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[N_CC5_COUNTRY] [varchar] (3) COLLATE Latin1_General_CI_AS NULL,
[N_CC6_M_SURNAME] [varchar] (35) COLLATE Latin1_General_CI_AS NULL,
[N_CC7_M_CLASS] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[N_CC8_M_FORENAME] [varchar] (35) COLLATE Latin1_General_CI_AS NULL,
[N_CC9_M_DOB] [date] NULL,
[N_CC10_M_TOWN] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[N_CC11_M_COUNTRY] [varchar] (3) COLLATE Latin1_General_CI_AS NULL,
[N_CC12_M_OCC] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[N_CC13_M_OCC_DIAG] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[N_CC6_F_SURNAME] [varchar] (35) COLLATE Latin1_General_CI_AS NULL,
[N_CC7_F_CLASS] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[N_CC8_F_FORENAME] [varchar] (35) COLLATE Latin1_General_CI_AS NULL,
[N_CC9_F_DOB] [date] NULL,
[N_CC10_F_TOWN] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[N_CC11_F_COUNTRY] [varchar] (3) COLLATE Latin1_General_CI_AS NULL,
[N_CC12_F_OCC] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[N_CC13_F_OCC_DIAG] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[N_CC14_MULTI_BIRTH] [int] NULL,
[R_POST_MORTEM] [bit] NULL,
[R_DAY_PHONE] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[DAY_PHONE_EXT] [varchar] (10) COLLATE Latin1_General_CI_AS NULL,
[R_EVE_PHONE] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[EVE_PHONE_EXT] [varchar] (10) COLLATE Latin1_General_CI_AS NULL,
[R_DEATH_TREATMENT] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[R_PM_DETAILS] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[L_IATROGENIC_DEATH] [bit] NULL,
[L_INFECTION_DEATH] [bit] NULL,
[L_DEATH_COMMENTS] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[RELIGION] [int] NULL,
[CONTACT_DETAILS] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[NOK_NAME] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[NOK_ADDRESS_1] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[NOK_ADDRESS_2] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[NOK_ADDRESS_3] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[NOK_ADDRESS_4] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[NOK_ADDRESS_5] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[NOK_POSTCODE] [varchar] (10) COLLATE Latin1_General_CI_AS NULL,
[NOK_CONTACT] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[NOK_RELATIONSHIP] [varchar] (4) COLLATE Latin1_General_CI_AS NULL,
[PAT_DEPENDANTS] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[CARER_NAME] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[CARER_ADDRESS_1] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[CARER_ADDRESS_2] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[CARER_ADDRESS_3] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[CARER_ADDRESS_4] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[CARER_ADDRESS_5] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[CARER_POSTCODE] [varchar] (10) COLLATE Latin1_General_CI_AS NULL,
[CARER_CONTACT] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CARER_RELATIONSHIP] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[CARER1_TYPE] [varchar] (4) COLLATE Latin1_General_CI_AS NULL,
[CARER2_NAME] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[CARER2_ADDRESS_1] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[CARER2_ADDRESS_2] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[CARER2_ADDRESS_3] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[CARER2_ADDRESS_4] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[CARER2_ADDRESS_5] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[CARER2_POSTCODE] [varchar] (10) COLLATE Latin1_General_CI_AS NULL,
[CARER2_CONTACT] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CARER2_RELATIONSHIP] [varchar] (4) COLLATE Latin1_General_CI_AS NULL,
[CARER2_TYPE] [varchar] (4) COLLATE Latin1_General_CI_AS NULL,
[PT_AT_RISK] [bit] NULL,
[REASON_RISK] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[GESTATION] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[CAUSE_OF_DEATH_UROLOGY] [int] NULL,
[AVOIDABLE_DEATH] [bit] NULL,
[AVOIDABLE_DETAILS] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[OTHER_DEATH_CAUSE_UROLOGY] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ACTION_ID] [int] NULL,
[STATED_GENDER_CODE] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[CAUSE_OF_DEATH_UROLOGY_FUP] [int] NULL,
[DEATH_WITHIN_30_DAYS_OF_TREAT] [int] NULL,
[DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT] [int] NULL,
[DEATH_CAUSE_LATER_DATE] [int] NULL,
[RegisteredPractice] [int] NULL,
[RegisteredGP] [int] NULL,
[PersonSexualOrientation] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ADD CONSTRAINT [PK_tblDEMOGRAPHICS_mvw_UH] PRIMARY KEY CLUSTERED ([SrcSys], [Src_UID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Address1] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([Address1]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Address2] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([Address2]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Address3] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([Address3]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Address4] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([Address4]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Address5] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([Address5]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_CasenoteId] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([CasenoteId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_DeathStatus] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([DeathStatus]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_DoB] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([DoB]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_DoD] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([DoD]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Ethnicity] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([Ethnicity]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Forename] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([Forename]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tblDEMOGRAPHICS_mvw_UH_HashBytesValue] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([HashBytesValue]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_IsMostRecent] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([IsMostRecent]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_IsSCR_' + @Guid + '] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([IsSCR]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tblDEMOGRAPHICS_mvw_UH_IsSCR] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([IsSCR]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_NhsNumber] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([NhsNumber]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_OrignalNhsNo] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([OriginalNhsNo]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_OriginalPasId] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([OriginalPasId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_PasId] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([PasId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Postcode] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([Postcode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_ReligionCode] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([ReligionCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Sex] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([Sex]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Surname] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([Surname]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Title] ON [Merge_DM_Match].[tblDEMOGRAPHICS_mvw_UH] ([Title]) ON [PRIMARY]
GO
