CREATE TABLE [Merge_R_Compare].[DedupeChangedRefs]
(
[SrcSys_MajorExt] [tinyint] NULL,
[Src_UID_MajorExt] [varchar] (255) NULL,
[SrcSys_Major] [tinyint] NULL,
[Src_UID_Major] [varchar] (255) NULL,
[IsValidatedMajor] [bit] NULL,
[IsConfirmed] [bit] NULL,
[LastUpdated] [datetime] NULL,
[SrcSys] [tinyint] NOT NULL,
[Src_UID] [varchar] (255) NOT NULL,
[CARE_ID] [int] NULL,
[PATIENT_ID] [int] NULL,
[OrigPATIENT_ID] [int] NOT NULL,
[PATIENT_ID_Diff] [int] NOT NULL,
[TEMP_ID_Diff] [int] NOT NULL,
[L_CANCER_SITE_Diff] [int] NOT NULL,
[N2_1_REFERRAL_SOURCE_Diff] [int] NOT NULL,
[N2_2_ORG_CODE_REF_Diff] [int] NOT NULL,
[N2_3_REFERRER_CODE_Diff] [int] NOT NULL,
[N2_4_PRIORITY_TYPE_Diff] [int] NOT NULL,
[N2_5_DECISION_DATE_Diff] [int] NOT NULL,
[N2_6_RECEIPT_DATE_Diff] [int] NOT NULL,
[N2_7_CONSULTANT_Diff] [int] NOT NULL,
[N2_8_SPECIALTY_Diff] [int] NOT NULL,
[N2_9_FIRST_SEEN_DATE_Diff] [int] NOT NULL,
[N1_3_ORG_CODE_SEEN_Diff] [int] NOT NULL,
[N2_10_FIRST_SEEN_DELAY_Diff] [int] NOT NULL,
[N2_12_CANCER_TYPE_Diff] [int] NOT NULL,
[N2_13_CANCER_STATUS_Diff] [int] NOT NULL,
[L_FIRST_APPOINTMENT_Diff] [int] NOT NULL,
[L_CANCELLED_DATE_Diff] [int] NOT NULL,
[N2_14_ADJ_TIME_Diff] [int] NOT NULL,
[N2_15_ADJ_REASON_Diff] [int] NOT NULL,
[L_REFERRAL_METHOD_Diff] [int] NOT NULL,
[N2_16_OP_REFERRAL_Diff] [int] NOT NULL,
[L_SPECIALIST_DATE_Diff] [int] NOT NULL,
[L_ORG_CODE_SPECIALIST_Diff] [int] NOT NULL,
[L_SPECIALIST_SEEN_DATE_Diff] [int] NOT NULL,
[N1_3_ORG_CODE_SPEC_SEEN_Diff] [int] NOT NULL,
[N_UPGRADE_DATE_Diff] [int] NOT NULL,
[N_UPGRADE_ORG_CODE_Diff] [int] NOT NULL,
[L_UPGRADE_WHEN_Diff] [int] NOT NULL,
[L_UPGRADE_WHO_Diff] [int] NOT NULL,
[N4_1_DIAGNOSIS_DATE_Diff] [int] NOT NULL,
[L_DIAGNOSIS_Diff] [int] NOT NULL,
[N4_2_DIAGNOSIS_CODE_Diff] [int] NOT NULL,
[L_ORG_CODE_DIAGNOSIS_Diff] [int] NOT NULL,
[L_PT_INFORMED_DATE_Diff] [int] NOT NULL,
[L_OTHER_DIAG_DATE_Diff] [int] NOT NULL,
[N4_3_LATERALITY_Diff] [int] NOT NULL,
[N4_4_BASIS_DIAGNOSIS_Diff] [int] NOT NULL,
[L_TOPOGRAPHY_Diff] [int] NOT NULL,
[L_HISTOLOGY_GROUP_Diff] [int] NOT NULL,
[N4_5_HISTOLOGY_Diff] [int] NOT NULL,
[N4_6_DIFFERENTIATION_Diff] [int] NOT NULL,
[ClinicalTStage_Diff] [int] NOT NULL,
[ClinicalTCertainty_Diff] [int] NOT NULL,
[ClinicalNStage_Diff] [int] NOT NULL,
[ClinicalNCertainty_Diff] [int] NOT NULL,
[ClinicalMStage_Diff] [int] NOT NULL,
[ClinicalMCertainty_Diff] [int] NOT NULL,
[ClinicalOverallCertainty_Diff] [int] NOT NULL,
[N6_9_SITE_CLASSIFICATION_Diff] [int] NOT NULL,
[PathologicalOverallCertainty_Diff] [int] NOT NULL,
[PathologicalTCertainty_Diff] [int] NOT NULL,
[PathologicalTStage_Diff] [int] NOT NULL,
[PathologicalNCertainty_Diff] [int] NOT NULL,
[PathologicalNStage_Diff] [int] NOT NULL,
[PathologicalMCertainty_Diff] [int] NOT NULL,
[PathologicalMStage_Diff] [int] NOT NULL,
[L_GP_INFORMED_Diff] [int] NOT NULL,
[L_GP_INFORMED_DATE_Diff] [int] NOT NULL,
[L_GP_NOT_Diff] [int] NOT NULL,
[L_REL_INFORMED_Diff] [int] NOT NULL,
[L_NURSE_PRESENT_Diff] [int] NOT NULL,
[L_SPEC_NURSE_DATE_Diff] [int] NOT NULL,
[L_SEEN_NURSE_DATE_Diff] [int] NOT NULL,
[N16_1_ADJ_DAYS_Diff] [int] NOT NULL,
[N16_2_ADJ_DAYS_Diff] [int] NOT NULL,
[N16_3_ADJ_DECISION_CODE_Diff] [int] NOT NULL,
[N16_4_ADJ_TREAT_CODE_Diff] [int] NOT NULL,
[N16_5_DECISION_REASON_CODE_Diff] [int] NOT NULL,
[N16_6_TREATMENT_REASON_CODE_Diff] [int] NOT NULL,
[PathologicalTNMDate_Diff] [int] NOT NULL,
[ClinicalTNMDate_Diff] [int] NOT NULL,
[L_FIRST_CONSULTANT_Diff] [int] NOT NULL,
[L_APPROPRIATE_Diff] [int] NOT NULL,
[L_TERTIARY_DATE_Diff] [int] NOT NULL,
[L_TERTIARY_TRUST_Diff] [int] NOT NULL,
[L_TERTIARY_REASON_Diff] [int] NOT NULL,
[L_INAP_REF_Diff] [int] NOT NULL,
[L_NEW_CA_SITE_Diff] [int] NOT NULL,
[L_AUTO_REF_Diff] [int] NOT NULL,
[L_SEC_DIAGNOSIS_G_Diff] [int] NOT NULL,
[L_SEC_DIAGNOSIS_Diff] [int] NOT NULL,
[L_WRONG_REF_Diff] [int] NOT NULL,
[L_WRONG_REASON_Diff] [int] NOT NULL,
[L_TUMOUR_STATUS_Diff] [int] NOT NULL,
[L_NON_CANCER_Diff] [int] NOT NULL,
[L_FIRST_APP_Diff] [int] NOT NULL,
[L_NO_APP_Diff] [int] NOT NULL,
[L_DIAG_WHO_Diff] [int] NOT NULL,
[L_RECURRENCE_Diff] [int] NOT NULL,
[GP_PRACTICE_CODE_Diff] [int] NOT NULL,
[ClinicalTNMGroup_Diff] [int] NOT NULL,
[PathologicalTNMGroup_Diff] [int] NOT NULL,
[L_KEY_WORKER_SEEN_Diff] [int] NOT NULL,
[L_PALLIATIVE_SPECIALIST_SEEN_Diff] [int] NOT NULL,
[GERM_CELL_NON_CNS_ID_Diff] [int] NOT NULL,
[RECURRENCE_CANCER_SITE_ID_Diff] [int] NOT NULL,
[ICD03_GROUP_Diff] [int] NOT NULL,
[ICD03_Diff] [int] NOT NULL,
[L_DATE_DIAGNOSIS_DAHNO_LUCADA_Diff] [int] NOT NULL,
[L_INDICATOR_CODE_Diff] [int] NOT NULL,
[PRIMARY_DIAGNOSIS_SUB_COMMENT_Diff] [int] NOT NULL,
[CONSULTANT_CODE_AT_DIAGNOSIS_Diff] [int] NOT NULL,
[CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS_Diff] [int] NOT NULL,
[FETOPROTEIN_Diff] [int] NOT NULL,
[GONADOTROPIN_Diff] [int] NOT NULL,
[GONADOTROPIN_SERUM_Diff] [int] NOT NULL,
[FETOPROTEIN_SERUM_Diff] [int] NOT NULL,
[SARCOMA_TUMOUR_SITE_BONE_Diff] [int] NOT NULL,
[SARCOMA_TUMOUR_SITE_SOFT_TISSUE_Diff] [int] NOT NULL,
[SARCOMA_TUMOUR_SUBSITE_BONE_Diff] [int] NOT NULL,
[SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE_Diff] [int] NOT NULL,
[FIRST_APPT_TIME_Diff] [int] NOT NULL,
[TRANSFER_REASON_Diff] [int] NOT NULL,
[DATE_NEW_REFERRAL_Diff] [int] NOT NULL,
[TUMOUR_SITE_NEW_Diff] [int] NOT NULL,
[DATE_TRANSFER_ACTIONED_Diff] [int] NOT NULL,
[SOURCE_CARE_ID_Diff] [int] NOT NULL,
[ADT_REF_ID_Diff] [int] NOT NULL,
[ACTION_ID_Diff] [int] NOT NULL,
[DIAGNOSIS_ACTION_ID_Diff] [int] NOT NULL,
[ORIGINAL_SOURCE_CARE_ID_Diff] [int] NOT NULL,
[NON_CANCER_DIAGNOSIS_CHAPTER_Diff] [int] NOT NULL,
[NON_CANCER_DIAGNOSIS_GROUP_Diff] [int] NOT NULL,
[NON_CANCER_DIAGNOSIS_CODE_Diff] [int] NOT NULL,
[TNM_UNKNOWN_Diff] [int] NOT NULL,
[ReferringPractice_Diff] [int] NOT NULL,
[ReferringGP_Diff] [int] NOT NULL,
[ReferringBranch_Diff] [int] NOT NULL,
[BankedTissue_Diff] [int] NOT NULL,
[BankedTissueTumour_Diff] [int] NOT NULL,
[BankedTissueBlood_Diff] [int] NOT NULL,
[BankedTissueCSF_Diff] [int] NOT NULL,
[BankedTissueBoneMarrow_Diff] [int] NOT NULL,
[SNOMed_CT_Diff] [int] NOT NULL,
[ADT_PLACER_ID_Diff] [int] NOT NULL,
[SNOMEDCTDiagnosisID_Diff] [int] NOT NULL,
[FasterDiagnosisOrganisationID_Diff] [int] NOT NULL,
[FasterDiagnosisCancerSiteOverrideID_Diff] [int] NOT NULL,
[FasterDiagnosisExclusionDate_Diff] [int] NOT NULL,
[FasterDiagnosisExclusionReasonID_Diff] [int] NOT NULL,
[FasterDiagnosisDelayReasonID_Diff] [int] NOT NULL,
[FasterDiagnosisDelayReasonComments_Diff] [int] NOT NULL,
[FasterDiagnosisCommunicationMethodID_Diff] [int] NOT NULL,
[FasterDiagnosisInformingCareProfessionalID_Diff] [int] NOT NULL,
[FasterDiagnosisOtherCareProfessional_Diff] [int] NOT NULL,
[FasterDiagnosisOtherCommunicationMethod_Diff] [int] NOT NULL,
[NonPrimaryPathwayOptionsID_Diff] [int] NOT NULL,
[DiagnosisUncertainty_Diff] [int] NOT NULL,
[TNMOrganisation_Diff] [int] NOT NULL,
[FasterDiagnosisTargetRCComments_Diff] [int] NOT NULL,
[FasterDiagnosisEndRCComments_Diff] [int] NOT NULL,
[TNMOrganisation_Integrated_Diff] [int] NOT NULL,
[LDHValue_Diff] [int] NOT NULL,
[BankedTissueUrine_Diff] [int] NOT NULL,
[SubsiteID_Diff] [int] NOT NULL,
[PredictedBreachStatus_Diff] [int] NOT NULL,
[RMRefID_Diff] [int] NOT NULL,
[TertiaryReferralKey_Diff] [int] NOT NULL,
[ClinicalTLetter_Diff] [int] NOT NULL,
[ClinicalNLetter_Diff] [int] NOT NULL,
[ClinicalMLetter_Diff] [int] NOT NULL,
[PathologicalTLetter_Diff] [int] NOT NULL,
[PathologicalNLetter_Diff] [int] NOT NULL,
[PathologicalMLetter_Diff] [int] NOT NULL,
[FDPlannedInterval_Diff] [int] NOT NULL,
[LabReportDate_Diff] [int] NOT NULL,
[LabReportOrgID_Diff] [int] NOT NULL,
[ReferralRoute_Diff] [int] NOT NULL,
[ReferralOtherRoute_Diff] [int] NOT NULL,
[RelapseMorphology_Diff] [int] NOT NULL,
[RelapseFlow_Diff] [int] NOT NULL,
[RelapseMolecular_Diff] [int] NOT NULL,
[RelapseClinicalExamination_Diff] [int] NOT NULL,
[RelapseOther_Diff] [int] NOT NULL,
[RapidDiagnostic_Diff] [int] NOT NULL,
[PrimaryReferralFlag_Diff] [int] NOT NULL,
[OtherAssessedBy_Diff] [int] NOT NULL,
[SharedBreach_Diff] [int] NOT NULL,
[PredictedBreachYear_Diff] [int] NOT NULL,
[PredictedBreachMonth_Diff] [int] NOT NULL
)
GO
