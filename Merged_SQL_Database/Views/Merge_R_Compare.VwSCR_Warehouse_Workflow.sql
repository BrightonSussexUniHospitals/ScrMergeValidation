SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [Merge_R_Compare].[VwSCR_Warehouse_Workflow]
AS

SELECT		 [SrcSysID]
			,[IdentityTypeRecordId]
			,[IdentityTypeId]
			,[WorkflowID]

FROM		[SCR_Warehouse].[Workflow]

GO
