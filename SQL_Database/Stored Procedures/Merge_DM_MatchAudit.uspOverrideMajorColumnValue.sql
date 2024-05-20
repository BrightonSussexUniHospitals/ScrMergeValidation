SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_MatchAudit].[uspOverrideMajorColumnValue]

		(@Success BIT
		,@ErrorMessage VARCHAR(MAX) = NULL
		,@UserID VARCHAR(255)

		,@tableName VARCHAR(255)
		,@SrcSys_Major TINYINT
		,@Src_UID_Major VARCHAR(255)
		,@ColumnName VARCHAR(255)
		,@SrcSys_Donor TINYINT
		,@Src_UID_Donor VARCHAR(255)
		)

AS 

PRINT 'Merge_DM_MatchAudit.uspOverrideMajorColumnValue'

INSERT INTO Merge_DM_MatchAudit.tblOverrideMajorColumnValue
		(Success
		,ErrorMessage
		,UserID

		,tableName
		,SrcSys_Major
		,Src_UID_Major
		,ColumnName
		,SrcSys_Donor
		,Src_UID_Donor
		)

VALUES	(@Success
		,@ErrorMessage
		,@UserID

		,@tableName
		,@SrcSys_Major
		,@Src_UID_Major
		,@ColumnName
		,@SrcSys_Donor
		,@Src_UID_Donor
		)
GO
