SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE VIEW [Merge_R_Compare].[VwSCR_Warehouse_SCR_InterProviderTransfers]
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
		),OrganisationSites_Code AS 
		(SELECT	id
				,code
				,description
		FROM	SCR_DW.SCR.dbo_OrganisationSites
		)

SELECT		 pre.SrcSysID AS OrigSrcSysID
			,5 AS SrcSysID
			,pre.TertiaryReferralID AS OrigTertiaryReferralID
			,dwtr.TertiaryReferralID
			,pre.CareID AS OrigCARE_ID
			,renum_mainref_major.CARE_ID AS CareID
			,ipt_aud.ACTION_ID 
			,pre.SCR_IPTTypeCode
			,pre.SCR_IPTTypeDesc
			,pre.LogicalIPTTypeCode
			,pre.LogicalIPTTypeDesc
			,pre.IPTDate
			,pre.IPTReferralReasonCode
			,pre.IPTReferralReasonDesc
			,pre.IPTReceiptReasonCode
			,pre.IPTReceiptReasonDesc
			,ISNULL(dworg_ref.ID, pre.ReferringOrgID) AS ReferringOrgID 
			,dworg_ref.Code AS ReferringOrgCode 
			,dworg_ref.Description AS ReferringOrgName
			,LEFT(CAST(pre.TertiaryReferralOutComments AS VARCHAR(1000)),1000) AS TertiaryReferralOutComments
			,ISNULL(dworg_rec.ID, pre.ReceivingOrgID) AS ReceivingOrgID 
			,dworg_rec.Code AS ReceivingOrgCode
			,dworg_rec.Description AS ReceivingOrgName
			,pre.IptReasonTypeCareIdIx 
			,pre.IptPPI_Ix
			,pre.IptPPI_RevIx
			,pre.IptChainRevIx
			,pre.IptErrorCode
			,pre.IptErrorDesc
			,pre.BreakChain
			,pre.IncludeInChain
			,pre.IsTransferOfCare
			,LEFT(CAST(dwusers.FullName + ' {.' + dwusers.UserName + '.}' AS VARCHAR(4000)),50) AS LastUpdatedBy 

FROM		SCR_Warehouse.SCR_InterProviderTransfers pre

LEFT JOIN	SCR_DW.SCR.dbo_tblMAIN_REFERRALS dwref
											ON	pre.CareID = dwref.DW_SOURCE_ID
											AND pre.SrcSysID = dwref.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_ETL.map.tblMAIN_REFERRALS_tblValidatedData ref_vd_minor
																			ON	pre.SrcSysId = ref_vd_minor.SrcSys
																			AND	pre.CareID = ref_vd_minor.Src_UID
INNER JOIN	SCR_DW.SCR.dbo_tblMAIN_REFERRALS renum_mainref_major
																ON	ref_vd_minor.Src_UID_MajorExt = renum_mainref_major.DW_SOURCE_ID
																AND ref_vd_minor.SrcSys_MajorExt = renum_mainref_major.DW_SOURCE_SYSTEM_ID

LEFT JOIN 	SCR_DW.SCR.dbo_tblTERTIARY_REFERRALS dwtr
											ON pre.TertiaryReferralID = dwtr.DW_SOURCE_ID
											AND pre.SrcSysID = dwtr.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT ipt_aud									
											ON	pre.ACTION_ID = ipt_aud.DW_SOURCE_ID
											AND	pre.SrcSysID = ipt_aud.DW_SOURCE_SYSTEM_ID
LEFT JOIN	OrganisationSites_Id dworg_ref
									ON pre.ReferringOrgID = dworg_ref.DW_SOURCE_ID 
									AND pre.SrcSysID = dworg_ref.DW_SOURCE_SYSTEM_ID
LEFT JOIN	OrganisationSites_Id dworg_rec
									ON pre.ReceivingOrgID = dworg_rec.DW_SOURCE_ID 
									AND pre.SrcSysID = dworg_rec.DW_SOURCE_SYSTEM_ID
LEFT JOIN	CancerReporting_PREMERGE.LocalConfig.tblAUDIT user_aud
														ON pre.ACTION_ID = user_aud.ACTION_ID
														AND pre.SrcSysID = user_aud.SrcSysID
LEFT JOIN	SCR_DW.SCR.dbo_AspNetUsers dwusers
										ON	user_aud.SrcSysID = dwusers.DW_SOURCE_SYSTEM_ID
										AND	LOWER(user_aud.USER_ID) = dwusers.DW_SOURCE_ID

GO
