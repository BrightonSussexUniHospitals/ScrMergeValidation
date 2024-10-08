SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Merge_DM_MatchViews].[tblMAIN_REFERRALS] AS

/******************************************************** © Copyright & Licensing ****************************************************************
© 2019 Perspicacity Ltd & Brighton & Sussex University Hospitals

This code / file is part of Perspicacity & BSUH's Cancer Data Warehouse & Reporting suite.

This Cancer Data Warehouse & Reporting suite is free software: you can 
redistribute it and/or modify it under the terms of the GNU Affero 
General Public License as published by the Free Software Foundation, 
either version 3 of the License, or (at your option) any later version.

This Cancer Data Warehouse & Reporting suite is distributed in the hope 
that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

A full copy of this code can be found at https://github.com/BrightonSussexUniHospitals/CancerReportingSuite

You may also be interested in the other repositories at https://github.com/perspicacity-ltd or
https://github.com/BrightonSussexUniHospitals

Original Work Created Date:	30/07/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop) & BSUH (Lawrence Simpson)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk / lawrencesimpson@nhs.net
Description:				Create a local config view to point at the place where the SCR
							replicated data is located so that the core procedures don't
							need to be changed when they are copied to different environments 
							(e.g. live vs test or from one trust to another)
**************************************************************************************************************************************************/

	-- Select a replica dataset from a V22.2 table
	SELECT  CAST(1 AS tinyint) AS SrcSysID    --ignore tilda tilda
			,CARE_ID
			,PATIENT_ID
			,TEMP_ID = TEMP_ID COLLATE DATABASE_DEFAULT
			,L_CANCER_SITE = L_CANCER_SITE COLLATE DATABASE_DEFAULT
			,N2_1_REFERRAL_SOURCE = N2_1_REFERRAL_SOURCE COLLATE DATABASE_DEFAULT
			,N2_2_ORG_CODE_REF = N2_2_ORG_CODE_REF COLLATE DATABASE_DEFAULT
			,N2_3_REFERRER_CODE = N2_3_REFERRER_CODE COLLATE DATABASE_DEFAULT
			,N2_4_PRIORITY_TYPE = N2_4_PRIORITY_TYPE COLLATE DATABASE_DEFAULT
			,N2_5_DECISION_DATE
			,N2_6_RECEIPT_DATE
			,N2_7_CONSULTANT = N2_7_CONSULTANT COLLATE DATABASE_DEFAULT
			,N2_8_SPECIALTY
			,N2_9_FIRST_SEEN_DATE
			,N1_3_ORG_CODE_SEEN = N1_3_ORG_CODE_SEEN COLLATE DATABASE_DEFAULT
			,N2_10_FIRST_SEEN_DELAY = N2_10_FIRST_SEEN_DELAY COLLATE DATABASE_DEFAULT
			,N2_12_CANCER_TYPE = N2_12_CANCER_TYPE COLLATE DATABASE_DEFAULT
			,N2_13_CANCER_STATUS = N2_13_CANCER_STATUS COLLATE DATABASE_DEFAULT
			,L_FIRST_APPOINTMENT
			,L_CANCELLED_DATE
			,N2_14_ADJ_TIME
			,N2_15_ADJ_REASON
			,L_REFERRAL_METHOD
			,N2_16_OP_REFERRAL = N2_16_OP_REFERRAL COLLATE DATABASE_DEFAULT
			,L_SPECIALIST_DATE
			,L_ORG_CODE_SPECIALIST = L_ORG_CODE_SPECIALIST COLLATE DATABASE_DEFAULT
			,L_SPECIALIST_SEEN_DATE
			,N1_3_ORG_CODE_SPEC_SEEN = N1_3_ORG_CODE_SPEC_SEEN COLLATE DATABASE_DEFAULT
			,N_UPGRADE_DATE
			,N_UPGRADE_ORG_CODE = N_UPGRADE_ORG_CODE COLLATE DATABASE_DEFAULT
			,L_UPGRADE_WHEN
			,L_UPGRADE_WHO
			,N4_1_DIAGNOSIS_DATE
			,L_DIAGNOSIS = L_DIAGNOSIS COLLATE DATABASE_DEFAULT
			,N4_2_DIAGNOSIS_CODE = N4_2_DIAGNOSIS_CODE COLLATE DATABASE_DEFAULT
			,L_ORG_CODE_DIAGNOSIS = L_ORG_CODE_DIAGNOSIS COLLATE DATABASE_DEFAULT
			,L_PT_INFORMED_DATE
			,L_OTHER_DIAG_DATE
			,N4_3_LATERALITY = N4_3_LATERALITY COLLATE DATABASE_DEFAULT
			,N4_4_BASIS_DIAGNOSIS
			,L_TOPOGRAPHY = L_TOPOGRAPHY COLLATE DATABASE_DEFAULT
			,L_HISTOLOGY_GROUP
			,N4_5_HISTOLOGY = N4_5_HISTOLOGY COLLATE DATABASE_DEFAULT
			,N4_6_DIFFERENTIATION = N4_6_DIFFERENTIATION COLLATE DATABASE_DEFAULT
			,ClinicalTStage = ClinicalTStage COLLATE DATABASE_DEFAULT
			,ClinicalTCertainty = ClinicalTCertainty COLLATE DATABASE_DEFAULT
			,ClinicalNStage = ClinicalNStage COLLATE DATABASE_DEFAULT
			,ClinicalNCertainty = ClinicalNCertainty COLLATE DATABASE_DEFAULT
			,ClinicalMStage = ClinicalMStage COLLATE DATABASE_DEFAULT
			,ClinicalMCertainty = ClinicalMCertainty COLLATE DATABASE_DEFAULT
			,ClinicalOverallCertainty = ClinicalOverallCertainty COLLATE DATABASE_DEFAULT
			,N6_9_SITE_CLASSIFICATION = N6_9_SITE_CLASSIFICATION COLLATE DATABASE_DEFAULT
			,PathologicalOverallCertainty = PathologicalOverallCertainty COLLATE DATABASE_DEFAULT
			,PathologicalTCertainty = PathologicalTCertainty COLLATE DATABASE_DEFAULT
			,PathologicalTStage = PathologicalTStage COLLATE DATABASE_DEFAULT
			,PathologicalNCertainty = PathologicalNCertainty COLLATE DATABASE_DEFAULT
			,PathologicalNStage = PathologicalNStage COLLATE DATABASE_DEFAULT
			,PathologicalMCertainty = PathologicalMCertainty COLLATE DATABASE_DEFAULT
			,PathologicalMStage = PathologicalMStage COLLATE DATABASE_DEFAULT
			,L_GP_INFORMED
			,L_GP_INFORMED_DATE
			,L_GP_NOT = L_GP_NOT COLLATE DATABASE_DEFAULT
			,L_REL_INFORMED
			,L_NURSE_PRESENT = L_NURSE_PRESENT COLLATE DATABASE_DEFAULT
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
			,L_FIRST_CONSULTANT = L_FIRST_CONSULTANT COLLATE DATABASE_DEFAULT
			,L_APPROPRIATE
			,L_TERTIARY_DATE
			,L_TERTIARY_TRUST = L_TERTIARY_TRUST COLLATE DATABASE_DEFAULT
			,L_TERTIARY_REASON
			,L_INAP_REF
			,L_NEW_CA_SITE = L_NEW_CA_SITE COLLATE DATABASE_DEFAULT
			,L_AUTO_REF
			,L_SEC_DIAGNOSIS_G = L_SEC_DIAGNOSIS_G COLLATE DATABASE_DEFAULT
			,L_SEC_DIAGNOSIS = L_SEC_DIAGNOSIS COLLATE DATABASE_DEFAULT
			,L_WRONG_REF
			,L_WRONG_REASON = L_WRONG_REASON COLLATE DATABASE_DEFAULT
			,L_TUMOUR_STATUS
			,L_NON_CANCER = L_NON_CANCER COLLATE DATABASE_DEFAULT
			,L_FIRST_APP
			,L_NO_APP
			,L_DIAG_WHO
			,L_RECURRENCE
			,L_OTHER_SYMPS = L_OTHER_SYMPS COLLATE DATABASE_DEFAULT
			,L_COMMENTS = L_COMMENTS COLLATE DATABASE_DEFAULT
			,N2_11_FIRST_SEEN_REASON = N2_11_FIRST_SEEN_REASON COLLATE DATABASE_DEFAULT
			,N16_7_DECISION_REASON = N16_7_DECISION_REASON COLLATE DATABASE_DEFAULT
			,N16_8_TREATMENT_REASON = N16_8_TREATMENT_REASON COLLATE DATABASE_DEFAULT
			,L_DIAGNOSIS_COMMENTS = L_DIAGNOSIS_COMMENTS COLLATE DATABASE_DEFAULT
			,GP_PRACTICE_CODE = GP_PRACTICE_CODE COLLATE DATABASE_DEFAULT
			,ClinicalTNMGroup = ClinicalTNMGroup COLLATE DATABASE_DEFAULT
			,PathologicalTNMGroup = PathologicalTNMGroup COLLATE DATABASE_DEFAULT
			,L_KEY_WORKER_SEEN = L_KEY_WORKER_SEEN COLLATE DATABASE_DEFAULT
			,L_PALLIATIVE_SPECIALIST_SEEN = L_PALLIATIVE_SPECIALIST_SEEN COLLATE DATABASE_DEFAULT
			,GERM_CELL_NON_CNS_ID
			,RECURRENCE_CANCER_SITE_ID
			,ICD03_GROUP
			,ICD03 = ICD03 COLLATE DATABASE_DEFAULT
			,L_DATE_DIAGNOSIS_DAHNO_LUCADA
			,L_INDICATOR_CODE = L_INDICATOR_CODE COLLATE DATABASE_DEFAULT
			,PRIMARY_DIAGNOSIS_SUB_COMMENT = PRIMARY_DIAGNOSIS_SUB_COMMENT COLLATE DATABASE_DEFAULT
			,CONSULTANT_CODE_AT_DIAGNOSIS = CONSULTANT_CODE_AT_DIAGNOSIS COLLATE DATABASE_DEFAULT
			,CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS = CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS COLLATE DATABASE_DEFAULT
			,FETOPROTEIN
			,GONADOTROPIN
			,GONADOTROPIN_SERUM
			,FETOPROTEIN_SERUM
			,SARCOMA_TUMOUR_SITE_BONE = SARCOMA_TUMOUR_SITE_BONE COLLATE DATABASE_DEFAULT
			,SARCOMA_TUMOUR_SITE_SOFT_TISSUE = SARCOMA_TUMOUR_SITE_SOFT_TISSUE COLLATE DATABASE_DEFAULT
			,SARCOMA_TUMOUR_SUBSITE_BONE = SARCOMA_TUMOUR_SUBSITE_BONE COLLATE DATABASE_DEFAULT
			,SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
			,ROOT_DECISION_DATE_COMMENTS = ROOT_DECISION_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_RECEIPT_DATE_COMMENTS = ROOT_RECEIPT_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_FIRST_SEEN_DATE_COMMENTS = ROOT_FIRST_SEEN_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_DIAGNOSIS_DATE_COMMENTS = ROOT_DIAGNOSIS_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS = ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_UPGRADE_COMMENTS = ROOT_UPGRADE_COMMENTS COLLATE DATABASE_DEFAULT
			,FIRST_APPT_TIME
			,TRANSFER_REASON
			,DATE_NEW_REFERRAL
			,TUMOUR_SITE_NEW
			,DATE_TRANSFER_ACTIONED
			,SOURCE_CARE_ID
			,ADT_REF_ID = ADT_REF_ID COLLATE DATABASE_DEFAULT
			,ACTION_ID
			,DIAGNOSIS_ACTION_ID
			,ORIGINAL_SOURCE_CARE_ID
			,TRANSFER_DATE_COMMENTS = TRANSFER_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,SPECIALIST_REFERRAL_COMMENTS = SPECIALIST_REFERRAL_COMMENTS COLLATE DATABASE_DEFAULT
			,NON_CANCER_DIAGNOSIS_CHAPTER
			,NON_CANCER_DIAGNOSIS_GROUP = NON_CANCER_DIAGNOSIS_GROUP COLLATE DATABASE_DEFAULT
			,NON_CANCER_DIAGNOSIS_CODE = NON_CANCER_DIAGNOSIS_CODE COLLATE DATABASE_DEFAULT
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
			,ADT_PLACER_ID = ADT_PLACER_ID COLLATE DATABASE_DEFAULT
			,SNOMEDCTDiagnosisID
			,FasterDiagnosisOrganisationID
			,FasterDiagnosisCancerSiteOverrideID
			,FasterDiagnosisExclusionDate
			,FasterDiagnosisExclusionReasonID
			,FasterDiagnosisDelayReasonID
			,FasterDiagnosisDelayReasonComments = FasterDiagnosisDelayReasonComments COLLATE DATABASE_DEFAULT
			,FasterDiagnosisCommunicationMethodID
			,FasterDiagnosisInformingCareProfessionalID
			,FasterDiagnosisOtherCareProfessional = FasterDiagnosisOtherCareProfessional COLLATE DATABASE_DEFAULT
			,FasterDiagnosisOtherCommunicationMethod = FasterDiagnosisOtherCommunicationMethod COLLATE DATABASE_DEFAULT
			,CAST(NULL AS INT) AS DEPRECATED_20_01_RecurrenceMetastaticType
			,NonPrimaryPathwayOptionsID
			,DiagnosisUncertainty
			,TNMOrganisation
			,FasterDiagnosisTargetRCComments = FasterDiagnosisTargetRCComments COLLATE DATABASE_DEFAULT
			,FasterDiagnosisEndRCComments = FasterDiagnosisEndRCComments COLLATE DATABASE_DEFAULT
			,TNMOrganisation_Integrated
			,LDHValue
			,CAST(NULL AS INT) AS DEPRECATED_20_01_LDH_NORMAL
			,BankedTissueUrine
			,SubsiteID
			,PredictedBreachStatus
			,RMRefID
			,TertiaryReferralKey
			,ClinicalTLetter = ClinicalTLetter COLLATE DATABASE_DEFAULT
			,ClinicalNLetter = ClinicalNLetter COLLATE DATABASE_DEFAULT
			,ClinicalMLetter = ClinicalMLetter COLLATE DATABASE_DEFAULT
			,PathologicalTLetter = PathologicalTLetter COLLATE DATABASE_DEFAULT
			,PathologicalNLetter = PathologicalNLetter COLLATE DATABASE_DEFAULT
			,PathologicalMLetter = PathologicalMLetter COLLATE DATABASE_DEFAULT
			,FDPlannedInterval
			,LabReportDate
			,LabReportOrgID
			,ReferralRoute
			,ReferralOtherRoute = ReferralOtherRoute COLLATE DATABASE_DEFAULT
			,RelapseMorphology
			,RelapseFlow
			,RelapseMolecular
			,RelapseClinicalExamination
			,RelapseOther
			,RapidDiagnostic = RapidDiagnostic COLLATE DATABASE_DEFAULT
			,PrimaryReferralFlag
			,OtherAssessedBy = OtherAssessedBy COLLATE DATABASE_DEFAULT
			,SharedBreach
			,PredictedBreachYear
			,PredictedBreachMonth
	FROM [CancerRegister_WSHT]..tblMAIN_REFERRALS

		UNION ALL 

	-- Select a replica dataset from a V22.2 table
	SELECT  CAST(2 AS tinyint) AS SrcSysID    --ignore tilda tilda
			,CARE_ID
			,PATIENT_ID
			,TEMP_ID = TEMP_ID COLLATE DATABASE_DEFAULT
			,L_CANCER_SITE = L_CANCER_SITE COLLATE DATABASE_DEFAULT
			,N2_1_REFERRAL_SOURCE = N2_1_REFERRAL_SOURCE COLLATE DATABASE_DEFAULT
			,N2_2_ORG_CODE_REF = N2_2_ORG_CODE_REF COLLATE DATABASE_DEFAULT
			,N2_3_REFERRER_CODE = N2_3_REFERRER_CODE COLLATE DATABASE_DEFAULT
			,N2_4_PRIORITY_TYPE = N2_4_PRIORITY_TYPE COLLATE DATABASE_DEFAULT
			,N2_5_DECISION_DATE
			,N2_6_RECEIPT_DATE
			,N2_7_CONSULTANT = N2_7_CONSULTANT COLLATE DATABASE_DEFAULT
			,N2_8_SPECIALTY
			,N2_9_FIRST_SEEN_DATE
			,N1_3_ORG_CODE_SEEN = N1_3_ORG_CODE_SEEN COLLATE DATABASE_DEFAULT
			,N2_10_FIRST_SEEN_DELAY = N2_10_FIRST_SEEN_DELAY COLLATE DATABASE_DEFAULT
			,N2_12_CANCER_TYPE = N2_12_CANCER_TYPE COLLATE DATABASE_DEFAULT
			,N2_13_CANCER_STATUS = N2_13_CANCER_STATUS COLLATE DATABASE_DEFAULT
			,L_FIRST_APPOINTMENT
			,L_CANCELLED_DATE
			,N2_14_ADJ_TIME
			,N2_15_ADJ_REASON
			,L_REFERRAL_METHOD
			,N2_16_OP_REFERRAL = N2_16_OP_REFERRAL COLLATE DATABASE_DEFAULT
			,L_SPECIALIST_DATE
			,L_ORG_CODE_SPECIALIST = L_ORG_CODE_SPECIALIST COLLATE DATABASE_DEFAULT
			,L_SPECIALIST_SEEN_DATE
			,N1_3_ORG_CODE_SPEC_SEEN = N1_3_ORG_CODE_SPEC_SEEN COLLATE DATABASE_DEFAULT
			,N_UPGRADE_DATE
			,N_UPGRADE_ORG_CODE = N_UPGRADE_ORG_CODE COLLATE DATABASE_DEFAULT
			,L_UPGRADE_WHEN
			,L_UPGRADE_WHO
			,N4_1_DIAGNOSIS_DATE
			,L_DIAGNOSIS = L_DIAGNOSIS COLLATE DATABASE_DEFAULT
			,N4_2_DIAGNOSIS_CODE = N4_2_DIAGNOSIS_CODE COLLATE DATABASE_DEFAULT
			,L_ORG_CODE_DIAGNOSIS = L_ORG_CODE_DIAGNOSIS COLLATE DATABASE_DEFAULT
			,L_PT_INFORMED_DATE
			,L_OTHER_DIAG_DATE
			,N4_3_LATERALITY = N4_3_LATERALITY COLLATE DATABASE_DEFAULT
			,N4_4_BASIS_DIAGNOSIS
			,L_TOPOGRAPHY = L_TOPOGRAPHY COLLATE DATABASE_DEFAULT
			,L_HISTOLOGY_GROUP
			,N4_5_HISTOLOGY = N4_5_HISTOLOGY COLLATE DATABASE_DEFAULT
			,N4_6_DIFFERENTIATION = N4_6_DIFFERENTIATION COLLATE DATABASE_DEFAULT
			,ClinicalTStage = ClinicalTStage COLLATE DATABASE_DEFAULT
			,ClinicalTCertainty = ClinicalTCertainty COLLATE DATABASE_DEFAULT
			,ClinicalNStage = ClinicalNStage COLLATE DATABASE_DEFAULT
			,ClinicalNCertainty = ClinicalNCertainty COLLATE DATABASE_DEFAULT
			,ClinicalMStage = ClinicalMStage COLLATE DATABASE_DEFAULT
			,ClinicalMCertainty = ClinicalMCertainty COLLATE DATABASE_DEFAULT
			,ClinicalOverallCertainty = ClinicalOverallCertainty COLLATE DATABASE_DEFAULT
			,N6_9_SITE_CLASSIFICATION = N6_9_SITE_CLASSIFICATION COLLATE DATABASE_DEFAULT
			,PathologicalOverallCertainty = PathologicalOverallCertainty COLLATE DATABASE_DEFAULT
			,PathologicalTCertainty = PathologicalTCertainty COLLATE DATABASE_DEFAULT
			,PathologicalTStage = PathologicalTStage COLLATE DATABASE_DEFAULT
			,PathologicalNCertainty = PathologicalNCertainty COLLATE DATABASE_DEFAULT
			,PathologicalNStage = PathologicalNStage COLLATE DATABASE_DEFAULT
			,PathologicalMCertainty = PathologicalMCertainty COLLATE DATABASE_DEFAULT
			,PathologicalMStage = PathologicalMStage COLLATE DATABASE_DEFAULT
			,L_GP_INFORMED
			,L_GP_INFORMED_DATE
			,L_GP_NOT = L_GP_NOT COLLATE DATABASE_DEFAULT
			,L_REL_INFORMED
			,L_NURSE_PRESENT = L_NURSE_PRESENT COLLATE DATABASE_DEFAULT
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
			,L_FIRST_CONSULTANT = L_FIRST_CONSULTANT COLLATE DATABASE_DEFAULT
			,L_APPROPRIATE
			,L_TERTIARY_DATE
			,L_TERTIARY_TRUST = L_TERTIARY_TRUST COLLATE DATABASE_DEFAULT
			,L_TERTIARY_REASON
			,L_INAP_REF
			,L_NEW_CA_SITE = L_NEW_CA_SITE COLLATE DATABASE_DEFAULT
			,L_AUTO_REF
			,L_SEC_DIAGNOSIS_G = L_SEC_DIAGNOSIS_G COLLATE DATABASE_DEFAULT
			,L_SEC_DIAGNOSIS = L_SEC_DIAGNOSIS COLLATE DATABASE_DEFAULT
			,L_WRONG_REF
			,L_WRONG_REASON = L_WRONG_REASON COLLATE DATABASE_DEFAULT
			,L_TUMOUR_STATUS
			,L_NON_CANCER = L_NON_CANCER COLLATE DATABASE_DEFAULT
			,L_FIRST_APP
			,L_NO_APP
			,L_DIAG_WHO
			,L_RECURRENCE
			,L_OTHER_SYMPS = L_OTHER_SYMPS COLLATE DATABASE_DEFAULT
			,L_COMMENTS = L_COMMENTS COLLATE DATABASE_DEFAULT
			,N2_11_FIRST_SEEN_REASON = N2_11_FIRST_SEEN_REASON COLLATE DATABASE_DEFAULT
			,N16_7_DECISION_REASON = N16_7_DECISION_REASON COLLATE DATABASE_DEFAULT
			,N16_8_TREATMENT_REASON = N16_8_TREATMENT_REASON COLLATE DATABASE_DEFAULT
			,L_DIAGNOSIS_COMMENTS = L_DIAGNOSIS_COMMENTS COLLATE DATABASE_DEFAULT
			,GP_PRACTICE_CODE = GP_PRACTICE_CODE COLLATE DATABASE_DEFAULT
			,ClinicalTNMGroup = ClinicalTNMGroup COLLATE DATABASE_DEFAULT
			,PathologicalTNMGroup = PathologicalTNMGroup COLLATE DATABASE_DEFAULT
			,L_KEY_WORKER_SEEN = L_KEY_WORKER_SEEN COLLATE DATABASE_DEFAULT
			,L_PALLIATIVE_SPECIALIST_SEEN = L_PALLIATIVE_SPECIALIST_SEEN COLLATE DATABASE_DEFAULT
			,GERM_CELL_NON_CNS_ID
			,RECURRENCE_CANCER_SITE_ID
			,ICD03_GROUP
			,ICD03 = ICD03 COLLATE DATABASE_DEFAULT
			,L_DATE_DIAGNOSIS_DAHNO_LUCADA
			,L_INDICATOR_CODE = L_INDICATOR_CODE COLLATE DATABASE_DEFAULT
			,PRIMARY_DIAGNOSIS_SUB_COMMENT = PRIMARY_DIAGNOSIS_SUB_COMMENT COLLATE DATABASE_DEFAULT
			,CONSULTANT_CODE_AT_DIAGNOSIS = CONSULTANT_CODE_AT_DIAGNOSIS COLLATE DATABASE_DEFAULT
			,CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS = CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS COLLATE DATABASE_DEFAULT
			,FETOPROTEIN
			,GONADOTROPIN
			,GONADOTROPIN_SERUM
			,FETOPROTEIN_SERUM
			,SARCOMA_TUMOUR_SITE_BONE = SARCOMA_TUMOUR_SITE_BONE COLLATE DATABASE_DEFAULT
			,SARCOMA_TUMOUR_SITE_SOFT_TISSUE = SARCOMA_TUMOUR_SITE_SOFT_TISSUE COLLATE DATABASE_DEFAULT
			,SARCOMA_TUMOUR_SUBSITE_BONE = SARCOMA_TUMOUR_SUBSITE_BONE COLLATE DATABASE_DEFAULT
			,SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
			,ROOT_DECISION_DATE_COMMENTS = ROOT_DECISION_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_RECEIPT_DATE_COMMENTS = ROOT_RECEIPT_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_FIRST_SEEN_DATE_COMMENTS = ROOT_FIRST_SEEN_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_DIAGNOSIS_DATE_COMMENTS = ROOT_DIAGNOSIS_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS = ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_UPGRADE_COMMENTS = ROOT_UPGRADE_COMMENTS COLLATE DATABASE_DEFAULT
			,FIRST_APPT_TIME
			,TRANSFER_REASON
			,DATE_NEW_REFERRAL
			,TUMOUR_SITE_NEW
			,DATE_TRANSFER_ACTIONED
			,SOURCE_CARE_ID
			,ADT_REF_ID = ADT_REF_ID COLLATE DATABASE_DEFAULT
			,ACTION_ID
			,DIAGNOSIS_ACTION_ID
			,ORIGINAL_SOURCE_CARE_ID
			,TRANSFER_DATE_COMMENTS = TRANSFER_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,SPECIALIST_REFERRAL_COMMENTS = SPECIALIST_REFERRAL_COMMENTS COLLATE DATABASE_DEFAULT
			,NON_CANCER_DIAGNOSIS_CHAPTER
			,NON_CANCER_DIAGNOSIS_GROUP = NON_CANCER_DIAGNOSIS_GROUP COLLATE DATABASE_DEFAULT
			,NON_CANCER_DIAGNOSIS_CODE = NON_CANCER_DIAGNOSIS_CODE COLLATE DATABASE_DEFAULT
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
			,ADT_PLACER_ID = ADT_PLACER_ID COLLATE DATABASE_DEFAULT
			,SNOMEDCTDiagnosisID
			,FasterDiagnosisOrganisationID
			,FasterDiagnosisCancerSiteOverrideID
			,FasterDiagnosisExclusionDate
			,FasterDiagnosisExclusionReasonID
			,FasterDiagnosisDelayReasonID
			,FasterDiagnosisDelayReasonComments = FasterDiagnosisDelayReasonComments COLLATE DATABASE_DEFAULT
			,FasterDiagnosisCommunicationMethodID
			,FasterDiagnosisInformingCareProfessionalID
			,FasterDiagnosisOtherCareProfessional = FasterDiagnosisOtherCareProfessional COLLATE DATABASE_DEFAULT
			,FasterDiagnosisOtherCommunicationMethod = FasterDiagnosisOtherCommunicationMethod COLLATE DATABASE_DEFAULT
			,CAST(NULL AS INT) AS DEPRECATED_20_01_RecurrenceMetastaticType
			,NonPrimaryPathwayOptionsID
			,DiagnosisUncertainty
			,TNMOrganisation
			,FasterDiagnosisTargetRCComments = FasterDiagnosisTargetRCComments COLLATE DATABASE_DEFAULT
			,FasterDiagnosisEndRCComments = FasterDiagnosisEndRCComments COLLATE DATABASE_DEFAULT
			,TNMOrganisation_Integrated
			,LDHValue
			,CAST(NULL AS INT) AS DEPRECATED_20_01_LDH_NORMAL
			,BankedTissueUrine
			,SubsiteID
			,PredictedBreachStatus
			,RMRefID
			,TertiaryReferralKey
			,ClinicalTLetter = ClinicalTLetter COLLATE DATABASE_DEFAULT
			,ClinicalNLetter = ClinicalNLetter COLLATE DATABASE_DEFAULT
			,ClinicalMLetter = ClinicalMLetter COLLATE DATABASE_DEFAULT
			,PathologicalTLetter = PathologicalTLetter COLLATE DATABASE_DEFAULT
			,PathologicalNLetter = PathologicalNLetter COLLATE DATABASE_DEFAULT
			,PathologicalMLetter = PathologicalMLetter COLLATE DATABASE_DEFAULT
			,FDPlannedInterval
			,LabReportDate
			,LabReportOrgID
			,ReferralRoute
			,ReferralOtherRoute = ReferralOtherRoute COLLATE DATABASE_DEFAULT
			,RelapseMorphology
			,RelapseFlow
			,RelapseMolecular
			,RelapseClinicalExamination
			,RelapseOther
			,RapidDiagnostic = RapidDiagnostic COLLATE DATABASE_DEFAULT
			,PrimaryReferralFlag
			,OtherAssessedBy = OtherAssessedBy COLLATE DATABASE_DEFAULT
			,SharedBreach
			,PredictedBreachYear
			,PredictedBreachMonth
	FROM [CancerRegister_BSUH]..tblMAIN_REFERRALS
GO
