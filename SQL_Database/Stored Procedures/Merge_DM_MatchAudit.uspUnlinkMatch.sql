SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_MatchAudit].[uspUnlinkMatch]

		(@Success BIT
		,@ErrorMessage VARCHAR(MAX) = NULL
		,@UserID VARCHAR(255)

		,@tableName VARCHAR(255)
		,@SrcSys_Major TINYINT
		,@Src_UID_Major VARCHAR(255)
		,@SrcSys TINYINT
		,@Src_UID VARCHAR(255)
		)

AS 

INSERT INTO Merge_DM_MatchAudit.tblUnlinkMatch
		(Success
		,ErrorMessage
		,UserID

		,tableName
		,SrcSys_Major
		,Src_UID_Major
		,SrcSys
		,Src_UID
		)

VALUES	(@Success
		,@ErrorMessage
		,@UserID

		,@tableName
		,@SrcSys_Major
		,@Src_UID_Major
		,@SrcSys
		,@Src_UID
		)
GO
