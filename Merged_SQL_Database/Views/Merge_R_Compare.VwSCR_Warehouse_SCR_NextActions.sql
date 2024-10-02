SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [Merge_R_Compare].[VwSCR_Warehouse_SCR_NextActions]
AS

SELECT		 [PathwayUpdateEventID]
			,[SrcSysID]
			,[CareID]
			,[NextActionID]
			,[NextActionDesc]
			,[NextActionSpecificID]
			,[NextActionSpecificDesc]
			,[AdditionalDetails]
			,[OwnerID]
			,[OwnerDesc]
			,[OwnerRole]
			,[OwnerName]
			,[TargetDate]
			,[Escalate]
			,[OrganisationID]
			,[OrganisationDesc]
			,[ActionComplete]
			,[Inserted]
			,[InsertedBy]
			,[ACTION_ID]
			,[LastUpdated]
			,[LastUpdatedBy]
			,[CareIdIx]
			,[CareIdRevIx]
			,[CareIdIncompleteIx]
			,[CareIdIncompleteRevIx]
			,[ReportDate]
			,[NextActionColourValue]

FROM		[SCR_Warehouse].[SCR_NextActions]

GO
