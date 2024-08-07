CREATE TABLE [Merge_R_Compare].[tblMAIN_REFERRALS_tblValidatedData]
(
[SrcSys_MajorExt] [tinyint] NULL,
[Src_UID_MajorExt] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[SrcSys_Major] [tinyint] NULL,
[Src_UID_Major] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[IsValidatedMajor] [bit] NULL,
[IsConfirmed] [bit] NULL,
[LastUpdated] [datetime] NULL,
[SrcSys] [tinyint] NOT NULL,
[Src_UID] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[CARE_ID] [int] NULL,
[PATIENT_ID] [int] NULL,
[TEMP_ID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[L_CANCER_SITE] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[N2_1_REFERRAL_SOURCE] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[N2_2_ORG_CODE_REF] [varchar] (6) COLLATE Latin1_General_CI_AS NULL,
[N2_3_REFERRER_CODE] [varchar] (10) COLLATE Latin1_General_CI_AS NULL,
[N2_4_PRIORITY_TYPE] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[N2_5_DECISION_DATE] [smalldatetime] NULL,
[N2_6_RECEIPT_DATE] [smalldatetime] NULL,
[N2_7_CONSULTANT] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[N2_8_SPECIALTY] [int] NULL,
[N2_9_FIRST_SEEN_DATE] [smalldatetime] NULL,
[N1_3_ORG_CODE_SEEN] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[N2_10_FIRST_SEEN_DELAY] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[N2_12_CANCER_TYPE] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[N2_13_CANCER_STATUS] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[L_FIRST_APPOINTMENT] [int] NULL,
[L_CANCELLED_DATE] [smalldatetime] NULL,
[N2_14_ADJ_TIME] [int] NULL,
[N2_15_ADJ_REASON] [int] NULL,
[L_REFERRAL_METHOD] [int] NULL,
[N2_16_OP_REFERRAL] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[L_SPECIALIST_DATE] [smalldatetime] NULL,
[L_ORG_CODE_SPECIALIST] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[L_SPECIALIST_SEEN_DATE] [smalldatetime] NULL,
[N1_3_ORG_CODE_SPEC_SEEN] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[N_UPGRADE_DATE] [smalldatetime] NULL,
[N_UPGRADE_ORG_CODE] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[L_UPGRADE_WHEN] [int] NULL,
[L_UPGRADE_WHO] [int] NULL,
[N4_1_DIAGNOSIS_DATE] [smalldatetime] NULL,
[L_DIAGNOSIS] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[N4_2_DIAGNOSIS_CODE] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[L_ORG_CODE_DIAGNOSIS] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[L_PT_INFORMED_DATE] [smalldatetime] NULL,
[L_OTHER_DIAG_DATE] [smalldatetime] NULL,
[N4_3_LATERALITY] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[N4_4_BASIS_DIAGNOSIS] [int] NULL,
[L_TOPOGRAPHY] [varchar] (7) COLLATE Latin1_General_CI_AS NULL,
[L_HISTOLOGY_GROUP] [int] NULL,
[N4_5_HISTOLOGY] [varchar] (10) COLLATE Latin1_General_CI_AS NULL,
[N4_6_DIFFERENTIATION] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[ClinicalTStage] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[ClinicalTCertainty] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[ClinicalNStage] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[ClinicalNCertainty] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[ClinicalMStage] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[ClinicalMCertainty] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[ClinicalOverallCertainty] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[N6_9_SITE_CLASSIFICATION] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[PathologicalOverallCertainty] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[PathologicalTCertainty] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[PathologicalTStage] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[PathologicalNCertainty] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[PathologicalNStage] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[PathologicalMCertainty] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[PathologicalMStage] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[L_GP_INFORMED] [int] NULL,
[L_GP_INFORMED_DATE] [smalldatetime] NULL,
[L_GP_NOT] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[L_REL_INFORMED] [int] NULL,
[L_NURSE_PRESENT] [varchar] (3) COLLATE Latin1_General_CI_AS NULL,
[L_SPEC_NURSE_DATE] [smalldatetime] NULL,
[L_SEEN_NURSE_DATE] [smalldatetime] NULL,
[N16_1_ADJ_DAYS] [int] NULL,
[N16_2_ADJ_DAYS] [int] NULL,
[N16_3_ADJ_DECISION_CODE] [int] NULL,
[N16_4_ADJ_TREAT_CODE] [int] NULL,
[N16_5_DECISION_REASON_CODE] [int] NULL,
[N16_6_TREATMENT_REASON_CODE] [int] NULL,
[PathologicalTNMDate] [smalldatetime] NULL,
[ClinicalTNMDate] [smalldatetime] NULL,
[L_FIRST_CONSULTANT] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[L_APPROPRIATE] [int] NULL,
[L_TERTIARY_DATE] [smalldatetime] NULL,
[L_TERTIARY_TRUST] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[L_TERTIARY_REASON] [int] NULL,
[L_INAP_REF] [int] NULL,
[L_NEW_CA_SITE] [varchar] (20) COLLATE Latin1_General_CI_AS NULL,
[L_AUTO_REF] [int] NULL,
[L_SEC_DIAGNOSIS_G] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[L_SEC_DIAGNOSIS] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[L_WRONG_REF] [int] NULL,
[L_WRONG_REASON] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[L_TUMOUR_STATUS] [int] NULL,
[L_NON_CANCER] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[L_FIRST_APP] [int] NULL,
[L_NO_APP] [int] NULL,
[L_DIAG_WHO] [int] NULL,
[L_RECURRENCE] [int] NULL,
[L_OTHER_SYMPS] [text] COLLATE Latin1_General_CI_AS NULL,
[L_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[N2_11_FIRST_SEEN_REASON] [text] COLLATE Latin1_General_CI_AS NULL,
[N16_7_DECISION_REASON] [text] COLLATE Latin1_General_CI_AS NULL,
[N16_8_TREATMENT_REASON] [text] COLLATE Latin1_General_CI_AS NULL,
[L_DIAGNOSIS_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[GP_PRACTICE_CODE] [varchar] (15) COLLATE Latin1_General_CI_AS NULL,
[ClinicalTNMGroup] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[PathologicalTNMGroup] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[L_KEY_WORKER_SEEN] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[L_PALLIATIVE_SPECIALIST_SEEN] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[GERM_CELL_NON_CNS_ID] [int] NULL,
[RECURRENCE_CANCER_SITE_ID] [int] NULL,
[ICD03_GROUP] [int] NULL,
[ICD03] [varchar] (6) COLLATE Latin1_General_CI_AS NULL,
[L_DATE_DIAGNOSIS_DAHNO_LUCADA] [smalldatetime] NULL,
[L_INDICATOR_CODE] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[PRIMARY_DIAGNOSIS_SUB_COMMENT] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[CONSULTANT_CODE_AT_DIAGNOSIS] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[FETOPROTEIN] [int] NULL,
[GONADOTROPIN] [int] NULL,
[GONADOTROPIN_SERUM] [int] NULL,
[FETOPROTEIN_SERUM] [int] NULL,
[SARCOMA_TUMOUR_SITE_BONE] [varchar] (4) COLLATE Latin1_General_CI_AS NULL,
[SARCOMA_TUMOUR_SITE_SOFT_TISSUE] [varchar] (4) COLLATE Latin1_General_CI_AS NULL,
[SARCOMA_TUMOUR_SUBSITE_BONE] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE] [int] NULL,
[ROOT_DECISION_DATE_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[ROOT_RECEIPT_DATE_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[ROOT_FIRST_SEEN_DATE_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[ROOT_DIAGNOSIS_DATE_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[ROOT_UPGRADE_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[FIRST_APPT_TIME] [datetime] NULL,
[TRANSFER_REASON] [int] NULL,
[DATE_NEW_REFERRAL] [smalldatetime] NULL,
[TUMOUR_SITE_NEW] [int] NULL,
[DATE_TRANSFER_ACTIONED] [smalldatetime] NULL,
[SOURCE_CARE_ID] [int] NULL,
[ADT_REF_ID] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[ACTION_ID] [int] NULL,
[DIAGNOSIS_ACTION_ID] [int] NULL,
[ORIGINAL_SOURCE_CARE_ID] [int] NULL,
[TRANSFER_DATE_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[SPECIALIST_REFERRAL_COMMENTS] [text] COLLATE Latin1_General_CI_AS NULL,
[NON_CANCER_DIAGNOSIS_CHAPTER] [int] NULL,
[NON_CANCER_DIAGNOSIS_GROUP] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[NON_CANCER_DIAGNOSIS_CODE] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[TNM_UNKNOWN] [bit] NULL,
[ReferringPractice] [int] NULL,
[ReferringGP] [int] NULL,
[ReferringBranch] [int] NULL,
[BankedTissue] [int] NULL,
[BankedTissueTumour] [bit] NULL,
[BankedTissueBlood] [bit] NULL,
[BankedTissueCSF] [bit] NULL,
[BankedTissueBoneMarrow] [bit] NULL,
[SNOMed_CT] [int] NULL,
[ADT_PLACER_ID] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[SNOMEDCTDiagnosisID] [int] NULL,
[FasterDiagnosisOrganisationID] [int] NULL,
[FasterDiagnosisCancerSiteOverrideID] [int] NULL,
[FasterDiagnosisExclusionDate] [datetime] NULL,
[FasterDiagnosisExclusionReasonID] [int] NULL,
[FasterDiagnosisDelayReasonID] [int] NULL,
[FasterDiagnosisDelayReasonComments] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[FasterDiagnosisCommunicationMethodID] [int] NULL,
[FasterDiagnosisInformingCareProfessionalID] [int] NULL,
[FasterDiagnosisOtherCareProfessional] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[FasterDiagnosisOtherCommunicationMethod] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[NonPrimaryPathwayOptionsID] [int] NULL,
[DiagnosisUncertainty] [bit] NULL,
[TNMOrganisation] [int] NULL,
[FasterDiagnosisTargetRCComments] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[FasterDiagnosisEndRCComments] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[TNMOrganisation_Integrated] [int] NULL,
[LDHValue] [int] NULL,
[BankedTissueUrine] [bit] NULL,
[SubsiteID] [int] NULL,
[PredictedBreachStatus] [int] NULL,
[RMRefID] [int] NULL,
[TertiaryReferralKey] [uniqueidentifier] NULL,
[ClinicalTLetter] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[ClinicalNLetter] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[ClinicalMLetter] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[PathologicalTLetter] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[PathologicalNLetter] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[PathologicalMLetter] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[FDPlannedInterval] [bit] NULL,
[LabReportDate] [smalldatetime] NULL,
[LabReportOrgID] [int] NULL,
[ReferralRoute] [int] NULL,
[ReferralOtherRoute] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[RelapseMorphology] [bit] NULL,
[RelapseFlow] [bit] NULL,
[RelapseMolecular] [bit] NULL,
[RelapseClinicalExamination] [bit] NULL,
[RelapseOther] [bit] NULL,
[RapidDiagnostic] [nvarchar] (2) COLLATE Latin1_General_CI_AS NULL,
[PrimaryReferralFlag] [bit] NULL,
[OtherAssessedBy] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[SharedBreach] [decimal] (2, 1) NULL,
[PredictedBreachYear] [int] NULL,
[PredictedBreachMonth] [int] NULL,
[ValidatedRecordCreatedDttm] [datetime] NOT NULL
) ON [PRIMARY]
GO
