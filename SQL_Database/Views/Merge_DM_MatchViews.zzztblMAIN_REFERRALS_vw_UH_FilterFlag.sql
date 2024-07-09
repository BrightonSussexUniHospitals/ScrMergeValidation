SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [Merge_DM_MatchViews].[zzztblMAIN_REFERRALS_vw_UH_FilterFlag] AS	

		SELECT		-- Source ID's to go back to match
					IsSCR								= CAST(1 AS BIT)
					,SrcSys								= mainref.SrcSysID
					,Src_UID							= CAST(mainref.CARE_ID AS VARCHAR(255))
					,LinkedCareID						= ISNULL(LR.OriginalCareID,mainref.CARE_ID) 
					,PatientPathwayID					= dt.PATHWAY_ID	-- Pathway ID from definitive treatment table
					,HospitalNumber						= ISNULL(dem_val_maj.N1_2_HOSPITAL_NUMBER, dem.N1_2_HOSPITAL_NUMBER)
					,NHSNumber							= ISNULL(dem_val_maj.N1_1_NHS_NUMBER, dem.N1_1_NHS_NUMBER)
					,NotRecurrence						= CASE WHEN mainref.L_TUMOUR_STATUS != 4 THEN 1 ELSE NULL END
					-- Unique interface ID's to try matching for WOR / SRH duplicates
					,ADT_REF_ID_SameSys					= CAST(mainref.SrcSysID AS VARCHAR(255)) + '|' + CASE WHEN mainref.ADT_REF_ID NOT IN ('', '0') THEN mainref.ADT_REF_ID END
					,ADT_PLACER_ID_SameSys				= CAST(mainref.SrcSysID AS VARCHAR(255)) + '|' + CASE WHEN mainref.ADT_PLACER_ID NOT IN ('', '0') THEN mainref.ADT_PLACER_ID END
					,FasterDiagnosisOrganisationCode	= fd_org.Code	
					,FasterDiagnosisExclusionReasonCode	= mainref.FasterDiagnosisExclusionReasonID	
					,LastUpdated	= aud.ACTION_DATE
					,HashBytesValue	= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																		,dt.PATHWAY_ID
																		,ISNULL(dem_val_maj.N1_1_NHS_NUMBER, dem.N1_1_NHS_NUMBER)
																		,ISNULL(dem_val_maj.N1_2_HOSPITAL_NUMBER, dem.N1_2_HOSPITAL_NUMBER)
																		,mainref.L_CANCER_SITE
																		,mainref.N2_4_PRIORITY_TYPE
																		,CONVERT(VARCHAR(255), mainref.N2_6_RECEIPT_DATE, 126)
																		,CONVERT(VARCHAR(255), mainref.N2_5_DECISION_DATE, 126)
																		,mainref.ADT_REF_ID
																		,mainref.ADT_PLACER_ID
																		,mainref.N2_1_REFERRAL_SOURCE
																		,mainref.N2_12_CANCER_TYPE
																		,mainref.N2_13_CANCER_STATUS
																		,CONVERT(VARCHAR(255), mainref.N2_9_FIRST_SEEN_DATE, 126)
																		,mainref.N1_3_ORG_CODE_SEEN
																		,CONVERT(VARCHAR(255), mainref.L_OTHER_DIAG_DATE, 126)
																		,CONVERT(VARCHAR(255), mainref.N_UPGRADE_DATE, 126)
																		,mainref.N_UPGRADE_ORG_CODE
																		,CONVERT(VARCHAR(255), mainref.N4_1_DIAGNOSIS_DATE, 126)
																		,mainref.L_DIAGNOSIS
																		,mainref.L_ORG_CODE_DIAGNOSIS
																		,mainref.N4_2_DIAGNOSIS_CODE
																		,CONVERT(VARCHAR(255), mainref.L_PT_INFORMED_DATE, 126)
																		,mainref.FasterDiagnosisOrganisationID
																		,mainref.FasterDiagnosisExclusionReasonID
																		))

					---- Bring across later if needed	
					,mainref.CARE_ID
					,mainref.PATIENT_ID
					,mainref.TEMP_ID
					,mainref.L_CANCER_SITE
					,mainref.N2_1_REFERRAL_SOURCE
					,mainref.N2_2_ORG_CODE_REF
					,mainref.N2_3_REFERRER_CODE
					,mainref.N2_4_PRIORITY_TYPE
					,mainref.N2_5_DECISION_DATE
					,mainref.N2_6_RECEIPT_DATE
					,mainref.N2_7_CONSULTANT
					,mainref.N2_8_SPECIALTY
					,mainref.N2_9_FIRST_SEEN_DATE
					,mainref.N1_3_ORG_CODE_SEEN
					,mainref.N2_10_FIRST_SEEN_DELAY
					,mainref.N2_12_CANCER_TYPE	-- national suspected cancer type
					,mainref.N2_13_CANCER_STATUS	-- national status code (suspected, first, subs, recur, trans, prog + no plan, nhs plan, no nhs plan, commenced)
					,mainref.L_FIRST_APPOINTMENT
					,mainref.L_CANCELLED_DATE
					,mainref.N2_14_ADJ_TIME
					,mainref.N2_15_ADJ_REASON
					,mainref.L_REFERRAL_METHOD
					,mainref.N2_16_OP_REFERRAL
					,mainref.L_SPECIALIST_DATE
					,mainref.L_ORG_CODE_SPECIALIST
					,mainref.L_SPECIALIST_SEEN_DATE
					,mainref.N1_3_ORG_CODE_SPEC_SEEN
					,mainref.N_UPGRADE_DATE
					,mainref.N_UPGRADE_ORG_CODE
					,mainref.L_UPGRADE_WHEN
					,mainref.L_UPGRADE_WHO
					,mainref.N4_1_DIAGNOSIS_DATE
					,mainref.L_DIAGNOSIS
					,mainref.N4_2_DIAGNOSIS_CODE
					,mainref.L_ORG_CODE_DIAGNOSIS
					,mainref.L_PT_INFORMED_DATE
					,mainref.L_OTHER_DIAG_DATE			-- Date no cancer
					,mainref.N4_3_LATERALITY
					,mainref.N4_4_BASIS_DIAGNOSIS
					,mainref.L_TOPOGRAPHY
					,mainref.L_HISTOLOGY_GROUP
					,mainref.N4_5_HISTOLOGY
					,mainref.N4_6_DIFFERENTIATION
					,mainref.ClinicalTStage
					,mainref.ClinicalTCertainty
					,mainref.ClinicalNStage
					,mainref.ClinicalNCertainty
					,mainref.ClinicalMStage
					,mainref.ClinicalMCertainty
					,mainref.ClinicalOverallCertainty
					,mainref.N6_9_SITE_CLASSIFICATION
					,mainref.PathologicalOverallCertainty
					,mainref.PathologicalTCertainty
					,mainref.PathologicalTStage
					,mainref.PathologicalNCertainty
					,mainref.PathologicalNStage
					,mainref.PathologicalMCertainty
					,mainref.PathologicalMStage
					,mainref.L_GP_INFORMED
					,mainref.L_GP_INFORMED_DATE
					,mainref.L_GP_NOT
					,mainref.L_REL_INFORMED
					,mainref.L_NURSE_PRESENT
					,mainref.L_SPEC_NURSE_DATE
					,mainref.L_SEEN_NURSE_DATE
					,mainref.N16_1_ADJ_DAYS
					,mainref.N16_2_ADJ_DAYS
					,mainref.N16_3_ADJ_DECISION_CODE
					,mainref.N16_4_ADJ_TREAT_CODE
					,mainref.N16_5_DECISION_REASON_CODE
					,mainref.N16_6_TREATMENT_REASON_CODE
					,mainref.PathologicalTNMDate
					,mainref.ClinicalTNMDate
					,mainref.L_FIRST_CONSULTANT
					,mainref.L_APPROPRIATE
					,mainref.L_TERTIARY_DATE
					,mainref.L_TERTIARY_TRUST
					,mainref.L_TERTIARY_REASON
					,mainref.L_INAP_REF
					,mainref.L_NEW_CA_SITE
					,mainref.L_AUTO_REF
					,mainref.L_SEC_DIAGNOSIS_G
					,mainref.L_SEC_DIAGNOSIS
					,mainref.L_WRONG_REF
					,mainref.L_WRONG_REASON
					,mainref.L_TUMOUR_STATUS
					,mainref.L_NON_CANCER
					,mainref.L_FIRST_APP
					,mainref.L_NO_APP
					,mainref.L_DIAG_WHO
					,mainref.L_RECURRENCE
					,mainref.L_OTHER_SYMPS
					,mainref.L_COMMENTS
					,mainref.N2_11_FIRST_SEEN_REASON
					,mainref.N16_7_DECISION_REASON
					,mainref.N16_8_TREATMENT_REASON
					,mainref.L_DIAGNOSIS_COMMENTS
					,mainref.GP_PRACTICE_CODE
					,mainref.ClinicalTNMGroup
					,mainref.PathologicalTNMGroup
					,mainref.L_KEY_WORKER_SEEN
					,mainref.L_PALLIATIVE_SPECIALIST_SEEN
					,mainref.GERM_CELL_NON_CNS_ID
					,mainref.RECURRENCE_CANCER_SITE_ID
					,mainref.ICD03_GROUP
					,mainref.ICD03
					,mainref.L_DATE_DIAGNOSIS_DAHNO_LUCADA
					,mainref.L_INDICATOR_CODE
					,mainref.PRIMARY_DIAGNOSIS_SUB_COMMENT
					,mainref.CONSULTANT_CODE_AT_DIAGNOSIS
					,mainref.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS
					,mainref.FETOPROTEIN
					,mainref.GONADOTROPIN
					,mainref.GONADOTROPIN_SERUM
					,mainref.FETOPROTEIN_SERUM
					,mainref.SARCOMA_TUMOUR_SITE_BONE
					,mainref.SARCOMA_TUMOUR_SITE_SOFT_TISSUE
					,mainref.SARCOMA_TUMOUR_SUBSITE_BONE
					,mainref.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
					,mainref.ROOT_DECISION_DATE_COMMENTS
					,mainref.ROOT_RECEIPT_DATE_COMMENTS
					,mainref.ROOT_FIRST_SEEN_DATE_COMMENTS
					,mainref.ROOT_DIAGNOSIS_DATE_COMMENTS
					,mainref.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS
					,mainref.ROOT_UPGRADE_COMMENTS
					,mainref.FIRST_APPT_TIME
					,mainref.TRANSFER_REASON
					,mainref.DATE_NEW_REFERRAL
					,mainref.TUMOUR_SITE_NEW
					,mainref.DATE_TRANSFER_ACTIONED
					,mainref.SOURCE_CARE_ID
					,mainref.ADT_REF_ID
					,mainref.ACTION_ID
					,mainref.DIAGNOSIS_ACTION_ID
					,mainref.ORIGINAL_SOURCE_CARE_ID
					,mainref.TRANSFER_DATE_COMMENTS
					,mainref.SPECIALIST_REFERRAL_COMMENTS
					,mainref.NON_CANCER_DIAGNOSIS_CHAPTER
					,mainref.NON_CANCER_DIAGNOSIS_GROUP
					,mainref.NON_CANCER_DIAGNOSIS_CODE
					,mainref.TNM_UNKNOWN
					,mainref.ReferringPractice
					,mainref.ReferringGP
					,mainref.ReferringBranch
					,mainref.BankedTissue
					,mainref.BankedTissueTumour
					,mainref.BankedTissueBlood
					,mainref.BankedTissueCSF
					,mainref.BankedTissueBoneMarrow
					,mainref.SNOMed_CT
					,mainref.ADT_PLACER_ID
					,mainref.SNOMEDCTDiagnosisID
					,mainref.FasterDiagnosisOrganisationID
					,mainref.FasterDiagnosisCancerSiteOverrideID
					,mainref.FasterDiagnosisExclusionDate
					,mainref.FasterDiagnosisExclusionReasonID
					,mainref.FasterDiagnosisDelayReasonID
					,mainref.FasterDiagnosisDelayReasonComments
					,mainref.FasterDiagnosisCommunicationMethodID
					,mainref.FasterDiagnosisInformingCareProfessionalID
					,mainref.FasterDiagnosisOtherCareProfessional
					,mainref.FasterDiagnosisOtherCommunicationMethod
					--,mainref.DEPRECATED_20_01_RecurrenceMetastaticType
					,mainref.NonPrimaryPathwayOptionsID
					,mainref.DiagnosisUncertainty
					,mainref.TNMOrganisation
					,mainref.FasterDiagnosisTargetRCComments
					,mainref.FasterDiagnosisEndRCComments
					,mainref.TNMOrganisation_Integrated
					,mainref.LDHValue
					--,mainref.DEPRECATED_20_01_LDH_NORMAL
					,mainref.BankedTissueUrine
					,mainref.SubsiteID
					,mainref.PredictedBreachStatus
					,mainref.RMRefID
					,mainref.TertiaryReferralKey
					,mainref.ClinicalTLetter
					,mainref.ClinicalNLetter
					,mainref.ClinicalMLetter
					,mainref.PathologicalTLetter
					,mainref.PathologicalNLetter
					,mainref.PathologicalMLetter
					,mainref.FDPlannedInterval
					,mainref.LabReportDate
					,mainref.LabReportOrgID
					,mainref.ReferralRoute
					,mainref.ReferralOtherRoute
					,mainref.RelapseMorphology
					,mainref.RelapseFlow
					,mainref.RelapseMolecular
					,mainref.RelapseClinicalExamination
					,mainref.RelapseOther
					,mainref.RapidDiagnostic
					,mainref.PrimaryReferralFlag
					,mainref.OtherAssessedBy
					,mainref.SharedBreach
					,mainref.PredictedBreachYear
					,mainref.PredictedBreachMonth
					,CASE	WHEN		ISNULL(mainref.N2_13_CANCER_STATUS, '') != '69' -- exclude cancer status for linked referral
							AND			IsLR.SrcSysID IS NULL							-- exclude joins to the linked referral table 
							AND			ISNULL(mainref.L_INAP_REF,'') != '1'
							AND			ISNULL(mainref.TRANSFER_REASON,'') != '1'
							AND			ISNULL(mainref.L_TUMOUR_STATUS,'') NOT IN ('7') --not  OtherTumourSite
							AND NOT (	ISNULL(mainref.L_TUMOUR_STATUS,'')  IN ('1') AND MayBeEmptyRef.SrcSysID IS NULL) -- exclude Unknown TumourStatus only when no link to MayBeEmptyRef table
							THEN 1
							ELSE 0 
							END AS MatchingFilter

					-- Uncategorised
					
		FROM		Merge_DM_MatchViews.tblMAIN_REFERRALS mainref
		LEFT JOIN	Merge_DM_MatchViews.tblDEMOGRAPHICS dem
													ON	mainref.SrcSysID = dem.SrcSysID
													AND	mainref.PATIENT_ID = dem.PATIENT_ID
		LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_tblValidatedData dem_val
																			ON	mainref.SrcSysID = dem_val.SrcSys
																			AND	mainref.PATIENT_ID = dem_val.Src_UID
		LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_tblValidatedData dem_val_maj
																			ON	dem_val.SrcSys_Major = dem_val_maj.SrcSys
																			AND	dem_val.Src_UID_Major = dem_val_maj.Src_UID
		LEFT JOIN	(SELECT * 
							,ROW_NUMBER() OVER (PARTITION BY tblDEFINITIVE_TREATMENT.SrcSysID, tblDEFINITIVE_TREATMENT.CARE_ID ORDER BY tblDEFINITIVE_TREATMENT.TREAT_NO, CASE WHEN tblDEFINITIVE_TREATMENT.TREATMENT_EVENT IS NULL THEN 0 ELSE 1 END DESC, tblDEFINITIVE_TREATMENT.DECISION_DATE ASC, tblDEFINITIVE_TREATMENT.START_DATE ASC ) AS TreatIx
							FROM Merge_DM_MatchViews.tblDEFINITIVE_TREATMENT
							WHERE	tblDEFINITIVE_TREATMENT.PATHWAY_ID IS NOT NULL 
									AND	tblDEFINITIVE_TREATMENT.PATHWAY_ID != ''
									AND	LEFT(tblDEFINITIVE_TREATMENT.PATHWAY_ID, 4) != '1000'
									AND	tblDEFINITIVE_TREATMENT.TREAT_NO = 1) dt
		
														ON	mainref.CARE_ID = dt.CARE_ID							--links to treatment table for PathwayID
														AND	mainref.SrcSysID = dt.SrcSysID
														AND dt.TreatIx = 1
		LEFT JOIN	Merge_DM_MatchViews.tblAUDIT aud
											ON	mainref.SrcSysID = aud.SrcSysID
											AND	mainref.ACTION_ID = aud.ACTION_ID
		LEFT JOIN	Merge_DM_MatchViews.OrganisationSites fd_org
														ON	mainref.SrcSysID = fd_org.SrcSysID
														AND	mainref.FasterDiagnosisOrganisationID = fd_org.ID

		LEFT JOIN   Merge_DM_MatchViews.tblLinkedReferrals LR 
															ON mainref.SrcSysID = LR.srcsysID
															AND mainref.CARE_ID = LR.LinkedCareID

		LEFT JOIN   (SELECT srcsysID, OriginalCareID FROM Merge_DM_MatchViews.tblLinkedReferrals GROUP BY srcsysID, OriginalCareID) IsLR 
																																		ON mainref.SrcSysID = IsLR.srcsysID
																																		AND mainref.CARE_ID = IsLR.OriginalCareID

		LEFT JOIN	(SELECT ADT_REF_ID
							,SrcSysID
							FROM Merge_DM_MatchViews.tblMAIN_REFERRALS
					GROUP BY ADT_REF_ID
							,SrcSysID
					HAVING COUNT(*) >1) MayBeEmptyRef
														ON mainref.ADT_REF_ID = MayBeEmptyRef.ADT_REF_ID
														AND mainref.SrcSysID = MayBeEmptyRef.SrcSysID

											
		--WHERE		ISNULL(mainref.N2_13_CANCER_STATUS, '') != '69'
		--AND			ISNULL(mainref.L_INAP_REF,'') != '1'
		--AND			ISNULL(mainref.TRANSFER_REASON,'') != '1'
		--AND			ISNULL(mainref.L_TUMOUR_STATUS,'') NOT IN ('7') --not  OtherTumourSite
		--AND NOT (	ISNULL(mainref.L_TUMOUR_STATUS,'')  IN ('1') AND MayBeEmptyRef.SrcSysID IS NULL) -- exclude Unknown TumourStatus only when no link to MayBeEmptyRef table


GO
