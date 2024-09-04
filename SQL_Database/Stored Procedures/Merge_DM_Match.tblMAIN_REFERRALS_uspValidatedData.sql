SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [Merge_DM_Match].[tblMAIN_REFERRALS_uspValidatedData]

		(@PivotForSSRS BIT = 0
		,@OutputToTable BIT = 0
		)

AS 

/******************************************************** © Copyright & Licensing ****************************************************************
© 2024 Perspicacity Ltd & University Hospitals Sussex

This code / file is part of Perspicacity & University Hospitals Sussex SCR merge validation suite.

This SCR merge validation suite is free software: you can 
redistribute it and/or modify it under the terms of the GNU Affero 
General Public License as published by the Free Software Foundation, 
either version 3 of the License, or (at your option) any later version.

This SCR migration merge suite is distributed in the hope 
that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

A full copy of this code can be found at https://github.com/BrightonSussexUniHospitals/ScrMergeValidation

You may also be interested in the other repositories at https://github.com/perspicacity-ltd or
https://github.com/BrightonSussexUniHospitals

Original Work Created Date:	19/04/2024
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				A stored procedure to return the validated DM matching data for incororporating into the merge process
							or for the purposes of validation
**************************************************************************************************************************************************/

-- Test me
-- EXEC Merge_DM_Match.tblMAIN_REFERRALS_uspValidatedData
-- EXEC Merge_DM_Match.tblMAIN_REFERRALS_uspValidatedData @PivotForSSRS = 1
-- EXEC Merge_DM_Match.tblMAIN_REFERRALS_uspValidatedData @OutputToTable = 1

/*****************************************************************************************************************************************/
-- Create the temporary tables needed to create the output
/*****************************************************************************************************************************************/
		
		-- Create the #RelatedEntities table if it doesn't already exist - this allows a set of SrcSys/Src_UIDs to be passed to the procedure if we wish to retrieve the data for a specific cohort
		IF OBJECT_ID('tempdb..#RelatedEntities') IS NULL
		CREATE TABLE #RelatedEntities (IsSCR BIT NOT NULL, SrcSys TINYINT NOT NULL, Src_UID VARCHAR(255) NOT NULL) 
		-- INSERT INTO #RelatedEntities (IsSCR,SrcSys,Src_UID) VALUES (1,1,'146038') INSERT INTO #RelatedEntities (IsSCR,SrcSys,Src_UID) VALUES (1,2,'417618')

		-- Test whether we have any records in the #RelatedEntities table
		DECLARE @HasRelatedEntities BIT
		SELECT @HasRelatedEntities = COUNT(*) FROM #RelatedEntities

		-- Create the #mcIx table to represent the match control table with a priority order to it
		IF OBJECT_ID('tempdb..#mcIx') IS NOT NULL DROP TABLE #mcIx
		SELECT		IsMajor = CASE WHEN mc.SrcSys_Major = mc.SrcSys AND mc.Src_UID_Major = mc.Src_UID THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
					,IsMajorSCR = CASE WHEN mc.SrcSys_Major IN (1,2) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
					,IsConfirmed = CASE WHEN mmv_Confirmed.SrcSys_Major IS NOT NULL THEN 1 ELSE 0 END
					,mc.*
					,mcIx = ROW_NUMBER() OVER (PARTITION BY mc.SrcSys_Major, mc.Src_UID_Major ORDER BY mc.IsSCR DESC, uh.LastUpdated DESC, mc.SrcSys, mc.Src_UID)
					,uh.LastUpdated
		INTO		#mcIx
		FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
		INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																ON	mc.SrcSys = uh.SrcSys
																AND	mc.Src_UID = uh.Src_UID
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv_Confirmed
																			ON	mc.SrcSys_Major = mmv_Confirmed.SrcSys_Major
																			AND	mc.Src_UID_Major = mmv_Confirmed.Src_UID_Major
																			AND	mmv_Confirmed.ValidationStatus IN ('Confirmed')
		LEFT JOIN	#RelatedEntities re
										ON	mc.SrcSys = re.SrcSys
										AND	mc.Src_UID = re.Src_UID
		WHERE		re.SrcSys IS NOT NULL
		OR			@HasRelatedEntities = 0

		-- Create an index on the temporary match control table
		DECLARE @NewID VARCHAR(255)
		DECLARE @SQL_mc VARCHAR(MAX)
		SELECT @NewID = CAST(NEWID() AS VARCHAR(255))
		SET @SQL_mc = 'CREATE UNIQUE CLUSTERED INDEX [PK_mcIx_' + @NewID + '] ON #mcIx (SrcSys ASC, Src_UID ASC)'; PRINT @SQL_mc; EXEC (@SQL_mc)
		SET @SQL_mc = 'CREATE NONCLUSTERED INDEX [Ix_mcIx_Major_' + @NewID + '] ON #mcIx (SrcSys_Major ASC, Src_UID_Major)'; PRINT @SQL_mc; EXEC (@SQL_mc)

		-- SELECT * FROM #mcIx WHERE #mcIx.IsMajorSCR = 0

/*****************************************************************************************************************************************/
-- Create the validated dataset and populate the output
/*****************************************************************************************************************************************/

		-- Create the #ValidatedData table to temporarily hold the output dataset
		IF OBJECT_ID('tempdb..#ValidatedData') IS NOT NULL DROP TABLE #ValidatedData
		SELECT		SrcSys_MajorExt		= CAST(NULL AS TINYINT)
					,Src_UID_MajorExt	= CAST(NULL AS VARCHAR(255))
					,SrcSys_Major		= CAST(NULL AS TINYINT)
					,Src_UID_Major		= CAST(NULL AS VARCHAR(255))
					,IsValidatedMajor	= CAST(NULL AS BIT)
					,IsConfirmed		= CAST(NULL AS BIT)
					,LastUpdated		= CAST(NULL AS DATETIME)
					,uh.SrcSys
					,uh.Src_UID
					,uh.CARE_ID
					,uh.PATIENT_ID
					,uh.TEMP_ID
					,uh.L_CANCER_SITE
					,uh.N2_1_REFERRAL_SOURCE
					,uh.N2_2_ORG_CODE_REF
					,uh.N2_3_REFERRER_CODE
					,uh.N2_4_PRIORITY_TYPE
					,uh.N2_5_DECISION_DATE
					,uh.N2_6_RECEIPT_DATE
					,uh.N2_7_CONSULTANT
					,uh.N2_8_SPECIALTY
					,uh.N2_9_FIRST_SEEN_DATE
					,uh.N1_3_ORG_CODE_SEEN
					,uh.N2_10_FIRST_SEEN_DELAY
					,uh.N2_12_CANCER_TYPE
					,uh.N2_13_CANCER_STATUS
					,uh.L_FIRST_APPOINTMENT
					,uh.L_CANCELLED_DATE
					,uh.N2_14_ADJ_TIME
					,uh.N2_15_ADJ_REASON
					,uh.L_REFERRAL_METHOD
					,uh.N2_16_OP_REFERRAL
					,uh.L_SPECIALIST_DATE
					,uh.L_ORG_CODE_SPECIALIST
					,uh.L_SPECIALIST_SEEN_DATE
					,uh.N1_3_ORG_CODE_SPEC_SEEN
					,uh.N_UPGRADE_DATE
					,uh.N_UPGRADE_ORG_CODE
					,uh.L_UPGRADE_WHEN
					,uh.L_UPGRADE_WHO
					,uh.N4_1_DIAGNOSIS_DATE
					,uh.L_DIAGNOSIS
					,uh.N4_2_DIAGNOSIS_CODE
					,uh.L_ORG_CODE_DIAGNOSIS
					,uh.L_PT_INFORMED_DATE
					,uh.L_OTHER_DIAG_DATE
					,uh.N4_3_LATERALITY
					,uh.N4_4_BASIS_DIAGNOSIS
					,uh.L_TOPOGRAPHY
					,uh.L_HISTOLOGY_GROUP
					,uh.N4_5_HISTOLOGY
					,uh.N4_6_DIFFERENTIATION
					,uh.ClinicalTStage
					,uh.ClinicalTCertainty
					,uh.ClinicalNStage
					,uh.ClinicalNCertainty
					,uh.ClinicalMStage
					,uh.ClinicalMCertainty
					,uh.ClinicalOverallCertainty
					,uh.N6_9_SITE_CLASSIFICATION
					,uh.PathologicalOverallCertainty
					,uh.PathologicalTCertainty
					,uh.PathologicalTStage
					,uh.PathologicalNCertainty
					,uh.PathologicalNStage
					,uh.PathologicalMCertainty
					,uh.PathologicalMStage
					,uh.L_GP_INFORMED
					,uh.L_GP_INFORMED_DATE
					,uh.L_GP_NOT
					,uh.L_REL_INFORMED
					,uh.L_NURSE_PRESENT
					,uh.L_SPEC_NURSE_DATE
					,uh.L_SEEN_NURSE_DATE
					,uh.N16_1_ADJ_DAYS
					,uh.N16_2_ADJ_DAYS
					,uh.N16_3_ADJ_DECISION_CODE
					,uh.N16_4_ADJ_TREAT_CODE
					,uh.N16_5_DECISION_REASON_CODE
					,uh.N16_6_TREATMENT_REASON_CODE
					,uh.PathologicalTNMDate
					,uh.ClinicalTNMDate
					,uh.L_FIRST_CONSULTANT
					,uh.L_APPROPRIATE
					,uh.L_TERTIARY_DATE
					,uh.L_TERTIARY_TRUST
					,uh.L_TERTIARY_REASON
					,uh.L_INAP_REF
					,uh.L_NEW_CA_SITE
					,uh.L_AUTO_REF
					,uh.L_SEC_DIAGNOSIS_G
					,uh.L_SEC_DIAGNOSIS
					,uh.L_WRONG_REF
					,uh.L_WRONG_REASON
					,uh.L_TUMOUR_STATUS
					,uh.L_NON_CANCER
					,uh.L_FIRST_APP
					,uh.L_NO_APP
					,uh.L_DIAG_WHO
					,uh.L_RECURRENCE
					,uh.L_OTHER_SYMPS
					,uh.L_COMMENTS
					,uh.N2_11_FIRST_SEEN_REASON
					,uh.N16_7_DECISION_REASON
					,uh.N16_8_TREATMENT_REASON
					,uh.L_DIAGNOSIS_COMMENTS
					,uh.GP_PRACTICE_CODE
					,uh.ClinicalTNMGroup
					,uh.PathologicalTNMGroup
					,uh.L_KEY_WORKER_SEEN
					,uh.L_PALLIATIVE_SPECIALIST_SEEN
					,uh.GERM_CELL_NON_CNS_ID
					,uh.RECURRENCE_CANCER_SITE_ID
					,uh.ICD03_GROUP
					,uh.ICD03
					,uh.L_DATE_DIAGNOSIS_DAHNO_LUCADA
					,uh.L_INDICATOR_CODE
					,uh.PRIMARY_DIAGNOSIS_SUB_COMMENT
					,uh.CONSULTANT_CODE_AT_DIAGNOSIS
					,uh.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS
					,uh.FETOPROTEIN
					,uh.GONADOTROPIN
					,uh.GONADOTROPIN_SERUM
					,uh.FETOPROTEIN_SERUM
					,uh.SARCOMA_TUMOUR_SITE_BONE
					,uh.SARCOMA_TUMOUR_SITE_SOFT_TISSUE
					,uh.SARCOMA_TUMOUR_SUBSITE_BONE
					,uh.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
					,uh.ROOT_DECISION_DATE_COMMENTS
					,uh.ROOT_RECEIPT_DATE_COMMENTS
					,uh.ROOT_FIRST_SEEN_DATE_COMMENTS
					,uh.ROOT_DIAGNOSIS_DATE_COMMENTS
					,uh.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS
					,uh.ROOT_UPGRADE_COMMENTS
					,uh.FIRST_APPT_TIME
					,uh.TRANSFER_REASON
					,uh.DATE_NEW_REFERRAL
					,uh.TUMOUR_SITE_NEW
					,uh.DATE_TRANSFER_ACTIONED
					,uh.SOURCE_CARE_ID
					,uh.ADT_REF_ID
					,uh.ACTION_ID
					,uh.DIAGNOSIS_ACTION_ID
					,uh.ORIGINAL_SOURCE_CARE_ID
					,uh.TRANSFER_DATE_COMMENTS
					,uh.SPECIALIST_REFERRAL_COMMENTS
					,uh.NON_CANCER_DIAGNOSIS_CHAPTER
					,uh.NON_CANCER_DIAGNOSIS_GROUP
					,uh.NON_CANCER_DIAGNOSIS_CODE
					,uh.TNM_UNKNOWN
					,uh.ReferringPractice
					,uh.ReferringGP
					,uh.ReferringBranch
					,uh.BankedTissue
					,uh.BankedTissueTumour
					,uh.BankedTissueBlood
					,uh.BankedTissueCSF
					,uh.BankedTissueBoneMarrow
					,uh.SNOMed_CT
					,uh.ADT_PLACER_ID
					,uh.SNOMEDCTDiagnosisID
					,uh.FasterDiagnosisOrganisationID
					,uh.FasterDiagnosisCancerSiteOverrideID
					,uh.FasterDiagnosisExclusionDate
					,uh.FasterDiagnosisExclusionReasonID
					,uh.FasterDiagnosisDelayReasonID
					,uh.FasterDiagnosisDelayReasonComments
					,uh.FasterDiagnosisCommunicationMethodID
					,uh.FasterDiagnosisInformingCareProfessionalID
					,uh.FasterDiagnosisOtherCareProfessional
					,uh.FasterDiagnosisOtherCommunicationMethod
					--,uh.DEPRECATED_20_01_RecurrenceMetastaticType
					,uh.NonPrimaryPathwayOptionsID
					,uh.DiagnosisUncertainty
					,uh.TNMOrganisation
					,uh.FasterDiagnosisTargetRCComments
					,uh.FasterDiagnosisEndRCComments
					,uh.TNMOrganisation_Integrated
					,uh.LDHValue
					--,uh.DEPRECATED_20_01_LDH_NORMAL
					,uh.BankedTissueUrine
					,uh.SubsiteID
					,uh.PredictedBreachStatus
					,uh.RMRefID
					,uh.TertiaryReferralKey
					,uh.ClinicalTLetter
					,uh.ClinicalNLetter
					,uh.ClinicalMLetter
					,uh.PathologicalTLetter
					,uh.PathologicalNLetter
					,uh.PathologicalMLetter
					,uh.FDPlannedInterval
					,uh.LabReportDate
					,uh.LabReportOrgID
					,uh.ReferralRoute
					,uh.ReferralOtherRoute
					,uh.RelapseMorphology
					,uh.RelapseFlow
					,uh.RelapseMolecular
					,uh.RelapseClinicalExamination
					,uh.RelapseOther
					,uh.RapidDiagnostic
					,uh.PrimaryReferralFlag
					,uh.OtherAssessedBy
					,uh.SharedBreach
					,uh.PredictedBreachYear
					,uh.PredictedBreachMonth
		INTO		#ValidatedData
		FROM		Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
		WHERE		0 = 1 -- only return an empty dataset with the desired table structure

		-- internal majors
		INSERT INTO	#ValidatedData
		SELECT		SrcSys_MajorExt								= mc.SrcSys_Major
					,Src_UID_MajorExt							= mc.Src_UID_Major
					,SrcSys_Major								= mc.SrcSys_Major
					,Src_UID_Major								= mc.Src_UID_Major
					,IsValidatedMajor							= 1
					,IsConfirmed								= mc.IsConfirmed
					,LastUpdated								= uh.LastUpdated
					,SrcSys										= mc.SrcSys
					,Src_UID									= mc.Src_UID
					,CARE_ID									= CASE WHEN mmvc.CARE_ID = 1 THEN mmv.CARE_ID ELSE uh.CARE_ID END
					,PATIENT_ID									= CASE WHEN mmvc.PATIENT_ID = 1 THEN mmv.PATIENT_ID ELSE uh.PATIENT_ID END
					,TEMP_ID									= CASE WHEN mmvc.TEMP_ID = 1 THEN mmv.TEMP_ID ELSE uh.TEMP_ID END
					,L_CANCER_SITE								= CASE WHEN mmvc.L_CANCER_SITE = 1 THEN mmv.L_CANCER_SITE ELSE uh.L_CANCER_SITE END
					,N2_1_REFERRAL_SOURCE						= CASE WHEN mmvc.N2_1_REFERRAL_SOURCE = 1 THEN mmv.N2_1_REFERRAL_SOURCE ELSE uh.N2_1_REFERRAL_SOURCE END
					,N2_2_ORG_CODE_REF							= CASE WHEN mmvc.N2_2_ORG_CODE_REF = 1 THEN mmv.N2_2_ORG_CODE_REF ELSE uh.N2_2_ORG_CODE_REF END
					,N2_3_REFERRER_CODE							= CASE WHEN mmvc.N2_3_REFERRER_CODE = 1 THEN mmv.N2_3_REFERRER_CODE ELSE uh.N2_3_REFERRER_CODE END
					,N2_4_PRIORITY_TYPE							= CASE WHEN mmvc.N2_4_PRIORITY_TYPE = 1 THEN mmv.N2_4_PRIORITY_TYPE ELSE uh.N2_4_PRIORITY_TYPE END
					,N2_5_DECISION_DATE							= CASE WHEN mmvc.N2_5_DECISION_DATE = 1 THEN mmv.N2_5_DECISION_DATE ELSE uh.N2_5_DECISION_DATE END
					,N2_6_RECEIPT_DATE							= CASE WHEN mmvc.N2_6_RECEIPT_DATE = 1 THEN mmv.N2_6_RECEIPT_DATE ELSE uh.N2_6_RECEIPT_DATE END
					,N2_7_CONSULTANT							= CASE WHEN mmvc.N2_7_CONSULTANT = 1 THEN mmv.N2_7_CONSULTANT ELSE uh.N2_7_CONSULTANT END
					,N2_8_SPECIALTY								= CASE WHEN mmvc.N2_8_SPECIALTY = 1 THEN mmv.N2_8_SPECIALTY ELSE uh.N2_8_SPECIALTY END
					,N2_9_FIRST_SEEN_DATE						= CASE WHEN mmvc.N2_9_FIRST_SEEN_DATE = 1 THEN mmv.N2_9_FIRST_SEEN_DATE ELSE uh.N2_9_FIRST_SEEN_DATE END
					,N1_3_ORG_CODE_SEEN							= CASE WHEN mmvc.N1_3_ORG_CODE_SEEN = 1 THEN mmv.N1_3_ORG_CODE_SEEN ELSE uh.N1_3_ORG_CODE_SEEN END
					,N2_10_FIRST_SEEN_DELAY						= CASE WHEN mmvc.N2_10_FIRST_SEEN_DELAY = 1 THEN mmv.N2_10_FIRST_SEEN_DELAY ELSE uh.N2_10_FIRST_SEEN_DELAY END
					,N2_12_CANCER_TYPE							= CASE WHEN mmvc.N2_12_CANCER_TYPE = 1 THEN mmv.N2_12_CANCER_TYPE ELSE uh.N2_12_CANCER_TYPE END
					,N2_13_CANCER_STATUS						= CASE WHEN mmvc.N2_13_CANCER_STATUS = 1 THEN mmv.N2_13_CANCER_STATUS ELSE uh.N2_13_CANCER_STATUS END
					,L_FIRST_APPOINTMENT						= CASE WHEN mmvc.L_FIRST_APPOINTMENT = 1 THEN mmv.L_FIRST_APPOINTMENT ELSE uh.L_FIRST_APPOINTMENT END
					,L_CANCELLED_DATE							= CASE WHEN mmvc.L_CANCELLED_DATE = 1 THEN mmv.L_CANCELLED_DATE ELSE uh.L_CANCELLED_DATE END
					,N2_14_ADJ_TIME								= CASE WHEN mmvc.N2_14_ADJ_TIME = 1 THEN mmv.N2_14_ADJ_TIME ELSE uh.N2_14_ADJ_TIME END
					,N2_15_ADJ_REASON							= CASE WHEN mmvc.N2_15_ADJ_REASON = 1 THEN mmv.N2_15_ADJ_REASON ELSE uh.N2_15_ADJ_REASON END
					,L_REFERRAL_METHOD							= CASE WHEN mmvc.L_REFERRAL_METHOD = 1 THEN mmv.L_REFERRAL_METHOD ELSE uh.L_REFERRAL_METHOD END
					,N2_16_OP_REFERRAL							= CASE WHEN mmvc.N2_16_OP_REFERRAL = 1 THEN mmv.N2_16_OP_REFERRAL ELSE uh.N2_16_OP_REFERRAL END
					,L_SPECIALIST_DATE							= CASE WHEN mmvc.L_SPECIALIST_DATE = 1 THEN mmv.L_SPECIALIST_DATE ELSE uh.L_SPECIALIST_DATE END
					,L_ORG_CODE_SPECIALIST						= CASE WHEN mmvc.L_ORG_CODE_SPECIALIST = 1 THEN mmv.L_ORG_CODE_SPECIALIST ELSE uh.L_ORG_CODE_SPECIALIST END
					,L_SPECIALIST_SEEN_DATE						= CASE WHEN mmvc.L_SPECIALIST_SEEN_DATE = 1 THEN mmv.L_SPECIALIST_SEEN_DATE ELSE uh.L_SPECIALIST_SEEN_DATE END
					,N1_3_ORG_CODE_SPEC_SEEN					= CASE WHEN mmvc.N1_3_ORG_CODE_SPEC_SEEN = 1 THEN mmv.N1_3_ORG_CODE_SPEC_SEEN ELSE uh.N1_3_ORG_CODE_SPEC_SEEN END
					,N_UPGRADE_DATE								= CASE WHEN mmvc.N_UPGRADE_DATE = 1 THEN mmv.N_UPGRADE_DATE ELSE uh.N_UPGRADE_DATE END
					,N_UPGRADE_ORG_CODE							= CASE WHEN mmvc.N_UPGRADE_ORG_CODE = 1 THEN mmv.N_UPGRADE_ORG_CODE ELSE uh.N_UPGRADE_ORG_CODE END
					,L_UPGRADE_WHEN								= CASE WHEN mmvc.L_UPGRADE_WHEN = 1 THEN mmv.L_UPGRADE_WHEN ELSE uh.L_UPGRADE_WHEN END
					,L_UPGRADE_WHO								= CASE WHEN mmvc.L_UPGRADE_WHO = 1 THEN mmv.L_UPGRADE_WHO ELSE uh.L_UPGRADE_WHO END
					,N4_1_DIAGNOSIS_DATE						= CASE WHEN mmvc.N4_1_DIAGNOSIS_DATE = 1 THEN mmv.N4_1_DIAGNOSIS_DATE ELSE uh.N4_1_DIAGNOSIS_DATE END
					,L_DIAGNOSIS								= CASE WHEN mmvc.L_DIAGNOSIS = 1 THEN mmv.L_DIAGNOSIS ELSE uh.L_DIAGNOSIS END
					,N4_2_DIAGNOSIS_CODE						= CASE WHEN mmvc.N4_2_DIAGNOSIS_CODE = 1 THEN mmv.N4_2_DIAGNOSIS_CODE ELSE uh.N4_2_DIAGNOSIS_CODE END
					,L_ORG_CODE_DIAGNOSIS						= CASE WHEN mmvc.L_ORG_CODE_DIAGNOSIS = 1 THEN mmv.L_ORG_CODE_DIAGNOSIS ELSE uh.L_ORG_CODE_DIAGNOSIS END
					,L_PT_INFORMED_DATE							= CASE WHEN mmvc.L_PT_INFORMED_DATE = 1 THEN mmv.L_PT_INFORMED_DATE ELSE uh.L_PT_INFORMED_DATE END
					,L_OTHER_DIAG_DATE							= CASE WHEN mmvc.L_OTHER_DIAG_DATE = 1 THEN mmv.L_OTHER_DIAG_DATE ELSE uh.L_OTHER_DIAG_DATE END
					,N4_3_LATERALITY							= CASE WHEN mmvc.N4_3_LATERALITY = 1 THEN mmv.N4_3_LATERALITY ELSE uh.N4_3_LATERALITY END
					,N4_4_BASIS_DIAGNOSIS						= CASE WHEN mmvc.N4_4_BASIS_DIAGNOSIS = 1 THEN mmv.N4_4_BASIS_DIAGNOSIS ELSE uh.N4_4_BASIS_DIAGNOSIS END
					,L_TOPOGRAPHY								= CASE WHEN mmvc.L_TOPOGRAPHY = 1 THEN mmv.L_TOPOGRAPHY ELSE uh.L_TOPOGRAPHY END
					,L_HISTOLOGY_GROUP							= CASE WHEN mmvc.L_HISTOLOGY_GROUP = 1 THEN mmv.L_HISTOLOGY_GROUP ELSE uh.L_HISTOLOGY_GROUP END
					,N4_5_HISTOLOGY								= CASE WHEN mmvc.N4_5_HISTOLOGY = 1 THEN mmv.N4_5_HISTOLOGY ELSE uh.N4_5_HISTOLOGY END
					,N4_6_DIFFERENTIATION						= CASE WHEN mmvc.N4_6_DIFFERENTIATION = 1 THEN mmv.N4_6_DIFFERENTIATION ELSE uh.N4_6_DIFFERENTIATION END
					,ClinicalTStage								= CASE WHEN mmvc.ClinicalTStage = 1 THEN mmv.ClinicalTStage ELSE uh.ClinicalTStage END
					,ClinicalTCertainty							= CASE WHEN mmvc.ClinicalTCertainty = 1 THEN mmv.ClinicalTCertainty ELSE uh.ClinicalTCertainty END
					,ClinicalNStage								= CASE WHEN mmvc.ClinicalNStage = 1 THEN mmv.ClinicalNStage ELSE uh.ClinicalNStage END
					,ClinicalNCertainty							= CASE WHEN mmvc.ClinicalNCertainty = 1 THEN mmv.ClinicalNCertainty ELSE uh.ClinicalNCertainty END
					,ClinicalMStage								= CASE WHEN mmvc.ClinicalMStage = 1 THEN mmv.ClinicalMStage ELSE uh.ClinicalMStage END
					,ClinicalMCertainty							= CASE WHEN mmvc.ClinicalMCertainty = 1 THEN mmv.ClinicalMCertainty ELSE uh.ClinicalMCertainty END
					,ClinicalOverallCertainty					= CASE WHEN mmvc.ClinicalOverallCertainty = 1 THEN mmv.ClinicalOverallCertainty ELSE uh.ClinicalOverallCertainty END
					,N6_9_SITE_CLASSIFICATION					= CASE WHEN mmvc.N6_9_SITE_CLASSIFICATION = 1 THEN mmv.N6_9_SITE_CLASSIFICATION ELSE uh.N6_9_SITE_CLASSIFICATION END
					,PathologicalOverallCertainty				= CASE WHEN mmvc.PathologicalOverallCertainty = 1 THEN mmv.PathologicalOverallCertainty ELSE uh.PathologicalOverallCertainty END
					,PathologicalTCertainty						= CASE WHEN mmvc.PathologicalTCertainty = 1 THEN mmv.PathologicalTCertainty ELSE uh.PathologicalTCertainty END
					,PathologicalTStage							= CASE WHEN mmvc.PathologicalTStage = 1 THEN mmv.PathologicalTStage ELSE uh.PathologicalTStage END
					,PathologicalNCertainty						= CASE WHEN mmvc.PathologicalNCertainty = 1 THEN mmv.PathologicalNCertainty ELSE uh.PathologicalNCertainty END
					,PathologicalNStage							= CASE WHEN mmvc.PathologicalNStage = 1 THEN mmv.PathologicalNStage ELSE uh.PathologicalNStage END
					,PathologicalMCertainty						= CASE WHEN mmvc.PathologicalMCertainty = 1 THEN mmv.PathologicalMCertainty ELSE uh.PathologicalMCertainty END
					,PathologicalMStage							= CASE WHEN mmvc.PathologicalMStage = 1 THEN mmv.PathologicalMStage ELSE uh.PathologicalMStage END
					,L_GP_INFORMED								= CASE WHEN mmvc.L_GP_INFORMED = 1 THEN mmv.L_GP_INFORMED ELSE uh.L_GP_INFORMED END
					,L_GP_INFORMED_DATE							= CASE WHEN mmvc.L_GP_INFORMED_DATE = 1 THEN mmv.L_GP_INFORMED_DATE ELSE uh.L_GP_INFORMED_DATE END
					,L_GP_NOT									= CASE WHEN mmvc.L_GP_NOT = 1 THEN mmv.L_GP_NOT ELSE uh.L_GP_NOT END
					,L_REL_INFORMED								= CASE WHEN mmvc.L_REL_INFORMED = 1 THEN mmv.L_REL_INFORMED ELSE uh.L_REL_INFORMED END
					,L_NURSE_PRESENT							= CASE WHEN mmvc.L_NURSE_PRESENT = 1 THEN mmv.L_NURSE_PRESENT ELSE uh.L_NURSE_PRESENT END
					,L_SPEC_NURSE_DATE							= CASE WHEN mmvc.L_SPEC_NURSE_DATE = 1 THEN mmv.L_SPEC_NURSE_DATE ELSE uh.L_SPEC_NURSE_DATE END
					,L_SEEN_NURSE_DATE							= CASE WHEN mmvc.L_SEEN_NURSE_DATE = 1 THEN mmv.L_SEEN_NURSE_DATE ELSE uh.L_SEEN_NURSE_DATE END
					,N16_1_ADJ_DAYS								= CASE WHEN mmvc.N16_1_ADJ_DAYS = 1 THEN mmv.N16_1_ADJ_DAYS ELSE uh.N16_1_ADJ_DAYS END
					,N16_2_ADJ_DAYS								= CASE WHEN mmvc.N16_2_ADJ_DAYS = 1 THEN mmv.N16_2_ADJ_DAYS ELSE uh.N16_2_ADJ_DAYS END
					,N16_3_ADJ_DECISION_CODE					= CASE WHEN mmvc.N16_3_ADJ_DECISION_CODE = 1 THEN mmv.N16_3_ADJ_DECISION_CODE ELSE uh.N16_3_ADJ_DECISION_CODE END
					,N16_4_ADJ_TREAT_CODE						= CASE WHEN mmvc.N16_4_ADJ_TREAT_CODE = 1 THEN mmv.N16_4_ADJ_TREAT_CODE ELSE uh.N16_4_ADJ_TREAT_CODE END
					,N16_5_DECISION_REASON_CODE					= CASE WHEN mmvc.N16_5_DECISION_REASON_CODE = 1 THEN mmv.N16_5_DECISION_REASON_CODE ELSE uh.N16_5_DECISION_REASON_CODE END
					,N16_6_TREATMENT_REASON_CODE				= CASE WHEN mmvc.N16_6_TREATMENT_REASON_CODE = 1 THEN mmv.N16_6_TREATMENT_REASON_CODE ELSE uh.N16_6_TREATMENT_REASON_CODE END
					,PathologicalTNMDate						= CASE WHEN mmvc.PathologicalTNMDate = 1 THEN mmv.PathologicalTNMDate ELSE uh.PathologicalTNMDate END
					,ClinicalTNMDate							= CASE WHEN mmvc.ClinicalTNMDate = 1 THEN mmv.ClinicalTNMDate ELSE uh.ClinicalTNMDate END
					,L_FIRST_CONSULTANT							= CASE WHEN mmvc.L_FIRST_CONSULTANT = 1 THEN mmv.L_FIRST_CONSULTANT ELSE uh.L_FIRST_CONSULTANT END
					,L_APPROPRIATE								= CASE WHEN mmvc.L_APPROPRIATE = 1 THEN mmv.L_APPROPRIATE ELSE uh.L_APPROPRIATE END
					,L_TERTIARY_DATE							= CASE WHEN mmvc.L_TERTIARY_DATE = 1 THEN mmv.L_TERTIARY_DATE ELSE uh.L_TERTIARY_DATE END
					,L_TERTIARY_TRUST							= CASE WHEN mmvc.L_TERTIARY_TRUST = 1 THEN mmv.L_TERTIARY_TRUST ELSE uh.L_TERTIARY_TRUST END
					,L_TERTIARY_REASON							= CASE WHEN mmvc.L_TERTIARY_REASON = 1 THEN mmv.L_TERTIARY_REASON ELSE uh.L_TERTIARY_REASON END
					,L_INAP_REF									= CASE WHEN mmvc.L_INAP_REF = 1 THEN mmv.L_INAP_REF ELSE uh.L_INAP_REF END
					,L_NEW_CA_SITE								= CASE WHEN mmvc.L_NEW_CA_SITE = 1 THEN mmv.L_NEW_CA_SITE ELSE uh.L_NEW_CA_SITE END
					,L_AUTO_REF									= CASE WHEN mmvc.L_AUTO_REF = 1 THEN mmv.L_AUTO_REF ELSE uh.L_AUTO_REF END
					,L_SEC_DIAGNOSIS_G							= CASE WHEN mmvc.L_SEC_DIAGNOSIS_G = 1 THEN mmv.L_SEC_DIAGNOSIS_G ELSE uh.L_SEC_DIAGNOSIS_G END
					,L_SEC_DIAGNOSIS							= CASE WHEN mmvc.L_SEC_DIAGNOSIS = 1 THEN mmv.L_SEC_DIAGNOSIS ELSE uh.L_SEC_DIAGNOSIS END
					,L_WRONG_REF								= CASE WHEN mmvc.L_WRONG_REF = 1 THEN mmv.L_WRONG_REF ELSE uh.L_WRONG_REF END
					,L_WRONG_REASON								= CASE WHEN mmvc.L_WRONG_REASON = 1 THEN mmv.L_WRONG_REASON ELSE uh.L_WRONG_REASON END
					,L_TUMOUR_STATUS							= CASE WHEN mmvc.L_TUMOUR_STATUS = 1 THEN mmv.L_TUMOUR_STATUS ELSE uh.L_TUMOUR_STATUS END
					,L_NON_CANCER								= CASE WHEN mmvc.L_NON_CANCER = 1 THEN mmv.L_NON_CANCER ELSE uh.L_NON_CANCER END
					,L_FIRST_APP								= CASE WHEN mmvc.L_FIRST_APP = 1 THEN mmv.L_FIRST_APP ELSE uh.L_FIRST_APP END
					,L_NO_APP									= CASE WHEN mmvc.L_NO_APP = 1 THEN mmv.L_NO_APP ELSE uh.L_NO_APP END
					,L_DIAG_WHO									= CASE WHEN mmvc.L_DIAG_WHO = 1 THEN mmv.L_DIAG_WHO ELSE uh.L_DIAG_WHO END
					,L_RECURRENCE								= CASE WHEN mmvc.L_RECURRENCE = 1 THEN mmv.L_RECURRENCE ELSE uh.L_RECURRENCE END
					,L_OTHER_SYMPS								= CASE WHEN mmvc.L_OTHER_SYMPS = 1 THEN mmv.L_OTHER_SYMPS ELSE uh.L_OTHER_SYMPS END
					,L_COMMENTS									= CASE WHEN mmvc.L_COMMENTS = 1 THEN mmv.L_COMMENTS ELSE uh.L_COMMENTS END
					,N2_11_FIRST_SEEN_REASON					= CASE WHEN mmvc.N2_11_FIRST_SEEN_REASON = 1 THEN mmv.N2_11_FIRST_SEEN_REASON ELSE uh.N2_11_FIRST_SEEN_REASON END
					,N16_7_DECISION_REASON						= CASE WHEN mmvc.N16_7_DECISION_REASON = 1 THEN mmv.N16_7_DECISION_REASON ELSE uh.N16_7_DECISION_REASON END
					,N16_8_TREATMENT_REASON						= CASE WHEN mmvc.N16_8_TREATMENT_REASON = 1 THEN mmv.N16_8_TREATMENT_REASON ELSE uh.N16_8_TREATMENT_REASON END
					,L_DIAGNOSIS_COMMENTS						= CASE WHEN mmvc.L_DIAGNOSIS_COMMENTS = 1 THEN mmv.L_DIAGNOSIS_COMMENTS ELSE uh.L_DIAGNOSIS_COMMENTS END
					,GP_PRACTICE_CODE							= CASE WHEN mmvc.GP_PRACTICE_CODE = 1 THEN mmv.GP_PRACTICE_CODE ELSE uh.GP_PRACTICE_CODE END
					,ClinicalTNMGroup							= CASE WHEN mmvc.ClinicalTNMGroup = 1 THEN mmv.ClinicalTNMGroup ELSE uh.ClinicalTNMGroup END
					,PathologicalTNMGroup						= CASE WHEN mmvc.PathologicalTNMGroup = 1 THEN mmv.PathologicalTNMGroup ELSE uh.PathologicalTNMGroup END
					,L_KEY_WORKER_SEEN							= CASE WHEN mmvc.L_KEY_WORKER_SEEN = 1 THEN mmv.L_KEY_WORKER_SEEN ELSE uh.L_KEY_WORKER_SEEN END
					,L_PALLIATIVE_SPECIALIST_SEEN				= CASE WHEN mmvc.L_PALLIATIVE_SPECIALIST_SEEN = 1 THEN mmv.L_PALLIATIVE_SPECIALIST_SEEN ELSE uh.L_PALLIATIVE_SPECIALIST_SEEN END
					,GERM_CELL_NON_CNS_ID						= CASE WHEN mmvc.GERM_CELL_NON_CNS_ID = 1 THEN mmv.GERM_CELL_NON_CNS_ID ELSE uh.GERM_CELL_NON_CNS_ID END
					,RECURRENCE_CANCER_SITE_ID					= CASE WHEN mmvc.RECURRENCE_CANCER_SITE_ID = 1 THEN mmv.RECURRENCE_CANCER_SITE_ID ELSE uh.RECURRENCE_CANCER_SITE_ID END
					,ICD03_GROUP								= CASE WHEN mmvc.ICD03_GROUP = 1 THEN mmv.ICD03_GROUP ELSE uh.ICD03_GROUP END
					,ICD03										= CASE WHEN mmvc.ICD03 = 1 THEN mmv.ICD03 ELSE uh.ICD03 END
					,L_DATE_DIAGNOSIS_DAHNO_LUCADA				= CASE WHEN mmvc.L_DATE_DIAGNOSIS_DAHNO_LUCADA = 1 THEN mmv.L_DATE_DIAGNOSIS_DAHNO_LUCADA ELSE uh.L_DATE_DIAGNOSIS_DAHNO_LUCADA END
					,L_INDICATOR_CODE							= CASE WHEN mmvc.L_INDICATOR_CODE = 1 THEN mmv.L_INDICATOR_CODE ELSE uh.L_INDICATOR_CODE END
					,PRIMARY_DIAGNOSIS_SUB_COMMENT				= CASE WHEN mmvc.PRIMARY_DIAGNOSIS_SUB_COMMENT = 1 THEN mmv.PRIMARY_DIAGNOSIS_SUB_COMMENT ELSE uh.PRIMARY_DIAGNOSIS_SUB_COMMENT END
					,CONSULTANT_CODE_AT_DIAGNOSIS				= CASE WHEN mmvc.CONSULTANT_CODE_AT_DIAGNOSIS = 1 THEN mmv.CONSULTANT_CODE_AT_DIAGNOSIS ELSE uh.CONSULTANT_CODE_AT_DIAGNOSIS END
					,CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS		= CASE WHEN mmvc.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS = 1 THEN mmv.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS ELSE uh.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS END
					,FETOPROTEIN								= CASE WHEN mmvc.FETOPROTEIN = 1 THEN mmv.FETOPROTEIN ELSE uh.FETOPROTEIN END
					,GONADOTROPIN								= CASE WHEN mmvc.GONADOTROPIN = 1 THEN mmv.GONADOTROPIN ELSE uh.GONADOTROPIN END
					,GONADOTROPIN_SERUM							= CASE WHEN mmvc.GONADOTROPIN_SERUM = 1 THEN mmv.GONADOTROPIN_SERUM ELSE uh.GONADOTROPIN_SERUM END
					,FETOPROTEIN_SERUM							= CASE WHEN mmvc.FETOPROTEIN_SERUM = 1 THEN mmv.FETOPROTEIN_SERUM ELSE uh.FETOPROTEIN_SERUM END
					,SARCOMA_TUMOUR_SITE_BONE					= CASE WHEN mmvc.SARCOMA_TUMOUR_SITE_BONE = 1 THEN mmv.SARCOMA_TUMOUR_SITE_BONE ELSE uh.SARCOMA_TUMOUR_SITE_BONE END
					,SARCOMA_TUMOUR_SITE_SOFT_TISSUE			= CASE WHEN mmvc.SARCOMA_TUMOUR_SITE_SOFT_TISSUE = 1 THEN mmv.SARCOMA_TUMOUR_SITE_SOFT_TISSUE ELSE uh.SARCOMA_TUMOUR_SITE_SOFT_TISSUE END
					,SARCOMA_TUMOUR_SUBSITE_BONE				= CASE WHEN mmvc.SARCOMA_TUMOUR_SUBSITE_BONE = 1 THEN mmv.SARCOMA_TUMOUR_SUBSITE_BONE ELSE uh.SARCOMA_TUMOUR_SUBSITE_BONE END
					,SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE			= CASE WHEN mmvc.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE = 1 THEN mmv.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE ELSE uh.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE END
					,ROOT_DECISION_DATE_COMMENTS				= CASE WHEN mmvc.ROOT_DECISION_DATE_COMMENTS = 1 THEN mmv.ROOT_DECISION_DATE_COMMENTS ELSE uh.ROOT_DECISION_DATE_COMMENTS END
					,ROOT_RECEIPT_DATE_COMMENTS					= CASE WHEN mmvc.ROOT_RECEIPT_DATE_COMMENTS = 1 THEN mmv.ROOT_RECEIPT_DATE_COMMENTS ELSE uh.ROOT_RECEIPT_DATE_COMMENTS END
					,ROOT_FIRST_SEEN_DATE_COMMENTS				= CASE WHEN mmvc.ROOT_FIRST_SEEN_DATE_COMMENTS = 1 THEN mmv.ROOT_FIRST_SEEN_DATE_COMMENTS ELSE uh.ROOT_FIRST_SEEN_DATE_COMMENTS END
					,ROOT_DIAGNOSIS_DATE_COMMENTS				= CASE WHEN mmvc.ROOT_DIAGNOSIS_DATE_COMMENTS = 1 THEN mmv.ROOT_DIAGNOSIS_DATE_COMMENTS ELSE uh.ROOT_DIAGNOSIS_DATE_COMMENTS END
					,ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS		= CASE WHEN mmvc.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS = 1 THEN mmv.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS ELSE uh.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS END
					,ROOT_UPGRADE_COMMENTS						= CASE WHEN mmvc.ROOT_UPGRADE_COMMENTS = 1 THEN mmv.ROOT_UPGRADE_COMMENTS ELSE uh.ROOT_UPGRADE_COMMENTS END
					,FIRST_APPT_TIME							= CASE WHEN mmvc.FIRST_APPT_TIME = 1 THEN mmv.FIRST_APPT_TIME ELSE uh.FIRST_APPT_TIME END
					,TRANSFER_REASON							= CASE WHEN mmvc.TRANSFER_REASON = 1 THEN mmv.TRANSFER_REASON ELSE uh.TRANSFER_REASON END
					,DATE_NEW_REFERRAL							= CASE WHEN mmvc.DATE_NEW_REFERRAL = 1 THEN mmv.DATE_NEW_REFERRAL ELSE uh.DATE_NEW_REFERRAL END
					,TUMOUR_SITE_NEW							= CASE WHEN mmvc.TUMOUR_SITE_NEW = 1 THEN mmv.TUMOUR_SITE_NEW ELSE uh.TUMOUR_SITE_NEW END
					,DATE_TRANSFER_ACTIONED						= CASE WHEN mmvc.DATE_TRANSFER_ACTIONED = 1 THEN mmv.DATE_TRANSFER_ACTIONED ELSE uh.DATE_TRANSFER_ACTIONED END
					,SOURCE_CARE_ID								= CASE WHEN mmvc.SOURCE_CARE_ID = 1 THEN mmv.SOURCE_CARE_ID ELSE uh.SOURCE_CARE_ID END
					,ADT_REF_ID									= CASE WHEN mmvc.ADT_REF_ID = 1 THEN mmv.ADT_REF_ID ELSE uh.ADT_REF_ID END
					,ACTION_ID									= CASE WHEN mmvc.ACTION_ID = 1 THEN mmv.ACTION_ID ELSE uh.ACTION_ID END
					,DIAGNOSIS_ACTION_ID						= CASE WHEN mmvc.DIAGNOSIS_ACTION_ID = 1 THEN mmv.DIAGNOSIS_ACTION_ID ELSE uh.DIAGNOSIS_ACTION_ID END
					,ORIGINAL_SOURCE_CARE_ID					= CASE WHEN mmvc.ORIGINAL_SOURCE_CARE_ID = 1 THEN mmv.ORIGINAL_SOURCE_CARE_ID ELSE uh.ORIGINAL_SOURCE_CARE_ID END
					,TRANSFER_DATE_COMMENTS						= CASE WHEN mmvc.TRANSFER_DATE_COMMENTS = 1 THEN mmv.TRANSFER_DATE_COMMENTS ELSE uh.TRANSFER_DATE_COMMENTS END
					,SPECIALIST_REFERRAL_COMMENTS				= CASE WHEN mmvc.SPECIALIST_REFERRAL_COMMENTS = 1 THEN mmv.SPECIALIST_REFERRAL_COMMENTS ELSE uh.SPECIALIST_REFERRAL_COMMENTS END
					,NON_CANCER_DIAGNOSIS_CHAPTER				= CASE WHEN mmvc.NON_CANCER_DIAGNOSIS_CHAPTER = 1 THEN mmv.NON_CANCER_DIAGNOSIS_CHAPTER ELSE uh.NON_CANCER_DIAGNOSIS_CHAPTER END
					,NON_CANCER_DIAGNOSIS_GROUP					= CASE WHEN mmvc.NON_CANCER_DIAGNOSIS_GROUP = 1 THEN mmv.NON_CANCER_DIAGNOSIS_GROUP ELSE uh.NON_CANCER_DIAGNOSIS_GROUP END
					,NON_CANCER_DIAGNOSIS_CODE					= CASE WHEN mmvc.NON_CANCER_DIAGNOSIS_CODE = 1 THEN mmv.NON_CANCER_DIAGNOSIS_CODE ELSE uh.NON_CANCER_DIAGNOSIS_CODE END
					,TNM_UNKNOWN								= CASE WHEN mmvc.TNM_UNKNOWN = 1 THEN mmv.TNM_UNKNOWN ELSE uh.TNM_UNKNOWN END
					,ReferringPractice							= CASE WHEN mmvc.ReferringPractice = 1 THEN mmv.ReferringPractice ELSE uh.ReferringPractice END
					,ReferringGP								= CASE WHEN mmvc.ReferringGP = 1 THEN mmv.ReferringGP ELSE uh.ReferringGP END
					,ReferringBranch							= CASE WHEN mmvc.ReferringBranch = 1 THEN mmv.ReferringBranch ELSE uh.ReferringBranch END
					,BankedTissue								= CASE WHEN mmvc.BankedTissue = 1 THEN mmv.BankedTissue ELSE uh.BankedTissue END
					,BankedTissueTumour							= CASE WHEN mmvc.BankedTissueTumour = 1 THEN mmv.BankedTissueTumour ELSE uh.BankedTissueTumour END
					,BankedTissueBlood							= CASE WHEN mmvc.BankedTissueBlood = 1 THEN mmv.BankedTissueBlood ELSE uh.BankedTissueBlood END
					,BankedTissueCSF							= CASE WHEN mmvc.BankedTissueCSF = 1 THEN mmv.BankedTissueCSF ELSE uh.BankedTissueCSF END
					,BankedTissueBoneMarrow						= CASE WHEN mmvc.BankedTissueBoneMarrow = 1 THEN mmv.BankedTissueBoneMarrow ELSE uh.BankedTissueBoneMarrow END
					,SNOMed_CT									= CASE WHEN mmvc.SNOMed_CT = 1 THEN mmv.SNOMed_CT ELSE uh.SNOMed_CT END
					,ADT_PLACER_ID								= CASE WHEN mmvc.ADT_PLACER_ID = 1 THEN mmv.ADT_PLACER_ID ELSE uh.ADT_PLACER_ID END
					,SNOMEDCTDiagnosisID						= CASE WHEN mmvc.SNOMEDCTDiagnosisID = 1 THEN mmv.SNOMEDCTDiagnosisID ELSE uh.SNOMEDCTDiagnosisID END
					,FasterDiagnosisOrganisationID				= CASE WHEN mmvc.FasterDiagnosisOrganisationID = 1 THEN ISNULL(FD_org.ID, mmv.FasterDiagnosisOrganisationID) ELSE uh.FasterDiagnosisOrganisationID END
					,FasterDiagnosisCancerSiteOverrideID		= CASE WHEN mmvc.FasterDiagnosisCancerSiteOverrideID = 1 THEN mmv.FasterDiagnosisCancerSiteOverrideID ELSE uh.FasterDiagnosisCancerSiteOverrideID END
					,FasterDiagnosisExclusionDate				= CASE WHEN mmvc.FasterDiagnosisExclusionDate = 1 THEN mmv.FasterDiagnosisExclusionDate ELSE uh.FasterDiagnosisExclusionDate END
					,FasterDiagnosisExclusionReasonID			= CASE WHEN mmvc.FasterDiagnosisExclusionReasonID = 1 THEN mmv.FasterDiagnosisExclusionReasonID ELSE uh.FasterDiagnosisExclusionReasonID END
					,FasterDiagnosisDelayReasonID				= CASE WHEN mmvc.FasterDiagnosisDelayReasonID = 1 THEN mmv.FasterDiagnosisDelayReasonID ELSE uh.FasterDiagnosisDelayReasonID END
					,FasterDiagnosisDelayReasonComments			= CASE WHEN mmvc.FasterDiagnosisDelayReasonComments = 1 THEN mmv.FasterDiagnosisDelayReasonComments ELSE uh.FasterDiagnosisDelayReasonComments END
					,FasterDiagnosisCommunicationMethodID		= CASE WHEN mmvc.FasterDiagnosisCommunicationMethodID = 1 THEN mmv.FasterDiagnosisCommunicationMethodID ELSE uh.FasterDiagnosisCommunicationMethodID END
					,FasterDiagnosisInformingCareProfessionalID	= CASE WHEN mmvc.FasterDiagnosisInformingCareProfessionalID = 1 THEN mmv.FasterDiagnosisInformingCareProfessionalID ELSE uh.FasterDiagnosisInformingCareProfessionalID END
					,FasterDiagnosisOtherCareProfessional		= CASE WHEN mmvc.FasterDiagnosisOtherCareProfessional = 1 THEN mmv.FasterDiagnosisOtherCareProfessional ELSE uh.FasterDiagnosisOtherCareProfessional END
					,FasterDiagnosisOtherCommunicationMethod	= CASE WHEN mmvc.FasterDiagnosisOtherCommunicationMethod = 1 THEN mmv.FasterDiagnosisOtherCommunicationMethod ELSE uh.FasterDiagnosisOtherCommunicationMethod END
					--,DEPRECATED_20_01_RecurrenceMetastaticType	= CASE WHEN mmvc.DEPRECATED_20_01_RecurrenceMetastaticType = 1 THEN mmv.DEPRECATED_20_01_RecurrenceMetastaticType ELSE uh.DEPRECATED_20_01_RecurrenceMetastaticType END
					,NonPrimaryPathwayOptionsID					= CASE WHEN mmvc.NonPrimaryPathwayOptionsID = 1 THEN mmv.NonPrimaryPathwayOptionsID ELSE uh.NonPrimaryPathwayOptionsID END
					,DiagnosisUncertainty						= CASE WHEN mmvc.DiagnosisUncertainty = 1 THEN mmv.DiagnosisUncertainty ELSE uh.DiagnosisUncertainty END
					,TNMOrganisation							= CASE WHEN mmvc.TNMOrganisation = 1 THEN mmv.TNMOrganisation ELSE uh.TNMOrganisation END
					,FasterDiagnosisTargetRCComments			= CASE WHEN mmvc.FasterDiagnosisTargetRCComments = 1 THEN mmv.FasterDiagnosisTargetRCComments ELSE uh.FasterDiagnosisTargetRCComments END
					,FasterDiagnosisEndRCComments				= CASE WHEN mmvc.FasterDiagnosisEndRCComments = 1 THEN mmv.FasterDiagnosisEndRCComments ELSE uh.FasterDiagnosisEndRCComments END
					,TNMOrganisation_Integrated					= CASE WHEN mmvc.TNMOrganisation_Integrated = 1 THEN mmv.TNMOrganisation_Integrated ELSE uh.TNMOrganisation_Integrated END
					,LDHValue									= CASE WHEN mmvc.LDHValue = 1 THEN mmv.LDHValue ELSE uh.LDHValue END
					--,DEPRECATED_20_01_LDH_NORMAL				= CASE WHEN mmvc.DEPRECATED_20_01_LDH_NORMAL = 1 THEN mmv.DEPRECATED_20_01_LDH_NORMAL ELSE uh.DEPRECATED_20_01_LDH_NORMAL END
					,BankedTissueUrine							= CASE WHEN mmvc.BankedTissueUrine = 1 THEN mmv.BankedTissueUrine ELSE uh.BankedTissueUrine END
					,SubsiteID									= CASE WHEN mmvc.SubsiteID = 1 THEN mmv.SubsiteID ELSE uh.SubsiteID END
					,PredictedBreachStatus						= CASE WHEN mmvc.PredictedBreachStatus = 1 THEN mmv.PredictedBreachStatus ELSE uh.PredictedBreachStatus END
					,RMRefID									= CASE WHEN mmvc.RMRefID = 1 THEN mmv.RMRefID ELSE uh.RMRefID END
					,TertiaryReferralKey						= CASE WHEN mmvc.TertiaryReferralKey = 1 THEN mmv.TertiaryReferralKey ELSE uh.TertiaryReferralKey END
					,ClinicalTLetter							= CASE WHEN mmvc.ClinicalTLetter = 1 THEN mmv.ClinicalTLetter ELSE uh.ClinicalTLetter END
					,ClinicalNLetter							= CASE WHEN mmvc.ClinicalNLetter = 1 THEN mmv.ClinicalNLetter ELSE uh.ClinicalNLetter END
					,ClinicalMLetter							= CASE WHEN mmvc.ClinicalMLetter = 1 THEN mmv.ClinicalMLetter ELSE uh.ClinicalMLetter END
					,PathologicalTLetter						= CASE WHEN mmvc.PathologicalTLetter = 1 THEN mmv.PathologicalTLetter ELSE uh.PathologicalTLetter END
					,PathologicalNLetter						= CASE WHEN mmvc.PathologicalNLetter = 1 THEN mmv.PathologicalNLetter ELSE uh.PathologicalNLetter END
					,PathologicalMLetter						= CASE WHEN mmvc.PathologicalMLetter = 1 THEN mmv.PathologicalMLetter ELSE uh.PathologicalMLetter END
					,FDPlannedInterval							= CASE WHEN mmvc.FDPlannedInterval = 1 THEN mmv.FDPlannedInterval ELSE uh.FDPlannedInterval END
					,LabReportDate								= CASE WHEN mmvc.LabReportDate = 1 THEN mmv.LabReportDate ELSE uh.LabReportDate END
					,LabReportOrgID								= CASE WHEN mmvc.LabReportOrgID = 1 THEN mmv.LabReportOrgID ELSE uh.LabReportOrgID END
					,ReferralRoute								= CASE WHEN mmvc.ReferralRoute = 1 THEN mmv.ReferralRoute ELSE uh.ReferralRoute END
					,ReferralOtherRoute							= CASE WHEN mmvc.ReferralOtherRoute = 1 THEN mmv.ReferralOtherRoute ELSE uh.ReferralOtherRoute END
					,RelapseMorphology							= CASE WHEN mmvc.RelapseMorphology = 1 THEN mmv.RelapseMorphology ELSE uh.RelapseMorphology END
					,RelapseFlow								= CASE WHEN mmvc.RelapseFlow = 1 THEN mmv.RelapseFlow ELSE uh.RelapseFlow END
					,RelapseMolecular							= CASE WHEN mmvc.RelapseMolecular = 1 THEN mmv.RelapseMolecular ELSE uh.RelapseMolecular END
					,RelapseClinicalExamination					= CASE WHEN mmvc.RelapseClinicalExamination = 1 THEN mmv.RelapseClinicalExamination ELSE uh.RelapseClinicalExamination END
					,RelapseOther								= CASE WHEN mmvc.RelapseOther = 1 THEN mmv.RelapseOther ELSE uh.RelapseOther END
					,RapidDiagnostic							= CASE WHEN mmvc.RapidDiagnostic = 1 THEN mmv.RapidDiagnostic ELSE uh.RapidDiagnostic END
					,PrimaryReferralFlag						= CASE WHEN mmvc.PrimaryReferralFlag = 1 THEN mmv.PrimaryReferralFlag ELSE uh.PrimaryReferralFlag END
					,OtherAssessedBy							= CASE WHEN mmvc.OtherAssessedBy = 1 THEN mmv.OtherAssessedBy ELSE uh.OtherAssessedBy END
					,SharedBreach								= CASE WHEN mmvc.SharedBreach = 1 THEN mmv.SharedBreach ELSE uh.SharedBreach END
					,PredictedBreachYear						= CASE WHEN mmvc.PredictedBreachYear = 1 THEN mmv.PredictedBreachYear ELSE uh.PredictedBreachYear END
					,PredictedBreachMonth						= CASE WHEN mmvc.PredictedBreachMonth = 1 THEN mmv.PredictedBreachMonth ELSE uh.PredictedBreachMonth END
		FROM		#mcIx mc
		INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																ON	mc.SrcSys_Major = uh.SrcSys
																AND	mc.Src_UID_Major = uh.Src_UID
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv
																			ON	mc.SrcSys_Major = mmv.SrcSys_Major
																			AND	mc.Src_UID_Major = mmv.Src_UID_Major
																			AND	mmv.ValidationStatus NOT IN ('All Matches Algorithmic') -- use this to stop column overrides for validation records with these statuses
		LEFT JOIN	Merge_DM_MatchViews.tblMAIN_REFERRALS_vw_Match_MajorValidationColumns mmvc
																							ON	mmv.SrcSys_Major = mmvc.SrcSys_Major
																							AND	mmv.Src_UID_Major = mmvc.Src_UID_Major
		LEFT JOIN	Merge_DM_MatchViews.tblMAIN_REFERRALS_vw_Match_MajorValidationColumns_SrcSys mmvcs
																							ON	mmv.SrcSys_Major = mmvcs.SrcSys_Major
																							AND	mmv.Src_UID_Major = mmvcs.Src_UID_Major
		LEFT JOIN	SCR_DW.SCR.dbo_OrganisationSites FD_org
															ON	mmvcs.FasterDiagnosisOrganisationID = 2
															AND	mmv.FasterDiagnosisOrganisationID = FD_Org.DW_SOURCE_PATIENT_ID
		WHERE		mc.IsMajor = 1
		AND			mc.IsMajorSCR = 1

		-- external majors
		INSERT INTO	#ValidatedData
		SELECT		SrcSys_MajorExt								= mc.SrcSys_Major
					,Src_UID_MajorExt							= mc.Src_UID_Major
					,SrcSys_Major								= mc.SrcSys
					,Src_UID_Major								= mc.Src_UID
					,IsValidatedMajor							= 1
					,IsConfirmed								= mc.IsConfirmed
					,LastUpdated								= uh.LastUpdated
					,SrcSys										= mc.SrcSys
					,Src_UID									= mc.Src_UID
					,CARE_ID									= CASE WHEN mmvc.CARE_ID = 1 THEN mmv.CARE_ID ELSE uh.CARE_ID END
					,PATIENT_ID									= CASE WHEN mmvc.PATIENT_ID = 1 THEN mmv.PATIENT_ID ELSE uh.PATIENT_ID END
					,TEMP_ID									= CASE WHEN mmvc.TEMP_ID = 1 THEN mmv.TEMP_ID ELSE uh.TEMP_ID END
					,L_CANCER_SITE								= CASE WHEN mmvc.L_CANCER_SITE = 1 THEN mmv.L_CANCER_SITE ELSE uh.L_CANCER_SITE END
					,N2_1_REFERRAL_SOURCE						= CASE WHEN mmvc.N2_1_REFERRAL_SOURCE = 1 THEN mmv.N2_1_REFERRAL_SOURCE ELSE uh.N2_1_REFERRAL_SOURCE END
					,N2_2_ORG_CODE_REF							= CASE WHEN mmvc.N2_2_ORG_CODE_REF = 1 THEN mmv.N2_2_ORG_CODE_REF ELSE uh.N2_2_ORG_CODE_REF END
					,N2_3_REFERRER_CODE							= CASE WHEN mmvc.N2_3_REFERRER_CODE = 1 THEN mmv.N2_3_REFERRER_CODE ELSE uh.N2_3_REFERRER_CODE END
					,N2_4_PRIORITY_TYPE							= CASE WHEN mmvc.N2_4_PRIORITY_TYPE = 1 THEN mmv.N2_4_PRIORITY_TYPE ELSE uh.N2_4_PRIORITY_TYPE END
					,N2_5_DECISION_DATE							= CASE WHEN mmvc.N2_5_DECISION_DATE = 1 THEN mmv.N2_5_DECISION_DATE ELSE uh.N2_5_DECISION_DATE END
					,N2_6_RECEIPT_DATE							= CASE WHEN mmvc.N2_6_RECEIPT_DATE = 1 THEN mmv.N2_6_RECEIPT_DATE ELSE uh.N2_6_RECEIPT_DATE END
					,N2_7_CONSULTANT							= CASE WHEN mmvc.N2_7_CONSULTANT = 1 THEN mmv.N2_7_CONSULTANT ELSE uh.N2_7_CONSULTANT END
					,N2_8_SPECIALTY								= CASE WHEN mmvc.N2_8_SPECIALTY = 1 THEN mmv.N2_8_SPECIALTY ELSE uh.N2_8_SPECIALTY END
					,N2_9_FIRST_SEEN_DATE						= CASE WHEN mmvc.N2_9_FIRST_SEEN_DATE = 1 THEN mmv.N2_9_FIRST_SEEN_DATE ELSE uh.N2_9_FIRST_SEEN_DATE END
					,N1_3_ORG_CODE_SEEN							= CASE WHEN mmvc.N1_3_ORG_CODE_SEEN = 1 THEN mmv.N1_3_ORG_CODE_SEEN ELSE uh.N1_3_ORG_CODE_SEEN END
					,N2_10_FIRST_SEEN_DELAY						= CASE WHEN mmvc.N2_10_FIRST_SEEN_DELAY = 1 THEN mmv.N2_10_FIRST_SEEN_DELAY ELSE uh.N2_10_FIRST_SEEN_DELAY END
					,N2_12_CANCER_TYPE							= CASE WHEN mmvc.N2_12_CANCER_TYPE = 1 THEN mmv.N2_12_CANCER_TYPE ELSE uh.N2_12_CANCER_TYPE END
					,N2_13_CANCER_STATUS						= CASE WHEN mmvc.N2_13_CANCER_STATUS = 1 THEN mmv.N2_13_CANCER_STATUS ELSE uh.N2_13_CANCER_STATUS END
					,L_FIRST_APPOINTMENT						= CASE WHEN mmvc.L_FIRST_APPOINTMENT = 1 THEN mmv.L_FIRST_APPOINTMENT ELSE uh.L_FIRST_APPOINTMENT END
					,L_CANCELLED_DATE							= CASE WHEN mmvc.L_CANCELLED_DATE = 1 THEN mmv.L_CANCELLED_DATE ELSE uh.L_CANCELLED_DATE END
					,N2_14_ADJ_TIME								= CASE WHEN mmvc.N2_14_ADJ_TIME = 1 THEN mmv.N2_14_ADJ_TIME ELSE uh.N2_14_ADJ_TIME END
					,N2_15_ADJ_REASON							= CASE WHEN mmvc.N2_15_ADJ_REASON = 1 THEN mmv.N2_15_ADJ_REASON ELSE uh.N2_15_ADJ_REASON END
					,L_REFERRAL_METHOD							= CASE WHEN mmvc.L_REFERRAL_METHOD = 1 THEN mmv.L_REFERRAL_METHOD ELSE uh.L_REFERRAL_METHOD END
					,N2_16_OP_REFERRAL							= CASE WHEN mmvc.N2_16_OP_REFERRAL = 1 THEN mmv.N2_16_OP_REFERRAL ELSE uh.N2_16_OP_REFERRAL END
					,L_SPECIALIST_DATE							= CASE WHEN mmvc.L_SPECIALIST_DATE = 1 THEN mmv.L_SPECIALIST_DATE ELSE uh.L_SPECIALIST_DATE END
					,L_ORG_CODE_SPECIALIST						= CASE WHEN mmvc.L_ORG_CODE_SPECIALIST = 1 THEN mmv.L_ORG_CODE_SPECIALIST ELSE uh.L_ORG_CODE_SPECIALIST END
					,L_SPECIALIST_SEEN_DATE						= CASE WHEN mmvc.L_SPECIALIST_SEEN_DATE = 1 THEN mmv.L_SPECIALIST_SEEN_DATE ELSE uh.L_SPECIALIST_SEEN_DATE END
					,N1_3_ORG_CODE_SPEC_SEEN					= CASE WHEN mmvc.N1_3_ORG_CODE_SPEC_SEEN = 1 THEN mmv.N1_3_ORG_CODE_SPEC_SEEN ELSE uh.N1_3_ORG_CODE_SPEC_SEEN END
					,N_UPGRADE_DATE								= CASE WHEN mmvc.N_UPGRADE_DATE = 1 THEN mmv.N_UPGRADE_DATE ELSE uh.N_UPGRADE_DATE END
					,N_UPGRADE_ORG_CODE							= CASE WHEN mmvc.N_UPGRADE_ORG_CODE = 1 THEN mmv.N_UPGRADE_ORG_CODE ELSE uh.N_UPGRADE_ORG_CODE END
					,L_UPGRADE_WHEN								= CASE WHEN mmvc.L_UPGRADE_WHEN = 1 THEN mmv.L_UPGRADE_WHEN ELSE uh.L_UPGRADE_WHEN END
					,L_UPGRADE_WHO								= CASE WHEN mmvc.L_UPGRADE_WHO = 1 THEN mmv.L_UPGRADE_WHO ELSE uh.L_UPGRADE_WHO END
					,N4_1_DIAGNOSIS_DATE						= CASE WHEN mmvc.N4_1_DIAGNOSIS_DATE = 1 THEN mmv.N4_1_DIAGNOSIS_DATE ELSE uh.N4_1_DIAGNOSIS_DATE END
					,L_DIAGNOSIS								= CASE WHEN mmvc.L_DIAGNOSIS = 1 THEN mmv.L_DIAGNOSIS ELSE uh.L_DIAGNOSIS END
					,N4_2_DIAGNOSIS_CODE						= CASE WHEN mmvc.N4_2_DIAGNOSIS_CODE = 1 THEN mmv.N4_2_DIAGNOSIS_CODE ELSE uh.N4_2_DIAGNOSIS_CODE END
					,L_ORG_CODE_DIAGNOSIS						= CASE WHEN mmvc.L_ORG_CODE_DIAGNOSIS = 1 THEN mmv.L_ORG_CODE_DIAGNOSIS ELSE uh.L_ORG_CODE_DIAGNOSIS END
					,L_PT_INFORMED_DATE							= CASE WHEN mmvc.L_PT_INFORMED_DATE = 1 THEN mmv.L_PT_INFORMED_DATE ELSE uh.L_PT_INFORMED_DATE END
					,L_OTHER_DIAG_DATE							= CASE WHEN mmvc.L_OTHER_DIAG_DATE = 1 THEN mmv.L_OTHER_DIAG_DATE ELSE uh.L_OTHER_DIAG_DATE END
					,N4_3_LATERALITY							= CASE WHEN mmvc.N4_3_LATERALITY = 1 THEN mmv.N4_3_LATERALITY ELSE uh.N4_3_LATERALITY END
					,N4_4_BASIS_DIAGNOSIS						= CASE WHEN mmvc.N4_4_BASIS_DIAGNOSIS = 1 THEN mmv.N4_4_BASIS_DIAGNOSIS ELSE uh.N4_4_BASIS_DIAGNOSIS END
					,L_TOPOGRAPHY								= CASE WHEN mmvc.L_TOPOGRAPHY = 1 THEN mmv.L_TOPOGRAPHY ELSE uh.L_TOPOGRAPHY END
					,L_HISTOLOGY_GROUP							= CASE WHEN mmvc.L_HISTOLOGY_GROUP = 1 THEN mmv.L_HISTOLOGY_GROUP ELSE uh.L_HISTOLOGY_GROUP END
					,N4_5_HISTOLOGY								= CASE WHEN mmvc.N4_5_HISTOLOGY = 1 THEN mmv.N4_5_HISTOLOGY ELSE uh.N4_5_HISTOLOGY END
					,N4_6_DIFFERENTIATION						= CASE WHEN mmvc.N4_6_DIFFERENTIATION = 1 THEN mmv.N4_6_DIFFERENTIATION ELSE uh.N4_6_DIFFERENTIATION END
					,ClinicalTStage								= CASE WHEN mmvc.ClinicalTStage = 1 THEN mmv.ClinicalTStage ELSE uh.ClinicalTStage END
					,ClinicalTCertainty							= CASE WHEN mmvc.ClinicalTCertainty = 1 THEN mmv.ClinicalTCertainty ELSE uh.ClinicalTCertainty END
					,ClinicalNStage								= CASE WHEN mmvc.ClinicalNStage = 1 THEN mmv.ClinicalNStage ELSE uh.ClinicalNStage END
					,ClinicalNCertainty							= CASE WHEN mmvc.ClinicalNCertainty = 1 THEN mmv.ClinicalNCertainty ELSE uh.ClinicalNCertainty END
					,ClinicalMStage								= CASE WHEN mmvc.ClinicalMStage = 1 THEN mmv.ClinicalMStage ELSE uh.ClinicalMStage END
					,ClinicalMCertainty							= CASE WHEN mmvc.ClinicalMCertainty = 1 THEN mmv.ClinicalMCertainty ELSE uh.ClinicalMCertainty END
					,ClinicalOverallCertainty					= CASE WHEN mmvc.ClinicalOverallCertainty = 1 THEN mmv.ClinicalOverallCertainty ELSE uh.ClinicalOverallCertainty END
					,N6_9_SITE_CLASSIFICATION					= CASE WHEN mmvc.N6_9_SITE_CLASSIFICATION = 1 THEN mmv.N6_9_SITE_CLASSIFICATION ELSE uh.N6_9_SITE_CLASSIFICATION END
					,PathologicalOverallCertainty				= CASE WHEN mmvc.PathologicalOverallCertainty = 1 THEN mmv.PathologicalOverallCertainty ELSE uh.PathologicalOverallCertainty END
					,PathologicalTCertainty						= CASE WHEN mmvc.PathologicalTCertainty = 1 THEN mmv.PathologicalTCertainty ELSE uh.PathologicalTCertainty END
					,PathologicalTStage							= CASE WHEN mmvc.PathologicalTStage = 1 THEN mmv.PathologicalTStage ELSE uh.PathologicalTStage END
					,PathologicalNCertainty						= CASE WHEN mmvc.PathologicalNCertainty = 1 THEN mmv.PathologicalNCertainty ELSE uh.PathologicalNCertainty END
					,PathologicalNStage							= CASE WHEN mmvc.PathologicalNStage = 1 THEN mmv.PathologicalNStage ELSE uh.PathologicalNStage END
					,PathologicalMCertainty						= CASE WHEN mmvc.PathologicalMCertainty = 1 THEN mmv.PathologicalMCertainty ELSE uh.PathologicalMCertainty END
					,PathologicalMStage							= CASE WHEN mmvc.PathologicalMStage = 1 THEN mmv.PathologicalMStage ELSE uh.PathologicalMStage END
					,L_GP_INFORMED								= CASE WHEN mmvc.L_GP_INFORMED = 1 THEN mmv.L_GP_INFORMED ELSE uh.L_GP_INFORMED END
					,L_GP_INFORMED_DATE							= CASE WHEN mmvc.L_GP_INFORMED_DATE = 1 THEN mmv.L_GP_INFORMED_DATE ELSE uh.L_GP_INFORMED_DATE END
					,L_GP_NOT									= CASE WHEN mmvc.L_GP_NOT = 1 THEN mmv.L_GP_NOT ELSE uh.L_GP_NOT END
					,L_REL_INFORMED								= CASE WHEN mmvc.L_REL_INFORMED = 1 THEN mmv.L_REL_INFORMED ELSE uh.L_REL_INFORMED END
					,L_NURSE_PRESENT							= CASE WHEN mmvc.L_NURSE_PRESENT = 1 THEN mmv.L_NURSE_PRESENT ELSE uh.L_NURSE_PRESENT END
					,L_SPEC_NURSE_DATE							= CASE WHEN mmvc.L_SPEC_NURSE_DATE = 1 THEN mmv.L_SPEC_NURSE_DATE ELSE uh.L_SPEC_NURSE_DATE END
					,L_SEEN_NURSE_DATE							= CASE WHEN mmvc.L_SEEN_NURSE_DATE = 1 THEN mmv.L_SEEN_NURSE_DATE ELSE uh.L_SEEN_NURSE_DATE END
					,N16_1_ADJ_DAYS								= CASE WHEN mmvc.N16_1_ADJ_DAYS = 1 THEN mmv.N16_1_ADJ_DAYS ELSE uh.N16_1_ADJ_DAYS END
					,N16_2_ADJ_DAYS								= CASE WHEN mmvc.N16_2_ADJ_DAYS = 1 THEN mmv.N16_2_ADJ_DAYS ELSE uh.N16_2_ADJ_DAYS END
					,N16_3_ADJ_DECISION_CODE					= CASE WHEN mmvc.N16_3_ADJ_DECISION_CODE = 1 THEN mmv.N16_3_ADJ_DECISION_CODE ELSE uh.N16_3_ADJ_DECISION_CODE END
					,N16_4_ADJ_TREAT_CODE						= CASE WHEN mmvc.N16_4_ADJ_TREAT_CODE = 1 THEN mmv.N16_4_ADJ_TREAT_CODE ELSE uh.N16_4_ADJ_TREAT_CODE END
					,N16_5_DECISION_REASON_CODE					= CASE WHEN mmvc.N16_5_DECISION_REASON_CODE = 1 THEN mmv.N16_5_DECISION_REASON_CODE ELSE uh.N16_5_DECISION_REASON_CODE END
					,N16_6_TREATMENT_REASON_CODE				= CASE WHEN mmvc.N16_6_TREATMENT_REASON_CODE = 1 THEN mmv.N16_6_TREATMENT_REASON_CODE ELSE uh.N16_6_TREATMENT_REASON_CODE END
					,PathologicalTNMDate						= CASE WHEN mmvc.PathologicalTNMDate = 1 THEN mmv.PathologicalTNMDate ELSE uh.PathologicalTNMDate END
					,ClinicalTNMDate							= CASE WHEN mmvc.ClinicalTNMDate = 1 THEN mmv.ClinicalTNMDate ELSE uh.ClinicalTNMDate END
					,L_FIRST_CONSULTANT							= CASE WHEN mmvc.L_FIRST_CONSULTANT = 1 THEN mmv.L_FIRST_CONSULTANT ELSE uh.L_FIRST_CONSULTANT END
					,L_APPROPRIATE								= CASE WHEN mmvc.L_APPROPRIATE = 1 THEN mmv.L_APPROPRIATE ELSE uh.L_APPROPRIATE END
					,L_TERTIARY_DATE							= CASE WHEN mmvc.L_TERTIARY_DATE = 1 THEN mmv.L_TERTIARY_DATE ELSE uh.L_TERTIARY_DATE END
					,L_TERTIARY_TRUST							= CASE WHEN mmvc.L_TERTIARY_TRUST = 1 THEN mmv.L_TERTIARY_TRUST ELSE uh.L_TERTIARY_TRUST END
					,L_TERTIARY_REASON							= CASE WHEN mmvc.L_TERTIARY_REASON = 1 THEN mmv.L_TERTIARY_REASON ELSE uh.L_TERTIARY_REASON END
					,L_INAP_REF									= CASE WHEN mmvc.L_INAP_REF = 1 THEN mmv.L_INAP_REF ELSE uh.L_INAP_REF END
					,L_NEW_CA_SITE								= CASE WHEN mmvc.L_NEW_CA_SITE = 1 THEN mmv.L_NEW_CA_SITE ELSE uh.L_NEW_CA_SITE END
					,L_AUTO_REF									= CASE WHEN mmvc.L_AUTO_REF = 1 THEN mmv.L_AUTO_REF ELSE uh.L_AUTO_REF END
					,L_SEC_DIAGNOSIS_G							= CASE WHEN mmvc.L_SEC_DIAGNOSIS_G = 1 THEN mmv.L_SEC_DIAGNOSIS_G ELSE uh.L_SEC_DIAGNOSIS_G END
					,L_SEC_DIAGNOSIS							= CASE WHEN mmvc.L_SEC_DIAGNOSIS = 1 THEN mmv.L_SEC_DIAGNOSIS ELSE uh.L_SEC_DIAGNOSIS END
					,L_WRONG_REF								= CASE WHEN mmvc.L_WRONG_REF = 1 THEN mmv.L_WRONG_REF ELSE uh.L_WRONG_REF END
					,L_WRONG_REASON								= CASE WHEN mmvc.L_WRONG_REASON = 1 THEN mmv.L_WRONG_REASON ELSE uh.L_WRONG_REASON END
					,L_TUMOUR_STATUS							= CASE WHEN mmvc.L_TUMOUR_STATUS = 1 THEN mmv.L_TUMOUR_STATUS ELSE uh.L_TUMOUR_STATUS END
					,L_NON_CANCER								= CASE WHEN mmvc.L_NON_CANCER = 1 THEN mmv.L_NON_CANCER ELSE uh.L_NON_CANCER END
					,L_FIRST_APP								= CASE WHEN mmvc.L_FIRST_APP = 1 THEN mmv.L_FIRST_APP ELSE uh.L_FIRST_APP END
					,L_NO_APP									= CASE WHEN mmvc.L_NO_APP = 1 THEN mmv.L_NO_APP ELSE uh.L_NO_APP END
					,L_DIAG_WHO									= CASE WHEN mmvc.L_DIAG_WHO = 1 THEN mmv.L_DIAG_WHO ELSE uh.L_DIAG_WHO END
					,L_RECURRENCE								= CASE WHEN mmvc.L_RECURRENCE = 1 THEN mmv.L_RECURRENCE ELSE uh.L_RECURRENCE END
					,L_OTHER_SYMPS								= CASE WHEN mmvc.L_OTHER_SYMPS = 1 THEN mmv.L_OTHER_SYMPS ELSE uh.L_OTHER_SYMPS END
					,L_COMMENTS									= CASE WHEN mmvc.L_COMMENTS = 1 THEN mmv.L_COMMENTS ELSE uh.L_COMMENTS END
					,N2_11_FIRST_SEEN_REASON					= CASE WHEN mmvc.N2_11_FIRST_SEEN_REASON = 1 THEN mmv.N2_11_FIRST_SEEN_REASON ELSE uh.N2_11_FIRST_SEEN_REASON END
					,N16_7_DECISION_REASON						= CASE WHEN mmvc.N16_7_DECISION_REASON = 1 THEN mmv.N16_7_DECISION_REASON ELSE uh.N16_7_DECISION_REASON END
					,N16_8_TREATMENT_REASON						= CASE WHEN mmvc.N16_8_TREATMENT_REASON = 1 THEN mmv.N16_8_TREATMENT_REASON ELSE uh.N16_8_TREATMENT_REASON END
					,L_DIAGNOSIS_COMMENTS						= CASE WHEN mmvc.L_DIAGNOSIS_COMMENTS = 1 THEN mmv.L_DIAGNOSIS_COMMENTS ELSE uh.L_DIAGNOSIS_COMMENTS END
					,GP_PRACTICE_CODE							= CASE WHEN mmvc.GP_PRACTICE_CODE = 1 THEN mmv.GP_PRACTICE_CODE ELSE uh.GP_PRACTICE_CODE END
					,ClinicalTNMGroup							= CASE WHEN mmvc.ClinicalTNMGroup = 1 THEN mmv.ClinicalTNMGroup ELSE uh.ClinicalTNMGroup END
					,PathologicalTNMGroup						= CASE WHEN mmvc.PathologicalTNMGroup = 1 THEN mmv.PathologicalTNMGroup ELSE uh.PathologicalTNMGroup END
					,L_KEY_WORKER_SEEN							= CASE WHEN mmvc.L_KEY_WORKER_SEEN = 1 THEN mmv.L_KEY_WORKER_SEEN ELSE uh.L_KEY_WORKER_SEEN END
					,L_PALLIATIVE_SPECIALIST_SEEN				= CASE WHEN mmvc.L_PALLIATIVE_SPECIALIST_SEEN = 1 THEN mmv.L_PALLIATIVE_SPECIALIST_SEEN ELSE uh.L_PALLIATIVE_SPECIALIST_SEEN END
					,GERM_CELL_NON_CNS_ID						= CASE WHEN mmvc.GERM_CELL_NON_CNS_ID = 1 THEN mmv.GERM_CELL_NON_CNS_ID ELSE uh.GERM_CELL_NON_CNS_ID END
					,RECURRENCE_CANCER_SITE_ID					= CASE WHEN mmvc.RECURRENCE_CANCER_SITE_ID = 1 THEN mmv.RECURRENCE_CANCER_SITE_ID ELSE uh.RECURRENCE_CANCER_SITE_ID END
					,ICD03_GROUP								= CASE WHEN mmvc.ICD03_GROUP = 1 THEN mmv.ICD03_GROUP ELSE uh.ICD03_GROUP END
					,ICD03										= CASE WHEN mmvc.ICD03 = 1 THEN mmv.ICD03 ELSE uh.ICD03 END
					,L_DATE_DIAGNOSIS_DAHNO_LUCADA				= CASE WHEN mmvc.L_DATE_DIAGNOSIS_DAHNO_LUCADA = 1 THEN mmv.L_DATE_DIAGNOSIS_DAHNO_LUCADA ELSE uh.L_DATE_DIAGNOSIS_DAHNO_LUCADA END
					,L_INDICATOR_CODE							= CASE WHEN mmvc.L_INDICATOR_CODE = 1 THEN mmv.L_INDICATOR_CODE ELSE uh.L_INDICATOR_CODE END
					,PRIMARY_DIAGNOSIS_SUB_COMMENT				= CASE WHEN mmvc.PRIMARY_DIAGNOSIS_SUB_COMMENT = 1 THEN mmv.PRIMARY_DIAGNOSIS_SUB_COMMENT ELSE uh.PRIMARY_DIAGNOSIS_SUB_COMMENT END
					,CONSULTANT_CODE_AT_DIAGNOSIS				= CASE WHEN mmvc.CONSULTANT_CODE_AT_DIAGNOSIS = 1 THEN mmv.CONSULTANT_CODE_AT_DIAGNOSIS ELSE uh.CONSULTANT_CODE_AT_DIAGNOSIS END
					,CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS		= CASE WHEN mmvc.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS = 1 THEN mmv.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS ELSE uh.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS END
					,FETOPROTEIN								= CASE WHEN mmvc.FETOPROTEIN = 1 THEN mmv.FETOPROTEIN ELSE uh.FETOPROTEIN END
					,GONADOTROPIN								= CASE WHEN mmvc.GONADOTROPIN = 1 THEN mmv.GONADOTROPIN ELSE uh.GONADOTROPIN END
					,GONADOTROPIN_SERUM							= CASE WHEN mmvc.GONADOTROPIN_SERUM = 1 THEN mmv.GONADOTROPIN_SERUM ELSE uh.GONADOTROPIN_SERUM END
					,FETOPROTEIN_SERUM							= CASE WHEN mmvc.FETOPROTEIN_SERUM = 1 THEN mmv.FETOPROTEIN_SERUM ELSE uh.FETOPROTEIN_SERUM END
					,SARCOMA_TUMOUR_SITE_BONE					= CASE WHEN mmvc.SARCOMA_TUMOUR_SITE_BONE = 1 THEN mmv.SARCOMA_TUMOUR_SITE_BONE ELSE uh.SARCOMA_TUMOUR_SITE_BONE END
					,SARCOMA_TUMOUR_SITE_SOFT_TISSUE			= CASE WHEN mmvc.SARCOMA_TUMOUR_SITE_SOFT_TISSUE = 1 THEN mmv.SARCOMA_TUMOUR_SITE_SOFT_TISSUE ELSE uh.SARCOMA_TUMOUR_SITE_SOFT_TISSUE END
					,SARCOMA_TUMOUR_SUBSITE_BONE				= CASE WHEN mmvc.SARCOMA_TUMOUR_SUBSITE_BONE = 1 THEN mmv.SARCOMA_TUMOUR_SUBSITE_BONE ELSE uh.SARCOMA_TUMOUR_SUBSITE_BONE END
					,SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE			= CASE WHEN mmvc.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE = 1 THEN mmv.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE ELSE uh.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE END
					,ROOT_DECISION_DATE_COMMENTS				= CASE WHEN mmvc.ROOT_DECISION_DATE_COMMENTS = 1 THEN mmv.ROOT_DECISION_DATE_COMMENTS ELSE uh.ROOT_DECISION_DATE_COMMENTS END
					,ROOT_RECEIPT_DATE_COMMENTS					= CASE WHEN mmvc.ROOT_RECEIPT_DATE_COMMENTS = 1 THEN mmv.ROOT_RECEIPT_DATE_COMMENTS ELSE uh.ROOT_RECEIPT_DATE_COMMENTS END
					,ROOT_FIRST_SEEN_DATE_COMMENTS				= CASE WHEN mmvc.ROOT_FIRST_SEEN_DATE_COMMENTS = 1 THEN mmv.ROOT_FIRST_SEEN_DATE_COMMENTS ELSE uh.ROOT_FIRST_SEEN_DATE_COMMENTS END
					,ROOT_DIAGNOSIS_DATE_COMMENTS				= CASE WHEN mmvc.ROOT_DIAGNOSIS_DATE_COMMENTS = 1 THEN mmv.ROOT_DIAGNOSIS_DATE_COMMENTS ELSE uh.ROOT_DIAGNOSIS_DATE_COMMENTS END
					,ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS		= CASE WHEN mmvc.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS = 1 THEN mmv.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS ELSE uh.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS END
					,ROOT_UPGRADE_COMMENTS						= CASE WHEN mmvc.ROOT_UPGRADE_COMMENTS = 1 THEN mmv.ROOT_UPGRADE_COMMENTS ELSE uh.ROOT_UPGRADE_COMMENTS END
					,FIRST_APPT_TIME							= CASE WHEN mmvc.FIRST_APPT_TIME = 1 THEN mmv.FIRST_APPT_TIME ELSE uh.FIRST_APPT_TIME END
					,TRANSFER_REASON							= CASE WHEN mmvc.TRANSFER_REASON = 1 THEN mmv.TRANSFER_REASON ELSE uh.TRANSFER_REASON END
					,DATE_NEW_REFERRAL							= CASE WHEN mmvc.DATE_NEW_REFERRAL = 1 THEN mmv.DATE_NEW_REFERRAL ELSE uh.DATE_NEW_REFERRAL END
					,TUMOUR_SITE_NEW							= CASE WHEN mmvc.TUMOUR_SITE_NEW = 1 THEN mmv.TUMOUR_SITE_NEW ELSE uh.TUMOUR_SITE_NEW END
					,DATE_TRANSFER_ACTIONED						= CASE WHEN mmvc.DATE_TRANSFER_ACTIONED = 1 THEN mmv.DATE_TRANSFER_ACTIONED ELSE uh.DATE_TRANSFER_ACTIONED END
					,SOURCE_CARE_ID								= CASE WHEN mmvc.SOURCE_CARE_ID = 1 THEN mmv.SOURCE_CARE_ID ELSE uh.SOURCE_CARE_ID END
					,ADT_REF_ID									= CASE WHEN mmvc.ADT_REF_ID = 1 THEN mmv.ADT_REF_ID ELSE uh.ADT_REF_ID END
					,ACTION_ID									= CASE WHEN mmvc.ACTION_ID = 1 THEN mmv.ACTION_ID ELSE uh.ACTION_ID END
					,DIAGNOSIS_ACTION_ID						= CASE WHEN mmvc.DIAGNOSIS_ACTION_ID = 1 THEN mmv.DIAGNOSIS_ACTION_ID ELSE uh.DIAGNOSIS_ACTION_ID END
					,ORIGINAL_SOURCE_CARE_ID					= CASE WHEN mmvc.ORIGINAL_SOURCE_CARE_ID = 1 THEN mmv.ORIGINAL_SOURCE_CARE_ID ELSE uh.ORIGINAL_SOURCE_CARE_ID END
					,TRANSFER_DATE_COMMENTS						= CASE WHEN mmvc.TRANSFER_DATE_COMMENTS = 1 THEN mmv.TRANSFER_DATE_COMMENTS ELSE uh.TRANSFER_DATE_COMMENTS END
					,SPECIALIST_REFERRAL_COMMENTS				= CASE WHEN mmvc.SPECIALIST_REFERRAL_COMMENTS = 1 THEN mmv.SPECIALIST_REFERRAL_COMMENTS ELSE uh.SPECIALIST_REFERRAL_COMMENTS END
					,NON_CANCER_DIAGNOSIS_CHAPTER				= CASE WHEN mmvc.NON_CANCER_DIAGNOSIS_CHAPTER = 1 THEN mmv.NON_CANCER_DIAGNOSIS_CHAPTER ELSE uh.NON_CANCER_DIAGNOSIS_CHAPTER END
					,NON_CANCER_DIAGNOSIS_GROUP					= CASE WHEN mmvc.NON_CANCER_DIAGNOSIS_GROUP = 1 THEN mmv.NON_CANCER_DIAGNOSIS_GROUP ELSE uh.NON_CANCER_DIAGNOSIS_GROUP END
					,NON_CANCER_DIAGNOSIS_CODE					= CASE WHEN mmvc.NON_CANCER_DIAGNOSIS_CODE = 1 THEN mmv.NON_CANCER_DIAGNOSIS_CODE ELSE uh.NON_CANCER_DIAGNOSIS_CODE END
					,TNM_UNKNOWN								= CASE WHEN mmvc.TNM_UNKNOWN = 1 THEN mmv.TNM_UNKNOWN ELSE uh.TNM_UNKNOWN END
					,ReferringPractice							= CASE WHEN mmvc.ReferringPractice = 1 THEN mmv.ReferringPractice ELSE uh.ReferringPractice END
					,ReferringGP								= CASE WHEN mmvc.ReferringGP = 1 THEN mmv.ReferringGP ELSE uh.ReferringGP END
					,ReferringBranch							= CASE WHEN mmvc.ReferringBranch = 1 THEN mmv.ReferringBranch ELSE uh.ReferringBranch END
					,BankedTissue								= CASE WHEN mmvc.BankedTissue = 1 THEN mmv.BankedTissue ELSE uh.BankedTissue END
					,BankedTissueTumour							= CASE WHEN mmvc.BankedTissueTumour = 1 THEN mmv.BankedTissueTumour ELSE uh.BankedTissueTumour END
					,BankedTissueBlood							= CASE WHEN mmvc.BankedTissueBlood = 1 THEN mmv.BankedTissueBlood ELSE uh.BankedTissueBlood END
					,BankedTissueCSF							= CASE WHEN mmvc.BankedTissueCSF = 1 THEN mmv.BankedTissueCSF ELSE uh.BankedTissueCSF END
					,BankedTissueBoneMarrow						= CASE WHEN mmvc.BankedTissueBoneMarrow = 1 THEN mmv.BankedTissueBoneMarrow ELSE uh.BankedTissueBoneMarrow END
					,SNOMed_CT									= CASE WHEN mmvc.SNOMed_CT = 1 THEN mmv.SNOMed_CT ELSE uh.SNOMed_CT END
					,ADT_PLACER_ID								= CASE WHEN mmvc.ADT_PLACER_ID = 1 THEN mmv.ADT_PLACER_ID ELSE uh.ADT_PLACER_ID END
					,SNOMEDCTDiagnosisID						= CASE WHEN mmvc.SNOMEDCTDiagnosisID = 1 THEN mmv.SNOMEDCTDiagnosisID ELSE uh.SNOMEDCTDiagnosisID END
					,FasterDiagnosisOrganisationID				= CASE WHEN mmvc.FasterDiagnosisOrganisationID = 1 THEN ISNULL(FD_org.ID, mmv.FasterDiagnosisOrganisationID) ELSE uh.FasterDiagnosisOrganisationID END
					,FasterDiagnosisCancerSiteOverrideID		= CASE WHEN mmvc.FasterDiagnosisCancerSiteOverrideID = 1 THEN mmv.FasterDiagnosisCancerSiteOverrideID ELSE uh.FasterDiagnosisCancerSiteOverrideID END
					,FasterDiagnosisExclusionDate				= CASE WHEN mmvc.FasterDiagnosisExclusionDate = 1 THEN mmv.FasterDiagnosisExclusionDate ELSE uh.FasterDiagnosisExclusionDate END
					,FasterDiagnosisExclusionReasonID			= CASE WHEN mmvc.FasterDiagnosisExclusionReasonID = 1 THEN mmv.FasterDiagnosisExclusionReasonID ELSE uh.FasterDiagnosisExclusionReasonID END
					,FasterDiagnosisDelayReasonID				= CASE WHEN mmvc.FasterDiagnosisDelayReasonID = 1 THEN mmv.FasterDiagnosisDelayReasonID ELSE uh.FasterDiagnosisDelayReasonID END
					,FasterDiagnosisDelayReasonComments			= CASE WHEN mmvc.FasterDiagnosisDelayReasonComments = 1 THEN mmv.FasterDiagnosisDelayReasonComments ELSE uh.FasterDiagnosisDelayReasonComments END
					,FasterDiagnosisCommunicationMethodID		= CASE WHEN mmvc.FasterDiagnosisCommunicationMethodID = 1 THEN mmv.FasterDiagnosisCommunicationMethodID ELSE uh.FasterDiagnosisCommunicationMethodID END
					,FasterDiagnosisInformingCareProfessionalID	= CASE WHEN mmvc.FasterDiagnosisInformingCareProfessionalID = 1 THEN mmv.FasterDiagnosisInformingCareProfessionalID ELSE uh.FasterDiagnosisInformingCareProfessionalID END
					,FasterDiagnosisOtherCareProfessional		= CASE WHEN mmvc.FasterDiagnosisOtherCareProfessional = 1 THEN mmv.FasterDiagnosisOtherCareProfessional ELSE uh.FasterDiagnosisOtherCareProfessional END
					,FasterDiagnosisOtherCommunicationMethod	= CASE WHEN mmvc.FasterDiagnosisOtherCommunicationMethod = 1 THEN mmv.FasterDiagnosisOtherCommunicationMethod ELSE uh.FasterDiagnosisOtherCommunicationMethod END
					--,DEPRECATED_20_01_RecurrenceMetastaticType	= CASE WHEN mmvc.DEPRECATED_20_01_RecurrenceMetastaticType = 1 THEN mmv.DEPRECATED_20_01_RecurrenceMetastaticType ELSE uh.DEPRECATED_20_01_RecurrenceMetastaticType END
					,NonPrimaryPathwayOptionsID					= CASE WHEN mmvc.NonPrimaryPathwayOptionsID = 1 THEN mmv.NonPrimaryPathwayOptionsID ELSE uh.NonPrimaryPathwayOptionsID END
					,DiagnosisUncertainty						= CASE WHEN mmvc.DiagnosisUncertainty = 1 THEN mmv.DiagnosisUncertainty ELSE uh.DiagnosisUncertainty END
					,TNMOrganisation							= CASE WHEN mmvc.TNMOrganisation = 1 THEN mmv.TNMOrganisation ELSE uh.TNMOrganisation END
					,FasterDiagnosisTargetRCComments			= CASE WHEN mmvc.FasterDiagnosisTargetRCComments = 1 THEN mmv.FasterDiagnosisTargetRCComments ELSE uh.FasterDiagnosisTargetRCComments END
					,FasterDiagnosisEndRCComments				= CASE WHEN mmvc.FasterDiagnosisEndRCComments = 1 THEN mmv.FasterDiagnosisEndRCComments ELSE uh.FasterDiagnosisEndRCComments END
					,TNMOrganisation_Integrated					= CASE WHEN mmvc.TNMOrganisation_Integrated = 1 THEN mmv.TNMOrganisation_Integrated ELSE uh.TNMOrganisation_Integrated END
					,LDHValue									= CASE WHEN mmvc.LDHValue = 1 THEN mmv.LDHValue ELSE uh.LDHValue END
					--,DEPRECATED_20_01_LDH_NORMAL				= CASE WHEN mmvc.DEPRECATED_20_01_LDH_NORMAL = 1 THEN mmv.DEPRECATED_20_01_LDH_NORMAL ELSE uh.DEPRECATED_20_01_LDH_NORMAL END
					,BankedTissueUrine							= CASE WHEN mmvc.BankedTissueUrine = 1 THEN mmv.BankedTissueUrine ELSE uh.BankedTissueUrine END
					,SubsiteID									= CASE WHEN mmvc.SubsiteID = 1 THEN mmv.SubsiteID ELSE uh.SubsiteID END
					,PredictedBreachStatus						= CASE WHEN mmvc.PredictedBreachStatus = 1 THEN mmv.PredictedBreachStatus ELSE uh.PredictedBreachStatus END
					,RMRefID									= CASE WHEN mmvc.RMRefID = 1 THEN mmv.RMRefID ELSE uh.RMRefID END
					,TertiaryReferralKey						= CASE WHEN mmvc.TertiaryReferralKey = 1 THEN mmv.TertiaryReferralKey ELSE uh.TertiaryReferralKey END
					,ClinicalTLetter							= CASE WHEN mmvc.ClinicalTLetter = 1 THEN mmv.ClinicalTLetter ELSE uh.ClinicalTLetter END
					,ClinicalNLetter							= CASE WHEN mmvc.ClinicalNLetter = 1 THEN mmv.ClinicalNLetter ELSE uh.ClinicalNLetter END
					,ClinicalMLetter							= CASE WHEN mmvc.ClinicalMLetter = 1 THEN mmv.ClinicalMLetter ELSE uh.ClinicalMLetter END
					,PathologicalTLetter						= CASE WHEN mmvc.PathologicalTLetter = 1 THEN mmv.PathologicalTLetter ELSE uh.PathologicalTLetter END
					,PathologicalNLetter						= CASE WHEN mmvc.PathologicalNLetter = 1 THEN mmv.PathologicalNLetter ELSE uh.PathologicalNLetter END
					,PathologicalMLetter						= CASE WHEN mmvc.PathologicalMLetter = 1 THEN mmv.PathologicalMLetter ELSE uh.PathologicalMLetter END
					,FDPlannedInterval							= CASE WHEN mmvc.FDPlannedInterval = 1 THEN mmv.FDPlannedInterval ELSE uh.FDPlannedInterval END
					,LabReportDate								= CASE WHEN mmvc.LabReportDate = 1 THEN mmv.LabReportDate ELSE uh.LabReportDate END
					,LabReportOrgID								= CASE WHEN mmvc.LabReportOrgID = 1 THEN mmv.LabReportOrgID ELSE uh.LabReportOrgID END
					,ReferralRoute								= CASE WHEN mmvc.ReferralRoute = 1 THEN mmv.ReferralRoute ELSE uh.ReferralRoute END
					,ReferralOtherRoute							= CASE WHEN mmvc.ReferralOtherRoute = 1 THEN mmv.ReferralOtherRoute ELSE uh.ReferralOtherRoute END
					,RelapseMorphology							= CASE WHEN mmvc.RelapseMorphology = 1 THEN mmv.RelapseMorphology ELSE uh.RelapseMorphology END
					,RelapseFlow								= CASE WHEN mmvc.RelapseFlow = 1 THEN mmv.RelapseFlow ELSE uh.RelapseFlow END
					,RelapseMolecular							= CASE WHEN mmvc.RelapseMolecular = 1 THEN mmv.RelapseMolecular ELSE uh.RelapseMolecular END
					,RelapseClinicalExamination					= CASE WHEN mmvc.RelapseClinicalExamination = 1 THEN mmv.RelapseClinicalExamination ELSE uh.RelapseClinicalExamination END
					,RelapseOther								= CASE WHEN mmvc.RelapseOther = 1 THEN mmv.RelapseOther ELSE uh.RelapseOther END
					,RapidDiagnostic							= CASE WHEN mmvc.RapidDiagnostic = 1 THEN mmv.RapidDiagnostic ELSE uh.RapidDiagnostic END
					,PrimaryReferralFlag						= CASE WHEN mmvc.PrimaryReferralFlag = 1 THEN mmv.PrimaryReferralFlag ELSE uh.PrimaryReferralFlag END
					,OtherAssessedBy							= CASE WHEN mmvc.OtherAssessedBy = 1 THEN mmv.OtherAssessedBy ELSE uh.OtherAssessedBy END
					,SharedBreach								= CASE WHEN mmvc.SharedBreach = 1 THEN mmv.SharedBreach ELSE uh.SharedBreach END
					,PredictedBreachYear						= CASE WHEN mmvc.PredictedBreachYear = 1 THEN mmv.PredictedBreachYear ELSE uh.PredictedBreachYear END
					,PredictedBreachMonth						= CASE WHEN mmvc.PredictedBreachMonth = 1 THEN mmv.PredictedBreachMonth ELSE uh.PredictedBreachMonth END
		FROM		#mcIx mc
		INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																ON	mc.SrcSys = uh.SrcSys
																AND	mc.Src_UID = uh.Src_UID
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv
																			ON	mc.SrcSys_Major = mmv.SrcSys_Major
																			AND	mc.Src_UID_Major = mmv.Src_UID_Major
																			AND	mmv.ValidationStatus NOT IN ('All Matches Algorithmic') -- use this to stop column overrides for validation records with these statuses
		LEFT JOIN	Merge_DM_MatchViews.tblMAIN_REFERRALS_vw_Match_MajorValidationColumns mmvc
																							ON	mmv.SrcSys_Major = mmvc.SrcSys_Major
																							AND	mmv.Src_UID_Major = mmvc.Src_UID_Major
		LEFT JOIN	Merge_DM_MatchViews.tblMAIN_REFERRALS_vw_Match_MajorValidationColumns_SrcSys mmvcs
																							ON	mmv.SrcSys_Major = mmvcs.SrcSys_Major
																							AND	mmv.Src_UID_Major = mmvcs.Src_UID_Major
		LEFT JOIN	SCR_DW.SCR.dbo_OrganisationSites FD_org
															ON	mmvcs.FasterDiagnosisOrganisationID = 2
															AND	mmv.FasterDiagnosisOrganisationID = FD_Org.DW_SOURCE_PATIENT_ID
		WHERE		mc.IsMajorSCR = 0
		AND			mc.mcIx = 1

		-- unconfirmed minors 
		INSERT INTO	#ValidatedData
		SELECT		SrcSys_MajorExt								= mc.SrcSys_Major
					,Src_UID_MajorExt							= mc.Src_UID_Major
					,SrcSys_Major								= mc.SrcSys
					,Src_UID_Major								= mc.Src_UID
					,IsValidatedMajor							= 0
					,IsConfirmed								= mc.IsConfirmed
					,LastUpdated								= uh.LastUpdated
					,SrcSys										= mc.SrcSys
					,Src_UID									= mc.Src_UID
					,CARE_ID									= uh.CARE_ID
					,PATIENT_ID									= uh.PATIENT_ID
					,TEMP_ID									= uh.TEMP_ID
					,L_CANCER_SITE								= uh.L_CANCER_SITE
					,N2_1_REFERRAL_SOURCE						= uh.N2_1_REFERRAL_SOURCE
					,N2_2_ORG_CODE_REF							= uh.N2_2_ORG_CODE_REF
					,N2_3_REFERRER_CODE							= uh.N2_3_REFERRER_CODE
					,N2_4_PRIORITY_TYPE							= uh.N2_4_PRIORITY_TYPE
					,N2_5_DECISION_DATE							= uh.N2_5_DECISION_DATE
					,N2_6_RECEIPT_DATE							= uh.N2_6_RECEIPT_DATE
					,N2_7_CONSULTANT							= uh.N2_7_CONSULTANT
					,N2_8_SPECIALTY								= uh.N2_8_SPECIALTY
					,N2_9_FIRST_SEEN_DATE						= uh.N2_9_FIRST_SEEN_DATE
					,N1_3_ORG_CODE_SEEN							= uh.N1_3_ORG_CODE_SEEN
					,N2_10_FIRST_SEEN_DELAY						= uh.N2_10_FIRST_SEEN_DELAY
					,N2_12_CANCER_TYPE							= uh.N2_12_CANCER_TYPE
					,N2_13_CANCER_STATUS						= uh.N2_13_CANCER_STATUS
					,L_FIRST_APPOINTMENT						= uh.L_FIRST_APPOINTMENT
					,L_CANCELLED_DATE							= uh.L_CANCELLED_DATE
					,N2_14_ADJ_TIME								= uh.N2_14_ADJ_TIME
					,N2_15_ADJ_REASON							= uh.N2_15_ADJ_REASON
					,L_REFERRAL_METHOD							= uh.L_REFERRAL_METHOD
					,N2_16_OP_REFERRAL							= uh.N2_16_OP_REFERRAL
					,L_SPECIALIST_DATE							= uh.L_SPECIALIST_DATE
					,L_ORG_CODE_SPECIALIST						= uh.L_ORG_CODE_SPECIALIST
					,L_SPECIALIST_SEEN_DATE						= uh.L_SPECIALIST_SEEN_DATE
					,N1_3_ORG_CODE_SPEC_SEEN					= uh.N1_3_ORG_CODE_SPEC_SEEN
					,N_UPGRADE_DATE								= uh.N_UPGRADE_DATE
					,N_UPGRADE_ORG_CODE							= uh.N_UPGRADE_ORG_CODE
					,L_UPGRADE_WHEN								= uh.L_UPGRADE_WHEN
					,L_UPGRADE_WHO								= uh.L_UPGRADE_WHO
					,N4_1_DIAGNOSIS_DATE						= uh.N4_1_DIAGNOSIS_DATE
					,L_DIAGNOSIS								= uh.L_DIAGNOSIS
					,N4_2_DIAGNOSIS_CODE						= uh.N4_2_DIAGNOSIS_CODE
					,L_ORG_CODE_DIAGNOSIS						= uh.L_ORG_CODE_DIAGNOSIS
					,L_PT_INFORMED_DATE							= uh.L_PT_INFORMED_DATE
					,L_OTHER_DIAG_DATE							= uh.L_OTHER_DIAG_DATE
					,N4_3_LATERALITY							= uh.N4_3_LATERALITY
					,N4_4_BASIS_DIAGNOSIS						= uh.N4_4_BASIS_DIAGNOSIS
					,L_TOPOGRAPHY								= uh.L_TOPOGRAPHY
					,L_HISTOLOGY_GROUP							= uh.L_HISTOLOGY_GROUP
					,N4_5_HISTOLOGY								= uh.N4_5_HISTOLOGY
					,N4_6_DIFFERENTIATION						= uh.N4_6_DIFFERENTIATION
					,ClinicalTStage								= uh.ClinicalTStage
					,ClinicalTCertainty							= uh.ClinicalTCertainty
					,ClinicalNStage								= uh.ClinicalNStage
					,ClinicalNCertainty							= uh.ClinicalNCertainty
					,ClinicalMStage								= uh.ClinicalMStage
					,ClinicalMCertainty							= uh.ClinicalMCertainty
					,ClinicalOverallCertainty					= uh.ClinicalOverallCertainty
					,N6_9_SITE_CLASSIFICATION					= uh.N6_9_SITE_CLASSIFICATION
					,PathologicalOverallCertainty				= uh.PathologicalOverallCertainty
					,PathologicalTCertainty						= uh.PathologicalTCertainty
					,PathologicalTStage							= uh.PathologicalTStage
					,PathologicalNCertainty						= uh.PathologicalNCertainty
					,PathologicalNStage							= uh.PathologicalNStage
					,PathologicalMCertainty						= uh.PathologicalMCertainty
					,PathologicalMStage							= uh.PathologicalMStage
					,L_GP_INFORMED								= uh.L_GP_INFORMED
					,L_GP_INFORMED_DATE							= uh.L_GP_INFORMED_DATE
					,L_GP_NOT									= uh.L_GP_NOT
					,L_REL_INFORMED								= uh.L_REL_INFORMED
					,L_NURSE_PRESENT							= uh.L_NURSE_PRESENT
					,L_SPEC_NURSE_DATE							= uh.L_SPEC_NURSE_DATE
					,L_SEEN_NURSE_DATE							= uh.L_SEEN_NURSE_DATE
					,N16_1_ADJ_DAYS								= uh.N16_1_ADJ_DAYS
					,N16_2_ADJ_DAYS								= uh.N16_2_ADJ_DAYS
					,N16_3_ADJ_DECISION_CODE					= uh.N16_3_ADJ_DECISION_CODE
					,N16_4_ADJ_TREAT_CODE						= uh.N16_4_ADJ_TREAT_CODE
					,N16_5_DECISION_REASON_CODE					= uh.N16_5_DECISION_REASON_CODE
					,N16_6_TREATMENT_REASON_CODE				= uh.N16_6_TREATMENT_REASON_CODE
					,PathologicalTNMDate						= uh.PathologicalTNMDate
					,ClinicalTNMDate							= uh.ClinicalTNMDate
					,L_FIRST_CONSULTANT							= uh.L_FIRST_CONSULTANT
					,L_APPROPRIATE								= uh.L_APPROPRIATE
					,L_TERTIARY_DATE							= uh.L_TERTIARY_DATE
					,L_TERTIARY_TRUST							= uh.L_TERTIARY_TRUST
					,L_TERTIARY_REASON							= uh.L_TERTIARY_REASON
					,L_INAP_REF									= uh.L_INAP_REF
					,L_NEW_CA_SITE								= uh.L_NEW_CA_SITE
					,L_AUTO_REF									= uh.L_AUTO_REF
					,L_SEC_DIAGNOSIS_G							= uh.L_SEC_DIAGNOSIS_G
					,L_SEC_DIAGNOSIS							= uh.L_SEC_DIAGNOSIS
					,L_WRONG_REF								= uh.L_WRONG_REF
					,L_WRONG_REASON								= uh.L_WRONG_REASON
					,L_TUMOUR_STATUS							= uh.L_TUMOUR_STATUS
					,L_NON_CANCER								= uh.L_NON_CANCER
					,L_FIRST_APP								= uh.L_FIRST_APP
					,L_NO_APP									= uh.L_NO_APP
					,L_DIAG_WHO									= uh.L_DIAG_WHO
					,L_RECURRENCE								= uh.L_RECURRENCE
					,L_OTHER_SYMPS								= uh.L_OTHER_SYMPS
					,L_COMMENTS									= uh.L_COMMENTS
					,N2_11_FIRST_SEEN_REASON					= uh.N2_11_FIRST_SEEN_REASON
					,N16_7_DECISION_REASON						= uh.N16_7_DECISION_REASON
					,N16_8_TREATMENT_REASON						= uh.N16_8_TREATMENT_REASON
					,L_DIAGNOSIS_COMMENTS						= uh.L_DIAGNOSIS_COMMENTS
					,GP_PRACTICE_CODE							= uh.GP_PRACTICE_CODE
					,ClinicalTNMGroup							= uh.ClinicalTNMGroup
					,PathologicalTNMGroup						= uh.PathologicalTNMGroup
					,L_KEY_WORKER_SEEN							= uh.L_KEY_WORKER_SEEN
					,L_PALLIATIVE_SPECIALIST_SEEN				= uh.L_PALLIATIVE_SPECIALIST_SEEN
					,GERM_CELL_NON_CNS_ID						= uh.GERM_CELL_NON_CNS_ID
					,RECURRENCE_CANCER_SITE_ID					= uh.RECURRENCE_CANCER_SITE_ID
					,ICD03_GROUP								= uh.ICD03_GROUP
					,ICD03										= uh.ICD03
					,L_DATE_DIAGNOSIS_DAHNO_LUCADA				= uh.L_DATE_DIAGNOSIS_DAHNO_LUCADA
					,L_INDICATOR_CODE							= uh.L_INDICATOR_CODE
					,PRIMARY_DIAGNOSIS_SUB_COMMENT				= uh.PRIMARY_DIAGNOSIS_SUB_COMMENT
					,CONSULTANT_CODE_AT_DIAGNOSIS				= uh.CONSULTANT_CODE_AT_DIAGNOSIS
					,CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS		= uh.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS
					,FETOPROTEIN								= uh.FETOPROTEIN
					,GONADOTROPIN								= uh.GONADOTROPIN
					,GONADOTROPIN_SERUM							= uh.GONADOTROPIN_SERUM
					,FETOPROTEIN_SERUM							= uh.FETOPROTEIN_SERUM
					,SARCOMA_TUMOUR_SITE_BONE					= uh.SARCOMA_TUMOUR_SITE_BONE
					,SARCOMA_TUMOUR_SITE_SOFT_TISSUE			= uh.SARCOMA_TUMOUR_SITE_SOFT_TISSUE
					,SARCOMA_TUMOUR_SUBSITE_BONE				= uh.SARCOMA_TUMOUR_SUBSITE_BONE
					,SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE			= uh.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
					,ROOT_DECISION_DATE_COMMENTS				= uh.ROOT_DECISION_DATE_COMMENTS
					,ROOT_RECEIPT_DATE_COMMENTS					= uh.ROOT_RECEIPT_DATE_COMMENTS
					,ROOT_FIRST_SEEN_DATE_COMMENTS				= uh.ROOT_FIRST_SEEN_DATE_COMMENTS
					,ROOT_DIAGNOSIS_DATE_COMMENTS				= uh.ROOT_DIAGNOSIS_DATE_COMMENTS
					,ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS		= uh.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS
					,ROOT_UPGRADE_COMMENTS						= uh.ROOT_UPGRADE_COMMENTS
					,FIRST_APPT_TIME							= uh.FIRST_APPT_TIME
					,TRANSFER_REASON							= uh.TRANSFER_REASON
					,DATE_NEW_REFERRAL							= uh.DATE_NEW_REFERRAL
					,TUMOUR_SITE_NEW							= uh.TUMOUR_SITE_NEW
					,DATE_TRANSFER_ACTIONED						= uh.DATE_TRANSFER_ACTIONED
					,SOURCE_CARE_ID								= uh.SOURCE_CARE_ID
					,ADT_REF_ID									= uh.ADT_REF_ID
					,ACTION_ID									= uh.ACTION_ID
					,DIAGNOSIS_ACTION_ID						= uh.DIAGNOSIS_ACTION_ID
					,ORIGINAL_SOURCE_CARE_ID					= uh.ORIGINAL_SOURCE_CARE_ID
					,TRANSFER_DATE_COMMENTS						= uh.TRANSFER_DATE_COMMENTS
					,SPECIALIST_REFERRAL_COMMENTS				= uh.SPECIALIST_REFERRAL_COMMENTS
					,NON_CANCER_DIAGNOSIS_CHAPTER				= uh.NON_CANCER_DIAGNOSIS_CHAPTER
					,NON_CANCER_DIAGNOSIS_GROUP					= uh.NON_CANCER_DIAGNOSIS_GROUP
					,NON_CANCER_DIAGNOSIS_CODE					= uh.NON_CANCER_DIAGNOSIS_CODE
					,TNM_UNKNOWN								= uh.TNM_UNKNOWN
					,ReferringPractice							= uh.ReferringPractice
					,ReferringGP								= uh.ReferringGP
					,ReferringBranch							= uh.ReferringBranch
					,BankedTissue								= uh.BankedTissue
					,BankedTissueTumour							= uh.BankedTissueTumour
					,BankedTissueBlood							= uh.BankedTissueBlood
					,BankedTissueCSF							= uh.BankedTissueCSF
					,BankedTissueBoneMarrow						= uh.BankedTissueBoneMarrow
					,SNOMed_CT									= uh.SNOMed_CT
					,ADT_PLACER_ID								= uh.ADT_PLACER_ID
					,SNOMEDCTDiagnosisID						= uh.SNOMEDCTDiagnosisID
					,FasterDiagnosisOrganisationID				= uh.FasterDiagnosisOrganisationID
					,FasterDiagnosisCancerSiteOverrideID		= uh.FasterDiagnosisCancerSiteOverrideID
					,FasterDiagnosisExclusionDate				= uh.FasterDiagnosisExclusionDate
					,FasterDiagnosisExclusionReasonID			= uh.FasterDiagnosisExclusionReasonID
					,FasterDiagnosisDelayReasonID				= uh.FasterDiagnosisDelayReasonID
					,FasterDiagnosisDelayReasonComments			= uh.FasterDiagnosisDelayReasonComments
					,FasterDiagnosisCommunicationMethodID		= uh.FasterDiagnosisCommunicationMethodID
					,FasterDiagnosisInformingCareProfessionalID	= uh.FasterDiagnosisInformingCareProfessionalID
					,FasterDiagnosisOtherCareProfessional		= uh.FasterDiagnosisOtherCareProfessional
					,FasterDiagnosisOtherCommunicationMethod	= uh.FasterDiagnosisOtherCommunicationMethod
					--,DEPRECATED_20_01_RecurrenceMetastaticType	= uh.DEPRECATED_20_01_RecurrenceMetastaticType
					,NonPrimaryPathwayOptionsID					= uh.NonPrimaryPathwayOptionsID
					,DiagnosisUncertainty						= uh.DiagnosisUncertainty
					,TNMOrganisation							= uh.TNMOrganisation
					,FasterDiagnosisTargetRCComments			= uh.FasterDiagnosisTargetRCComments
					,FasterDiagnosisEndRCComments				= uh.FasterDiagnosisEndRCComments
					,TNMOrganisation_Integrated					= uh.TNMOrganisation_Integrated
					,LDHValue									= uh.LDHValue
					--,DEPRECATED_20_01_LDH_NORMAL				= uh.DEPRECATED_20_01_LDH_NORMAL
					,BankedTissueUrine							= uh.BankedTissueUrine
					,SubsiteID									= uh.SubsiteID
					,PredictedBreachStatus						= uh.PredictedBreachStatus
					,RMRefID									= uh.RMRefID
					,TertiaryReferralKey						= uh.TertiaryReferralKey
					,ClinicalTLetter							= uh.ClinicalTLetter
					,ClinicalNLetter							= uh.ClinicalNLetter
					,ClinicalMLetter							= uh.ClinicalMLetter
					,PathologicalTLetter						= uh.PathologicalTLetter
					,PathologicalNLetter						= uh.PathologicalNLetter
					,PathologicalMLetter						= uh.PathologicalMLetter
					,FDPlannedInterval							= uh.FDPlannedInterval
					,LabReportDate								= uh.LabReportDate
					,LabReportOrgID								= uh.LabReportOrgID
					,ReferralRoute								= uh.ReferralRoute
					,ReferralOtherRoute							= uh.ReferralOtherRoute
					,RelapseMorphology							= uh.RelapseMorphology
					,RelapseFlow								= uh.RelapseFlow
					,RelapseMolecular							= uh.RelapseMolecular
					,RelapseClinicalExamination					= uh.RelapseClinicalExamination
					,RelapseOther								= uh.RelapseOther
					,RapidDiagnostic							= uh.RapidDiagnostic
					,PrimaryReferralFlag						= uh.PrimaryReferralFlag
					,OtherAssessedBy							= uh.OtherAssessedBy
					,SharedBreach								= uh.SharedBreach
					,PredictedBreachYear						= uh.PredictedBreachYear
					,PredictedBreachMonth						= uh.PredictedBreachMonth
		FROM		#mcIx mc
		INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																ON	mc.SrcSys = uh.SrcSys
																AND	mc.Src_UID = uh.Src_UID
		LEFT JOIN	#ValidatedData vd
									ON	mc.SrcSys = vd.SrcSys
									AND	mc.Src_UID = vd.Src_UID
		WHERE		mc.IsConfirmed = 0
		AND			vd.SrcSys IS NULL
		
		-- minors that are left
		INSERT INTO	#ValidatedData
					(SrcSys_MajorExt
					,Src_UID_MajorExt
					,SrcSys_Major
					,Src_UID_Major
					,IsValidatedMajor
					,IsConfirmed
					,LastUpdated
					,SrcSys
					,Src_UID
					)
		SELECT		SrcSys_MajorExt							= mc.SrcSys_Major
					,Src_UID_MajorExt						= mc.Src_UID_Major
					,SrcSys_Major							= ISNULL(mc_1st.SrcSys, mc.SrcSys_Major)
					,Src_UID_Major							= ISNULL(mc_1st.Src_UID, mc.Src_UID_Major)
					,IsValidatedMajor						= 0
					,IsConfirmed							= mc.IsConfirmed
					,LastUpdated							= mc.LastUpdated
					,SrcSys									= mc.SrcSys
					,Src_UID								= mc.Src_UID
		FROM		#mcIx mc
		LEFT JOIN	#mcIx mc_1st
								ON	mc.SrcSys_Major = mc_1st.SrcSys_Major
								AND	mc.Src_UID_Major = mc_1st.Src_UID_Major
								AND	mc_1st.IsMajorSCR = 0
								AND	mc_1st.mcIx = 1
		LEFT JOIN	#ValidatedData vd
									ON	mc.SrcSys = vd.SrcSys
									AND	mc.Src_UID = vd.Src_UID
		WHERE		vd.SrcSys IS NULL

		-- SCR records that aren't in the match control table (if we are creating a bulk dataset)
		IF @HasRelatedEntities = 0
		INSERT INTO	#ValidatedData
		SELECT		SrcSys_MajorExt								= uh.SrcSys
					,Src_UID_MajorExt							= uh.Src_UID
					,SrcSys_Major								= uh.SrcSys
					,Src_UID_Major								= uh.Src_UID
					,IsValidatedMajor							= 0
					,IsConfirmed								= 0
					,LastUpdated								= uh.LastUpdated
					,SrcSys										= uh.SrcSys
					,Src_UID									= uh.Src_UID
					,CARE_ID									= uh.CARE_ID
					,PATIENT_ID									= uh.PATIENT_ID
					,TEMP_ID									= uh.TEMP_ID
					,L_CANCER_SITE								= uh.L_CANCER_SITE
					,N2_1_REFERRAL_SOURCE						= uh.N2_1_REFERRAL_SOURCE
					,N2_2_ORG_CODE_REF							= uh.N2_2_ORG_CODE_REF
					,N2_3_REFERRER_CODE							= uh.N2_3_REFERRER_CODE
					,N2_4_PRIORITY_TYPE							= uh.N2_4_PRIORITY_TYPE
					,N2_5_DECISION_DATE							= uh.N2_5_DECISION_DATE
					,N2_6_RECEIPT_DATE							= uh.N2_6_RECEIPT_DATE
					,N2_7_CONSULTANT							= uh.N2_7_CONSULTANT
					,N2_8_SPECIALTY								= uh.N2_8_SPECIALTY
					,N2_9_FIRST_SEEN_DATE						= uh.N2_9_FIRST_SEEN_DATE
					,N1_3_ORG_CODE_SEEN							= uh.N1_3_ORG_CODE_SEEN
					,N2_10_FIRST_SEEN_DELAY						= uh.N2_10_FIRST_SEEN_DELAY
					,N2_12_CANCER_TYPE							= uh.N2_12_CANCER_TYPE
					,N2_13_CANCER_STATUS						= uh.N2_13_CANCER_STATUS
					,L_FIRST_APPOINTMENT						= uh.L_FIRST_APPOINTMENT
					,L_CANCELLED_DATE							= uh.L_CANCELLED_DATE
					,N2_14_ADJ_TIME								= uh.N2_14_ADJ_TIME
					,N2_15_ADJ_REASON							= uh.N2_15_ADJ_REASON
					,L_REFERRAL_METHOD							= uh.L_REFERRAL_METHOD
					,N2_16_OP_REFERRAL							= uh.N2_16_OP_REFERRAL
					,L_SPECIALIST_DATE							= uh.L_SPECIALIST_DATE
					,L_ORG_CODE_SPECIALIST						= uh.L_ORG_CODE_SPECIALIST
					,L_SPECIALIST_SEEN_DATE						= uh.L_SPECIALIST_SEEN_DATE
					,N1_3_ORG_CODE_SPEC_SEEN					= uh.N1_3_ORG_CODE_SPEC_SEEN
					,N_UPGRADE_DATE								= uh.N_UPGRADE_DATE
					,N_UPGRADE_ORG_CODE							= uh.N_UPGRADE_ORG_CODE
					,L_UPGRADE_WHEN								= uh.L_UPGRADE_WHEN
					,L_UPGRADE_WHO								= uh.L_UPGRADE_WHO
					,N4_1_DIAGNOSIS_DATE						= uh.N4_1_DIAGNOSIS_DATE
					,L_DIAGNOSIS								= uh.L_DIAGNOSIS
					,N4_2_DIAGNOSIS_CODE						= uh.N4_2_DIAGNOSIS_CODE
					,L_ORG_CODE_DIAGNOSIS						= uh.L_ORG_CODE_DIAGNOSIS
					,L_PT_INFORMED_DATE							= uh.L_PT_INFORMED_DATE
					,L_OTHER_DIAG_DATE							= uh.L_OTHER_DIAG_DATE
					,N4_3_LATERALITY							= uh.N4_3_LATERALITY
					,N4_4_BASIS_DIAGNOSIS						= uh.N4_4_BASIS_DIAGNOSIS
					,L_TOPOGRAPHY								= uh.L_TOPOGRAPHY
					,L_HISTOLOGY_GROUP							= uh.L_HISTOLOGY_GROUP
					,N4_5_HISTOLOGY								= uh.N4_5_HISTOLOGY
					,N4_6_DIFFERENTIATION						= uh.N4_6_DIFFERENTIATION
					,ClinicalTStage								= uh.ClinicalTStage
					,ClinicalTCertainty							= uh.ClinicalTCertainty
					,ClinicalNStage								= uh.ClinicalNStage
					,ClinicalNCertainty							= uh.ClinicalNCertainty
					,ClinicalMStage								= uh.ClinicalMStage
					,ClinicalMCertainty							= uh.ClinicalMCertainty
					,ClinicalOverallCertainty					= uh.ClinicalOverallCertainty
					,N6_9_SITE_CLASSIFICATION					= uh.N6_9_SITE_CLASSIFICATION
					,PathologicalOverallCertainty				= uh.PathologicalOverallCertainty
					,PathologicalTCertainty						= uh.PathologicalTCertainty
					,PathologicalTStage							= uh.PathologicalTStage
					,PathologicalNCertainty						= uh.PathologicalNCertainty
					,PathologicalNStage							= uh.PathologicalNStage
					,PathologicalMCertainty						= uh.PathologicalMCertainty
					,PathologicalMStage							= uh.PathologicalMStage
					,L_GP_INFORMED								= uh.L_GP_INFORMED
					,L_GP_INFORMED_DATE							= uh.L_GP_INFORMED_DATE
					,L_GP_NOT									= uh.L_GP_NOT
					,L_REL_INFORMED								= uh.L_REL_INFORMED
					,L_NURSE_PRESENT							= uh.L_NURSE_PRESENT
					,L_SPEC_NURSE_DATE							= uh.L_SPEC_NURSE_DATE
					,L_SEEN_NURSE_DATE							= uh.L_SEEN_NURSE_DATE
					,N16_1_ADJ_DAYS								= uh.N16_1_ADJ_DAYS
					,N16_2_ADJ_DAYS								= uh.N16_2_ADJ_DAYS
					,N16_3_ADJ_DECISION_CODE					= uh.N16_3_ADJ_DECISION_CODE
					,N16_4_ADJ_TREAT_CODE						= uh.N16_4_ADJ_TREAT_CODE
					,N16_5_DECISION_REASON_CODE					= uh.N16_5_DECISION_REASON_CODE
					,N16_6_TREATMENT_REASON_CODE				= uh.N16_6_TREATMENT_REASON_CODE
					,PathologicalTNMDate						= uh.PathologicalTNMDate
					,ClinicalTNMDate							= uh.ClinicalTNMDate
					,L_FIRST_CONSULTANT							= uh.L_FIRST_CONSULTANT
					,L_APPROPRIATE								= uh.L_APPROPRIATE
					,L_TERTIARY_DATE							= uh.L_TERTIARY_DATE
					,L_TERTIARY_TRUST							= uh.L_TERTIARY_TRUST
					,L_TERTIARY_REASON							= uh.L_TERTIARY_REASON
					,L_INAP_REF									= uh.L_INAP_REF
					,L_NEW_CA_SITE								= uh.L_NEW_CA_SITE
					,L_AUTO_REF									= uh.L_AUTO_REF
					,L_SEC_DIAGNOSIS_G							= uh.L_SEC_DIAGNOSIS_G
					,L_SEC_DIAGNOSIS							= uh.L_SEC_DIAGNOSIS
					,L_WRONG_REF								= uh.L_WRONG_REF
					,L_WRONG_REASON								= uh.L_WRONG_REASON
					,L_TUMOUR_STATUS							= uh.L_TUMOUR_STATUS
					,L_NON_CANCER								= uh.L_NON_CANCER
					,L_FIRST_APP								= uh.L_FIRST_APP
					,L_NO_APP									= uh.L_NO_APP
					,L_DIAG_WHO									= uh.L_DIAG_WHO
					,L_RECURRENCE								= uh.L_RECURRENCE
					,L_OTHER_SYMPS								= uh.L_OTHER_SYMPS
					,L_COMMENTS									= uh.L_COMMENTS
					,N2_11_FIRST_SEEN_REASON					= uh.N2_11_FIRST_SEEN_REASON
					,N16_7_DECISION_REASON						= uh.N16_7_DECISION_REASON
					,N16_8_TREATMENT_REASON						= uh.N16_8_TREATMENT_REASON
					,L_DIAGNOSIS_COMMENTS						= uh.L_DIAGNOSIS_COMMENTS
					,GP_PRACTICE_CODE							= uh.GP_PRACTICE_CODE
					,ClinicalTNMGroup							= uh.ClinicalTNMGroup
					,PathologicalTNMGroup						= uh.PathologicalTNMGroup
					,L_KEY_WORKER_SEEN							= uh.L_KEY_WORKER_SEEN
					,L_PALLIATIVE_SPECIALIST_SEEN				= uh.L_PALLIATIVE_SPECIALIST_SEEN
					,GERM_CELL_NON_CNS_ID						= uh.GERM_CELL_NON_CNS_ID
					,RECURRENCE_CANCER_SITE_ID					= uh.RECURRENCE_CANCER_SITE_ID
					,ICD03_GROUP								= uh.ICD03_GROUP
					,ICD03										= uh.ICD03
					,L_DATE_DIAGNOSIS_DAHNO_LUCADA				= uh.L_DATE_DIAGNOSIS_DAHNO_LUCADA
					,L_INDICATOR_CODE							= uh.L_INDICATOR_CODE
					,PRIMARY_DIAGNOSIS_SUB_COMMENT				= uh.PRIMARY_DIAGNOSIS_SUB_COMMENT
					,CONSULTANT_CODE_AT_DIAGNOSIS				= uh.CONSULTANT_CODE_AT_DIAGNOSIS
					,CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS		= uh.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS
					,FETOPROTEIN								= uh.FETOPROTEIN
					,GONADOTROPIN								= uh.GONADOTROPIN
					,GONADOTROPIN_SERUM							= uh.GONADOTROPIN_SERUM
					,FETOPROTEIN_SERUM							= uh.FETOPROTEIN_SERUM
					,SARCOMA_TUMOUR_SITE_BONE					= uh.SARCOMA_TUMOUR_SITE_BONE
					,SARCOMA_TUMOUR_SITE_SOFT_TISSUE			= uh.SARCOMA_TUMOUR_SITE_SOFT_TISSUE
					,SARCOMA_TUMOUR_SUBSITE_BONE				= uh.SARCOMA_TUMOUR_SUBSITE_BONE
					,SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE			= uh.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
					,ROOT_DECISION_DATE_COMMENTS				= uh.ROOT_DECISION_DATE_COMMENTS
					,ROOT_RECEIPT_DATE_COMMENTS					= uh.ROOT_RECEIPT_DATE_COMMENTS
					,ROOT_FIRST_SEEN_DATE_COMMENTS				= uh.ROOT_FIRST_SEEN_DATE_COMMENTS
					,ROOT_DIAGNOSIS_DATE_COMMENTS				= uh.ROOT_DIAGNOSIS_DATE_COMMENTS
					,ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS		= uh.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS
					,ROOT_UPGRADE_COMMENTS						= uh.ROOT_UPGRADE_COMMENTS
					,FIRST_APPT_TIME							= uh.FIRST_APPT_TIME
					,TRANSFER_REASON							= uh.TRANSFER_REASON
					,DATE_NEW_REFERRAL							= uh.DATE_NEW_REFERRAL
					,TUMOUR_SITE_NEW							= uh.TUMOUR_SITE_NEW
					,DATE_TRANSFER_ACTIONED						= uh.DATE_TRANSFER_ACTIONED
					,SOURCE_CARE_ID								= uh.SOURCE_CARE_ID
					,ADT_REF_ID									= uh.ADT_REF_ID
					,ACTION_ID									= uh.ACTION_ID
					,DIAGNOSIS_ACTION_ID						= uh.DIAGNOSIS_ACTION_ID
					,ORIGINAL_SOURCE_CARE_ID					= uh.ORIGINAL_SOURCE_CARE_ID
					,TRANSFER_DATE_COMMENTS						= uh.TRANSFER_DATE_COMMENTS
					,SPECIALIST_REFERRAL_COMMENTS				= uh.SPECIALIST_REFERRAL_COMMENTS
					,NON_CANCER_DIAGNOSIS_CHAPTER				= uh.NON_CANCER_DIAGNOSIS_CHAPTER
					,NON_CANCER_DIAGNOSIS_GROUP					= uh.NON_CANCER_DIAGNOSIS_GROUP
					,NON_CANCER_DIAGNOSIS_CODE					= uh.NON_CANCER_DIAGNOSIS_CODE
					,TNM_UNKNOWN								= uh.TNM_UNKNOWN
					,ReferringPractice							= uh.ReferringPractice
					,ReferringGP								= uh.ReferringGP
					,ReferringBranch							= uh.ReferringBranch
					,BankedTissue								= uh.BankedTissue
					,BankedTissueTumour							= uh.BankedTissueTumour
					,BankedTissueBlood							= uh.BankedTissueBlood
					,BankedTissueCSF							= uh.BankedTissueCSF
					,BankedTissueBoneMarrow						= uh.BankedTissueBoneMarrow
					,SNOMed_CT									= uh.SNOMed_CT
					,ADT_PLACER_ID								= uh.ADT_PLACER_ID
					,SNOMEDCTDiagnosisID						= uh.SNOMEDCTDiagnosisID
					,FasterDiagnosisOrganisationID				= uh.FasterDiagnosisOrganisationID
					,FasterDiagnosisCancerSiteOverrideID		= uh.FasterDiagnosisCancerSiteOverrideID
					,FasterDiagnosisExclusionDate				= uh.FasterDiagnosisExclusionDate
					,FasterDiagnosisExclusionReasonID			= uh.FasterDiagnosisExclusionReasonID
					,FasterDiagnosisDelayReasonID				= uh.FasterDiagnosisDelayReasonID
					,FasterDiagnosisDelayReasonComments			= uh.FasterDiagnosisDelayReasonComments
					,FasterDiagnosisCommunicationMethodID		= uh.FasterDiagnosisCommunicationMethodID
					,FasterDiagnosisInformingCareProfessionalID	= uh.FasterDiagnosisInformingCareProfessionalID
					,FasterDiagnosisOtherCareProfessional		= uh.FasterDiagnosisOtherCareProfessional
					,FasterDiagnosisOtherCommunicationMethod	= uh.FasterDiagnosisOtherCommunicationMethod
					--,DEPRECATED_20_01_RecurrenceMetastaticType	= uh.DEPRECATED_20_01_RecurrenceMetastaticType
					,NonPrimaryPathwayOptionsID					= uh.NonPrimaryPathwayOptionsID
					,DiagnosisUncertainty						= uh.DiagnosisUncertainty
					,TNMOrganisation							= uh.TNMOrganisation
					,FasterDiagnosisTargetRCComments			= uh.FasterDiagnosisTargetRCComments
					,FasterDiagnosisEndRCComments				= uh.FasterDiagnosisEndRCComments
					,TNMOrganisation_Integrated					= uh.TNMOrganisation_Integrated
					,LDHValue									= uh.LDHValue
					--,DEPRECATED_20_01_LDH_NORMAL				= uh.DEPRECATED_20_01_LDH_NORMAL
					,BankedTissueUrine							= uh.BankedTissueUrine
					,SubsiteID									= uh.SubsiteID
					,PredictedBreachStatus						= uh.PredictedBreachStatus
					,RMRefID									= uh.RMRefID
					,TertiaryReferralKey						= uh.TertiaryReferralKey
					,ClinicalTLetter							= uh.ClinicalTLetter
					,ClinicalNLetter							= uh.ClinicalNLetter
					,ClinicalMLetter							= uh.ClinicalMLetter
					,PathologicalTLetter						= uh.PathologicalTLetter
					,PathologicalNLetter						= uh.PathologicalNLetter
					,PathologicalMLetter						= uh.PathologicalMLetter
					,FDPlannedInterval							= uh.FDPlannedInterval
					,LabReportDate								= uh.LabReportDate
					,LabReportOrgID								= uh.LabReportOrgID
					,ReferralRoute								= uh.ReferralRoute
					,ReferralOtherRoute							= uh.ReferralOtherRoute
					,RelapseMorphology							= uh.RelapseMorphology
					,RelapseFlow								= uh.RelapseFlow
					,RelapseMolecular							= uh.RelapseMolecular
					,RelapseClinicalExamination					= uh.RelapseClinicalExamination
					,RelapseOther								= uh.RelapseOther
					,RapidDiagnostic							= uh.RapidDiagnostic
					,PrimaryReferralFlag						= uh.PrimaryReferralFlag
					,OtherAssessedBy							= uh.OtherAssessedBy
					,SharedBreach								= uh.SharedBreach
					,PredictedBreachYear						= uh.PredictedBreachYear
					,PredictedBreachMonth						= uh.PredictedBreachMonth
		FROM		Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
																ON	uh.SrcSys = mc.SrcSys
																AND	uh.Src_UID = mc.Src_UID
		LEFT JOIN	#ValidatedData vd
									ON	mc.SrcSys = vd.SrcSys
									AND	mc.Src_UID = vd.Src_UID
		WHERE		mc.SrcSys IS NULL
		OR			vd.SrcSys IS NULL

		-- Excluded SCR records that won't be in the match control table (if we are creating a bulk dataset)
		IF @HasRelatedEntities = 0
		INSERT INTO	#ValidatedData
		SELECT		SrcSys_MajorExt								= uh.SrcSys
					,Src_UID_MajorExt							= uh.Src_UID
					,SrcSys_Major								= uh.SrcSys
					,Src_UID_Major								= uh.Src_UID
					,IsValidatedMajor							= 0
					,IsConfirmed								= 0
					,LastUpdated								= uh.LastUpdated
					,SrcSys										= uh.SrcSys
					,Src_UID									= uh.Src_UID
					,CARE_ID									= uh.CARE_ID
					,PATIENT_ID									= uh.PATIENT_ID
					,TEMP_ID									= uh.TEMP_ID
					,L_CANCER_SITE								= uh.L_CANCER_SITE
					,N2_1_REFERRAL_SOURCE						= uh.N2_1_REFERRAL_SOURCE
					,N2_2_ORG_CODE_REF							= uh.N2_2_ORG_CODE_REF
					,N2_3_REFERRER_CODE							= uh.N2_3_REFERRER_CODE
					,N2_4_PRIORITY_TYPE							= uh.N2_4_PRIORITY_TYPE
					,N2_5_DECISION_DATE							= uh.N2_5_DECISION_DATE
					,N2_6_RECEIPT_DATE							= uh.N2_6_RECEIPT_DATE
					,N2_7_CONSULTANT							= uh.N2_7_CONSULTANT
					,N2_8_SPECIALTY								= uh.N2_8_SPECIALTY
					,N2_9_FIRST_SEEN_DATE						= uh.N2_9_FIRST_SEEN_DATE
					,N1_3_ORG_CODE_SEEN							= uh.N1_3_ORG_CODE_SEEN
					,N2_10_FIRST_SEEN_DELAY						= uh.N2_10_FIRST_SEEN_DELAY
					,N2_12_CANCER_TYPE							= uh.N2_12_CANCER_TYPE
					,N2_13_CANCER_STATUS						= uh.N2_13_CANCER_STATUS
					,L_FIRST_APPOINTMENT						= uh.L_FIRST_APPOINTMENT
					,L_CANCELLED_DATE							= uh.L_CANCELLED_DATE
					,N2_14_ADJ_TIME								= uh.N2_14_ADJ_TIME
					,N2_15_ADJ_REASON							= uh.N2_15_ADJ_REASON
					,L_REFERRAL_METHOD							= uh.L_REFERRAL_METHOD
					,N2_16_OP_REFERRAL							= uh.N2_16_OP_REFERRAL
					,L_SPECIALIST_DATE							= uh.L_SPECIALIST_DATE
					,L_ORG_CODE_SPECIALIST						= uh.L_ORG_CODE_SPECIALIST
					,L_SPECIALIST_SEEN_DATE						= uh.L_SPECIALIST_SEEN_DATE
					,N1_3_ORG_CODE_SPEC_SEEN					= uh.N1_3_ORG_CODE_SPEC_SEEN
					,N_UPGRADE_DATE								= uh.N_UPGRADE_DATE
					,N_UPGRADE_ORG_CODE							= uh.N_UPGRADE_ORG_CODE
					,L_UPGRADE_WHEN								= uh.L_UPGRADE_WHEN
					,L_UPGRADE_WHO								= uh.L_UPGRADE_WHO
					,N4_1_DIAGNOSIS_DATE						= uh.N4_1_DIAGNOSIS_DATE
					,L_DIAGNOSIS								= uh.L_DIAGNOSIS
					,N4_2_DIAGNOSIS_CODE						= uh.N4_2_DIAGNOSIS_CODE
					,L_ORG_CODE_DIAGNOSIS						= uh.L_ORG_CODE_DIAGNOSIS
					,L_PT_INFORMED_DATE							= uh.L_PT_INFORMED_DATE
					,L_OTHER_DIAG_DATE							= uh.L_OTHER_DIAG_DATE
					,N4_3_LATERALITY							= uh.N4_3_LATERALITY
					,N4_4_BASIS_DIAGNOSIS						= uh.N4_4_BASIS_DIAGNOSIS
					,L_TOPOGRAPHY								= uh.L_TOPOGRAPHY
					,L_HISTOLOGY_GROUP							= uh.L_HISTOLOGY_GROUP
					,N4_5_HISTOLOGY								= uh.N4_5_HISTOLOGY
					,N4_6_DIFFERENTIATION						= uh.N4_6_DIFFERENTIATION
					,ClinicalTStage								= uh.ClinicalTStage
					,ClinicalTCertainty							= uh.ClinicalTCertainty
					,ClinicalNStage								= uh.ClinicalNStage
					,ClinicalNCertainty							= uh.ClinicalNCertainty
					,ClinicalMStage								= uh.ClinicalMStage
					,ClinicalMCertainty							= uh.ClinicalMCertainty
					,ClinicalOverallCertainty					= uh.ClinicalOverallCertainty
					,N6_9_SITE_CLASSIFICATION					= uh.N6_9_SITE_CLASSIFICATION
					,PathologicalOverallCertainty				= uh.PathologicalOverallCertainty
					,PathologicalTCertainty						= uh.PathologicalTCertainty
					,PathologicalTStage							= uh.PathologicalTStage
					,PathologicalNCertainty						= uh.PathologicalNCertainty
					,PathologicalNStage							= uh.PathologicalNStage
					,PathologicalMCertainty						= uh.PathologicalMCertainty
					,PathologicalMStage							= uh.PathologicalMStage
					,L_GP_INFORMED								= uh.L_GP_INFORMED
					,L_GP_INFORMED_DATE							= uh.L_GP_INFORMED_DATE
					,L_GP_NOT									= uh.L_GP_NOT
					,L_REL_INFORMED								= uh.L_REL_INFORMED
					,L_NURSE_PRESENT							= uh.L_NURSE_PRESENT
					,L_SPEC_NURSE_DATE							= uh.L_SPEC_NURSE_DATE
					,L_SEEN_NURSE_DATE							= uh.L_SEEN_NURSE_DATE
					,N16_1_ADJ_DAYS								= uh.N16_1_ADJ_DAYS
					,N16_2_ADJ_DAYS								= uh.N16_2_ADJ_DAYS
					,N16_3_ADJ_DECISION_CODE					= uh.N16_3_ADJ_DECISION_CODE
					,N16_4_ADJ_TREAT_CODE						= uh.N16_4_ADJ_TREAT_CODE
					,N16_5_DECISION_REASON_CODE					= uh.N16_5_DECISION_REASON_CODE
					,N16_6_TREATMENT_REASON_CODE				= uh.N16_6_TREATMENT_REASON_CODE
					,PathologicalTNMDate						= uh.PathologicalTNMDate
					,ClinicalTNMDate							= uh.ClinicalTNMDate
					,L_FIRST_CONSULTANT							= uh.L_FIRST_CONSULTANT
					,L_APPROPRIATE								= uh.L_APPROPRIATE
					,L_TERTIARY_DATE							= uh.L_TERTIARY_DATE
					,L_TERTIARY_TRUST							= uh.L_TERTIARY_TRUST
					,L_TERTIARY_REASON							= uh.L_TERTIARY_REASON
					,L_INAP_REF									= uh.L_INAP_REF
					,L_NEW_CA_SITE								= uh.L_NEW_CA_SITE
					,L_AUTO_REF									= uh.L_AUTO_REF
					,L_SEC_DIAGNOSIS_G							= uh.L_SEC_DIAGNOSIS_G
					,L_SEC_DIAGNOSIS							= uh.L_SEC_DIAGNOSIS
					,L_WRONG_REF								= uh.L_WRONG_REF
					,L_WRONG_REASON								= uh.L_WRONG_REASON
					,L_TUMOUR_STATUS							= uh.L_TUMOUR_STATUS
					,L_NON_CANCER								= uh.L_NON_CANCER
					,L_FIRST_APP								= uh.L_FIRST_APP
					,L_NO_APP									= uh.L_NO_APP
					,L_DIAG_WHO									= uh.L_DIAG_WHO
					,L_RECURRENCE								= uh.L_RECURRENCE
					,L_OTHER_SYMPS								= uh.L_OTHER_SYMPS
					,L_COMMENTS									= uh.L_COMMENTS
					,N2_11_FIRST_SEEN_REASON					= uh.N2_11_FIRST_SEEN_REASON
					,N16_7_DECISION_REASON						= uh.N16_7_DECISION_REASON
					,N16_8_TREATMENT_REASON						= uh.N16_8_TREATMENT_REASON
					,L_DIAGNOSIS_COMMENTS						= uh.L_DIAGNOSIS_COMMENTS
					,GP_PRACTICE_CODE							= uh.GP_PRACTICE_CODE
					,ClinicalTNMGroup							= uh.ClinicalTNMGroup
					,PathologicalTNMGroup						= uh.PathologicalTNMGroup
					,L_KEY_WORKER_SEEN							= uh.L_KEY_WORKER_SEEN
					,L_PALLIATIVE_SPECIALIST_SEEN				= uh.L_PALLIATIVE_SPECIALIST_SEEN
					,GERM_CELL_NON_CNS_ID						= uh.GERM_CELL_NON_CNS_ID
					,RECURRENCE_CANCER_SITE_ID					= uh.RECURRENCE_CANCER_SITE_ID
					,ICD03_GROUP								= uh.ICD03_GROUP
					,ICD03										= uh.ICD03
					,L_DATE_DIAGNOSIS_DAHNO_LUCADA				= uh.L_DATE_DIAGNOSIS_DAHNO_LUCADA
					,L_INDICATOR_CODE							= uh.L_INDICATOR_CODE
					,PRIMARY_DIAGNOSIS_SUB_COMMENT				= uh.PRIMARY_DIAGNOSIS_SUB_COMMENT
					,CONSULTANT_CODE_AT_DIAGNOSIS				= uh.CONSULTANT_CODE_AT_DIAGNOSIS
					,CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS		= uh.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS
					,FETOPROTEIN								= uh.FETOPROTEIN
					,GONADOTROPIN								= uh.GONADOTROPIN
					,GONADOTROPIN_SERUM							= uh.GONADOTROPIN_SERUM
					,FETOPROTEIN_SERUM							= uh.FETOPROTEIN_SERUM
					,SARCOMA_TUMOUR_SITE_BONE					= uh.SARCOMA_TUMOUR_SITE_BONE
					,SARCOMA_TUMOUR_SITE_SOFT_TISSUE			= uh.SARCOMA_TUMOUR_SITE_SOFT_TISSUE
					,SARCOMA_TUMOUR_SUBSITE_BONE				= uh.SARCOMA_TUMOUR_SUBSITE_BONE
					,SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE			= uh.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
					,ROOT_DECISION_DATE_COMMENTS				= uh.ROOT_DECISION_DATE_COMMENTS
					,ROOT_RECEIPT_DATE_COMMENTS					= uh.ROOT_RECEIPT_DATE_COMMENTS
					,ROOT_FIRST_SEEN_DATE_COMMENTS				= uh.ROOT_FIRST_SEEN_DATE_COMMENTS
					,ROOT_DIAGNOSIS_DATE_COMMENTS				= uh.ROOT_DIAGNOSIS_DATE_COMMENTS
					,ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS		= uh.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS
					,ROOT_UPGRADE_COMMENTS						= uh.ROOT_UPGRADE_COMMENTS
					,FIRST_APPT_TIME							= uh.FIRST_APPT_TIME
					,TRANSFER_REASON							= uh.TRANSFER_REASON
					,DATE_NEW_REFERRAL							= uh.DATE_NEW_REFERRAL
					,TUMOUR_SITE_NEW							= uh.TUMOUR_SITE_NEW
					,DATE_TRANSFER_ACTIONED						= uh.DATE_TRANSFER_ACTIONED
					,SOURCE_CARE_ID								= uh.SOURCE_CARE_ID
					,ADT_REF_ID									= uh.ADT_REF_ID
					,ACTION_ID									= uh.ACTION_ID
					,DIAGNOSIS_ACTION_ID						= uh.DIAGNOSIS_ACTION_ID
					,ORIGINAL_SOURCE_CARE_ID					= uh.ORIGINAL_SOURCE_CARE_ID
					,TRANSFER_DATE_COMMENTS						= uh.TRANSFER_DATE_COMMENTS
					,SPECIALIST_REFERRAL_COMMENTS				= uh.SPECIALIST_REFERRAL_COMMENTS
					,NON_CANCER_DIAGNOSIS_CHAPTER				= uh.NON_CANCER_DIAGNOSIS_CHAPTER
					,NON_CANCER_DIAGNOSIS_GROUP					= uh.NON_CANCER_DIAGNOSIS_GROUP
					,NON_CANCER_DIAGNOSIS_CODE					= uh.NON_CANCER_DIAGNOSIS_CODE
					,TNM_UNKNOWN								= uh.TNM_UNKNOWN
					,ReferringPractice							= uh.ReferringPractice
					,ReferringGP								= uh.ReferringGP
					,ReferringBranch							= uh.ReferringBranch
					,BankedTissue								= uh.BankedTissue
					,BankedTissueTumour							= uh.BankedTissueTumour
					,BankedTissueBlood							= uh.BankedTissueBlood
					,BankedTissueCSF							= uh.BankedTissueCSF
					,BankedTissueBoneMarrow						= uh.BankedTissueBoneMarrow
					,SNOMed_CT									= uh.SNOMed_CT
					,ADT_PLACER_ID								= uh.ADT_PLACER_ID
					,SNOMEDCTDiagnosisID						= uh.SNOMEDCTDiagnosisID
					,FasterDiagnosisOrganisationID				= uh.FasterDiagnosisOrganisationID
					,FasterDiagnosisCancerSiteOverrideID		= uh.FasterDiagnosisCancerSiteOverrideID
					,FasterDiagnosisExclusionDate				= uh.FasterDiagnosisExclusionDate
					,FasterDiagnosisExclusionReasonID			= uh.FasterDiagnosisExclusionReasonID
					,FasterDiagnosisDelayReasonID				= uh.FasterDiagnosisDelayReasonID
					,FasterDiagnosisDelayReasonComments			= uh.FasterDiagnosisDelayReasonComments
					,FasterDiagnosisCommunicationMethodID		= uh.FasterDiagnosisCommunicationMethodID
					,FasterDiagnosisInformingCareProfessionalID	= uh.FasterDiagnosisInformingCareProfessionalID
					,FasterDiagnosisOtherCareProfessional		= uh.FasterDiagnosisOtherCareProfessional
					,FasterDiagnosisOtherCommunicationMethod	= uh.FasterDiagnosisOtherCommunicationMethod
					--,DEPRECATED_20_01_RecurrenceMetastaticType	= uh.DEPRECATED_20_01_RecurrenceMetastaticType
					,NonPrimaryPathwayOptionsID					= uh.NonPrimaryPathwayOptionsID
					,DiagnosisUncertainty						= uh.DiagnosisUncertainty
					,TNMOrganisation							= uh.TNMOrganisation
					,FasterDiagnosisTargetRCComments			= uh.FasterDiagnosisTargetRCComments
					,FasterDiagnosisEndRCComments				= uh.FasterDiagnosisEndRCComments
					,TNMOrganisation_Integrated					= uh.TNMOrganisation_Integrated
					,LDHValue									= uh.LDHValue
					--,DEPRECATED_20_01_LDH_NORMAL				= uh.DEPRECATED_20_01_LDH_NORMAL
					,BankedTissueUrine							= uh.BankedTissueUrine
					,SubsiteID									= uh.SubsiteID
					,PredictedBreachStatus						= uh.PredictedBreachStatus
					,RMRefID									= uh.RMRefID
					,TertiaryReferralKey						= uh.TertiaryReferralKey
					,ClinicalTLetter							= uh.ClinicalTLetter
					,ClinicalNLetter							= uh.ClinicalNLetter
					,ClinicalMLetter							= uh.ClinicalMLetter
					,PathologicalTLetter						= uh.PathologicalTLetter
					,PathologicalNLetter						= uh.PathologicalNLetter
					,PathologicalMLetter						= uh.PathologicalMLetter
					,FDPlannedInterval							= uh.FDPlannedInterval
					,LabReportDate								= uh.LabReportDate
					,LabReportOrgID								= uh.LabReportOrgID
					,ReferralRoute								= uh.ReferralRoute
					,ReferralOtherRoute							= uh.ReferralOtherRoute
					,RelapseMorphology							= uh.RelapseMorphology
					,RelapseFlow								= uh.RelapseFlow
					,RelapseMolecular							= uh.RelapseMolecular
					,RelapseClinicalExamination					= uh.RelapseClinicalExamination
					,RelapseOther								= uh.RelapseOther
					,RapidDiagnostic							= uh.RapidDiagnostic
					,PrimaryReferralFlag						= uh.PrimaryReferralFlag
					,OtherAssessedBy							= uh.OtherAssessedBy
					,SharedBreach								= uh.SharedBreach
					,PredictedBreachYear						= uh.PredictedBreachYear
					,PredictedBreachMonth						= uh.PredictedBreachMonth
		FROM		Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded uh
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
																ON	uh.SrcSys = mc.SrcSys
																AND	uh.Src_UID = mc.Src_UID
		LEFT JOIN	#ValidatedData vd
									ON	mc.SrcSys = vd.SrcSys
									AND	mc.Src_UID = vd.Src_UID
		WHERE		mc.SrcSys IS NULL
		OR			vd.SrcSys IS NULL


/*********************************************************************************************************************************************************************************************************************************************************************************/
-- Auto column over-rides
/*********************************************************************************************************************************************************************************************************************************************************************************/

		-- Create a temporary table to keep a record of auto column over-rides
		IF OBJECT_ID('tempdb..#tblMAIN_REFERRALS_AutoColumnOverrides') IS NOT NULL DROP TABLE #tblMAIN_REFERRALS_AutoColumnOverrides
		CREATE TABLE #tblMAIN_REFERRALS_AutoColumnOverrides
					(SrcSys_MajorExt TINYINT NOT NULL
					,Src_UID_MajorExt VARCHAR(255) NOT NULL
					,SrcSys TINYINT NOT NULL
					,Src_UID VARCHAR(255) NOT NULL
					,FieldName VARCHAR(255) NOT NULL
					)

		-- Auto column over-ride missing resultant SubsiteID where a minor has one (SubsiteID)
		UPDATE		ref_vd
		SET			ref_vd.SubsiteID = MinorOverride.SubsiteID
		OUTPUT		Inserted.SrcSys_MajorExt
					,Inserted.Src_UID_MajorExt
					,Inserted.SrcSys
					,Inserted.Src_UID
					,'SubsiteID'
		INTO		#tblMAIN_REFERRALS_AutoColumnOverrides (SrcSys_MajorExt,Src_UID_MajorExt,SrcSys,Src_UID,FieldName)
		FROM		#ValidatedData ref_vd
		INNER JOIN	(SELECT		ref_vd_major.SrcSys_MajorExt
								,ref_vd_major.Src_UID_MajorExt
								,ref_vd_major.SrcSys
								,ref_vd_major.Src_UID
								,uh.SubsiteID
								,ROW_NUMBER() OVER (PARTITION BY ref_vd_major.SrcSys_MajorExt, ref_vd_major.Src_UID_MajorExt ORDER BY uh.LastUpdated DESC, CASE WHEN ref_vd_major.SrcSys != uh.SrcSys THEN 1 ELSE 2 END, uh.Src_UID DESC) AS DeadlockIx
					FROM		#ValidatedData ref_vd_major
					LEFT JOIN	#ValidatedData ref_vd_minor
															ON	ref_vd_major.SrcSys_MajorExt = ref_vd_minor.SrcSys_MajorExt
															AND	ref_vd_major.Src_UID_MajorExt = ref_vd_minor.Src_UID_MajorExt
															AND	ref_vd_minor.IsConfirmed = 1
															AND	ref_vd_minor.IsValidatedMajor = 0
					LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																			ON	ref_vd_minor.SrcSys = uh.SrcSys
																			AND	ref_vd_minor.Src_UID = uh.Src_UID
					WHERE		ref_vd_major.IsConfirmed = 1					-- ref_vd_major is a validated major
					AND			ref_vd_major.IsValidatedMajor = 1				-- ref_vd_major is a validated major
					AND			ref_vd_major.SubsiteID IS NULL					-- resultant referral is missing a subsite
					AND			uh.SubsiteID IS NOT NULL						-- a minor record has a subsite
					AND			ref_vd_major.L_CANCER_SITE = uh.L_CANCER_SITE	-- the major and minor are in the same tumour site
								) MinorOverride
												ON	ref_vd.SrcSys_MajorExt = MinorOverride.SrcSys_MajorExt
												AND	ref_vd.Src_UID_MajorExt = MinorOverride.Src_UID_MajorExt
												AND	ref_vd.SrcSys = MinorOverride.SrcSys
												AND	ref_vd.Src_UID = MinorOverride.Src_UID
												AND	MinorOverride.DeadlockIx = 1

		-- Auto column over-ride resultant cancer status of first treatment where a minor has a subsequent treatment (N2_13_CANCER_STATUS)
		UPDATE		ref_vd
		SET			ref_vd.N2_13_CANCER_STATUS = MinorOverride.N2_13_CANCER_STATUS
		OUTPUT		Inserted.SrcSys_MajorExt
					,Inserted.Src_UID_MajorExt
					,Inserted.SrcSys
					,Inserted.Src_UID
					,'N2_13_CANCER_STATUS'
		INTO		#tblMAIN_REFERRALS_AutoColumnOverrides (SrcSys_MajorExt,Src_UID_MajorExt,SrcSys,Src_UID,FieldName)
		FROM		#ValidatedData ref_vd
		INNER JOIN	(SELECT		ref_vd_major.SrcSys_MajorExt
								,ref_vd_major.Src_UID_MajorExt
								,ref_vd_major.SrcSys
								,ref_vd_major.Src_UID
								,uh.N2_13_CANCER_STATUS
								,ROW_NUMBER() OVER (PARTITION BY ref_vd_major.SrcSys_MajorExt, ref_vd_major.Src_UID_MajorExt ORDER BY uh.LastUpdated DESC, CASE WHEN ref_vd_major.SrcSys != uh.SrcSys THEN 1 ELSE 2 END, uh.Src_UID DESC) AS DeadlockIx
					FROM		#ValidatedData ref_vd_major
					LEFT JOIN	#ValidatedData ref_vd_minor
															ON	ref_vd_major.SrcSys_MajorExt = ref_vd_minor.SrcSys_MajorExt
															AND	ref_vd_major.Src_UID_MajorExt = ref_vd_minor.Src_UID_MajorExt
															AND	ref_vd_minor.IsConfirmed = 1
															AND	ref_vd_minor.IsValidatedMajor = 0
					LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																			ON	ref_vd_minor.SrcSys = uh.SrcSys
																			AND	ref_vd_minor.Src_UID = uh.Src_UID
					WHERE		ref_vd_major.IsConfirmed = 1							-- ref_vd_major is a validated major
					AND			ref_vd_major.IsValidatedMajor = 1						-- ref_vd_major is a validated major
					AND			ISNULL(ref_vd_major.N2_13_CANCER_STATUS, '') != '21'	-- resultant referral is not a subsequent treatment
					AND			uh.N2_13_CANCER_STATUS = '21'							-- a minor record has a cancer status of subsequent treatment
								) MinorOverride
												ON	ref_vd.SrcSys_MajorExt = MinorOverride.SrcSys_MajorExt
												AND	ref_vd.Src_UID_MajorExt = MinorOverride.Src_UID_MajorExt
												AND	ref_vd.SrcSys = MinorOverride.SrcSys
												AND	ref_vd.Src_UID = MinorOverride.Src_UID
												AND	MinorOverride.DeadlockIx = 1

		-- Auto column over-ride missing resultant CNS Seen By Indication Code where a minor has one (L_INDICATOR_CODE)
		UPDATE		ref_vd
		SET			ref_vd.L_INDICATOR_CODE = MinorOverride.L_INDICATOR_CODE
		OUTPUT		Inserted.SrcSys_MajorExt
					,Inserted.Src_UID_MajorExt
					,Inserted.SrcSys
					,Inserted.Src_UID
					,'L_INDICATOR_CODE'
		INTO		#tblMAIN_REFERRALS_AutoColumnOverrides (SrcSys_MajorExt,Src_UID_MajorExt,SrcSys,Src_UID,FieldName)
		FROM		#ValidatedData ref_vd
		INNER JOIN	(SELECT		ref_vd_major.SrcSys_MajorExt
								,ref_vd_major.Src_UID_MajorExt
								,ref_vd_major.SrcSys
								,ref_vd_major.Src_UID
								,uh.L_INDICATOR_CODE
								,ROW_NUMBER() OVER (PARTITION BY ref_vd_major.SrcSys_MajorExt, ref_vd_major.Src_UID_MajorExt ORDER BY uh.LastUpdated DESC, CASE WHEN ref_vd_major.SrcSys != uh.SrcSys THEN 1 ELSE 2 END, uh.Src_UID DESC) AS DeadlockIx
					FROM		#ValidatedData ref_vd_major
					LEFT JOIN	#ValidatedData ref_vd_minor
															ON	ref_vd_major.SrcSys_MajorExt = ref_vd_minor.SrcSys_MajorExt
															AND	ref_vd_major.Src_UID_MajorExt = ref_vd_minor.Src_UID_MajorExt
															AND	ref_vd_minor.IsConfirmed = 1
															AND	ref_vd_minor.IsValidatedMajor = 0
					LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																			ON	ref_vd_minor.SrcSys = uh.SrcSys
																			AND	ref_vd_minor.Src_UID = uh.Src_UID
					WHERE		ref_vd_major.IsConfirmed = 1													-- ref_vd_major is a validated major
					AND			ref_vd_major.IsValidatedMajor = 1												-- ref_vd_major is a validated major
					AND			ref_vd_major.L_INDICATOR_CODE IS NULL											-- resultant referral is missing a CNS Seen By Indication Code
					AND			uh.L_INDICATOR_CODE IS NOT NULL													-- a minor record has a CNS Seen By Indication Code
					AND			(ref_vd_major.L_Diagnosis = uh.L_DIAGNOSIS										-- have the same basic diagnosis code
					OR			LEFT(ref_vd_major.N4_2_DIAGNOSIS_CODE, 3) = LEFT(uh.N4_2_DIAGNOSIS_CODE, 3))	-- have the same basic diagnosis code
					AND			ABS(DATEDIFF(DAY,ref_vd_major.N4_1_DIAGNOSIS_DATE, uh.N4_1_DIAGNOSIS_DATE)) <= 7-- have a diagnosis date within 7 days of each other
								) MinorOverride
												ON	ref_vd.SrcSys_MajorExt = MinorOverride.SrcSys_MajorExt
												AND	ref_vd.Src_UID_MajorExt = MinorOverride.Src_UID_MajorExt
												AND	ref_vd.SrcSys = MinorOverride.SrcSys
												AND	ref_vd.Src_UID = MinorOverride.Src_UID
												AND	MinorOverride.DeadlockIx = 1

		-- Auto column over-ride missing resultant Final Pre-Treatment (Clinical) Staging - T Stage where a minor has one (ClinicalTStage)
		UPDATE		ref_vd
		SET			ref_vd.ClinicalTStage = MinorOverride.ClinicalTStage
		OUTPUT		Inserted.SrcSys_MajorExt
					,Inserted.Src_UID_MajorExt
					,Inserted.SrcSys
					,Inserted.Src_UID
					,'ClinicalTStage'
		INTO		#tblMAIN_REFERRALS_AutoColumnOverrides (SrcSys_MajorExt,Src_UID_MajorExt,SrcSys,Src_UID,FieldName)
		FROM		#ValidatedData ref_vd
		INNER JOIN	(SELECT		ref_vd_major.SrcSys_MajorExt
								,ref_vd_major.Src_UID_MajorExt
								,ref_vd_major.SrcSys
								,ref_vd_major.Src_UID
								,uh.ClinicalTStage
								,ROW_NUMBER() OVER (PARTITION BY ref_vd_major.SrcSys_MajorExt, ref_vd_major.Src_UID_MajorExt ORDER BY uh.LastUpdated DESC, CASE WHEN ref_vd_major.SrcSys != uh.SrcSys THEN 1 ELSE 2 END, uh.Src_UID DESC) AS DeadlockIx
					FROM		#ValidatedData ref_vd_major
					LEFT JOIN	#ValidatedData ref_vd_minor
															ON	ref_vd_major.SrcSys_MajorExt = ref_vd_minor.SrcSys_MajorExt
															AND	ref_vd_major.Src_UID_MajorExt = ref_vd_minor.Src_UID_MajorExt
															AND	ref_vd_minor.IsConfirmed = 1
															AND	ref_vd_minor.IsValidatedMajor = 0
					LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																			ON	ref_vd_minor.SrcSys = uh.SrcSys
																			AND	ref_vd_minor.Src_UID = uh.Src_UID
					WHERE		ref_vd_major.IsConfirmed = 1													-- ref_vd_major is a validated major
					AND			ref_vd_major.IsValidatedMajor = 1												-- ref_vd_major is a validated major
					AND			ref_vd_major.ClinicalTStage IS NULL												-- resultant referral is missing a CNS Seen By Indication Code
					AND			uh.ClinicalTStage IS NOT NULL													-- a minor record has a CNS Seen By Indication Code
					AND			(ref_vd_major.L_Diagnosis = uh.L_DIAGNOSIS										-- have the same basic diagnosis code
					OR			LEFT(ref_vd_major.N4_2_DIAGNOSIS_CODE, 3) = LEFT(uh.N4_2_DIAGNOSIS_CODE, 3))	-- have the same basic diagnosis code
					AND			ABS(DATEDIFF(DAY,ref_vd_major.N4_1_DIAGNOSIS_DATE, uh.N4_1_DIAGNOSIS_DATE)) <= 7-- have a diagnosis date within 7 days of each other
								) MinorOverride
												ON	ref_vd.SrcSys_MajorExt = MinorOverride.SrcSys_MajorExt
												AND	ref_vd.Src_UID_MajorExt = MinorOverride.Src_UID_MajorExt
												AND	ref_vd.SrcSys = MinorOverride.SrcSys
												AND	ref_vd.Src_UID = MinorOverride.Src_UID
												AND	MinorOverride.DeadlockIx = 1

		-- Auto column over-ride missing resultant Final Pre-Treatment (Clinical) Staging - N Stage where a minor has one (ClinicalNStage)
		UPDATE		ref_vd
		SET			ref_vd.ClinicalNStage = MinorOverride.ClinicalNStage
		OUTPUT		Inserted.SrcSys_MajorExt
					,Inserted.Src_UID_MajorExt
					,Inserted.SrcSys
					,Inserted.Src_UID
					,'ClinicalNStage'
		INTO		#tblMAIN_REFERRALS_AutoColumnOverrides (SrcSys_MajorExt,Src_UID_MajorExt,SrcSys,Src_UID,FieldName)
		FROM		#ValidatedData ref_vd
		INNER JOIN	(SELECT		ref_vd_major.SrcSys_MajorExt
								,ref_vd_major.Src_UID_MajorExt
								,ref_vd_major.SrcSys
								,ref_vd_major.Src_UID
								,uh.ClinicalNStage
								,ROW_NUMBER() OVER (PARTITION BY ref_vd_major.SrcSys_MajorExt, ref_vd_major.Src_UID_MajorExt ORDER BY uh.LastUpdated DESC, CASE WHEN ref_vd_major.SrcSys != uh.SrcSys THEN 1 ELSE 2 END, uh.Src_UID DESC) AS DeadlockIx
					FROM		#ValidatedData ref_vd_major
					LEFT JOIN	#ValidatedData ref_vd_minor
															ON	ref_vd_major.SrcSys_MajorExt = ref_vd_minor.SrcSys_MajorExt
															AND	ref_vd_major.Src_UID_MajorExt = ref_vd_minor.Src_UID_MajorExt
															AND	ref_vd_minor.IsConfirmed = 1
															AND	ref_vd_minor.IsValidatedMajor = 0
					LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																			ON	ref_vd_minor.SrcSys = uh.SrcSys
																			AND	ref_vd_minor.Src_UID = uh.Src_UID
					WHERE		ref_vd_major.IsConfirmed = 1													-- ref_vd_major is a validated major
					AND			ref_vd_major.IsValidatedMajor = 1												-- ref_vd_major is a validated major
					AND			ref_vd_major.ClinicalNStage IS NULL												-- resultant referral is missing a CNS Seen By Indication Code
					AND			uh.ClinicalNStage IS NOT NULL													-- a minor record has a CNS Seen By Indication Code
					AND			(ref_vd_major.L_Diagnosis = uh.L_DIAGNOSIS										-- have the same basic diagnosis code
					OR			LEFT(ref_vd_major.N4_2_DIAGNOSIS_CODE, 3) = LEFT(uh.N4_2_DIAGNOSIS_CODE, 3))	-- have the same basic diagnosis code
					AND			ABS(DATEDIFF(DAY,ref_vd_major.N4_1_DIAGNOSIS_DATE, uh.N4_1_DIAGNOSIS_DATE)) <= 7-- have a diagnosis date within 7 days of each other
								) MinorOverride
												ON	ref_vd.SrcSys_MajorExt = MinorOverride.SrcSys_MajorExt
												AND	ref_vd.Src_UID_MajorExt = MinorOverride.Src_UID_MajorExt
												AND	ref_vd.SrcSys = MinorOverride.SrcSys
												AND	ref_vd.Src_UID = MinorOverride.Src_UID
												AND	MinorOverride.DeadlockIx = 1

		-- Auto column over-ride missing resultant Final Pre-Treatment (Clinical) Staging - M Stage where a minor has one (ClinicalMStage)
		UPDATE		ref_vd
		SET			ref_vd.ClinicalMStage = MinorOverride.ClinicalMStage
		OUTPUT		Inserted.SrcSys_MajorExt
					,Inserted.Src_UID_MajorExt
					,Inserted.SrcSys
					,Inserted.Src_UID
					,'ClinicalMStage'
		INTO		#tblMAIN_REFERRALS_AutoColumnOverrides (SrcSys_MajorExt,Src_UID_MajorExt,SrcSys,Src_UID,FieldName)
		FROM		#ValidatedData ref_vd
		INNER JOIN	(SELECT		ref_vd_major.SrcSys_MajorExt
								,ref_vd_major.Src_UID_MajorExt
								,ref_vd_major.SrcSys
								,ref_vd_major.Src_UID
								,uh.ClinicalMStage
								,ROW_NUMBER() OVER (PARTITION BY ref_vd_major.SrcSys_MajorExt, ref_vd_major.Src_UID_MajorExt ORDER BY uh.LastUpdated DESC, CASE WHEN ref_vd_major.SrcSys != uh.SrcSys THEN 1 ELSE 2 END, uh.Src_UID DESC) AS DeadlockIx
					FROM		#ValidatedData ref_vd_major
					LEFT JOIN	#ValidatedData ref_vd_minor
															ON	ref_vd_major.SrcSys_MajorExt = ref_vd_minor.SrcSys_MajorExt
															AND	ref_vd_major.Src_UID_MajorExt = ref_vd_minor.Src_UID_MajorExt
															AND	ref_vd_minor.IsConfirmed = 1
															AND	ref_vd_minor.IsValidatedMajor = 0
					LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																			ON	ref_vd_minor.SrcSys = uh.SrcSys
																			AND	ref_vd_minor.Src_UID = uh.Src_UID
					WHERE		ref_vd_major.IsConfirmed = 1													-- ref_vd_major is a validated major
					AND			ref_vd_major.IsValidatedMajor = 1												-- ref_vd_major is a validated major
					AND			ref_vd_major.ClinicalMStage IS NULL												-- resultant referral is missing a CNS Seen By Indication Code
					AND			uh.ClinicalMStage IS NOT NULL													-- a minor record has a CNS Seen By Indication Code
					AND			(ref_vd_major.L_Diagnosis = uh.L_DIAGNOSIS										-- have the same basic diagnosis code
					OR			LEFT(ref_vd_major.N4_2_DIAGNOSIS_CODE, 3) = LEFT(uh.N4_2_DIAGNOSIS_CODE, 3))	-- have the same basic diagnosis code
					AND			ABS(DATEDIFF(DAY,ref_vd_major.N4_1_DIAGNOSIS_DATE, uh.N4_1_DIAGNOSIS_DATE)) <= 7-- have a diagnosis date within 7 days of each other
								) MinorOverride
												ON	ref_vd.SrcSys_MajorExt = MinorOverride.SrcSys_MajorExt
												AND	ref_vd.Src_UID_MajorExt = MinorOverride.Src_UID_MajorExt
												AND	ref_vd.SrcSys = MinorOverride.SrcSys
												AND	ref_vd.Src_UID = MinorOverride.Src_UID
												AND	MinorOverride.DeadlockIx = 1

		-- Auto column over-ride missing resultant Final Pre-Treatment (Clinical) Staging - Date where a minor has one (ClinicalTNMDate)
		UPDATE		ref_vd
		SET			ref_vd.ClinicalTNMDate = MinorOverride.ClinicalTNMDate
		OUTPUT		Inserted.SrcSys_MajorExt
					,Inserted.Src_UID_MajorExt
					,Inserted.SrcSys
					,Inserted.Src_UID
					,'ClinicalTNMDate'
		INTO		#tblMAIN_REFERRALS_AutoColumnOverrides (SrcSys_MajorExt,Src_UID_MajorExt,SrcSys,Src_UID,FieldName)
		FROM		#ValidatedData ref_vd
		INNER JOIN	(SELECT		ref_vd_major.SrcSys_MajorExt
								,ref_vd_major.Src_UID_MajorExt
								,ref_vd_major.SrcSys
								,ref_vd_major.Src_UID
								,uh.ClinicalTNMDate
								,ROW_NUMBER() OVER (PARTITION BY ref_vd_major.SrcSys_MajorExt, ref_vd_major.Src_UID_MajorExt ORDER BY uh.LastUpdated DESC, CASE WHEN ref_vd_major.SrcSys != uh.SrcSys THEN 1 ELSE 2 END, uh.Src_UID DESC) AS DeadlockIx
					FROM		#ValidatedData ref_vd_major
					LEFT JOIN	#ValidatedData ref_vd_minor
															ON	ref_vd_major.SrcSys_MajorExt = ref_vd_minor.SrcSys_MajorExt
															AND	ref_vd_major.Src_UID_MajorExt = ref_vd_minor.Src_UID_MajorExt
															AND	ref_vd_minor.IsConfirmed = 1
															AND	ref_vd_minor.IsValidatedMajor = 0
					LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																			ON	ref_vd_minor.SrcSys = uh.SrcSys
																			AND	ref_vd_minor.Src_UID = uh.Src_UID
					WHERE		ref_vd_major.IsConfirmed = 1													-- ref_vd_major is a validated major
					AND			ref_vd_major.IsValidatedMajor = 1												-- ref_vd_major is a validated major
					AND			ref_vd_major.ClinicalTNMDate IS NULL											-- resultant referral is missing a CNS Seen By Indication Code
					AND			uh.ClinicalTNMDate IS NOT NULL													-- a minor record has a CNS Seen By Indication Code
					AND			(ref_vd_major.L_Diagnosis = uh.L_DIAGNOSIS										-- have the same basic diagnosis code
					OR			LEFT(ref_vd_major.N4_2_DIAGNOSIS_CODE, 3) = LEFT(uh.N4_2_DIAGNOSIS_CODE, 3))	-- have the same basic diagnosis code
					AND			ABS(DATEDIFF(DAY,ref_vd_major.N4_1_DIAGNOSIS_DATE, uh.N4_1_DIAGNOSIS_DATE)) <= 7-- have a diagnosis date within 7 days of each other
								) MinorOverride
												ON	ref_vd.SrcSys_MajorExt = MinorOverride.SrcSys_MajorExt
												AND	ref_vd.Src_UID_MajorExt = MinorOverride.Src_UID_MajorExt
												AND	ref_vd.SrcSys = MinorOverride.SrcSys
												AND	ref_vd.Src_UID = MinorOverride.Src_UID
												AND	MinorOverride.DeadlockIx = 1

		-- Auto column over-ride missing resultant ADT_REF_ID where a minor has one (ADT_REF_ID)
		UPDATE		ref_vd
		SET			ref_vd.ADT_REF_ID = MinorOverride.ADT_REF_ID
		OUTPUT		Inserted.SrcSys_MajorExt
					,Inserted.Src_UID_MajorExt
					,Inserted.SrcSys
					,Inserted.Src_UID
					,'ADT_REF_ID'
		INTO		#tblMAIN_REFERRALS_AutoColumnOverrides (SrcSys_MajorExt,Src_UID_MajorExt,SrcSys,Src_UID,FieldName)
		FROM		#ValidatedData ref_vd
		INNER JOIN	(SELECT		ref_vd_major.SrcSys_MajorExt
								,ref_vd_major.Src_UID_MajorExt
								,ref_vd_major.SrcSys
								,ref_vd_major.Src_UID
								,uh.ADT_REF_ID
								,ROW_NUMBER() OVER (PARTITION BY ref_vd_major.SrcSys_MajorExt, ref_vd_major.Src_UID_MajorExt ORDER BY uh.LastUpdated DESC, CASE WHEN ref_vd_major.SrcSys != uh.SrcSys THEN 1 ELSE 2 END, uh.Src_UID DESC) AS DeadlockIx
					FROM		#ValidatedData ref_vd_major
					LEFT JOIN	#ValidatedData ref_vd_minor
															ON	ref_vd_major.SrcSys_MajorExt = ref_vd_minor.SrcSys_MajorExt
															AND	ref_vd_major.Src_UID_MajorExt = ref_vd_minor.Src_UID_MajorExt
															AND	ref_vd_minor.IsConfirmed = 1
															AND	ref_vd_minor.IsValidatedMajor = 0
					LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																			ON	ref_vd_minor.SrcSys = uh.SrcSys
																			AND	ref_vd_minor.Src_UID = uh.Src_UID
					WHERE		ref_vd_major.IsConfirmed = 1													-- ref_vd_major is a validated major
					AND			ref_vd_major.IsValidatedMajor = 1												-- ref_vd_major is a validated major
					AND			ref_vd_major.ADT_REF_ID IS NULL													-- resultant referral is missing an ADT_REF_ID
					AND			uh.ADT_REF_ID IS NOT NULL														-- a minor record has an ADT_REF_ID
								) MinorOverride
												ON	ref_vd.SrcSys_MajorExt = MinorOverride.SrcSys_MajorExt
												AND	ref_vd.Src_UID_MajorExt = MinorOverride.Src_UID_MajorExt
												AND	ref_vd.SrcSys = MinorOverride.SrcSys
												AND	ref_vd.Src_UID = MinorOverride.Src_UID
												AND	MinorOverride.DeadlockIx = 1
												

		-- Auto column over-ride missing resultant ADT_REF_ID where a minor has one (ADT_REF_ID)
		UPDATE		ref_vd
		SET			ref_vd.ADT_PLACER_ID = MinorOverride.ADT_PLACER_ID
		OUTPUT		Inserted.SrcSys_MajorExt
					,Inserted.Src_UID_MajorExt
					,Inserted.SrcSys
					,Inserted.Src_UID
					,'ADT_PLACER_ID'
		INTO		#tblMAIN_REFERRALS_AutoColumnOverrides (SrcSys_MajorExt,Src_UID_MajorExt,SrcSys,Src_UID,FieldName)
		FROM		#ValidatedData ref_vd
		INNER JOIN	(SELECT		ref_vd_major.SrcSys_MajorExt
								,ref_vd_major.Src_UID_MajorExt
								,ref_vd_major.SrcSys
								,ref_vd_major.Src_UID
								,uh.ADT_PLACER_ID
								,ROW_NUMBER() OVER (PARTITION BY ref_vd_major.SrcSys_MajorExt, ref_vd_major.Src_UID_MajorExt ORDER BY uh.LastUpdated DESC, CASE WHEN ref_vd_major.SrcSys != uh.SrcSys THEN 1 ELSE 2 END, uh.Src_UID DESC) AS DeadlockIx
					FROM		#ValidatedData ref_vd_major
					LEFT JOIN	#ValidatedData ref_vd_minor
															ON	ref_vd_major.SrcSys_MajorExt = ref_vd_minor.SrcSys_MajorExt
															AND	ref_vd_major.Src_UID_MajorExt = ref_vd_minor.Src_UID_MajorExt
															AND	ref_vd_minor.IsConfirmed = 1
															AND	ref_vd_minor.IsValidatedMajor = 0
					LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																			ON	ref_vd_minor.SrcSys = uh.SrcSys
																			AND	ref_vd_minor.Src_UID = uh.Src_UID
					WHERE		ref_vd_major.IsConfirmed = 1													-- ref_vd_major is a validated major
					AND			ref_vd_major.IsValidatedMajor = 1												-- ref_vd_major is a validated major
					AND			ref_vd_major.ADT_PLACER_ID IS NULL													-- resultant referral is missing an ADT_REF_ID
					AND			uh.ADT_PLACER_ID IS NOT NULL														-- a minor record has an ADT_REF_ID
								) MinorOverride
												ON	ref_vd.SrcSys_MajorExt = MinorOverride.SrcSys_MajorExt
												AND	ref_vd.Src_UID_MajorExt = MinorOverride.Src_UID_MajorExt
												AND	ref_vd.SrcSys = MinorOverride.SrcSys
												AND	ref_vd.Src_UID = MinorOverride.Src_UID
												AND	MinorOverride.DeadlockIx = 1

/*********************************************************************************************************************************************************************************************************************************************************************************/
-- Output the data
/*********************************************************************************************************************************************************************************************************************************************************************************/

		-- Persist the data to a table
		IF	@OutputToTable = 1
		AND	@HasRelatedEntities = 0
		BEGIN
				-- Drop the persisted table if it exists
				IF OBJECT_ID('Merge_DM_Match.tblMAIN_REFERRALS_tblValidatedData') IS NOT NULL DROP TABLE Merge_DM_Match.tblMAIN_REFERRALS_tblValidatedData

				-- Persist the data
				SELECT		*
							,GETDATE() AS ValidatedRecordCreatedDttm
				INTO		Merge_DM_Match.tblMAIN_REFERRALS_tblValidatedData
				FROM		#ValidatedData

		END

		-- Output the table dataset
		IF	@OutputToTable = 0
		AND	@PivotForSSRS = 0
		SELECT		*
		FROM		#ValidatedData

		-- Output the pivoted data for SSRS
		IF	@PivotForSSRS = 1
		BEGIN

		--SELECT * FROM #ValidatedData

				-- Create the table of data we wish to present to SSRS
				IF OBJECT_ID ('tempdb..#DataForValidation') IS NOT NULL DROP TABLE #DataForValidation
				SELECT		*
				INTO		#DataForValidation
				FROM		#ValidatedData
				WHERE		#ValidatedData.IsValidatedMajor = 1

				-- Add in all other internal related rows to the data for validation
				INSERT INTO	#DataForValidation
				SELECT		SrcSys_MajorExt								= mc.SrcSys_Major
							,Src_UID_MajorExt							= mc.Src_UID_Major
							,SrcSys_Major								= ISNULL(mc_1st.SrcSys, mc.SrcSys_Major)
							,Src_UID_Major								= ISNULL(mc_1st.Src_UID, mc.Src_UID_Major)
							,IsValidatedMajor							= 0
							,IsConfirmed								= 0
							,LastUpdated								= uh.LastUpdated
							,SrcSys										= mc.SrcSys
							,Src_UID									= mc.Src_UID
							
							,CARE_ID									= uh.CARE_ID
							,PATIENT_ID									= uh.PATIENT_ID
							,TEMP_ID									= uh.TEMP_ID
							,L_CANCER_SITE								= uh.L_CANCER_SITE
							,N2_1_REFERRAL_SOURCE						= uh.N2_1_REFERRAL_SOURCE
							,N2_2_ORG_CODE_REF							= uh.N2_2_ORG_CODE_REF
							,N2_3_REFERRER_CODE							= uh.N2_3_REFERRER_CODE
							,N2_4_PRIORITY_TYPE							= uh.N2_4_PRIORITY_TYPE
							,N2_5_DECISION_DATE							= uh.N2_5_DECISION_DATE
							,N2_6_RECEIPT_DATE							= uh.N2_6_RECEIPT_DATE
							,N2_7_CONSULTANT							= uh.N2_7_CONSULTANT
							,N2_8_SPECIALTY								= uh.N2_8_SPECIALTY
							,N2_9_FIRST_SEEN_DATE						= uh.N2_9_FIRST_SEEN_DATE
							,N1_3_ORG_CODE_SEEN							= uh.N1_3_ORG_CODE_SEEN
							,N2_10_FIRST_SEEN_DELAY						= uh.N2_10_FIRST_SEEN_DELAY
							,N2_12_CANCER_TYPE							= uh.N2_12_CANCER_TYPE
							,N2_13_CANCER_STATUS						= uh.N2_13_CANCER_STATUS
							,L_FIRST_APPOINTMENT						= uh.L_FIRST_APPOINTMENT
							,L_CANCELLED_DATE							= uh.L_CANCELLED_DATE
							,N2_14_ADJ_TIME								= uh.N2_14_ADJ_TIME
							,N2_15_ADJ_REASON							= uh.N2_15_ADJ_REASON
							,L_REFERRAL_METHOD							= uh.L_REFERRAL_METHOD
							,N2_16_OP_REFERRAL							= uh.N2_16_OP_REFERRAL
							,L_SPECIALIST_DATE							= uh.L_SPECIALIST_DATE
							,L_ORG_CODE_SPECIALIST						= uh.L_ORG_CODE_SPECIALIST
							,L_SPECIALIST_SEEN_DATE						= uh.L_SPECIALIST_SEEN_DATE
							,N1_3_ORG_CODE_SPEC_SEEN					= uh.N1_3_ORG_CODE_SPEC_SEEN
							,N_UPGRADE_DATE								= uh.N_UPGRADE_DATE
							,N_UPGRADE_ORG_CODE							= uh.N_UPGRADE_ORG_CODE
							,L_UPGRADE_WHEN								= uh.L_UPGRADE_WHEN
							,L_UPGRADE_WHO								= uh.L_UPGRADE_WHO
							,N4_1_DIAGNOSIS_DATE						= uh.N4_1_DIAGNOSIS_DATE
							,L_DIAGNOSIS								= uh.L_DIAGNOSIS
							,N4_2_DIAGNOSIS_CODE						= uh.N4_2_DIAGNOSIS_CODE
							,L_ORG_CODE_DIAGNOSIS						= uh.L_ORG_CODE_DIAGNOSIS
							,L_PT_INFORMED_DATE							= uh.L_PT_INFORMED_DATE
							,L_OTHER_DIAG_DATE							= uh.L_OTHER_DIAG_DATE
							,N4_3_LATERALITY							= uh.N4_3_LATERALITY
							,N4_4_BASIS_DIAGNOSIS						= uh.N4_4_BASIS_DIAGNOSIS
							,L_TOPOGRAPHY								= uh.L_TOPOGRAPHY
							,L_HISTOLOGY_GROUP							= uh.L_HISTOLOGY_GROUP
							,N4_5_HISTOLOGY								= uh.N4_5_HISTOLOGY
							,N4_6_DIFFERENTIATION						= uh.N4_6_DIFFERENTIATION
							,ClinicalTStage								= uh.ClinicalTStage
							,ClinicalTCertainty							= uh.ClinicalTCertainty
							,ClinicalNStage								= uh.ClinicalNStage
							,ClinicalNCertainty							= uh.ClinicalNCertainty
							,ClinicalMStage								= uh.ClinicalMStage
							,ClinicalMCertainty							= uh.ClinicalMCertainty
							,ClinicalOverallCertainty					= uh.ClinicalOverallCertainty
							,N6_9_SITE_CLASSIFICATION					= uh.N6_9_SITE_CLASSIFICATION
							,PathologicalOverallCertainty				= uh.PathologicalOverallCertainty
							,PathologicalTCertainty						= uh.PathologicalTCertainty
							,PathologicalTStage							= uh.PathologicalTStage
							,PathologicalNCertainty						= uh.PathologicalNCertainty
							,PathologicalNStage							= uh.PathologicalNStage
							,PathologicalMCertainty						= uh.PathologicalMCertainty
							,PathologicalMStage							= uh.PathologicalMStage
							,L_GP_INFORMED								= uh.L_GP_INFORMED
							,L_GP_INFORMED_DATE							= uh.L_GP_INFORMED_DATE
							,L_GP_NOT									= uh.L_GP_NOT
							,L_REL_INFORMED								= uh.L_REL_INFORMED
							,L_NURSE_PRESENT							= uh.L_NURSE_PRESENT
							,L_SPEC_NURSE_DATE							= uh.L_SPEC_NURSE_DATE
							,L_SEEN_NURSE_DATE							= uh.L_SEEN_NURSE_DATE
							,N16_1_ADJ_DAYS								= uh.N16_1_ADJ_DAYS
							,N16_2_ADJ_DAYS								= uh.N16_2_ADJ_DAYS
							,N16_3_ADJ_DECISION_CODE					= uh.N16_3_ADJ_DECISION_CODE
							,N16_4_ADJ_TREAT_CODE						= uh.N16_4_ADJ_TREAT_CODE
							,N16_5_DECISION_REASON_CODE					= uh.N16_5_DECISION_REASON_CODE
							,N16_6_TREATMENT_REASON_CODE				= uh.N16_6_TREATMENT_REASON_CODE
							,PathologicalTNMDate						= uh.PathologicalTNMDate
							,ClinicalTNMDate							= uh.ClinicalTNMDate
							,L_FIRST_CONSULTANT							= uh.L_FIRST_CONSULTANT
							,L_APPROPRIATE								= uh.L_APPROPRIATE
							,L_TERTIARY_DATE							= uh.L_TERTIARY_DATE
							,L_TERTIARY_TRUST							= uh.L_TERTIARY_TRUST
							,L_TERTIARY_REASON							= uh.L_TERTIARY_REASON
							,L_INAP_REF									= uh.L_INAP_REF
							,L_NEW_CA_SITE								= uh.L_NEW_CA_SITE
							,L_AUTO_REF									= uh.L_AUTO_REF
							,L_SEC_DIAGNOSIS_G							= uh.L_SEC_DIAGNOSIS_G
							,L_SEC_DIAGNOSIS							= uh.L_SEC_DIAGNOSIS
							,L_WRONG_REF								= uh.L_WRONG_REF
							,L_WRONG_REASON								= uh.L_WRONG_REASON
							,L_TUMOUR_STATUS							= uh.L_TUMOUR_STATUS
							,L_NON_CANCER								= uh.L_NON_CANCER
							,L_FIRST_APP								= uh.L_FIRST_APP
							,L_NO_APP									= uh.L_NO_APP
							,L_DIAG_WHO									= uh.L_DIAG_WHO
							,L_RECURRENCE								= uh.L_RECURRENCE
							,L_OTHER_SYMPS								= uh.L_OTHER_SYMPS
							,L_COMMENTS									= uh.L_COMMENTS
							,N2_11_FIRST_SEEN_REASON					= uh.N2_11_FIRST_SEEN_REASON
							,N16_7_DECISION_REASON						= uh.N16_7_DECISION_REASON
							,N16_8_TREATMENT_REASON						= uh.N16_8_TREATMENT_REASON
							,L_DIAGNOSIS_COMMENTS						= uh.L_DIAGNOSIS_COMMENTS
							,GP_PRACTICE_CODE							= uh.GP_PRACTICE_CODE
							,ClinicalTNMGroup							= uh.ClinicalTNMGroup
							,PathologicalTNMGroup						= uh.PathologicalTNMGroup
							,L_KEY_WORKER_SEEN							= uh.L_KEY_WORKER_SEEN
							,L_PALLIATIVE_SPECIALIST_SEEN				= uh.L_PALLIATIVE_SPECIALIST_SEEN
							,GERM_CELL_NON_CNS_ID						= uh.GERM_CELL_NON_CNS_ID
							,RECURRENCE_CANCER_SITE_ID					= uh.RECURRENCE_CANCER_SITE_ID
							,ICD03_GROUP								= uh.ICD03_GROUP
							,ICD03										= uh.ICD03
							,L_DATE_DIAGNOSIS_DAHNO_LUCADA				= uh.L_DATE_DIAGNOSIS_DAHNO_LUCADA
							,L_INDICATOR_CODE							= uh.L_INDICATOR_CODE
							,PRIMARY_DIAGNOSIS_SUB_COMMENT				= uh.PRIMARY_DIAGNOSIS_SUB_COMMENT
							,CONSULTANT_CODE_AT_DIAGNOSIS				= uh.CONSULTANT_CODE_AT_DIAGNOSIS
							,CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS		= uh.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS
							,FETOPROTEIN								= uh.FETOPROTEIN
							,GONADOTROPIN								= uh.GONADOTROPIN
							,GONADOTROPIN_SERUM							= uh.GONADOTROPIN_SERUM
							,FETOPROTEIN_SERUM							= uh.FETOPROTEIN_SERUM
							,SARCOMA_TUMOUR_SITE_BONE					= uh.SARCOMA_TUMOUR_SITE_BONE
							,SARCOMA_TUMOUR_SITE_SOFT_TISSUE			= uh.SARCOMA_TUMOUR_SITE_SOFT_TISSUE
							,SARCOMA_TUMOUR_SUBSITE_BONE				= uh.SARCOMA_TUMOUR_SUBSITE_BONE
							,SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE			= uh.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
							,ROOT_DECISION_DATE_COMMENTS				= uh.ROOT_DECISION_DATE_COMMENTS
							,ROOT_RECEIPT_DATE_COMMENTS					= uh.ROOT_RECEIPT_DATE_COMMENTS
							,ROOT_FIRST_SEEN_DATE_COMMENTS				= uh.ROOT_FIRST_SEEN_DATE_COMMENTS
							,ROOT_DIAGNOSIS_DATE_COMMENTS				= uh.ROOT_DIAGNOSIS_DATE_COMMENTS
							,ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS		= uh.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS
							,ROOT_UPGRADE_COMMENTS						= uh.ROOT_UPGRADE_COMMENTS
							,FIRST_APPT_TIME							= uh.FIRST_APPT_TIME
							,TRANSFER_REASON							= uh.TRANSFER_REASON
							,DATE_NEW_REFERRAL							= uh.DATE_NEW_REFERRAL
							,TUMOUR_SITE_NEW							= uh.TUMOUR_SITE_NEW
							,DATE_TRANSFER_ACTIONED						= uh.DATE_TRANSFER_ACTIONED
							,SOURCE_CARE_ID								= uh.SOURCE_CARE_ID
							,ADT_REF_ID									= uh.ADT_REF_ID
							,ACTION_ID									= uh.ACTION_ID
							,DIAGNOSIS_ACTION_ID						= uh.DIAGNOSIS_ACTION_ID
							,ORIGINAL_SOURCE_CARE_ID					= uh.ORIGINAL_SOURCE_CARE_ID
							,TRANSFER_DATE_COMMENTS						= uh.TRANSFER_DATE_COMMENTS
							,SPECIALIST_REFERRAL_COMMENTS				= uh.SPECIALIST_REFERRAL_COMMENTS
							,NON_CANCER_DIAGNOSIS_CHAPTER				= uh.NON_CANCER_DIAGNOSIS_CHAPTER
							,NON_CANCER_DIAGNOSIS_GROUP					= uh.NON_CANCER_DIAGNOSIS_GROUP
							,NON_CANCER_DIAGNOSIS_CODE					= uh.NON_CANCER_DIAGNOSIS_CODE
							,TNM_UNKNOWN								= uh.TNM_UNKNOWN
							,ReferringPractice							= uh.ReferringPractice
							,ReferringGP								= uh.ReferringGP
							,ReferringBranch							= uh.ReferringBranch
							,BankedTissue								= uh.BankedTissue
							,BankedTissueTumour							= uh.BankedTissueTumour
							,BankedTissueBlood							= uh.BankedTissueBlood
							,BankedTissueCSF							= uh.BankedTissueCSF
							,BankedTissueBoneMarrow						= uh.BankedTissueBoneMarrow
							,SNOMed_CT									= uh.SNOMed_CT
							,ADT_PLACER_ID								= uh.ADT_PLACER_ID
							,SNOMEDCTDiagnosisID						= uh.SNOMEDCTDiagnosisID
							,FasterDiagnosisOrganisationID				= uh.FasterDiagnosisOrganisationID
							,FasterDiagnosisCancerSiteOverrideID		= uh.FasterDiagnosisCancerSiteOverrideID
							,FasterDiagnosisExclusionDate				= uh.FasterDiagnosisExclusionDate
							,FasterDiagnosisExclusionReasonID			= uh.FasterDiagnosisExclusionReasonID
							,FasterDiagnosisDelayReasonID				= uh.FasterDiagnosisDelayReasonID
							,FasterDiagnosisDelayReasonComments			= uh.FasterDiagnosisDelayReasonComments
							,FasterDiagnosisCommunicationMethodID		= uh.FasterDiagnosisCommunicationMethodID
							,FasterDiagnosisInformingCareProfessionalID	= uh.FasterDiagnosisInformingCareProfessionalID
							,FasterDiagnosisOtherCareProfessional		= uh.FasterDiagnosisOtherCareProfessional
							,FasterDiagnosisOtherCommunicationMethod	= uh.FasterDiagnosisOtherCommunicationMethod
							--,DEPRECATED_20_01_RecurrenceMetastaticType	= uh.DEPRECATED_20_01_RecurrenceMetastaticType
							,NonPrimaryPathwayOptionsID					= uh.NonPrimaryPathwayOptionsID
							,DiagnosisUncertainty						= uh.DiagnosisUncertainty
							,TNMOrganisation							= uh.TNMOrganisation
							,FasterDiagnosisTargetRCComments			= uh.FasterDiagnosisTargetRCComments
							,FasterDiagnosisEndRCComments				= uh.FasterDiagnosisEndRCComments
							,TNMOrganisation_Integrated					= uh.TNMOrganisation_Integrated
							,LDHValue									= uh.LDHValue
							--,DEPRECATED_20_01_LDH_NORMAL				= uh.DEPRECATED_20_01_LDH_NORMAL
							,BankedTissueUrine							= uh.BankedTissueUrine
							,SubsiteID									= uh.SubsiteID
							,PredictedBreachStatus						= uh.PredictedBreachStatus
							,RMRefID									= uh.RMRefID
							,TertiaryReferralKey						= uh.TertiaryReferralKey
							,ClinicalTLetter							= uh.ClinicalTLetter
							,ClinicalNLetter							= uh.ClinicalNLetter
							,ClinicalMLetter							= uh.ClinicalMLetter
							,PathologicalTLetter						= uh.PathologicalTLetter
							,PathologicalNLetter						= uh.PathologicalNLetter
							,PathologicalMLetter						= uh.PathologicalMLetter
							,FDPlannedInterval							= uh.FDPlannedInterval
							,LabReportDate								= uh.LabReportDate
							,LabReportOrgID								= uh.LabReportOrgID
							,ReferralRoute								= uh.ReferralRoute
							,ReferralOtherRoute							= uh.ReferralOtherRoute
							,RelapseMorphology							= uh.RelapseMorphology
							,RelapseFlow								= uh.RelapseFlow
							,RelapseMolecular							= uh.RelapseMolecular
							,RelapseClinicalExamination					= uh.RelapseClinicalExamination
							,RelapseOther								= uh.RelapseOther
							,RapidDiagnostic							= uh.RapidDiagnostic
							,PrimaryReferralFlag						= uh.PrimaryReferralFlag
							,OtherAssessedBy							= uh.OtherAssessedBy
							,SharedBreach								= uh.SharedBreach
							,PredictedBreachYear						= uh.PredictedBreachYear
							,PredictedBreachMonth						= uh.PredictedBreachMonth
				FROM		Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
				INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
																			ON	uh.SrcSys = mc.SrcSys
																			AND	uh.Src_UID = mc.Src_UID
				INNER JOIN	#RelatedEntities re
												ON	uh.SrcSys = re.SrcSys
												AND	uh.Src_UID = re.Src_UID
				LEFT JOIN	#mcIx mc_1st
										ON	mc.SrcSys_Major = mc_1st.SrcSys_Major
										AND	mc.Src_UID_Major = mc_1st.Src_UID_Major
										AND	mc_1st.IsMajorSCR = 0
										AND	mc_1st.mcIx = 1
				WHERE		uh.IsSCR = 1

				-- Add in all other external related rows to the data for validation
				INSERT INTO	#DataForValidation
				SELECT		SrcSys_MajorExt								= mc.SrcSys_Major
							,Src_UID_MajorExt							= mc.Src_UID_Major
							,SrcSys_Major								= ISNULL(mc_1st.SrcSys, mc.SrcSys_Major)
							,Src_UID_Major								= ISNULL(mc_1st.Src_UID, mc.Src_UID_Major)
							,IsValidatedMajor							= 0
							,IsConfirmed								= 0
							,LastUpdated								= uh.LastUpdated
							,SrcSys										= mc.SrcSys
							,Src_UID									= mc.Src_UID
							
							,CARE_ID									= uh.CARE_ID
							,PATIENT_ID									= uh.PATIENT_ID
							,TEMP_ID									= uh.TEMP_ID
							,L_CANCER_SITE								= uh.L_CANCER_SITE
							,N2_1_REFERRAL_SOURCE						= uh.N2_1_REFERRAL_SOURCE
							,N2_2_ORG_CODE_REF							= uh.N2_2_ORG_CODE_REF
							,N2_3_REFERRER_CODE							= uh.N2_3_REFERRER_CODE
							,N2_4_PRIORITY_TYPE							= uh.N2_4_PRIORITY_TYPE
							,N2_5_DECISION_DATE							= uh.N2_5_DECISION_DATE
							,N2_6_RECEIPT_DATE							= uh.N2_6_RECEIPT_DATE
							,N2_7_CONSULTANT							= uh.N2_7_CONSULTANT
							,N2_8_SPECIALTY								= uh.N2_8_SPECIALTY
							,N2_9_FIRST_SEEN_DATE						= uh.N2_9_FIRST_SEEN_DATE
							,N1_3_ORG_CODE_SEEN							= uh.N1_3_ORG_CODE_SEEN
							,N2_10_FIRST_SEEN_DELAY						= uh.N2_10_FIRST_SEEN_DELAY
							,N2_12_CANCER_TYPE							= uh.N2_12_CANCER_TYPE
							,N2_13_CANCER_STATUS						= uh.N2_13_CANCER_STATUS
							,L_FIRST_APPOINTMENT						= uh.L_FIRST_APPOINTMENT
							,L_CANCELLED_DATE							= uh.L_CANCELLED_DATE
							,N2_14_ADJ_TIME								= uh.N2_14_ADJ_TIME
							,N2_15_ADJ_REASON							= uh.N2_15_ADJ_REASON
							,L_REFERRAL_METHOD							= uh.L_REFERRAL_METHOD
							,N2_16_OP_REFERRAL							= uh.N2_16_OP_REFERRAL
							,L_SPECIALIST_DATE							= uh.L_SPECIALIST_DATE
							,L_ORG_CODE_SPECIALIST						= uh.L_ORG_CODE_SPECIALIST
							,L_SPECIALIST_SEEN_DATE						= uh.L_SPECIALIST_SEEN_DATE
							,N1_3_ORG_CODE_SPEC_SEEN					= uh.N1_3_ORG_CODE_SPEC_SEEN
							,N_UPGRADE_DATE								= uh.N_UPGRADE_DATE
							,N_UPGRADE_ORG_CODE							= uh.N_UPGRADE_ORG_CODE
							,L_UPGRADE_WHEN								= uh.L_UPGRADE_WHEN
							,L_UPGRADE_WHO								= uh.L_UPGRADE_WHO
							,N4_1_DIAGNOSIS_DATE						= uh.N4_1_DIAGNOSIS_DATE
							,L_DIAGNOSIS								= uh.L_DIAGNOSIS
							,N4_2_DIAGNOSIS_CODE						= uh.N4_2_DIAGNOSIS_CODE
							,L_ORG_CODE_DIAGNOSIS						= uh.L_ORG_CODE_DIAGNOSIS
							,L_PT_INFORMED_DATE							= uh.L_PT_INFORMED_DATE
							,L_OTHER_DIAG_DATE							= uh.L_OTHER_DIAG_DATE
							,N4_3_LATERALITY							= uh.N4_3_LATERALITY
							,N4_4_BASIS_DIAGNOSIS						= uh.N4_4_BASIS_DIAGNOSIS
							,L_TOPOGRAPHY								= uh.L_TOPOGRAPHY
							,L_HISTOLOGY_GROUP							= uh.L_HISTOLOGY_GROUP
							,N4_5_HISTOLOGY								= uh.N4_5_HISTOLOGY
							,N4_6_DIFFERENTIATION						= uh.N4_6_DIFFERENTIATION
							,ClinicalTStage								= uh.ClinicalTStage
							,ClinicalTCertainty							= uh.ClinicalTCertainty
							,ClinicalNStage								= uh.ClinicalNStage
							,ClinicalNCertainty							= uh.ClinicalNCertainty
							,ClinicalMStage								= uh.ClinicalMStage
							,ClinicalMCertainty							= uh.ClinicalMCertainty
							,ClinicalOverallCertainty					= uh.ClinicalOverallCertainty
							,N6_9_SITE_CLASSIFICATION					= uh.N6_9_SITE_CLASSIFICATION
							,PathologicalOverallCertainty				= uh.PathologicalOverallCertainty
							,PathologicalTCertainty						= uh.PathologicalTCertainty
							,PathologicalTStage							= uh.PathologicalTStage
							,PathologicalNCertainty						= uh.PathologicalNCertainty
							,PathologicalNStage							= uh.PathologicalNStage
							,PathologicalMCertainty						= uh.PathologicalMCertainty
							,PathologicalMStage							= uh.PathologicalMStage
							,L_GP_INFORMED								= uh.L_GP_INFORMED
							,L_GP_INFORMED_DATE							= uh.L_GP_INFORMED_DATE
							,L_GP_NOT									= uh.L_GP_NOT
							,L_REL_INFORMED								= uh.L_REL_INFORMED
							,L_NURSE_PRESENT							= uh.L_NURSE_PRESENT
							,L_SPEC_NURSE_DATE							= uh.L_SPEC_NURSE_DATE
							,L_SEEN_NURSE_DATE							= uh.L_SEEN_NURSE_DATE
							,N16_1_ADJ_DAYS								= uh.N16_1_ADJ_DAYS
							,N16_2_ADJ_DAYS								= uh.N16_2_ADJ_DAYS
							,N16_3_ADJ_DECISION_CODE					= uh.N16_3_ADJ_DECISION_CODE
							,N16_4_ADJ_TREAT_CODE						= uh.N16_4_ADJ_TREAT_CODE
							,N16_5_DECISION_REASON_CODE					= uh.N16_5_DECISION_REASON_CODE
							,N16_6_TREATMENT_REASON_CODE				= uh.N16_6_TREATMENT_REASON_CODE
							,PathologicalTNMDate						= uh.PathologicalTNMDate
							,ClinicalTNMDate							= uh.ClinicalTNMDate
							,L_FIRST_CONSULTANT							= uh.L_FIRST_CONSULTANT
							,L_APPROPRIATE								= uh.L_APPROPRIATE
							,L_TERTIARY_DATE							= uh.L_TERTIARY_DATE
							,L_TERTIARY_TRUST							= uh.L_TERTIARY_TRUST
							,L_TERTIARY_REASON							= uh.L_TERTIARY_REASON
							,L_INAP_REF									= uh.L_INAP_REF
							,L_NEW_CA_SITE								= uh.L_NEW_CA_SITE
							,L_AUTO_REF									= uh.L_AUTO_REF
							,L_SEC_DIAGNOSIS_G							= uh.L_SEC_DIAGNOSIS_G
							,L_SEC_DIAGNOSIS							= uh.L_SEC_DIAGNOSIS
							,L_WRONG_REF								= uh.L_WRONG_REF
							,L_WRONG_REASON								= uh.L_WRONG_REASON
							,L_TUMOUR_STATUS							= uh.L_TUMOUR_STATUS
							,L_NON_CANCER								= uh.L_NON_CANCER
							,L_FIRST_APP								= uh.L_FIRST_APP
							,L_NO_APP									= uh.L_NO_APP
							,L_DIAG_WHO									= uh.L_DIAG_WHO
							,L_RECURRENCE								= uh.L_RECURRENCE
							,L_OTHER_SYMPS								= uh.L_OTHER_SYMPS
							,L_COMMENTS									= uh.L_COMMENTS
							,N2_11_FIRST_SEEN_REASON					= uh.N2_11_FIRST_SEEN_REASON
							,N16_7_DECISION_REASON						= uh.N16_7_DECISION_REASON
							,N16_8_TREATMENT_REASON						= uh.N16_8_TREATMENT_REASON
							,L_DIAGNOSIS_COMMENTS						= uh.L_DIAGNOSIS_COMMENTS
							,GP_PRACTICE_CODE							= uh.GP_PRACTICE_CODE
							,ClinicalTNMGroup							= uh.ClinicalTNMGroup
							,PathologicalTNMGroup						= uh.PathologicalTNMGroup
							,L_KEY_WORKER_SEEN							= uh.L_KEY_WORKER_SEEN
							,L_PALLIATIVE_SPECIALIST_SEEN				= uh.L_PALLIATIVE_SPECIALIST_SEEN
							,GERM_CELL_NON_CNS_ID						= uh.GERM_CELL_NON_CNS_ID
							,RECURRENCE_CANCER_SITE_ID					= uh.RECURRENCE_CANCER_SITE_ID
							,ICD03_GROUP								= uh.ICD03_GROUP
							,ICD03										= uh.ICD03
							,L_DATE_DIAGNOSIS_DAHNO_LUCADA				= uh.L_DATE_DIAGNOSIS_DAHNO_LUCADA
							,L_INDICATOR_CODE							= uh.L_INDICATOR_CODE
							,PRIMARY_DIAGNOSIS_SUB_COMMENT				= uh.PRIMARY_DIAGNOSIS_SUB_COMMENT
							,CONSULTANT_CODE_AT_DIAGNOSIS				= uh.CONSULTANT_CODE_AT_DIAGNOSIS
							,CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS		= uh.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS
							,FETOPROTEIN								= uh.FETOPROTEIN
							,GONADOTROPIN								= uh.GONADOTROPIN
							,GONADOTROPIN_SERUM							= uh.GONADOTROPIN_SERUM
							,FETOPROTEIN_SERUM							= uh.FETOPROTEIN_SERUM
							,SARCOMA_TUMOUR_SITE_BONE					= uh.SARCOMA_TUMOUR_SITE_BONE
							,SARCOMA_TUMOUR_SITE_SOFT_TISSUE			= uh.SARCOMA_TUMOUR_SITE_SOFT_TISSUE
							,SARCOMA_TUMOUR_SUBSITE_BONE				= uh.SARCOMA_TUMOUR_SUBSITE_BONE
							,SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE			= uh.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
							,ROOT_DECISION_DATE_COMMENTS				= uh.ROOT_DECISION_DATE_COMMENTS
							,ROOT_RECEIPT_DATE_COMMENTS					= uh.ROOT_RECEIPT_DATE_COMMENTS
							,ROOT_FIRST_SEEN_DATE_COMMENTS				= uh.ROOT_FIRST_SEEN_DATE_COMMENTS
							,ROOT_DIAGNOSIS_DATE_COMMENTS				= uh.ROOT_DIAGNOSIS_DATE_COMMENTS
							,ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS		= uh.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS
							,ROOT_UPGRADE_COMMENTS						= uh.ROOT_UPGRADE_COMMENTS
							,FIRST_APPT_TIME							= uh.FIRST_APPT_TIME
							,TRANSFER_REASON							= uh.TRANSFER_REASON
							,DATE_NEW_REFERRAL							= uh.DATE_NEW_REFERRAL
							,TUMOUR_SITE_NEW							= uh.TUMOUR_SITE_NEW
							,DATE_TRANSFER_ACTIONED						= uh.DATE_TRANSFER_ACTIONED
							,SOURCE_CARE_ID								= uh.SOURCE_CARE_ID
							,ADT_REF_ID									= uh.ADT_REF_ID
							,ACTION_ID									= uh.ACTION_ID
							,DIAGNOSIS_ACTION_ID						= uh.DIAGNOSIS_ACTION_ID
							,ORIGINAL_SOURCE_CARE_ID					= uh.ORIGINAL_SOURCE_CARE_ID
							,TRANSFER_DATE_COMMENTS						= uh.TRANSFER_DATE_COMMENTS
							,SPECIALIST_REFERRAL_COMMENTS				= uh.SPECIALIST_REFERRAL_COMMENTS
							,NON_CANCER_DIAGNOSIS_CHAPTER				= uh.NON_CANCER_DIAGNOSIS_CHAPTER
							,NON_CANCER_DIAGNOSIS_GROUP					= uh.NON_CANCER_DIAGNOSIS_GROUP
							,NON_CANCER_DIAGNOSIS_CODE					= uh.NON_CANCER_DIAGNOSIS_CODE
							,TNM_UNKNOWN								= uh.TNM_UNKNOWN
							,ReferringPractice							= uh.ReferringPractice
							,ReferringGP								= uh.ReferringGP
							,ReferringBranch							= uh.ReferringBranch
							,BankedTissue								= uh.BankedTissue
							,BankedTissueTumour							= uh.BankedTissueTumour
							,BankedTissueBlood							= uh.BankedTissueBlood
							,BankedTissueCSF							= uh.BankedTissueCSF
							,BankedTissueBoneMarrow						= uh.BankedTissueBoneMarrow
							,SNOMed_CT									= uh.SNOMed_CT
							,ADT_PLACER_ID								= uh.ADT_PLACER_ID
							,SNOMEDCTDiagnosisID						= uh.SNOMEDCTDiagnosisID
							,FasterDiagnosisOrganisationID				= uh.FasterDiagnosisOrganisationID
							,FasterDiagnosisCancerSiteOverrideID		= uh.FasterDiagnosisCancerSiteOverrideID
							,FasterDiagnosisExclusionDate				= uh.FasterDiagnosisExclusionDate
							,FasterDiagnosisExclusionReasonID			= uh.FasterDiagnosisExclusionReasonID
							,FasterDiagnosisDelayReasonID				= uh.FasterDiagnosisDelayReasonID
							,FasterDiagnosisDelayReasonComments			= uh.FasterDiagnosisDelayReasonComments
							,FasterDiagnosisCommunicationMethodID		= uh.FasterDiagnosisCommunicationMethodID
							,FasterDiagnosisInformingCareProfessionalID	= uh.FasterDiagnosisInformingCareProfessionalID
							,FasterDiagnosisOtherCareProfessional		= uh.FasterDiagnosisOtherCareProfessional
							,FasterDiagnosisOtherCommunicationMethod	= uh.FasterDiagnosisOtherCommunicationMethod
							--,DEPRECATED_20_01_RecurrenceMetastaticType	= uh.DEPRECATED_20_01_RecurrenceMetastaticType
							,NonPrimaryPathwayOptionsID					= uh.NonPrimaryPathwayOptionsID
							,DiagnosisUncertainty						= uh.DiagnosisUncertainty
							,TNMOrganisation							= uh.TNMOrganisation
							,FasterDiagnosisTargetRCComments			= uh.FasterDiagnosisTargetRCComments
							,FasterDiagnosisEndRCComments				= uh.FasterDiagnosisEndRCComments
							,TNMOrganisation_Integrated					= uh.TNMOrganisation_Integrated
							,LDHValue									= uh.LDHValue
							--,DEPRECATED_20_01_LDH_NORMAL				= uh.DEPRECATED_20_01_LDH_NORMAL
							,BankedTissueUrine							= uh.BankedTissueUrine
							,SubsiteID									= uh.SubsiteID
							,PredictedBreachStatus						= uh.PredictedBreachStatus
							,RMRefID									= uh.RMRefID
							,TertiaryReferralKey						= uh.TertiaryReferralKey
							,ClinicalTLetter							= uh.ClinicalTLetter
							,ClinicalNLetter							= uh.ClinicalNLetter
							,ClinicalMLetter							= uh.ClinicalMLetter
							,PathologicalTLetter						= uh.PathologicalTLetter
							,PathologicalNLetter						= uh.PathologicalNLetter
							,PathologicalMLetter						= uh.PathologicalMLetter
							,FDPlannedInterval							= uh.FDPlannedInterval
							,LabReportDate								= uh.LabReportDate
							,LabReportOrgID								= uh.LabReportOrgID
							,ReferralRoute								= uh.ReferralRoute
							,ReferralOtherRoute							= uh.ReferralOtherRoute
							,RelapseMorphology							= uh.RelapseMorphology
							,RelapseFlow								= uh.RelapseFlow
							,RelapseMolecular							= uh.RelapseMolecular
							,RelapseClinicalExamination					= uh.RelapseClinicalExamination
							,RelapseOther								= uh.RelapseOther
							,RapidDiagnostic							= uh.RapidDiagnostic
							,PrimaryReferralFlag						= uh.PrimaryReferralFlag
							,OtherAssessedBy							= uh.OtherAssessedBy
							,SharedBreach								= uh.SharedBreach
							,PredictedBreachYear						= uh.PredictedBreachYear
							,PredictedBreachMonth						= uh.PredictedBreachMonth
				FROM		Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
				INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
																			ON	uh.SrcSys = mc.SrcSys
																			AND	uh.Src_UID = mc.Src_UID
				INNER JOIN	#RelatedEntities re
												ON	uh.SrcSys = re.SrcSys
												AND	uh.Src_UID = re.Src_UID
				LEFT JOIN	#mcIx mc_1st
										ON	mc.SrcSys_Major = mc_1st.SrcSys_Major
										AND	mc.Src_UID_Major = mc_1st.Src_UID_Major
										AND	mc_1st.IsMajorSCR = 0
										AND	mc_1st.mcIx = 1 
				WHERE		uh.IsSCR = 0
				
				-- Create and populate the list of colums we wish to present to SSRS 
				IF OBJECT_ID('tempdb..#ColumnDetails') IS NULL CREATE TABLE #ColumnDetails (TableName VARCHAR(255), ShowInReport BIT, ColumnName VARCHAR(255), ColumnDesc VARCHAR(255), ColumnGroup VARCHAR(255), ColumnSort SMALLINT, ColumnGroupSort TINYINT)
				TRUNCATE TABLE #ColumnDetails
				INSERT INTO #ColumnDetails (TableName,ShowInReport,ColumnName,ColumnDesc,ColumnGroup,ColumnSort,ColumnGroupSort) SELECT * FROM Merge_DM_Match.Config_ColumnsAndGroups WHERE ShowInReport = 1 AND TableName = 'tblMAIN_REFERRALS'


				-- Create and populate the row-wise (unpivoted) data that we need to present to the matrix in SSRS
				IF OBJECT_ID('tempdb..#Unpivoted') IS NOT NULL DROP TABLE #Unpivoted
				SELECT		'ValidatedData' AS ReportingCohort
							,ISNULL(RowWise.SrcSys_MajorExt, mmvc.SrcSys_MajorExt) AS SrcSys_MajorExt
							,ISNULL(RowWise.Src_UID_MajorExt, mmvc.Src_UID_MajorExt) AS Src_UID_MajorExt
							,ISNULL(RowWise.SrcSys_Major, mmvc.SrcSys_Major) AS SrcSys_Major
							,ISNULL(RowWise.Src_UID_Major, mmvc.Src_UID_Major) AS Src_UID_Major
							,ISNULL(RowWise.IsValidatedMajor, mmvc.IsValidatedMajor) AS IsValidatedMajor
							,ISNULL(RowWise.LastUpdated, mmvc.LastUpdated) AS LastUpdated
							,CAST(CASE	WHEN RowWise.SrcSys = 1 
										THEN 'https://ryrsomerset.wsht.nhs.uk/CancerRegister/patient_overview.aspx?CareID=' + RowWise.Src_UID
										WHEN RowWise.SrcSys = 2 
										THEN 'https://svvscr01.bsuh.nhs.uk/CancerRegister/patient_overview.aspx?CareID=' + RowWise.Src_UID
										END AS VARCHAR(255)) AS ScrHyperlink
							,ISNULL(RowWise.SrcSys, mmvc.SrcSys) AS SrcSys
							,ISNULL(RowWise.Src_UID, mmvc.Src_UID) AS Src_UID
							,ISNULL(RowWise.FieldName, mmvc.FieldName) AS FieldName
							,RowWise.FieldValue
							,CAST(NULL AS VARCHAR(255)) AS ColumnDesc
							,CAST(NULL AS VARCHAR(255)) AS ColumnGroup
							,CAST(NULL AS SMALLINT) AS ColumnSort
							,CAST(NULL AS TINYINT) AS ColumnGroupSort
							,CAST(NULL AS VARCHAR(1000)) AS ColumnGroupSummary
							,CAST(NULL AS SMALLINT) AS UnseenColumnsWithDiffs
							,CASE WHEN mmvc.SrcSys_Major IS NOT NULL OR ref_aco.SrcSys IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsColumnOverride
				INTO		#Unpivoted
				FROM		(SELECT		d4v.SrcSys_MajorExt
										,d4v.Src_UID_MajorExt
										,d4v.SrcSys_Major
										,d4v.Src_UID_Major
										,d4v.IsValidatedMajor
										,d4v.LastUpdated
										,d4v.SrcSys
										,d4v.Src_UID

										,CARE_ID									= CAST(d4v.CARE_ID AS VARCHAR(8000))
										,PATIENT_ID									= CAST(d4v.PATIENT_ID AS VARCHAR(8000))
										,TEMP_ID									= CAST(d4v.TEMP_ID AS VARCHAR(8000))
										,L_CANCER_SITE								= CAST(d4v.L_CANCER_SITE AS VARCHAR(8000))
										,N2_1_REFERRAL_SOURCE						= CAST(d4v.N2_1_REFERRAL_SOURCE AS VARCHAR(8000))
										,N2_2_ORG_CODE_REF							= CAST(d4v.N2_2_ORG_CODE_REF AS VARCHAR(8000))
										,N2_3_REFERRER_CODE							= CAST(d4v.N2_3_REFERRER_CODE AS VARCHAR(8000))
										,N2_4_PRIORITY_TYPE							= CAST(pt.PRIORITY_DESC AS VARCHAR(8000))
										,N2_5_DECISION_DATE							= CONVERT(VARCHAR(8000), d4v.N2_5_DECISION_DATE,103)
										,N2_6_RECEIPT_DATE							= CONVERT(VARCHAR(8000), d4v.N2_6_RECEIPT_DATE,103)
										,N2_7_CONSULTANT							= CAST(d4v.N2_7_CONSULTANT AS VARCHAR(8000))
										,N2_8_SPECIALTY								= CAST(d4v.N2_8_SPECIALTY AS VARCHAR(8000))
										,N2_9_FIRST_SEEN_DATE						= CONVERT(VARCHAR(8000), d4v.N2_9_FIRST_SEEN_DATE,103)
										,N1_3_ORG_CODE_SEEN							= CAST(d4v.N1_3_ORG_CODE_SEEN AS VARCHAR(8000))
										,N2_10_FIRST_SEEN_DELAY						= CAST(CASE WHEN CWT.Breach62 = 1 THEN DelayReason.DELAY_DESC END AS VARCHAR(8000))
										,N2_12_CANCER_TYPE							= CAST(CType.CANCER_TYPE_DESC AS VARCHAR(8000))
										,N2_13_CANCER_STATUS						= CAST(PStat.STATUS_DESC AS VARCHAR(8000))
										,L_FIRST_APPOINTMENT						= CAST(d4v.L_FIRST_APPOINTMENT AS VARCHAR(8000))
										,L_CANCELLED_DATE							= CONVERT(VARCHAR(8000), CASE WHEN d4v.L_NO_APP = 1 THEN d4v.L_CANCELLED_DATE END,103)
										,N2_14_ADJ_TIME								= CAST(CASE WHEN d4v.L_NO_APP = 1 THEN d4v.N2_14_ADJ_TIME END AS VARCHAR(8000))
										,N2_15_ADJ_REASON							= CAST(CASE WHEN d4v.L_NO_APP = 1 THEN Canx.CANCELLED_DESC END AS VARCHAR(8000))
										,L_REFERRAL_METHOD							= CAST(d4v.L_REFERRAL_METHOD AS VARCHAR(8000))
										,N2_16_OP_REFERRAL							= CAST(opref.REF_DESC AS VARCHAR(8000))
										,L_SPECIALIST_DATE							= CONVERT(VARCHAR(8000), d4v.L_SPECIALIST_DATE, 103)
										,L_ORG_CODE_SPECIALIST						= CAST(d4v.L_ORG_CODE_SPECIALIST AS VARCHAR(8000))
										,L_SPECIALIST_SEEN_DATE						= CONVERT(VARCHAR(8000), d4v.L_SPECIALIST_SEEN_DATE, 103)
										,N1_3_ORG_CODE_SPEC_SEEN					= CAST(d4v.N1_3_ORG_CODE_SPEC_SEEN AS VARCHAR(8000))
										,N_UPGRADE_DATE								= CONVERT(VARCHAR(8000), d4v.N_UPGRADE_DATE,103)
										,N_UPGRADE_ORG_CODE							= CAST(d4v.N_UPGRADE_ORG_CODE AS VARCHAR(8000))
										,L_UPGRADE_WHEN								= CAST(d4v.L_UPGRADE_WHEN AS VARCHAR(8000))
										,L_UPGRADE_WHO								= CAST(d4v.L_UPGRADE_WHO AS VARCHAR(8000))
										,N4_1_DIAGNOSIS_DATE						= CONVERT(VARCHAR(8000), d4v.N4_1_DIAGNOSIS_DATE,103)
										,L_DIAGNOSIS								= CAST(d4v.L_DIAGNOSIS AS VARCHAR(8000))
										,N4_2_DIAGNOSIS_CODE						= CAST(Diag.DIAG_CODE + ' - ' + Diag.DIAG_DESC AS VARCHAR(8000))
										,L_ORG_CODE_DIAGNOSIS						= CAST(d4v.L_ORG_CODE_DIAGNOSIS AS VARCHAR(8000))
										,L_PT_INFORMED_DATE							= CONVERT(VARCHAR(8000), d4v.L_PT_INFORMED_DATE,103)
										,L_OTHER_DIAG_DATE							= CONVERT(VARCHAR(8000), CASE WHEN d4v.N2_13_CANCER_STATUS = '03' THEN d4v.L_OTHER_DIAG_DATE END,103)
										,N4_3_LATERALITY							= CAST(lat.LAT_DESC AS VARCHAR(8000))
										,N4_4_BASIS_DIAGNOSIS						= CAST(d4v.N4_4_BASIS_DIAGNOSIS AS VARCHAR(8000))
										,L_TOPOGRAPHY								= CAST(d4v.L_TOPOGRAPHY AS VARCHAR(8000))
										,L_HISTOLOGY_GROUP							= CAST(d4v.L_HISTOLOGY_GROUP AS VARCHAR(8000))
										,N4_5_HISTOLOGY								= CAST(d4v.N4_5_HISTOLOGY AS VARCHAR(8000))
										,N4_6_DIFFERENTIATION						= CAST(d4v.N4_6_DIFFERENTIATION AS VARCHAR(8000))
										,ClinicalTStage								= CAST(d4v.ClinicalTStage AS VARCHAR(8000))
										,ClinicalTCertainty							= CAST(d4v.ClinicalTCertainty AS VARCHAR(8000))
										,ClinicalNStage								= CAST(d4v.ClinicalNStage AS VARCHAR(8000))
										,ClinicalNCertainty							= CAST(d4v.ClinicalNCertainty AS VARCHAR(8000))
										,ClinicalMStage								= CAST(d4v.ClinicalMStage AS VARCHAR(8000))
										,ClinicalMCertainty							= CAST(d4v.ClinicalMCertainty AS VARCHAR(8000))
										,ClinicalOverallCertainty					= CAST(d4v.ClinicalOverallCertainty AS VARCHAR(8000))
										,N6_9_SITE_CLASSIFICATION					= CAST(d4v.N6_9_SITE_CLASSIFICATION AS VARCHAR(8000))
										,PathologicalOverallCertainty				= CAST(d4v.PathologicalOverallCertainty AS VARCHAR(8000))
										,PathologicalTCertainty						= CAST(d4v.PathologicalTCertainty AS VARCHAR(8000))
										,PathologicalTStage							= CAST(d4v.PathologicalTStage AS VARCHAR(8000))
										,PathologicalNCertainty						= CAST(d4v.PathologicalNCertainty AS VARCHAR(8000))
										,PathologicalNStage							= CAST(d4v.PathologicalNStage AS VARCHAR(8000))
										,PathologicalMCertainty						= CAST(d4v.PathologicalMCertainty AS VARCHAR(8000))
										,PathologicalMStage							= CAST(d4v.PathologicalMStage AS VARCHAR(8000))
										,L_GP_INFORMED								= CAST(d4v.L_GP_INFORMED AS VARCHAR(8000))
										,L_GP_INFORMED_DATE							= CONVERT(VARCHAR(8000), d4v.L_GP_INFORMED_DATE, 103)
										,L_GP_NOT									= CAST(d4v.L_GP_NOT AS VARCHAR(8000))
										,L_REL_INFORMED								= CAST(d4v.L_REL_INFORMED AS VARCHAR(8000))
										,L_NURSE_PRESENT							= CAST(d4v.L_NURSE_PRESENT AS VARCHAR(8000))
										,L_SPEC_NURSE_DATE							= CONVERT(VARCHAR(8000), d4v.L_SPEC_NURSE_DATE, 103)
										,L_SEEN_NURSE_DATE							= CONVERT(VARCHAR(8000), d4v.L_SEEN_NURSE_DATE, 103)
										,N16_1_ADJ_DAYS								= CAST(d4v.N16_1_ADJ_DAYS AS VARCHAR(8000))
										,N16_2_ADJ_DAYS								= CAST(d4v.N16_2_ADJ_DAYS AS VARCHAR(8000))
										,N16_3_ADJ_DECISION_CODE					= CAST(d4v.N16_3_ADJ_DECISION_CODE AS VARCHAR(8000))
										,N16_4_ADJ_TREAT_CODE						= CAST(d4v.N16_4_ADJ_TREAT_CODE AS VARCHAR(8000))
										,N16_5_DECISION_REASON_CODE					= CAST(d4v.N16_5_DECISION_REASON_CODE AS VARCHAR(8000))
										,N16_6_TREATMENT_REASON_CODE				= CAST(d4v.N16_6_TREATMENT_REASON_CODE AS VARCHAR(8000))
										,PathologicalTNMDate						= CONVERT(VARCHAR(8000), d4v.PathologicalTNMDate, 103)
										,ClinicalTNMDate							= CONVERT(VARCHAR(8000), d4v.ClinicalTNMDate, 103)
										,L_FIRST_CONSULTANT							= CAST(d4v.L_FIRST_CONSULTANT AS VARCHAR(8000))
										,L_APPROPRIATE								= CAST(d4v.L_APPROPRIATE AS VARCHAR(8000))
										,L_TERTIARY_DATE							= CONVERT(VARCHAR(8000), d4v.L_TERTIARY_DATE, 103)
										,L_TERTIARY_TRUST							= CAST(d4v.L_TERTIARY_TRUST AS VARCHAR(8000))
										,L_TERTIARY_REASON							= CAST(d4v.L_TERTIARY_REASON AS VARCHAR(8000))
										,L_INAP_REF									= CAST(d4v.L_INAP_REF AS VARCHAR(8000))
										,L_NEW_CA_SITE								= CAST(d4v.L_NEW_CA_SITE AS VARCHAR(8000))
										,L_AUTO_REF									= CAST(d4v.L_AUTO_REF AS VARCHAR(8000))
										,L_SEC_DIAGNOSIS_G							= CAST(d4v.L_SEC_DIAGNOSIS_G AS VARCHAR(8000))
										,L_SEC_DIAGNOSIS							= CAST(d4v.L_SEC_DIAGNOSIS AS VARCHAR(8000))
										,L_WRONG_REF								= CAST(d4v.L_WRONG_REF AS VARCHAR(8000))
										,L_WRONG_REASON								= CAST(d4v.L_WRONG_REASON AS VARCHAR(8000))
										,L_TUMOUR_STATUS							= CAST(TStat.STATUS_DESC AS VARCHAR(8000))
										,L_NON_CANCER								= CAST(d4v.L_NON_CANCER AS VARCHAR(8000))
										,L_FIRST_APP								= CAST(AppType.TYPE_DESC AS VARCHAR(8000))
										,L_NO_APP									= CAST(d4v.L_NO_APP AS VARCHAR(8000))
										,L_DIAG_WHO									= CAST(d4v.L_DIAG_WHO AS VARCHAR(8000))
										,L_RECURRENCE								= CAST(d4v.L_RECURRENCE AS VARCHAR(8000))
										,L_OTHER_SYMPS								= CAST(d4v.L_OTHER_SYMPS AS VARCHAR(8000))
										,L_COMMENTS									= CAST(d4v.L_COMMENTS AS VARCHAR(8000))
										,N2_11_FIRST_SEEN_REASON					= CAST(d4v.N2_11_FIRST_SEEN_REASON AS VARCHAR(8000))
										,N16_7_DECISION_REASON						= CAST(d4v.N16_7_DECISION_REASON AS VARCHAR(8000))
										,N16_8_TREATMENT_REASON						= CAST(d4v.N16_8_TREATMENT_REASON AS VARCHAR(8000))
										,L_DIAGNOSIS_COMMENTS						= CAST(d4v.L_DIAGNOSIS_COMMENTS AS VARCHAR(8000))
										,GP_PRACTICE_CODE							= CAST(d4v.GP_PRACTICE_CODE AS VARCHAR(8000))
										,ClinicalTNMGroup							= CAST(d4v.ClinicalTNMGroup AS VARCHAR(8000))
										,PathologicalTNMGroup						= CAST(d4v.PathologicalTNMGroup AS VARCHAR(8000))
										,L_KEY_WORKER_SEEN							= CAST(d4v.L_KEY_WORKER_SEEN AS VARCHAR(8000))
										,L_PALLIATIVE_SPECIALIST_SEEN				= CAST(d4v.L_PALLIATIVE_SPECIALIST_SEEN AS VARCHAR(8000))
										,GERM_CELL_NON_CNS_ID						= CAST(d4v.GERM_CELL_NON_CNS_ID AS VARCHAR(8000))
										,RECURRENCE_CANCER_SITE_ID					= CAST(d4v.RECURRENCE_CANCER_SITE_ID AS VARCHAR(8000))
										,ICD03_GROUP								= CAST(d4v.ICD03_GROUP AS VARCHAR(8000))
										,ICD03										= CAST(d4v.ICD03 AS VARCHAR(8000))
										,L_DATE_DIAGNOSIS_DAHNO_LUCADA				= CONVERT(VARCHAR(8000), d4v.L_DATE_DIAGNOSIS_DAHNO_LUCADA, 103)
										,L_INDICATOR_CODE							= CAST(d4v.L_INDICATOR_CODE AS VARCHAR(8000))
										,PRIMARY_DIAGNOSIS_SUB_COMMENT				= CAST(d4v.PRIMARY_DIAGNOSIS_SUB_COMMENT AS VARCHAR(8000))
										,CONSULTANT_CODE_AT_DIAGNOSIS				= CAST(d4v.CONSULTANT_CODE_AT_DIAGNOSIS AS VARCHAR(8000))
										,CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS		= CAST(d4v.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS AS VARCHAR(8000))
										,FETOPROTEIN								= CAST(d4v.FETOPROTEIN AS VARCHAR(8000))
										,GONADOTROPIN								= CAST(d4v.GONADOTROPIN AS VARCHAR(8000))
										,GONADOTROPIN_SERUM							= CAST(d4v.GONADOTROPIN_SERUM AS VARCHAR(8000))
										,FETOPROTEIN_SERUM							= CAST(d4v.FETOPROTEIN_SERUM AS VARCHAR(8000))
										,SARCOMA_TUMOUR_SITE_BONE					= CAST(d4v.SARCOMA_TUMOUR_SITE_BONE AS VARCHAR(8000))
										,SARCOMA_TUMOUR_SITE_SOFT_TISSUE			= CAST(d4v.SARCOMA_TUMOUR_SITE_SOFT_TISSUE AS VARCHAR(8000))
										,SARCOMA_TUMOUR_SUBSITE_BONE				= CAST(d4v.SARCOMA_TUMOUR_SUBSITE_BONE AS VARCHAR(8000))
										,SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE			= CAST(d4v.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE AS VARCHAR(8000))
										,ROOT_DECISION_DATE_COMMENTS				= CONVERT(VARCHAR(8000), d4v.ROOT_DECISION_DATE_COMMENTS, 103)
										,ROOT_RECEIPT_DATE_COMMENTS					= CONVERT(VARCHAR(8000), d4v.ROOT_RECEIPT_DATE_COMMENTS, 103)
										,ROOT_FIRST_SEEN_DATE_COMMENTS				= CONVERT(VARCHAR(8000), d4v.ROOT_FIRST_SEEN_DATE_COMMENTS, 103)
										,ROOT_DIAGNOSIS_DATE_COMMENTS				= CONVERT(VARCHAR(8000), d4v.ROOT_DIAGNOSIS_DATE_COMMENTS, 103)
										,ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS		= CONVERT(VARCHAR(8000), d4v.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS, 103)
										,ROOT_UPGRADE_COMMENTS						= CAST(d4v.ROOT_UPGRADE_COMMENTS AS VARCHAR(8000))
										,FIRST_APPT_TIME							= CAST(d4v.FIRST_APPT_TIME AS VARCHAR(8000))
										,TRANSFER_REASON							= CAST(d4v.TRANSFER_REASON AS VARCHAR(8000))
										,DATE_NEW_REFERRAL							= CONVERT(VARCHAR(8000), d4v.DATE_NEW_REFERRAL, 103)
										,TUMOUR_SITE_NEW							= CAST(d4v.TUMOUR_SITE_NEW AS VARCHAR(8000))
										,DATE_TRANSFER_ACTIONED						= CONVERT(VARCHAR(8000), d4v.DATE_TRANSFER_ACTIONED, 103)
										,SOURCE_CARE_ID								= CAST(d4v.SOURCE_CARE_ID AS VARCHAR(8000))
										,ADT_REF_ID									= CAST(d4v.ADT_REF_ID AS VARCHAR(8000))
										,ACTION_ID									= CAST(d4v.ACTION_ID AS VARCHAR(8000))
										,DIAGNOSIS_ACTION_ID						= CAST(d4v.DIAGNOSIS_ACTION_ID AS VARCHAR(8000))
										,ORIGINAL_SOURCE_CARE_ID					= CAST(d4v.ORIGINAL_SOURCE_CARE_ID AS VARCHAR(8000))
										,TRANSFER_DATE_COMMENTS						= CONVERT(VARCHAR(8000), d4v.TRANSFER_DATE_COMMENTS, 103)
										,SPECIALIST_REFERRAL_COMMENTS				= CAST(d4v.SPECIALIST_REFERRAL_COMMENTS AS VARCHAR(8000))
										,NON_CANCER_DIAGNOSIS_CHAPTER				= CAST(d4v.NON_CANCER_DIAGNOSIS_CHAPTER AS VARCHAR(8000))
										,NON_CANCER_DIAGNOSIS_GROUP					= CAST(d4v.NON_CANCER_DIAGNOSIS_GROUP AS VARCHAR(8000))
										,NON_CANCER_DIAGNOSIS_CODE					= CAST(d4v.NON_CANCER_DIAGNOSIS_CODE AS VARCHAR(8000))
										,TNM_UNKNOWN								= CAST(d4v.TNM_UNKNOWN AS VARCHAR(8000))
										,ReferringPractice							= CAST(d4v.ReferringPractice AS VARCHAR(8000))
										,ReferringGP								= CAST(d4v.ReferringGP AS VARCHAR(8000))
										,ReferringBranch							= CAST(d4v.ReferringBranch AS VARCHAR(8000))
										,BankedTissue								= CAST(d4v.BankedTissue AS VARCHAR(8000))
										,BankedTissueTumour							= CAST(d4v.BankedTissueTumour AS VARCHAR(8000))
										,BankedTissueBlood							= CAST(d4v.BankedTissueBlood AS VARCHAR(8000))
										,BankedTissueCSF							= CAST(d4v.BankedTissueCSF AS VARCHAR(8000))
										,BankedTissueBoneMarrow						= CAST(d4v.BankedTissueBoneMarrow AS VARCHAR(8000))
										,SNOMed_CT									= CAST(d4v.SNOMed_CT AS VARCHAR(8000))
										,ADT_PLACER_ID								= CAST(d4v.ADT_PLACER_ID AS VARCHAR(8000))
										,SNOMEDCTDiagnosisID						= CAST(d4v.SNOMEDCTDiagnosisID AS VARCHAR(8000))
										,FasterDiagnosisOrganisationID				= CAST(FDorg.Description AS VARCHAR(8000))
										,FasterDiagnosisCancerSiteOverrideID		= CAST(d4v.FasterDiagnosisCancerSiteOverrideID AS VARCHAR(8000))
										,FasterDiagnosisExclusionDate				= CONVERT(VARCHAR(8000), d4v.FasterDiagnosisExclusionDate, 103)
										,FasterDiagnosisExclusionReasonID			= CAST(fder.Description AS VARCHAR(8000))
										,FasterDiagnosisDelayReasonID				= CAST(fddr.Description AS VARCHAR(8000))
										,FasterDiagnosisDelayReasonComments			= CAST(d4v.FasterDiagnosisDelayReasonComments AS VARCHAR(8000))
										,FasterDiagnosisCommunicationMethodID		= CAST(fdcm.Description AS VARCHAR(8000))
										,FasterDiagnosisInformingCareProfessionalID	= CAST(cp.Description AS VARCHAR(8000))
										,FasterDiagnosisOtherCareProfessional		= CAST(d4v.FasterDiagnosisOtherCareProfessional AS VARCHAR(8000))
										,FasterDiagnosisOtherCommunicationMethod	= CAST(d4v.FasterDiagnosisOtherCommunicationMethod AS VARCHAR(8000))
										--,DEPRECATED_20_01_RecurrenceMetastaticType	= CAST(d4v.DEPRECATED_20_01_RecurrenceMetastaticType AS VARCHAR(8000))
										,NonPrimaryPathwayOptionsID					= CAST(d4v.NonPrimaryPathwayOptionsID AS VARCHAR(8000))
										,DiagnosisUncertainty						= CAST(d4v.DiagnosisUncertainty AS VARCHAR(8000))
										,TNMOrganisation							= CAST(d4v.TNMOrganisation AS VARCHAR(8000))
										,FasterDiagnosisTargetRCComments			= CAST(d4v.FasterDiagnosisTargetRCComments AS VARCHAR(8000))
										,FasterDiagnosisEndRCComments				= CAST(d4v.FasterDiagnosisEndRCComments AS VARCHAR(8000))
										,TNMOrganisation_Integrated					= CAST(d4v.TNMOrganisation_Integrated AS VARCHAR(8000))
										,LDHValue									= CAST(d4v.LDHValue AS VARCHAR(8000))
										--,DEPRECATED_20_01_LDH_NORMAL				= CAST(d4v.DEPRECATED_20_01_LDH_NORMAL AS VARCHAR(8000))
										,BankedTissueUrine							= CAST(d4v.BankedTissueUrine AS VARCHAR(8000))
										,SubsiteID									= CAST(crs.Description AS VARCHAR(8000))
										,PredictedBreachStatus						= CAST(d4v.PredictedBreachStatus AS VARCHAR(8000))
										,RMRefID									= CAST(d4v.RMRefID AS VARCHAR(8000))
										,TertiaryReferralKey						= CAST(d4v.TertiaryReferralKey AS VARCHAR(8000))
										,ClinicalTLetter							= CAST(d4v.ClinicalTLetter AS VARCHAR(8000))
										,ClinicalNLetter							= CAST(d4v.ClinicalNLetter AS VARCHAR(8000))
										,ClinicalMLetter							= CAST(d4v.ClinicalMLetter AS VARCHAR(8000))
										,PathologicalTLetter						= CAST(d4v.PathologicalTLetter AS VARCHAR(8000))
										,PathologicalNLetter						= CAST(d4v.PathologicalNLetter AS VARCHAR(8000))
										,PathologicalMLetter						= CAST(d4v.PathologicalMLetter AS VARCHAR(8000))
										,FDPlannedInterval							= CAST(d4v.FDPlannedInterval AS VARCHAR(8000))
										,LabReportDate								= CONVERT(VARCHAR(8000), d4v.LabReportDate, 103)
										,LabReportOrgID								= CAST(d4v.LabReportOrgID AS VARCHAR(8000))
										,ReferralRoute								= CAST(d4v.ReferralRoute AS VARCHAR(8000))
										,ReferralOtherRoute							= CAST(d4v.ReferralOtherRoute AS VARCHAR(8000))
										,RelapseMorphology							= CAST(d4v.RelapseMorphology AS VARCHAR(8000))
										,RelapseFlow								= CAST(d4v.RelapseFlow AS VARCHAR(8000))
										,RelapseMolecular							= CAST(d4v.RelapseMolecular AS VARCHAR(8000))
										,RelapseClinicalExamination					= CAST(d4v.RelapseClinicalExamination AS VARCHAR(8000))
										,RelapseOther								= CAST(d4v.RelapseOther AS VARCHAR(8000))
										,RapidDiagnostic							= CAST(d4v.RapidDiagnostic AS VARCHAR(8000))
										,PrimaryReferralFlag						= CAST(d4v.PrimaryReferralFlag AS VARCHAR(8000))
										,OtherAssessedBy							= CAST(d4v.OtherAssessedBy AS VARCHAR(8000))
										,SharedBreach								= CAST(d4v.SharedBreach AS VARCHAR(8000))
										,PredictedBreachYear						= CAST(d4v.PredictedBreachYear AS VARCHAR(8000))
										,PredictedBreachMonth						= CAST(d4v.PredictedBreachMonth AS VARCHAR(8000))
							FROM		#DataForValidation d4v
							LEFT JOIN	Merge_DM_MatchViews.ltblPRIORITY_TYPE pt
																			ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = pt.SrcSysID
																			AND	d4v.N2_4_PRIORITY_TYPE COLLATE DATABASE_DEFAULT = pt.PRIORITY_CODE COLLATE DATABASE_DEFAULT
							LEFT JOIN	Merge_DM_MatchViews.ltblCANCER_TYPE CType
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = CType.SrcSysID
																		AND	d4v.N2_12_CANCER_TYPE COLLATE DATABASE_DEFAULT = CType.CANCER_TYPE_CODE COLLATE DATABASE_DEFAULT
							LEFT JOIN	Merge_DM_MatchViews.ltblSTATUS PStat
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = PStat.SrcSysID
																		AND	d4v.N2_13_CANCER_STATUS COLLATE DATABASE_DEFAULT = PStat.STATUS_CODE COLLATE DATABASE_DEFAULT
							LEFT JOIN	Merge_DM_MatchViews.ltblOUT_PATIENT_REFERRAL opref
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = opref.SrcSysID
																		AND	d4v.N2_16_OP_REFERRAL COLLATE DATABASE_DEFAULT = opref.REF_CODE COLLATE DATABASE_DEFAULT
							LEFT JOIN	Merge_DM_MatchViews.ltblAPP_TYPE AppType
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = AppType.SrcSysID
																		AND	d4v.L_FIRST_APP = AppType.TYPE_CODE
							LEFT JOIN	Merge_DM_MatchViews.CancerReferralSubsites crs
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = crs.SrcSysID
																		AND	d4v.SubsiteID = crs.ID
							LEFT JOIN	Merge_DM_MatchViews.ltblDELAY_REASON DelayReason
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = DelayReason.SrcSysID
																		AND	d4v.N2_10_FIRST_SEEN_DELAY COLLATE DATABASE_DEFAULT = DelayReason.DELAY_CODE COLLATE DATABASE_DEFAULT
							LEFT JOIN	Merge_DM_MatchViews.ltblCANCELLATION Canx
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = Canx.SrcSysID
																		AND	d4v.N2_15_ADJ_REASON = Canx.CANCELLED_CODE
							LEFT JOIN	Merge_DM_MatchViews.ltblDIAGNOSIS Diag
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = Diag.SrcSysID
																		AND	d4v.N4_2_DIAGNOSIS_CODE COLLATE DATABASE_DEFAULT = Diag.DIAG_CODE COLLATE DATABASE_DEFAULT
							LEFT JOIN	Merge_DM_MatchViews.ltblLATERALITY lat
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = lat.SrcSysID
																		AND	d4v.N4_3_LATERALITY COLLATE DATABASE_DEFAULT = lat.LAT_CODE COLLATE DATABASE_DEFAULT
							LEFT JOIN	Merge_DM_MatchViews.ltblCA_STATUS TStat
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = TStat.SrcSysID
																		AND	d4v.L_TUMOUR_STATUS = TStat.STATUS_CODE
							LEFT JOIN	Merge_DM_MatchViews.ltblFasterDiagnosisCommunicationMethod fdcm
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = fdcm.SrcSysID
																		AND	d4v.FasterDiagnosisCommunicationMethodID = fdcm.ID
							LEFT JOIN	Merge_DM_MatchViews.ltblCareProfessional cp
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = cp.SrcSysID
																		AND	d4v.FasterDiagnosisInformingCareProfessionalID = cp.ID
							LEFT JOIN	(SELECT 1 AS Map_SrcSys, ID AS Map_ID, * FROM SCR_DW.SCR.dbo_OrganisationSites
										UNION ALL
										SELECT 2 AS Map_SrcSys, DW_SOURCE_PATIENT_ID AS Map_ID, * FROM SCR_DW.SCR.dbo_OrganisationSites WHERE DW_SOURCE_PATIENT_ID IS NOT NULL
													) FDorg
															ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = FDorg.Map_SrcSys
															AND	d4v.FasterDiagnosisOrganisationID = FDorg.Map_ID
							LEFT JOIN	Merge_DM_MatchViews.ltblFasterDiagnosisExclusionReason fder
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = fder.SrcSysID
																		AND	d4v.FasterDiagnosisExclusionReasonID = fder.ID
							LEFT JOIN	Merge_DM_MatchViews.ltblFasterDiagnosisDelayReason fddr
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = fddr.SrcSysID
																		AND	d4v.FasterDiagnosisDelayReasonID = fddr.ID
							LEFT JOIN	SCR_Warehouse.SCR_CWT CWT
																ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = CWT.SrcSysID
																AND	d4v.CARE_ID = CWT.CARE_ID
																AND	CWT.cwtFlag62 IN (0,1,2)
										) UnpivotPrepare
							UNPIVOT		(FieldValue FOR FieldName IN
												(CARE_ID
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
												--,DEPRECATED_20_01_RecurrenceMetastaticType
												,NonPrimaryPathwayOptionsID
												,DiagnosisUncertainty
												,TNMOrganisation
												,FasterDiagnosisTargetRCComments
												,FasterDiagnosisEndRCComments
												,TNMOrganisation_Integrated
												,LDHValue
												--,DEPRECATED_20_01_LDH_NORMAL
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
												,PredictedBreachMonth
												)
										) AS RowWise
				INNER JOIN	#ColumnDetails cols
												ON	RowWise.FieldName COLLATE DATABASE_DEFAULT = cols.ColumnName COLLATE DATABASE_DEFAULT
				LEFT JOIN	#tblMAIN_REFERRALS_AutoColumnOverrides ref_aco
																		ON	RowWise.SrcSys_MajorExt = ref_aco.SrcSys_MajorExt
																		AND	RowWise.Src_UID_MajorExt COLLATE DATABASE_DEFAULT = ref_aco.Src_UID_MajorExt COLLATE DATABASE_DEFAULT
																		AND	RowWise.SrcSys = ref_aco.SrcSys
																		AND	RowWise.Src_UID COLLATE DATABASE_DEFAULT = ref_aco.Src_UID COLLATE DATABASE_DEFAULT
																		AND	RowWise.FieldName COLLATE DATABASE_DEFAULT = ref_aco.FieldName COLLATE DATABASE_DEFAULT
				FULL JOIN		(SELECT		d4v_inner.SrcSys_MajorExt
											,d4v_inner.Src_UID_MajorExt
											,d4v_inner.SrcSys_Major
											,d4v_inner.Src_UID_Major
											,d4v_inner.IsValidatedMajor
											,d4v_inner.LastUpdated
											,d4v_inner.SrcSys
											,d4v_inner.Src_UID
											,mmvc_inner.FieldName
								FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidationColumns mmvc_inner
								INNER JOIN	#DataForValidation d4v_inner
																	ON	mmvc_inner.SrcSys_Major = d4v_inner.SrcSys_MajorExt
																	AND	mmvc_inner.Src_UID_Major = d4v_inner.Src_UID_MajorExt
																	AND	mmvc_inner.SrcSys = d4v_inner.SrcSys
																	AND	mmvc_inner.Src_UID = d4v_inner.Src_UID
																	AND	d4v_inner.IsValidatedMajor = 0
								INNER JOIN	#ColumnDetails cols_inner
																	ON	mmvc_inner.FieldName COLLATE DATABASE_DEFAULT = cols_inner.ColumnName COLLATE DATABASE_DEFAULT
											) mmvc
													ON	RowWise.SrcSys_MajorExt = mmvc.SrcSys_MajorExt
													AND	RowWise.Src_UID_MajorExt COLLATE DATABASE_DEFAULT = mmvc.Src_UID_MajorExt COLLATE DATABASE_DEFAULT
													AND	RowWise.SrcSys = mmvc.SrcSys
													AND	RowWise.Src_UID COLLATE DATABASE_DEFAULT = mmvc.Src_UID COLLATE DATABASE_DEFAULT
													AND	RowWise.FieldName COLLATE DATABASE_DEFAULT = mmvc.FieldName COLLATE DATABASE_DEFAULT

				-- Add the Columns data
				UPDATE		up
				SET			ColumnDesc			= cols.ColumnDesc
							,ColumnGroup		= cols.ColumnGroup
							,up.ColumnSort		= cols.ColumnSort
							,ColumnGroupSort	= cols.ColumnGroupSort
				FROM		#Unpivoted up
				INNER JOIN	#ColumnDetails cols
												ON	up.FieldName COLLATE DATABASE_DEFAULT = cols.ColumnName COLLATE DATABASE_DEFAULT

				-- Add the Group Summary data
				UPDATE		up
				SET			ColumnGroupSummary	= CASE	WHEN up.ColumnGroup = 'Initial Referral'
														THEN CONCAT_WS('¿', d4v.L_CANCER_SITE, pt.PRIORITY_DESC)
														WHEN up.ColumnGroup = 'Additional Info'
														THEN '-'
														WHEN up.ColumnGroup = 'Diagnosis'
														THEN CONCAT_WS('¿', d4v.N4_2_DIAGNOSIS_CODE, CONVERT(VARCHAR(255), d4v.N4_1_DIAGNOSIS_DATE, 103))
														WHEN up.ColumnGroup = 'Faster Diagnosis'
														THEN ISNULL(FDorg.Description, '-')
														WHEN up.ColumnGroup = 'Staging'
														THEN ISNULL(CONCAT_WS('', 'T', d4v.ClinicalTStage, '-N', d4v.ClinicalNStage, '-M', d4v.ClinicalMStage,'¿',CONVERT(VARCHAR(1000), d4v.ClinicalTNMDate, 103)), '-')
														END
				FROM		#Unpivoted up
				LEFT JOIN	#DataForValidation d4v
													ON	up.SrcSys = d4v.SrcSys
													AND	up.Src_UID = d4v.Src_UID
													AND	up.IsValidatedMajor = d4v.IsValidatedMajor
				LEFT JOIN	Merge_DM_MatchViews.ltblPRIORITY_TYPE pt
																ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = pt.SrcSysID
																AND	d4v.N2_4_PRIORITY_TYPE COLLATE DATABASE_DEFAULT = pt.PRIORITY_CODE COLLATE DATABASE_DEFAULT
				LEFT JOIN	(SELECT 1 AS Map_SrcSys, ID AS Map_ID, * FROM SCR_DW.SCR.dbo_OrganisationSites
							UNION ALL
							SELECT 2 AS Map_SrcSys, DW_SOURCE_PATIENT_ID AS Map_ID, * FROM SCR_DW.SCR.dbo_OrganisationSites WHERE DW_SOURCE_PATIENT_ID IS NOT NULL
										) FDorg
												ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = FDorg.Map_SrcSys
												AND	d4v.FasterDiagnosisOrganisationID = FDorg.Map_ID

				-- Add the count of unseen columns with different data
				UPDATE		up
				SET			UnseenColumnsWithDiffs = ISNULL(UnseenColumnsWithDiffs.UnseenColumnsWithDiffs, 0)
				FROM		#Unpivoted up
				LEFT JOIN	(SELECT		FieldsPerColumnGroup.SrcSys_MajorExt
										,FieldsPerColumnGroup.Src_UID_MajorExt
										,FieldsPerColumnGroup.ColumnGroup
										,COUNT(*) AS UnseenColumnsWithDiffs
							FROM		(SELECT		ValuesPerField.SrcSys_MajorExt
													,ValuesPerField.Src_UID_MajorExt
													,ValuesPerField.ColumnGroup
													,ValuesPerField.FieldName
										FROM		(SELECT		up_inner.SrcSys_MajorExt
																,up_inner.Src_UID_MajorExt
																,up_inner.ColumnGroup
																,up_inner.FieldName
																,up_inner.FieldValue
																,COUNT(*) AS Prevalence
													FROM		#Unpivoted up_inner
													GROUP BY	up_inner.SrcSys_MajorExt
																,up_inner.Src_UID_MajorExt
																,up_inner.ColumnGroup
																,up_inner.FieldName
																,up_inner.FieldValue
																) ValuesPerField
										--WHERE		ValuesPerField.FieldName NOT IN ('L_CANCER_SITE', 'N2_4_PRIORITY_TYPE', 'N4_2_DIAGNOSIS_CODE', 'N4_1_DIAGNOSIS_DATE', 'FasterDiagnosisOrganisationID'
										--										, 'ClinicalTStage', 'ClinicalNStage', 'ClinicalMStage', 'ClinicalTNMDate')
										GROUP BY	ValuesPerField.SrcSys_MajorExt
													,ValuesPerField.Src_UID_MajorExt
													,ValuesPerField.ColumnGroup
													,ValuesPerField.FieldName
										HAVING		COUNT(*) > 1
										OR			SUM(ValuesPerField.Prevalence) < (SELECT COUNT(*) FROM #DataForValidation)
													) FieldsPerColumnGroup
							GROUP BY	FieldsPerColumnGroup.SrcSys_MajorExt
										,FieldsPerColumnGroup.Src_UID_MajorExt
										,FieldsPerColumnGroup.ColumnGroup
										) UnseenColumnsWithDiffs
																ON	up.SrcSys_MajorExt = UnseenColumnsWithDiffs.SrcSys_MajorExt
																AND	up.Src_UID_MajorExt = UnseenColumnsWithDiffs.Src_UID_MajorExt
																AND	up.ColumnGroup = UnseenColumnsWithDiffs.ColumnGroup

				-- Return the unpivoted data for SSRS
				SELECT		up.ReportingCohort
							,up.SrcSys_MajorExt
							,up.Src_UID_MajorExt
							,up.SrcSys_Major
							,up.Src_UID_Major
							,up.IsValidatedMajor
							,up.LastUpdated
							,up.ScrHyperlink
							,up.SrcSys
							,up.Src_UID
							,up.FieldName
							,up.FieldValue
							,up.ColumnDesc
							,up.ColumnGroup
							,up.ColumnSort
							,up.ColumnGroupSort
							,up.ColumnGroupSummary
							,up.UnseenColumnsWithDiffs
							,up.IsColumnOverride
				FROM		#Unpivoted up

		END





GO
