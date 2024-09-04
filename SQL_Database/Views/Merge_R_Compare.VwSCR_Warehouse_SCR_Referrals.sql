SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [Merge_R_Compare].[VwSCR_Warehouse_SCR_Referrals]
AS

WITH	OrganisationSites_Id AS 
		(SELECT	dw_source_id
				,dw_source_system_id
				,id
				,code
				,description
		FROM	SCR_DW.SCR.dbo_OrganisationSites
							
		UNION ALL 
							
		SELECT	dw_source_patient_id AS dw_source_id
				,2 AS dw_source_system_id
				,id
				,code
				,description
		FROM	SCR_DW.SCR.dbo_OrganisationSites
		WHERE	dw_source_patient_id IS NOT NULL
		AND		dw_source_system_id = 1
		)
		,OrganisationSites_Code AS 
		(SELECT	id
				,code
				,description
		FROM	SCR_DW.SCR.dbo_OrganisationSites
		)

SELECT		pre.CARE_ID AS OrigCARE_ID
			,dw_ref.CARE_ID
			,pre.SrcSysID AS OrigSrcSysID
			,5 AS SrcSysID
			,ss.SrcSysCode
			,ss.SrcSysName
			,pre.PatientPathwayID 
			,pre.PatientPathwayIdIssuer
			,dw_dem.PATIENT_ID AS PATIENT_ID
			,ISNULL(mainref_aud.ACTION_ID, dw_ref.ACTION_ID) AS MainRefActionId
			,diag_aud.ACTION_ID AS DiagnosisActionId 
			,dem_aud.ACTION_ID AS DemographicsActionId  
			,val_dem.N1_6_FORENAME AS Forename
			,val_dem.N1_5_SURNAME AS Surname
			,val_dem.N1_10_DATE_BIRTH AS DateBirth
			,val_dem.N1_2_HOSPITAL_NUMBER AS HospitalNumber
			,val_dem.N1_1_NHS_NUMBER AS NHSNumber
			,val_dem.NHS_NUMBER_STATUS AS NHSNumberStatusCode
			,val_dem.L_NSTS_STATUS AS NstsStatus
			,CASE	WHEN	val_dem.L_NSTS_STATUS IN (0,9) 
					THEN	1
					ELSE	0
					END AS IsTemporaryNHSNumber
			,val_dem.L_DEATH_STATUS AS DeathStatus
			,val_dem.N15_1_DATE_DEATH AS DateDeath
			,val_dem.N1_13_PCT AS PctCode
			,PCT.PCT_DESC AS PctDesc
			,pre.CcgCode
			,pre.CcgDesc
			,CancerSite = ISNULL(val_ref.L_CANCER_SITE, pre.CancerSite)
			,CancerSiteBS = ISNULL(CASE	
														WHEN	val_ref.N2_12_CANCER_TYPE  = 16  
														AND		val_ref.l_cancer_site = 'Breast'
														THEN	'Breast Symptomatic' 
														ELSE	val_ref.l_cancer_site 
														END, pre.CancerSiteBS)
			,CancerSubSiteCode = ISNULL(val_ref.SubsiteID, pre.CancerSubSiteCode)
			,CancerSubSiteDesc = ISNULL(CAST(crs.Description AS VARCHAR(25)), pre.CancerSubSiteDesc)
			,ReferralCancerSiteCode = ISNULL(CSite.CA_ID, pre.ReferralCancerSiteCode)
			,ReferralCancerSiteDesc = ISNULL(CSite.CA_SITE, pre.ReferralCancerSiteDesc)
			,ReferralCancerSiteBS = ISNULL(Case	WHEN	ISNULL(val_ref.N2_12_CANCER_TYPE, pre.CancerTypeCode)  = 16
															AND		CSite.CA_SITE = 'Breast'
															THEN	'Breast Symptomatic'    
															ELSE	CSite.CA_SITE
															END, pre.ReferralCancerSiteBS)
			,CancerTypeCode = ISNULL(val_ref.N2_12_CANCER_TYPE, pre.CancerTypeCode)
			,CancerTypeDesc = ISNULL(CType.CANCER_TYPE_DESC, pre.CancerTypeDesc)
			,PriorityTypeCode = ISNULL(val_ref.N2_4_PRIORITY_TYPE, pre.PriorityTypeCode)
			,PriorityTypeDesc = ISNULL(PType.PRIORITY_DESC, pre.PriorityTypeDesc)
			,SourceReferralCode = ISNULL(val_ref.N2_16_OP_REFERRAL, pre.SourceReferralCode)
			,SourceReferralDesc = ISNULL(Ref.REF_DESC, pre.SourceReferralDesc)
			,ReferralMethodCode = ISNULL(val_ref.L_REFERRAL_METHOD, pre.ReferralMethodCode)
			,DecisionToReferDate = ISNULL(val_ref.N2_5_DECISION_DATE, pre.DecisionToReferDate)
			,TumourStatusCode = ISNULL(val_ref.L_TUMOUR_STATUS, pre.TumourStatusCode)
			,TumourStatusDesc = ISNULL(TStat.STATUS_DESC, pre.TumourStatusDesc)
			,PatientStatusCode = ISNULL(val_ref.N2_13_CANCER_STATUS, pre.PatientStatusCode)
			,PatientStatusDesc = ISNULL(PStat.STATUS_DESC, pre.PatientStatusDesc)
			,PatientStatusCodeCwt = ISNULL(CASE	WHEN val_ref.N2_13_CANCER_STATUS = '69'
																THEN '03'
																ELSE val_ref.N2_13_CANCER_STATUS
																END, pre.PatientStatusCodeCwt)
			,PatientStatusDescCwt = ISNULL(PStat_cwt.STATUS_DESC, pre.PatientStatusDescCwt)
			,ConsultantCode = pre.ConsultantCode
			,ConsultantName = pre.ConsultantName
			,InappropriateRef = ISNULL(val_ref.L_INAP_REF, pre.InappropriateRef)
			,TransferReason = ISNULL(val_ref.TRANSFER_REASON, pre.TransferReason)
			,TransferNewRefDate = ISNULL(val_ref.DATE_NEW_REFERRAL, pre.TransferNewRefDate)
			,TransferTumourSiteCode = ISNULL(val_ref.TUMOUR_SITE_NEW, pre.TransferTumourSiteCode)
			,TransferTumourSiteDesc = ISNULL(val_ref.L_NEW_CA_SITE, pre.TransferTumourSiteDesc)
			,TransferActionedDate = ISNULL(val_ref.DATE_TRANSFER_ACTIONED, pre.TransferActionedDate)
			,dw_ref.SOURCE_CARE_ID AS TransferSourceCareId 
			,ISNULL(dw_ref.ORIGINAL_SOURCE_CARE_ID, dw_ref.CARE_ID) AS TransferOrigSourceCareId 
			,FastDiagInformedDate = ISNULL(val_ref.L_PT_INFORMED_DATE, pre.FastDiagInformedDate)
			,FastDiagExclDate = ISNULL(val_ref.FasterDiagnosisExclusionDate, pre.FastDiagExclDate)
			,FastDiagCancerSiteID = COALESCE(Diag.FasterDiagnosisCancerSiteID, DiagSub.FasterDiagnosisCancerSiteID, pre.FastDiagCancerSiteID)
			,FastDiagCancerSiteOverrideID = ISNULL(val_ref.FasterDiagnosisCancerSiteOverrideID, pre.FastDiagCancerSiteOverrideID)
			,FastDiagCancerSiteCode = ISNULL(fdcs.CWTCode, pre.FastDiagCancerSiteCode)
			,FastDiagCancerSiteDesc = ISNULL(fdcs.Description, pre.FastDiagCancerSiteDesc)
			,pre.FastDiagEndReasonID -- FastDiagEndReasonID = ISNULL(val_ref.FastDiagEndReasonID, pre.FastDiagEndReasonID)
			,pre.FastDiagEndReasonCode -- FastDiagEndReasonCode = ISNULL(val_ref.FastDiagEndReasonCode, pre.FastDiagEndReasonCode)
			,pre.FastDiagEndReasonDesc -- FastDiagEndReasonDesc = ISNULL(val_ref.FastDiagEndReasonDesc, pre.FastDiagEndReasonDesc)
			,FastDiagDelayReasonID = ISNULL(val_ref.FasterDiagnosisDelayReasonID, pre.FastDiagDelayReasonID)
			,pre.FastDiagDelayReasonCode -- FastDiagDelayReasonCode = ISNULL(val_ref.FastDiagDelayReasonCode, pre.FastDiagDelayReasonCode)
			,pre.FastDiagDelayReasonDesc -- FastDiagDelayReasonDesc = ISNULL(val_ref.FastDiagDelayReasonDesc, pre.FastDiagDelayReasonDesc)
			,LEFT(CAST(pre.FastDiagDelayReasonComments AS VARCHAR(1000)),1000) AS FastDiagDelayReasonComments
			,FastDiagExclReasonID = ISNULL(val_ref.FasterDiagnosisExclusionReasonID, pre.FastDiagExclReasonID)
			,pre.FastDiagExclReasonCode -- FastDiagExclReasonCode = ISNULL(val_ref.FastDiagExclReasonCode, pre.FastDiagExclReasonCode)
			,pre.FastDiagExclReasonDesc -- FastDiagExclReasonDesc = ISNULL(val_ref.FastDiagExclReasonDesc, pre.FastDiagExclReasonDesc)
			,dworg_fd.ID AS FastDiagOrgID
			,dworg_fd.Code AS FastDiagOrgCode
			,dworg_fd.Description AS FastDiagOrgDesc
			,FastDiagCommMethodID = ISNULL(val_ref.FasterDiagnosisCommunicationMethodID, pre.FastDiagCommMethodID)
			,pre.FastDiagCommMethodCode -- FastDiagCommMethodCode = ISNULL(val_ref.FastDiagCommMethodCode, pre.FastDiagCommMethodCode)
			,pre.FastDiagCommMethodDesc -- FastDiagCommMethodDesc = ISNULL(val_ref.FastDiagCommMethodDesc, pre.FastDiagCommMethodDesc)
			,FastDiagOtherCommMethod = ISNULL(val_ref.FasterDiagnosisOtherCommunicationMethod, pre.FastDiagOtherCommMethod)
			,FastDiagInformingCareProfID = ISNULL(val_ref.FasterDiagnosisInformingCareProfessionalID, pre.FastDiagInformingCareProfID)
			,pre.FastDiagInformingCareProfCode -- FastDiagInformingCareProfCode = ISNULL(val_ref.FastDiagInformingCareProfCode, pre.FastDiagInformingCareProfCode)
			,pre.FastDiagInformingCareProfDesc -- FastDiagInformingCareProfDesc = ISNULL(val_ref.FastDiagInformingCareProfDesc, pre.FastDiagInformingCareProfDesc)
			,FastDiagOtherCareProf = ISNULL(val_ref.FasterDiagnosisOtherCareProfessional, pre.FastDiagOtherCareProf)
			,FDPlannedInterval = ISNULL(val_ref.FDPlannedInterval, pre.FDPlannedInterval)
			,DateDiagnosis = ISNULL(val_ref.N4_1_DIAGNOSIS_DATE, pre.DateDiagnosis)
			,DateNoCancer = ISNULL(val_ref.L_OTHER_DIAG_DATE, pre.DateNoCancer)
			,pre.AgeAtDiagnosis -- AgeAtDiagnosis = ISNULL(val_ref.AgeAtDiagnosis, pre.AgeAtDiagnosis)
			,DiagnosisCode = ISNULL(val_ref.L_Diagnosis, pre.DiagnosisCode)
			,DiagnosisSubCode = ISNULL(val_ref.N4_2_DIAGNOSIS_CODE, pre.DiagnosisSubCode)
			,DiagnosisDesc = ISNULL(Diag.DIAG_DESC, pre.DiagnosisDesc)
			,DiagnosisSubDesc = ISNULL(DiagSub.DIAG_DESC, pre.DiagnosisSubDesc)
			,dworg_d.ID AS OrgIdDiagnosis
			,OrgCodeDiagnosis = ISNULL(val_ref.L_ORG_CODE_DIAGNOSIS, pre.OrgCodeDiagnosis)
			,dworg_d.Description AS OrgDescDiagnosis
			,SnomedCT_ID = ISNULL(val_ref.SNOMed_CT, pre.SnomedCT_ID)
			,pre.SnomedCT_MCode -- SnomedCT_MCode = ISNULL(val_ref.SnomedCT_MCode, pre.SnomedCT_MCode)
			,pre.SnomedCT_ConceptID -- SnomedCT_ConceptID = ISNULL(val_ref.SnomedCT_ConceptID, pre.SnomedCT_ConceptID)
			,pre.SnomedCT_Desc -- SnomedCT_Desc = ISNULL(val_ref.SnomedCT_Desc, pre.SnomedCT_Desc)
			,Histology = ISNULL(val_ref.N4_5_HISTOLOGY, pre.Histology)
			,DateReceipt = ISNULL(val_ref.N2_6_RECEIPT_DATE, pre.DateReceipt)
			,pre.AgeAtReferral -- AgeAtReferral = ISNULL(val_ref.AgeAtReferral, pre.AgeAtReferral)
			,AppointmentCancelledDate = ISNULL(val_ref.L_CANCELLED_DATE, pre.AppointmentCancelledDate)
			,DateConsultantUpgrade = ISNULL(val_ref.N_UPGRADE_DATE, pre.DateConsultantUpgrade)
			,DateFirstSeen = ISNULL(val_ref.N2_9_FIRST_SEEN_DATE, pre.DateFirstSeen)
			,dworg_u.ID AS OrgIdUpgrade
			,OrgCodeUpgrade = ISNULL(val_ref.N_UPGRADE_ORG_CODE, pre.OrgCodeUpgrade)
			,dworg_u.Description AS OrgDescUpgrade
			,dworg_fs.ID AS OrgIdFirstSeen
			,OrgCodeFirstSeen = ISNULL(val_ref.N1_3_ORG_CODE_SEEN, pre.OrgCodeFirstSeen)
			,dworg_fs.Description AS OrgDescFirstSeen
			,pre.OrgCodeMainCurrent
			,pre.OrgDescMainCurrent
			,FirstAppointmentTypeCode = ISNULL(val_ref.L_FIRST_APP, pre.FirstAppointmentTypeCode)
			,pre.FirstAppointmentTypeDesc -- FirstAppointmentTypeDesc = ISNULL(val_ref.FirstAppointmentTypeDesc, pre.FirstAppointmentTypeDesc)
			,FirstAppointmentOffered = ISNULL(val_ref.L_FIRST_APPOINTMENT, pre.FirstAppointmentOffered)
			,ReasonNoAppointmentCode = ISNULL(val_ref.L_NO_APP, pre.ReasonNoAppointmentCode)
			,pre.ReasonNoAppointmentDesc -- ReasonNoAppointmentDesc = ISNULL(val_ref.ReasonNoAppointmentDesc, pre.ReasonNoAppointmentDesc)
			,FirstSeenAdjTime = ISNULL(val_ref.N2_14_ADJ_TIME, pre.FirstSeenAdjTime)
			,FirstSeenAdjReasonCode = ISNULL(val_ref.N2_15_ADJ_REASON, pre.FirstSeenAdjReasonCode)
			,pre.FirstSeenAdjReasonDesc -- FirstSeenAdjReasonDesc = ISNULL(val_ref.FirstSeenAdjReasonDesc, pre.FirstSeenAdjReasonDesc)
			,FirstSeenDelayReasonCode = ISNULL(val_ref.N2_10_FIRST_SEEN_DELAY, pre.FirstSeenDelayReasonCode)
			,pre.FirstSeenDelayReasonDesc -- FirstSeenDelayReasonDesc = ISNULL(val_ref.FirstSeenDelayReasonDesc, pre.FirstSeenDelayReasonDesc)
			,LEFT(CAST(pre.FirstSeenDelayReasonComment AS VARCHAR(1000)),1000) AS FirstSeenDelayReasonComment
			,DTTAdjTime = ISNULL(val_ref.N16_2_ADJ_DAYS, pre.DTTAdjTime)
			,DTTAdjReasonCode = ISNULL(val_ref.N16_4_ADJ_TREAT_CODE, pre.DTTAdjReasonCode)
			,pre.DTTAdjReasonDesc -- DTTAdjReasonDesc = ISNULL(val_ref.DTTAdjReasonDesc, pre.DTTAdjReasonDesc)
			,pre.IsBCC -- IsBCC = ISNULL(val_ref.IsBCC, pre.IsBCC)
			,pre.IsCwtCancerDiagnosis -- IsCwtCancerDiagnosis = ISNULL(val_ref.IsCwtCancerDiagnosis, pre.IsCwtCancerDiagnosis)
			,pre.UnderCancerCareFlag
			,pre.RefreshMaxActionDate
			,pre.ReportDate
			,pre.DateLastTracked -- DateLastTracked = ISNULL(val_ref.DateLastTracked, pre.DateLastTracked)
			,pre.DaysSinceLastTracked -- DaysSinceLastTracked = ISNULL(val_ref.DaysSinceLastTracked, pre.DaysSinceLastTracked)
			,RTTBreachStatus = ISNULL(val_ref.PredictedBreachStatus, pre.RTTBreachStatus)
			,DelayReasonCode = ISNULL(val_ref.N16_5_DECISION_REASON_CODE, pre.DelayReasonCode)
			,pre.DelayReasonDesc -- DelayReasonDesc = ISNULL(val_ref.DelayReasonDesc, pre.DelayReasonDesc)
			,LEFT(CAST(pre.DelayReasonComment AS VARCHAR(1000)),1000) AS DelayReasonComment
			,SharedBreach = ISNULL(val_ref.SharedBreach, pre.SharedBreach)
			,PredictedBreachYear = ISNULL(val_ref.PredictedBreachYear, pre.PredictedBreachYear)
			,PredictedBreachMonth = ISNULL(val_ref.PredictedBreachMonth, pre.PredictedBreachMonth)
			,LateralityCode = ISNULL(val_ref.N4_3_LATERALITY, pre.LateralityCode)
			,pre.LateralityDesc -- LateralityDesc = ISNULL(val_ref.LateralityDesc, pre.LateralityDesc)
			,ClinicalTStage = ISNULL(val_ref.ClinicalTStage, pre.ClinicalTStage)
			,ClinicalNStage = ISNULL(val_ref.ClinicalNStage, pre.ClinicalNStage)
			,ClinicalMStage = ISNULL(val_ref.ClinicalMStage, pre.ClinicalMStage)
			,ClinicalTNM_Group = ISNULL(val_ref.ClinicalTNMGroup, pre.ClinicalTNM_Group)
			,PathologicalTStage = ISNULL(val_ref.PathologicalTStage, pre.PathologicalTStage)
			,PathologicalNStage = ISNULL(val_ref.PathologicalNStage, pre.PathologicalNStage)
			,PathologicalMStage = ISNULL(val_ref.PathologicalMStage, pre.PathologicalMStage)
			,PathologicalTNM_Group = ISNULL(val_ref.PathologicalTNMGroup, pre.PathologicalTNM_Group)
			,pre.FIGO_Stage1 -- FIGO_Stage1 = ISNULL(val_ref.FIGO_Stage1, pre.FIGO_Stage1)
			,pre.FIGO_Stage2 -- FIGO_Stage2 = ISNULL(val_ref.FIGO_Stage2, pre.FIGO_Stage2)
			,pre.FIGO_Stage3 -- FIGO_Stage3 = ISNULL(val_ref.FIGO_Stage3, pre.FIGO_Stage3)
			,pre.RISS_Stage -- RISS_Stage = ISNULL(val_ref.RISS_Stage, pre.RISS_Stage)
			,AnnArborStageCode = ISNULL(val_ref.N6_9_SITE_CLASSIFICATION, pre.AnnArborStageCode)
			,pre.AnnArborStageDesc -- AnnArborStageDesc = ISNULL(val_ref.AnnArborStageDesc, pre.AnnArborStageDesc)
			,pre.BinetStageCode -- BinetStageCode = ISNULL(val_ref.BinetStageCode, pre.BinetStageCode)
			,pre.BinetStageDesc -- BinetStageDesc = ISNULL(val_ref.BinetStageDesc, pre.BinetStageDesc)
			,CNSIndicatorCode = ISNULL(val_ref.L_INDICATOR_CODE, pre.CNSIndicatorCode)
			,pre.MaxWHO_Status -- MaxWHO_Status = ISNULL(val_ref.MaxWHO_Status, pre.MaxWHO_Status)
			,pre.IsCOSD_Staging -- IsCOSD_Staging = ISNULL(val_ref.IsCOSD_Staging, pre.IsCOSD_Staging)
			,pre.IsCOSD_StagingComplete -- IsCOSD_StagingComplete = ISNULL(val_ref.IsCOSD_StagingComplete, pre.IsCOSD_StagingComplete)
			,pre.IsCOSD_PerformanceStatus -- IsCOSD_PerformanceStatus = ISNULL(val_ref.IsCOSD_PerformanceStatus, pre.IsCOSD_PerformanceStatus)
			,pre.IsCOSD_PerformanceStatusComplete -- IsCOSD_PerformanceStatusComplete = ISNULL(val_ref.IsCOSD_PerformanceStatusComplete, pre.IsCOSD_PerformanceStatusComplete)

FROM		CancerReporting_PREMERGE.SCR_Warehouse.SCR_Referrals pre

-- referrals deduplicating, column overrides and remapping
LEFT JOIN	(SELECT		SrcSys AS SrcSys_Orig
						,Src_UID AS Src_UID_Orig
						,CASE WHEN IsConfirmed = 1 AND IsValidatedMajor = 0 THEN SrcSys_Major ELSE SrcSys END AS SrcSys
						,CASE WHEN IsConfirmed = 1 AND IsValidatedMajor = 0 THEN Src_UID_Major ELSE Src_UID END AS Src_UID
			FROM		Merge_R_Compare.tblMAIN_REFERRALS_tblValidatedData
						) map_ref
									ON	pre.SrcSysID = map_ref.SrcSys_Orig
									AND	pre.CARE_ID = map_ref.Src_UID_Orig

LEFT JOIN	Merge_R_Compare.tblMAIN_REFERRALS_tblValidatedData val_ref
																ON	map_ref.SrcSys = val_ref.SrcSys
																AND	map_ref.Src_UID = val_ref.Src_UID

LEFT JOIN	Merge_R_Compare.dbo_tblMAIN_REFERRALS dw_ref
											ON	val_ref.Src_UID = dw_ref.DW_SOURCE_ID
											AND val_ref.SrcSys = dw_ref.DW_SOURCE_SYSTEM_ID

-- demographics deduplicating, column overrides and remapping
LEFT JOIN	(SELECT		SrcSys AS SrcSys_Orig
						,Src_UID AS Src_UID_Orig
						,CASE WHEN IsConfirmed = 1 AND IsValidatedMajor = 0 THEN SrcSys_Major ELSE SrcSys END AS SrcSys
						,CASE WHEN IsConfirmed = 1 AND IsValidatedMajor = 0 THEN Src_UID_Major ELSE Src_UID END AS Src_UID
			FROM		Merge_R_Compare.tblDEMOGRAPHICS_tblValidatedData
						) map_dem
									ON	pre.SrcSysID = map_dem.SrcSys_Orig
									AND	pre.PATIENT_ID = map_dem.Src_UID_Orig

LEFT JOIN	Merge_R_Compare.tblDEMOGRAPHICS_tblValidatedData val_dem
																ON	map_dem.SrcSys = val_dem.SrcSys
																AND	map_dem.Src_UID = val_dem.Src_UID
LEFT JOIN	MERGE_R_COMPARE.dbo_tblDEMOGRAPHICS dw_dem
												ON	val_dem.SrcSys = dw_dem.DW_SOURCE_SYSTEM_ID
												AND	val_dem.PATIENT_ID = dw_dem.DW_SOURCE_ID
-- lookups
LEFT JOIN	LocalConfig.ltblNATIONAL_PCT PCT 
											ON	val_dem.SrcSys = PCT.SrcSysID
											AND	val_dem.N1_13_PCT = PCT.PCT_CODE
LEFT JOIN	LocalConfig.CancerReferralSubsites crs
						ON	ISNULL(val_ref.SubsiteID, pre.CancerSubSiteCode) = crs.ID
						AND	ISNULL(val_ref.SrcSys, pre.SrcSysID) = crs.SrcSysID
LEFT JOIN	LocalConfig.ltblCANCER_TYPE CType 
				ON	ISNULL(val_ref.N2_12_CANCER_TYPE, pre.CancerTypeCode) = CType.CANCER_TYPE_CODE		--links to treatment table for PathwayID
				AND	ISNULL(val_ref.SrcSys, pre.SrcSysID) = CType.SrcSysID
LEFT JOIN	LocalConfig.ltblCANCER_SITES CSite
				ON	CType.CANCER_SITE = CSite.CA_ID
				AND	CType.SrcSysID = CSite.SrcSysID
LEFT JOIN	LocalConfig.ltblPRIORITY_TYPE PType 
				ON	ISNULL(val_ref.N2_4_PRIORITY_TYPE, pre.PriorityTypeCode) = PType.PRIORITY_CODE		--links to Priority Type Code lookup
				AND	ISNULL(val_ref.SrcSys, pre.SrcSysID) = PType.SrcSysID
LEFT JOIN	LocalConfig.ltblOUT_PATIENT_REFERRAL Ref
				ON	ISNULL(val_ref.N2_16_OP_REFERRAL, pre.SourceReferralCode) = Ref.REF_CODE				--links to Referral Source Code lookup	
				AND	ISNULL(val_ref.SrcSys, pre.SrcSysID) = Ref.SrcSysID      		
LEFT JOIN	LocalConfig.ltblCA_STATUS TStat 
				ON	ISNULL(val_ref.L_TUMOUR_STATUS, pre.TumourStatusCode) = TStat.STATUS_CODE			--links to Tumour Status description lookup - Unknown or Primary for 2ww
				AND	ISNULL(val_ref.SrcSys, pre.SrcSysID) = TStat.SrcSysID
LEFT JOIN	LocalConfig.ltblSTATUS PStat 
				ON	ISNULL(val_ref.N2_13_CANCER_STATUS, pre.PatientStatusCode) = PStat.STATUS_CODE			--links to PatientStatus description lookup
				AND	ISNULL(val_ref.SrcSys, pre.SrcSysID) = PStat.SrcSysID
LEFT JOIN	LocalConfig.ltblSTATUS PStat_cwt
				ON	ISNULL(CASE	WHEN val_ref.N2_13_CANCER_STATUS = '69'
																THEN '03'
																ELSE val_ref.N2_13_CANCER_STATUS
																END, pre.PatientStatusCodeCwt) = PStat_cwt.STATUS_CODE			--links to PatientStatus description lookup
				AND	ISNULL(val_ref.SrcSys, pre.SrcSysID) = PStat_cwt.SrcSysID
LEFT JOIN	LocalConfig.ltblDIAGNOSIS Diag 
				ON	ISNULL(val_ref.L_Diagnosis, pre.DiagnosisCode) = Diag.DIAG_CODE				--links to diagnostic description lookup
				AND	ISNULL(val_ref.SrcSys, pre.SrcSysID) = Diag.SrcSysID
LEFT JOIN	LocalConfig.ltblDIAGNOSIS DiagSub
				ON	ISNULL(val_ref.N4_2_DIAGNOSIS_CODE, pre.DiagnosisSubCode) = DiagSub.DIAG_CODE				--links to diagnostic description lookup
				AND	ISNULL(val_ref.SrcSys, pre.SrcSysID) = DiagSub.SrcSysID
LEFT JOIN	LocalConfig.ltblFasterDiagnosisCancerSite fdcs
				ON	COALESCE(Diag.FasterDiagnosisCancerSiteID, DiagSub.FasterDiagnosisCancerSiteID, pre.FastDiagCancerSiteID) = fdcs.ID
				AND	ISNULL(val_ref.SrcSys, pre.SrcSysID) = fdcs.SrcSysID
												
-- audit trail renumbering
LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT dem_aud
											ON	val_dem.SrcSys = dem_aud.DW_SOURCE_SYSTEM_ID
											AND	val_dem.ACTION_ID = dem_aud.DW_SOURCE_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT diag_aud
											ON	pre.SrcSysID = diag_aud.DW_SOURCE_SYSTEM_ID
											AND	pre.DiagnosisActionId = diag_aud.DW_SOURCE_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT mainref_aud
											ON	pre.SrcSysID = mainref_aud.DW_SOURCE_SYSTEM_ID
											AND	pre.MainRefActionId = mainref_aud.DW_SOURCE_ID

LEFT JOIN	CancerReporting_MERGE.LocalConfig.SourceSystems ss
														ON ss.SrcSysID = 5
-- org sites remapping
LEFT JOIN	OrganisationSites_Id dworg_fd
									ON ISNULL(val_ref.FasterDiagnosisOrganisationID, pre.FastDiagOrgID) = dworg_fd.DW_SOURCE_ID 
									AND ISNULL(val_ref.SrcSys, pre.SrcSysID) = dworg_fd.DW_SOURCE_SYSTEM_ID

LEFT JOIN	OrganisationSites_Code dworg_fs
									ON ISNULL(val_ref.N1_3_ORG_CODE_SEEN, pre.OrgCodeFirstSeen) = dworg_fs.Code

LEFT JOIN	OrganisationSites_Code dworg_d
									ON ISNULL(val_ref.L_ORG_CODE_DIAGNOSIS, pre.OrgCodeDiagnosis) = dworg_d.Code

LEFT JOIN	OrganisationSites_Code dworg_u
									ON ISNULL(val_ref.N_UPGRADE_ORG_CODE, pre.OrgCodeUpgrade) = dworg_u.Code
GO
