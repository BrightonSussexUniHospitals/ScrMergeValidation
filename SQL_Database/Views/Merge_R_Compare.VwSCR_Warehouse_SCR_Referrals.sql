SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








--CREATE SCHEMA Merge_R_Compare AUTHORIZATION dbo

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
			,dwref.CARE_ID
			,pre.SrcSysID AS OrigSrcSysID
			,5 AS SrcSysID
			,ss.SrcSysCode
			,ss.SrcSysName
			,pre.PatientPathwayID 
			,pre.PatientPathwayIdIssuer
			,ISNULL(Pat_IDs.PRIMARY_PATIENT_ID, dwref.PATIENT_ID) AS PATIENT_ID
			,mainref_aud.ACTION_ID AS MainRefActionId
			,diag_aud.ACTION_ID AS DiagnosisActionId 
			,dem_aud.ACTION_ID AS DemographicsActionId 
			,pre.Forename
			,pre.Surname
			,pre.DateBirth
			,pre.HospitalNumber
			,pre.NHSNumber
			,pre.NHSNumberStatusCode
			,pre.NstsStatus
			,pre.IsTemporaryNHSNumber
			,pre.DeathStatus
			,pre.DateDeath
			,pre.PctCode
			,pre.PctDesc
			,pre.CcgCode
			,pre.CcgDesc
			,pre.CancerSite
			,pre.CancerSiteBS
			,pre.CancerSubSiteCode
			,pre.CancerSubSiteDesc
			,pre.ReferralCancerSiteCode
			,pre.ReferralCancerSiteDesc
			,pre.ReferralCancerSiteBS
			,pre.CancerTypeCode
			,pre.CancerTypeDesc
			,pre.PriorityTypeCode
			,pre.PriorityTypeDesc
			,pre.SourceReferralCode
			,pre.SourceReferralDesc
			,pre.ReferralMethodCode
			,pre.DecisionToReferDate
			,pre.TumourStatusCode
			,pre.TumourStatusDesc
			,pre.PatientStatusCode
			,pre.PatientStatusDesc
			,pre.PatientStatusCodeCwt
			,pre.PatientStatusDescCwt
			,pre.ConsultantCode
			,pre.ConsultantName
			,pre.InappropriateRef
			,pre.TransferReason
			,pre.TransferNewRefDate
			,pre.TransferTumourSiteCode
			,pre.TransferTumourSiteDesc
			,pre.TransferActionedDate
			,dwref.SOURCE_CARE_ID AS TransferSourceCareId 
			,ISNULL(dwref.ORIGINAL_SOURCE_CARE_ID, dwref.CARE_ID) AS TransferOrigSourceCareId 
			,pre.FastDiagInformedDate
			,pre.FastDiagExclDate
			,pre.FastDiagCancerSiteID
			,pre.FastDiagCancerSiteOverrideID
			,pre.FastDiagCancerSiteCode
			,pre.FastDiagCancerSiteDesc
			,pre.FastDiagEndReasonID
			,pre.FastDiagEndReasonCode
			,pre.FastDiagEndReasonDesc
			,pre.FastDiagDelayReasonID
			,pre.FastDiagDelayReasonCode
			,pre.FastDiagDelayReasonDesc
			,LEFT(CAST(pre.FastDiagDelayReasonComments AS VARCHAR(1000)),1000) AS FastDiagDelayReasonComments
			,pre.FastDiagExclReasonID
			,pre.FastDiagExclReasonCode
			,pre.FastDiagExclReasonDesc
			,dworg_fd.ID AS FastDiagOrgID
			,dworg_fd.Code AS FastDiagOrgCode
			,dworg_fd.Description AS FastDiagOrgDesc
			,pre.FastDiagCommMethodID
			,pre.FastDiagCommMethodCode
			,pre.FastDiagCommMethodDesc
			,pre.FastDiagOtherCommMethod
			,pre.FastDiagInformingCareProfID
			,pre.FastDiagInformingCareProfCode
			,pre.FastDiagInformingCareProfDesc
			,pre.FastDiagOtherCareProf
			,pre.FDPlannedInterval
			,pre.DateDiagnosis
			,pre.DateNoCancer
			,pre.AgeAtDiagnosis
			,pre.DiagnosisCode
			,pre.DiagnosisSubCode
			,pre.DiagnosisDesc
			,pre.DiagnosisSubDesc
			,dworg_d.ID AS OrgIdDiagnosis
			,pre.OrgCodeDiagnosis
			,dworg_d.Description AS OrgDescDiagnosis
			,pre.SnomedCT_ID
			,pre.SnomedCT_MCode
			,pre.SnomedCT_ConceptID
			,pre.SnomedCT_Desc
			,pre.Histology
			,pre.DateReceipt
			,pre.AgeAtReferral
			,pre.AppointmentCancelledDate
			,pre.DateConsultantUpgrade
			,pre.DateFirstSeen
			,dworg_u.ID AS OrgIdUpgrade
			,pre.OrgCodeUpgrade
			,dworg_u.Description AS OrgDescUpgrade
			,dworg_fs.ID AS OrgIdFirstSeen
			,pre.OrgCodeFirstSeen
			,dworg_fs.Description AS OrgDescFirstSeen
			,pre.OrgCodeMainCurrent
			,pre.OrgDescMainCurrent
			,pre.FirstAppointmentTypeCode
			,pre.FirstAppointmentTypeDesc
			,pre.FirstAppointmentOffered
			,pre.ReasonNoAppointmentCode
			,pre.ReasonNoAppointmentDesc
			,pre.FirstSeenAdjTime
			,pre.FirstSeenAdjReasonCode
			,pre.FirstSeenAdjReasonDesc
			,pre.FirstSeenDelayReasonCode
			,pre.FirstSeenDelayReasonDesc
			,LEFT(CAST(pre.FirstSeenDelayReasonComment AS VARCHAR(1000)),1000) AS FirstSeenDelayReasonComment
			,pre.DTTAdjTime
			,pre.DTTAdjReasonCode
			,pre.DTTAdjReasonDesc
			,pre.IsBCC
			,pre.IsCwtCancerDiagnosis
			,pre.UnderCancerCareFlag
			,pre.RefreshMaxActionDate
			,pre.ReportDate
			,pre.DateLastTracked
			,pre.DaysSinceLastTracked
			,pre.RTTBreachStatus
			,pre.DelayReasonCode
			,pre.DelayReasonDesc
			,LEFT(CAST(pre.DelayReasonComment AS VARCHAR(1000)),1000) AS DelayReasonComment
			,pre.SharedBreach
			,pre.PredictedBreachYear
			,pre.PredictedBreachMonth
			,pre.LateralityCode
			,pre.LateralityDesc
			,pre.ClinicalTStage
			,pre.ClinicalNStage
			,pre.ClinicalMStage
			,pre.ClinicalTNM_Group
			,pre.PathologicalTStage
			,pre.PathologicalNStage
			,pre.PathologicalMStage
			,pre.PathologicalTNM_Group
			,pre.FIGO_Stage1
			,pre.FIGO_Stage2
			,pre.FIGO_Stage3
			,pre.RISS_Stage
			,pre.AnnArborStageCode
			,pre.AnnArborStageDesc
			,pre.BinetStageCode
			,pre.BinetStageDesc
			,pre.CNSIndicatorCode
			,pre.MaxWHO_Status
			,pre.IsCOSD_Staging
			,pre.IsCOSD_StagingComplete
			,pre.IsCOSD_PerformanceStatus
			,pre.IsCOSD_PerformanceStatusComplete

FROM		CancerReporting_PREMERGE.SCR_Warehouse.SCR_Referrals pre

LEFT JOIN	SCR_DW.SCR.dbo_tblMAIN_REFERRALS dwref
											ON	pre.CARE_ID = dwref.DW_SOURCE_ID
											AND pre.SrcSysID = dwref.DW_SOURCE_SYSTEM_ID

LEFT JOIN	Patient_Merge.Patient_Merge.Pat_IDs Pat_IDs --to get the west PATIENT_ID when the brighton record has a west equivalent
														ON	pre.SrcSysID = Pat_IDs.MINOR_DW_SOURCE_SYSTEM_ID
														AND	pre.PATIENT_ID = Pat_IDs.MINOR_LOCAL_PATIENT_ID

LEFT JOIN	SCR_DW.SCR.dbo_tblDEMOGRAPHICS dwdem -- to get the renumbered brighton PATIENT_ID when the brighton record has no west equivalent
														ON	pre.SrcSysID = dwdem.DW_SOURCE_SYSTEM_ID
														AND	pre.PATIENT_ID = dwdem.DW_SOURCE_PATIENT_ID

LEFT JOIN	CancerReporting_PREMERGE.LocalConfig.tblDEMOGRAPHICS lc_dem -- to get original action ID from west demographic record when the brighton demographic record has a west equivalent
																	ON	Pat_IDs.PRIMARY_DW_SOURCE_SYSTEM_ID = lc_dem.SrcSysID
																	AND	Pat_IDs.PRIMARY_PATIENT_ID = lc_dem.PATIENT_ID

LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT dem_aud
											ON	pre.SrcSysID = dem_aud.DW_SOURCE_SYSTEM_ID
											AND	ISNULL(lc_dem.ACTION_ID, pre.DemographicsActionId) = dem_aud.DW_SOURCE_ID

LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT diag_aud
											ON	pre.SrcSysID = diag_aud.DW_SOURCE_SYSTEM_ID
											AND	pre.DiagnosisActionId = diag_aud.DW_SOURCE_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT mainref_aud
											ON	pre.SrcSysID = mainref_aud.DW_SOURCE_SYSTEM_ID
											AND	pre.MainRefActionId = mainref_aud.DW_SOURCE_ID

LEFT JOIN	CancerReporting_MERGE.LocalConfig.SourceSystems ss
														ON ss.SrcSysID = 5

LEFT JOIN	OrganisationSites_Id dworg_fd
									ON pre.FastDiagOrgID = dworg_fd.DW_SOURCE_ID 
									AND pre.SrcSysID = dworg_fd.DW_SOURCE_SYSTEM_ID

LEFT JOIN	OrganisationSites_Code dworg_fs
									ON pre.OrgCodeFirstSeen = dworg_fs.Code

LEFT JOIN	OrganisationSites_Code dworg_d
									ON pre.OrgCodeDiagnosis = dworg_d.Code

LEFT JOIN	OrganisationSites_Code dworg_u
									ON pre.OrgCodeUpgrade = dworg_u.Code
GO
