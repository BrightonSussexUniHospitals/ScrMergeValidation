SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [Merge_R_Compare].[VwSCR_Warehouse_Workflow]
AS

SELECT		 pre.SrcSysID AS OrigSrcSysID
			,5 AS SrcSysID
			,pre.IdentityTypeRecordId AS OrigIdentityTypeRecordId
			,cwt.CWT_ID AS IdentityTypeRecordId
			,pre.IdentityTypeId
			,pre.WorkflowID

FROM		SCR_Warehouse.Workflow pre

LEFT JOIN	Merge_R_Compare.VwSCR_Warehouse_SCR_CWT cwt
													ON pre.IdentityTypeRecordId = cwt.OrigCWT_ID

GO
