SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_MatchAudit].[uspDropOrKeep]

		(@Success BIT = NULL
		,@ErrorMessage VARCHAR(MAX) = NULL
		,@UserID VARCHAR(255) = NULL

		,@tableName VARCHAR(255) = NULL
		,@SrcSys TINYINT = NULL
		,@RecordID VARCHAR(255) = NULL
		,@RecordVariant VARCHAR(255) = NULL
		,@Migrate BIT = NULL
		)

AS 

/*****************************************************************************************************************************************/
-- Create and populate the #Aud_DropOrKeep table if it doesn't already exist
/*****************************************************************************************************************************************/
		
		IF OBJECT_ID('tempdb..#Aud_DropOrKeep') IS NULL 
		BEGIN
				
				-- Throw an error if there are missing parameter values
				IF @Success IS NULL OR @UserID IS NULL OR @tableName IS NULL
				THROW 50000, 'A null parameter value has been passed where one is expected', 1
				
				-- Create the #Aud_DropOrKeep table
				CREATE TABLE #Aud_DropOrKeep
							(Success BIT
							,ErrorMessage VARCHAR(MAX)
							,UserID VARCHAR(255)
							,tableName VARCHAR(255)
							,SrcSys TINYINT NULL
							,RecordID VARCHAR(255) NULL
							,RecordVariant VARCHAR(255) NULL
							,Migrate BIT NULL
							)

				-- Populate the #Aud_DropOrKeep table with the provided parameter values
				INSERT INTO	#Aud_DropOrKeep (Success,ErrorMessage,UserID,tableName,SrcSys,RecordID,RecordVariant,Migrate)
				VALUES (@Success, @ErrorMessage, @UserID, @tableName, @SrcSys, @RecordID, @RecordVariant, @Migrate)
				
		END

/*****************************************************************************************************************************************/
-- Insert an audit record of attempts to update Merge_DM_Match.tblDropOrKeep
/*****************************************************************************************************************************************/
		
INSERT INTO Merge_DM_MatchAudit.tblDropOrKeep
			(Success
			,ErrorMessage
			,UserID
			,tableName
			,SrcSys
			,RecordID
			,RecordVariant
			,Migrate
			)

SELECT		Success
			,ErrorMessage
			,UserID
			,tableName
			,SrcSys
			,RecordID
			,RecordVariant
			,Migrate
FROM		#Aud_DropOrKeep
GO
