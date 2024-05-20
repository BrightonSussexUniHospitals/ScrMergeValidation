SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_MatchAudit].[uspConfirmMajor]

		(@Success BIT = NULL
		,@ErrorMessage VARCHAR(MAX) = NULL
		,@UserID VARCHAR(255) = NULL

		,@tableName VARCHAR(255) = NULL
		,@SrcSys_Major TINYINT = NULL
		,@Src_UID_Major VARCHAR(255) = NULL
		)

AS 

/*****************************************************************************************************************************************/
-- Create and populate the #Aud_ConfirmMajor table if it doesn't already exist
/*****************************************************************************************************************************************/
		
		IF OBJECT_ID('tempdb..#Aud_ConfirmMajor') IS NULL 
		BEGIN
				
				-- Throw an error if there are missing parameter values
				IF @Success IS NULL OR @UserID IS NULL OR @tableName IS NULL OR @SrcSys_Major IS NULL OR @Src_UID_Major IS NULL
				THROW 50000, 'A null parameter value has been passed where one is expected', 1
				
				-- Create the #Aud_ConfirmMajor table
				CREATE TABLE #Aud_ConfirmMajor
							(Success BIT
							,ErrorMessage VARCHAR(MAX)
							,UserID VARCHAR(255)
							,tableName VARCHAR(255)
							,SrcSys_Major TINYINT
							,Src_UID_Major VARCHAR(255)
							)

				-- Populate the #Aud_ConfirmMajor table with the provided parameter values
				INSERT INTO	#Aud_ConfirmMajor (Success,ErrorMessage,UserID,tableName,SrcSys_Major,Src_UID_Major)
				VALUES (@Success, @ErrorMessage, @UserID, @tableName, @SrcSys_Major, @Src_UID_Major)
				
		END

/*****************************************************************************************************************************************/
-- Insert an audit record of attempts to update Merge_DM_Match.tblConfirmMajor
/*****************************************************************************************************************************************/
		
INSERT INTO Merge_DM_MatchAudit.tblConfirmMajor
			(Success
			,ErrorMessage
			,UserID
			,tableName
			,SrcSys_Major
			,Src_UID_Major
			)

SELECT		Success
			,ErrorMessage
			,UserID
			,tableName
			,SrcSys_Major
			,Src_UID_Major
FROM		#Aud_ConfirmMajor
GO
