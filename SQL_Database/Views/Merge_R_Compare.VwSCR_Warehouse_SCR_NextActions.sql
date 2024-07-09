SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [Merge_R_Compare].[VwSCR_Warehouse_SCR_NextActions]
AS

WITH OrganisationSites AS 
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

SELECT		 pre.PathwayUpdateEventID AS OrigPathwayUpdateEventID
			,dwpue.PathwayUpdateEventID
			,pre.SrcSysID AS OrigSrcSysID
			,5 AS SrcSysID
			,pre.CareID AS OrigCareID
			,dwref.CARE_ID AS CareID
			,pre.NextActionID --mapping
			,pre.NextActionDesc
			,pre.NextActionSpecificID --mapping?
			,pre.NextActionSpecificDesc
			,pre.AdditionalDetails
			,pre.OwnerID --mapping?
			,pre.OwnerDesc
			,pre.OwnerRole
			,pre.OwnerName
			,pre.TargetDate
			,pre.Escalate
			,dworg_na.ID AS OrganisationID
			,dworg_na.Description AS OrganisationDesc
			,pre.ActionComplete
			,pre.Inserted
			,pre.InsertedBy
			,aud.ACTION_ID -- ACTION_ID mapped
			,pre.LastUpdated
			,pre.LastUpdatedBy
			,pre.CareIdIx
			,pre.CareIdRevIx 
			,pre.CareIdIncompleteIx
			,pre.CareIdIncompleteRevIx
			,pre.ReportDate
			,pre.NextActionColourValue

FROM		SCR_Warehouse.SCR_NextActions pre

LEFT JOIN	SCR_DW.SCR.dbo_tblPathwayUpdateEvents dwpue
											ON	pre.PathwayUpdateEventID = dwpue.DW_SOURCE_ID
											AND pre.SrcSysID = dwpue.DW_SOURCE_SYSTEM_ID

LEFT JOIN	SCR_DW.SCR.dbo_tblMAIN_REFERRALS dwref
											ON	pre.CareID = dwref.DW_SOURCE_ID
											AND pre.SrcSysID = dwref.DW_SOURCE_SYSTEM_ID

LEFT JOIN	OrganisationSites dworg_na
									ON pre.OrganisationID = dworg_na.DW_SOURCE_ID 
									AND pre.SrcSysID = dworg_na.DW_SOURCE_SYSTEM_ID

LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT aud
									ON	pre.SrcSysID = aud.DW_SOURCE_SYSTEM_ID
									AND	pre.ACTION_ID = aud.DW_SOURCE_ID

GO
