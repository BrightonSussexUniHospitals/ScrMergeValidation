SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [Merge_R_Compare].[VwSCR_Warehouse_SCR_InterProviderTransfers]
AS

SELECT		 [SrcSysID]
			,[TertiaryReferralID]
			,[CareID]
			,[ACTION_ID]
			,[SCR_IPTTypeCode]
			,[SCR_IPTTypeDesc]
			,[LogicalIPTTypeCode]
			,[LogicalIPTTypeDesc]
			,[IPTDate]
			,[IPTReferralReasonCode]
			,[IPTReferralReasonDesc]
			,[IPTReceiptReasonCode]
			,[IPTReceiptReasonDesc]
			,[ReferringOrgID]
			,[ReferringOrgCode]
			,[ReferringOrgName]
			,LEFT(CAST([TertiaryReferralOutComments] AS VARCHAR(1000)),1000) AS [TertiaryReferralOutComments]
			,[ReceivingOrgID]
			,[ReceivingOrgCode]
			,[ReceivingOrgName]
			,[IptReasonTypeCareIdIx]
			,IptPPI_Ix
			,IptPPI_RevIx
			,IptChainRevIx
			,IptErrorCode
			,IptErrorDesc
			,BreakChain
			,IncludeInChain
			,[IsTransferOfCare]
			,[LastUpdatedBy]

FROM		[SCR_Warehouse].[SCR_InterProviderTransfers]

GO
