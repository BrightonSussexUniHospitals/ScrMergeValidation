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
			,dwref.CARE_ID
			,pre.SrcSysID AS OrigSrcSysID
			,5 AS SrcSysID
			,ss.SrcSysCode
			,ss.SrcSysName
			,pre.PatientPathwayID 
			,pre.PatientPathwayIdIssuer
			,dw_dem.PATIENT_ID AS PATIENT_ID
			,ISNULL(mainref_aud.ACTION_ID, dwref.ACTION_ID) AS MainRefActionId
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

LEFT JOIN	(SELECT		SrcSys AS SrcSys_Orig
						,Src_UID AS Src_UID_Orig
						,CASE WHEN IsConfirmed = 1 AND IsValidatedMajor = 0 THEN SrcSys_Major ELSE SrcSys END AS SrcSys
						,CASE WHEN IsConfirmed = 1 AND IsValidatedMajor = 0 THEN Src_UID_Major ELSE Src_UID END AS Src_UID
			FROM		SCR_ETL.map.tblDEMOGRAPHICS_tblValidatedData
						) map_dem
									ON	pre.SrcSysID = map_dem.SrcSys_Orig
									AND	pre.PATIENT_ID = map_dem.Src_UID_Orig

LEFT JOIN	Merge_R_Compare.tblDEMOGRAPHICS_tblValidatedData val_dem
																ON	map_dem.SrcSys = val_dem.SrcSys
																AND	map_dem.Src_UID = val_dem.Src_UID
LEFT JOIN	LocalConfig.ltblNATIONAL_PCT PCT 
											ON	val_dem.SrcSys = PCT.SrcSysID
											AND	val_dem.N1_13_PCT = PCT.PCT_CODE
LEFT JOIN	MERGE_R_COMPARE.dbo_tblDEMOGRAPHICS dw_dem
												ON	val_dem.SrcSys = dw_dem.DW_SOURCE_SYSTEM_ID
												AND	val_dem.PATIENT_ID = dw_dem.DW_SOURCE_ID

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
