SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [Merge_R_Compare].[VwSCR_Warehouse_SCR_Assessments]
AS

SELECT		pre.SrcSysID AS OrigSrcSysID
			,5 AS SrcSysID
			,pre.ASSESSMENT_ID AS OrigASSESSMENT_ID
			,dwma.ASSESSMENT_ID
			,pre.CARE_ID AS OrigCARE_ID
			,renum_mainref_major.CARE_ID
			,pre.TEMP_ID 
			,pre.ASSESSMENT_DATE
			,pre.AssessmentIx
			,pre.AssessmentRevIx
			,ass_aud.ACTION_ID
			,pre.FollowUpCode
			,pre.FollowUpDesc
			,pre.StratifiedFollowupTypeCode
			,pre.StratifiedFollowupTypeDesc
			,pre.SurveillanceFlag
			,pre.SurveillanceIx
			,pre.SurveillanceRevIx
			,pre.FollowUpPeriod
			,pre.FollowUpEndDate
			,pre.LastUpdatedBy AS OrigLastUpdatedBy
			,LEFT(CAST(dwusers.FullName + ' {.' + dwusers.UserName + '.}' AS VARCHAR(4000)),50) AS LastUpdatedBy 
			,pre.LastUpdateDate
			,pre.ReportDate

FROM		SCR_Warehouse.SCR_Assessments pre

LEFT JOIN	SCR_DW.SCR.dbo_tblMAIN_REFERRALS dwref
											ON	pre.CARE_ID = dwref.DW_SOURCE_ID
											AND pre.SrcSysID = dwref.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_ETL.map.tblMAIN_REFERRALS_tblValidatedData ref_vd_minor
																			ON	pre.SrcSysId = ref_vd_minor.SrcSys
																			AND	pre.CARE_ID = ref_vd_minor.Src_UID
INNER JOIN	SCR_DW.SCR.dbo_tblMAIN_REFERRALS renum_mainref_major
																ON	ref_vd_minor.Src_UID_MajorExt = renum_mainref_major.DW_SOURCE_ID
																AND ref_vd_minor.SrcSys_MajorExt = renum_mainref_major.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblMAIN_ASSESSMENT dwma
											ON pre.ASSESSMENT_ID = dwma.DW_SOURCE_ID
											AND pre.SrcSysID = dwma.DW_SOURCE_SYSTEM_ID							
LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT ass_aud
										ON pre.ACTION_ID = ass_aud.DW_SOURCE_ID
										AND pre.SrcSysID = ass_aud.DW_SOURCE_SYSTEM_ID	
LEFT JOIN	CancerReporting_PREMERGE.LocalConfig.tblAUDIT user_aud
														ON pre.ACTION_ID = user_aud.ACTION_ID
														AND pre.SrcSysID = user_aud.SrcSysID
LEFT JOIN	SCR_DW.SCR.dbo_AspNetUsers dwusers
										ON	user_aud.SrcSysID = dwusers.DW_SOURCE_SYSTEM_ID
										AND	LOWER(user_aud.USER_ID) = dwusers.DW_SOURCE_ID
										

								
GO
