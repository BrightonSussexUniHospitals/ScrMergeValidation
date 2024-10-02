SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [Merge_R_Compare].[VwSCR_Warehouse_SCR_Comments]
AS

SELECT		 pre.SrcSysId AS OrigSrcSysID
			,5 AS SrcSysId
			,pre.SourceRecordId AS OrigSourceRecordId
			,ISNULL(dwcom.COM_ID, dwcom_mcp.PLAN_ID) AS SourceRecordId
			,pre.SourceTableName
			,pre.SourceColumnName
			,pre.CARE_ID AS OrigCARE_ID
			,renum_mainref_major.CARE_ID
			,LEFT(CAST(pre.Comment AS VARCHAR(1000)), 1000) AS Comment
			,pre.CommentUser
			,pre.CommentDate
			,pre.CommentType
			,pre.CareIdIx
			,pre.CareIdRevIx
			,pre.CommentTypeCareIdIx
			,pre.CommentTypeCareIdRevIx
			,pre.ReportDate

FROM		SCR_Warehouse.SCR_Comments pre

LEFT JOIN	SCR_DW.SCR.dbo_tblMAIN_REFERRALS dwref
											ON	pre.CARE_ID = dwref.DW_SOURCE_ID
											AND pre.SrcSysID = dwref.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_ETL.map.tblMAIN_REFERRALS_tblValidatedData ref_vd_minor
																			ON	pre.SrcSysId = ref_vd_minor.SrcSys
																			AND	pre.CARE_ID = ref_vd_minor.Src_UID
INNER JOIN	SCR_DW.SCR.dbo_tblMAIN_REFERRALS renum_mainref_major
																ON	ref_vd_minor.Src_UID_MajorExt = renum_mainref_major.DW_SOURCE_ID
																AND ref_vd_minor.SrcSys_MajorExt = renum_mainref_major.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblTRACKING_COMMENTS dwcom
											ON pre.SourceRecordId = dwcom.DW_SOURCE_ID
											AND pre.SrcSysID = dwcom.DW_SOURCE_SYSTEM_ID
											AND	pre.SourceTableName = 'tblTRACKING_COMMENTS'
LEFT JOIN	SCR_DW.SCR.dbo_tblMAIN_CARE_PLAN dwcom_mcp
											ON pre.SourceRecordId = dwcom_mcp.DW_SOURCE_ID
											AND pre.SrcSysID = dwcom_mcp.DW_SOURCE_SYSTEM_ID
											AND	pre.SourceTableName = 'tblMAIN_CARE_PLAN'

GO
