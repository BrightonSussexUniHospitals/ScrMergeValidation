SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [Merge_DM_MatchViews].[tblMAIN_REFERRALS_vw_Match_MajorValidationColumns_SrcSys] AS

SELECT		*
FROM		(SELECT		SrcSys_Major
						,Src_UID_Major
						,FieldName
						,SrcSys
			FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidationColumns) mmvc
PIVOT		(MAX(SrcSys)
			FOR FieldName IN	(CARE_ID
								,PATIENT_ID
								,TEMP_ID
								,L_CANCER_SITE
								,N2_1_REFERRAL_SOURCE
								,N2_2_ORG_CODE_REF
								,N2_3_REFERRER_CODE
								,N2_4_PRIORITY_TYPE
								,N2_5_DECISION_DATE
								,N2_6_RECEIPT_DATE
								,N2_7_CONSULTANT
								,N2_8_SPECIALTY
								,N2_9_FIRST_SEEN_DATE
								,N1_3_ORG_CODE_SEEN
								,N2_10_FIRST_SEEN_DELAY
								,N2_12_CANCER_TYPE
								,N2_13_CANCER_STATUS
								,L_FIRST_APPOINTMENT
								,L_CANCELLED_DATE
								,N2_14_ADJ_TIME
								,N2_15_ADJ_REASON
								,L_REFERRAL_METHOD
								,N2_16_OP_REFERRAL
								,L_SPECIALIST_DATE
								,L_ORG_CODE_SPECIALIST
								,L_SPECIALIST_SEEN_DATE
								,N1_3_ORG_CODE_SPEC_SEEN
								,N_UPGRADE_DATE
								,N_UPGRADE_ORG_CODE
								,L_UPGRADE_WHEN
								,L_UPGRADE_WHO
								,N4_1_DIAGNOSIS_DATE
								,L_DIAGNOSIS
								,N4_2_DIAGNOSIS_CODE
								,L_ORG_CODE_DIAGNOSIS
								,L_PT_INFORMED_DATE
								,L_OTHER_DIAG_DATE
								,N4_3_LATERALITY
								,N4_4_BASIS_DIAGNOSIS
								,L_TOPOGRAPHY
								,L_HISTOLOGY_GROUP
								,N4_5_HISTOLOGY
								,N4_6_DIFFERENTIATION
								,ClinicalTStage
								,ClinicalTCertainty
								,ClinicalNStage
								,ClinicalNCertainty
								,ClinicalMStage
								,ClinicalMCertainty
								,ClinicalOverallCertainty
								,N6_9_SITE_CLASSIFICATION
								,PathologicalOverallCertainty
								,PathologicalTCertainty
								,PathologicalTStage
								,PathologicalNCertainty
								,PathologicalNStage
								,PathologicalMCertainty
								,PathologicalMStage
								,L_GP_INFORMED
								,L_GP_INFORMED_DATE
								,L_GP_NOT
								,L_REL_INFORMED
								,L_NURSE_PRESENT
								,L_SPEC_NURSE_DATE
								,L_SEEN_NURSE_DATE
								,N16_1_ADJ_DAYS
								,N16_2_ADJ_DAYS
								,N16_3_ADJ_DECISION_CODE
								,N16_4_ADJ_TREAT_CODE
								,N16_5_DECISION_REASON_CODE
								,N16_6_TREATMENT_REASON_CODE
								,PathologicalTNMDate
								,ClinicalTNMDate
								,L_FIRST_CONSULTANT
								,L_APPROPRIATE
								,L_TERTIARY_DATE
								,L_TERTIARY_TRUST
								,L_TERTIARY_REASON
								,L_INAP_REF
								,L_NEW_CA_SITE
								,L_AUTO_REF
								,L_SEC_DIAGNOSIS_G
								,L_SEC_DIAGNOSIS
								,L_WRONG_REF
								,L_WRONG_REASON
								,L_TUMOUR_STATUS
								,L_NON_CANCER
								,L_FIRST_APP
								,L_NO_APP
								,L_DIAG_WHO
								,L_RECURRENCE
								,L_OTHER_SYMPS
								,L_COMMENTS
								,N2_11_FIRST_SEEN_REASON
								,N16_7_DECISION_REASON
								,N16_8_TREATMENT_REASON
								,L_DIAGNOSIS_COMMENTS
								,GP_PRACTICE_CODE
								,ClinicalTNMGroup
								,PathologicalTNMGroup
								,L_KEY_WORKER_SEEN
								,L_PALLIATIVE_SPECIALIST_SEEN
								,GERM_CELL_NON_CNS_ID
								,RECURRENCE_CANCER_SITE_ID
								,ICD03_GROUP
								,ICD03
								,L_DATE_DIAGNOSIS_DAHNO_LUCADA
								,L_INDICATOR_CODE
								,PRIMARY_DIAGNOSIS_SUB_COMMENT
								,CONSULTANT_CODE_AT_DIAGNOSIS
								,CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS
								,FETOPROTEIN
								,GONADOTROPIN
								,GONADOTROPIN_SERUM
								,FETOPROTEIN_SERUM
								,SARCOMA_TUMOUR_SITE_BONE
								,SARCOMA_TUMOUR_SITE_SOFT_TISSUE
								,SARCOMA_TUMOUR_SUBSITE_BONE
								,SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
								,ROOT_DECISION_DATE_COMMENTS
								,ROOT_RECEIPT_DATE_COMMENTS
								,ROOT_FIRST_SEEN_DATE_COMMENTS
								,ROOT_DIAGNOSIS_DATE_COMMENTS
								,ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS
								,ROOT_UPGRADE_COMMENTS
								,FIRST_APPT_TIME
								,TRANSFER_REASON
								,DATE_NEW_REFERRAL
								,TUMOUR_SITE_NEW
								,DATE_TRANSFER_ACTIONED
								,SOURCE_CARE_ID
								,ADT_REF_ID
								,ACTION_ID
								,DIAGNOSIS_ACTION_ID
								,ORIGINAL_SOURCE_CARE_ID
								,TRANSFER_DATE_COMMENTS
								,SPECIALIST_REFERRAL_COMMENTS
								,NON_CANCER_DIAGNOSIS_CHAPTER
								,NON_CANCER_DIAGNOSIS_GROUP
								,NON_CANCER_DIAGNOSIS_CODE
								,TNM_UNKNOWN
								,ReferringPractice
								,ReferringGP
								,ReferringBranch
								,BankedTissue
								,BankedTissueTumour
								,BankedTissueBlood
								,BankedTissueCSF
								,BankedTissueBoneMarrow
								,SNOMed_CT
								,ADT_PLACER_ID
								,SNOMEDCTDiagnosisID
								,FasterDiagnosisOrganisationID
								,FasterDiagnosisCancerSiteOverrideID
								,FasterDiagnosisExclusionDate
								,FasterDiagnosisExclusionReasonID
								,FasterDiagnosisDelayReasonID
								,FasterDiagnosisDelayReasonComments
								,FasterDiagnosisCommunicationMethodID
								,FasterDiagnosisInformingCareProfessionalID
								,FasterDiagnosisOtherCareProfessional
								,FasterDiagnosisOtherCommunicationMethod
								,NonPrimaryPathwayOptionsID
								,DiagnosisUncertainty
								,TNMOrganisation
								,FasterDiagnosisTargetRCComments
								,FasterDiagnosisEndRCComments
								,TNMOrganisation_Integrated
								,LDHValue
								,BankedTissueUrine
								,SubsiteID
								,PredictedBreachStatus
								,RMRefID
								,TertiaryReferralKey
								,ClinicalTLetter
								,ClinicalNLetter
								,ClinicalMLetter
								,PathologicalTLetter
								,PathologicalNLetter
								,PathologicalMLetter
								,FDPlannedInterval
								,LabReportDate
								,LabReportOrgID
								,ReferralRoute
								,ReferralOtherRoute
								,RelapseMorphology
								,RelapseFlow
								,RelapseMolecular
								,RelapseClinicalExamination
								,RelapseOther
								,RapidDiagnostic
								,PrimaryReferralFlag
								,OtherAssessedBy
								,SharedBreach
								,PredictedBreachYear
								,PredictedBreachMonth)
			) AS PivotTable

GO
