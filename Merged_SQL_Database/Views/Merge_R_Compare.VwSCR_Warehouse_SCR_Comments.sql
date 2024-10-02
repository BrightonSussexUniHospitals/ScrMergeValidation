SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [Merge_R_Compare].[VwSCR_Warehouse_SCR_Comments]
AS

SELECT		 [SrcSysId]
			,[SourceRecordId]
			,[SourceTableName]
			,[SourceColumnName]
			,[CARE_ID]
			,LEFT(CAST([Comment] AS VARCHAR(1000)), 1000) AS [Comment]
			,[CommentUser]
			,[CommentDate]
			,[CommentType]
			,[CareIdIx]
			,[CareIdRevIx]
			,[CommentTypeCareIdIx]
			,[CommentTypeCareIdRevIx]
			,[ReportDate]

FROM		[SCR_Warehouse].[SCR_Comments]

GO
