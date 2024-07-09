SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_Match].[uspConfirmMajor]

		(@tableName VARCHAR(255)
		,@SrcSys_Major TINYINT = NULL
		,@Src_UID_Major VARCHAR(255) = NULL
		,@UserID VARCHAR(255)
		)

AS 

/******************************************************** © Copyright & Licensing ****************************************************************
© 2024 Perspicacity Ltd & University Hospitals Sussex

This code / file is part of Perspicacity & University Hospitals Sussex SCR merge validation suite.

This SCR merge validation suite is free software: you can 
redistribute it and/or modify it under the terms of the GNU Affero 
General Public License as published by the Free Software Foundation, 
either version 3 of the License, or (at your option) any later version.

This SCR migration merge suite is distributed in the hope 
that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

A full copy of this code can be found at https://github.com/BrightonSussexUniHospitals/ScrMergeValidation

You may also be interested in the other repositories at https://github.com/perspicacity-ltd or
https://github.com/BrightonSussexUniHospitals

Original Work Created Date:	31/01/2024
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				A stored procedure to confirm a major entity as being the correct record for migration
**************************************************************************************************************************************************/

-- Test me
-- EXEC Merge_DM_Match.uspConfirmMajor @tableName = 'tbl_XXX', @SrcSys_Major = 1, @Src_UID_Major = 1, @UserId = 'matthew.bishop'

/*****************************************************************************************************************************************/
-- Create and populate the #ConfirmMajor table if it doesn't already exist
/*****************************************************************************************************************************************/
		
		IF OBJECT_ID('tempdb..#ConfirmMajor') IS NULL 
		BEGIN
				-- Check all parameter values are present
				IF @SrcSys_Major IS NULL
				OR @Src_UID_Major IS NULL
				BEGIN
						
						-- Record the error
						EXEC Merge_DM_MatchAudit.uspConfirmMajor 0, 'Null parameter(s) supplied', @UserID, @tableName, @SrcSys_Major, @Src_UID_Major
						
						-- Exit the procedure
						RETURN

				END
				
				-- Create the #ConfirmMajor table
				CREATE TABLE #ConfirmMajor
							(SrcSys_Major TINYINT
							,Src_UID_Major VARCHAR(255)
							)

				-- Populate the #ConfirmMajor table with the provided parameter values
				INSERT INTO	#ConfirmMajor (SrcSys_Major,Src_UID_Major)
				VALUES (@SrcSys_Major, @Src_UID_Major)
				
		END

		IF OBJECT_ID('tempdb..#Aud_ConfirmMajor') IS NULL 
		BEGIN
				-- Create the #Aud_ConfirmMajor table to pass successes / failures to the audit trail
				CREATE TABLE #Aud_ConfirmMajor
							(Success BIT
							,ErrorMessage VARCHAR(MAX)
							,UserID VARCHAR(255)
							,tableName VARCHAR(255)
							,SrcSys_Major TINYINT
							,Src_UID_Major VARCHAR(255)
							)

		END
		ELSE
		BEGIN
				-- Truncate the #Aud_ConfirmMajor table so we only pass successes / failures from this execution to the audit trail
				TRUNCATE TABLE #Aud_ConfirmMajor
		END

/*****************************************************************************************************************************************/
-- Prepare for the updates
/*****************************************************************************************************************************************/
		
		DECLARE @SQL VARCHAR(MAX)

		-- Create a control table we will use to manage the dynamic SQL
		IF OBJECT_ID('tempdb..#DynamicSqlControl') IS NOT NULL DROP TABLE #DynamicSqlControl
		CREATE TABLE #DynamicSqlControl (ControlType VARCHAR(255), ControlValue SQL_VARIANT)

		-- Test whether any of the entities being confirmed are a major entity and an SCR record
		SET @SQL =	'INSERT INTO #DynamicSqlControl (ControlType, ControlValue) ' + CHAR(13) +
					'SELECT		''ValidityTest'', COUNT(*) ' + CHAR(13) +
					'FROM		Merge_DM_Match.' + @tableName + '_Match_Control mc ' + CHAR(13) +
					'INNER JOIN	#ConfirmMajor cm ' + CHAR(13) +
					'							ON mc.SrcSys_Major = cm.SrcSys_Major ' + CHAR(13) +
					'							AND mc.Src_UID_Major = cm.Src_UID_Major ' --+ CHAR(13) +
					--'WHERE		mc.IsScr = 1' -- commented to allow non-SCR records to become the major
		EXEC (@SQL)

		-- Record a consistent getdate in the dynamic sql control table
		INSERT INTO #DynamicSqlControl (ControlType, ControlValue) SELECT 'GETDATE', GETDATE()

/*****************************************************************************************************************************************/
-- Make the updates
/*****************************************************************************************************************************************/
		
		IF (SELECT COUNT(*) FROM #DynamicSqlControl WHERE ControlType = 'ValidityTest' AND ControlValue > 0) = 1
		BEGIN TRY

			BEGIN TRANSACTION

				-- Create a table to keep a record of entities that were inserted
				CREATE TABLE #ConfirmMajor_inserted
							(SrcSys_Major TINYINT
							,Src_UID_Major VARCHAR(255)
							)
				
				-- Update the major validation record (or create it if it does not exist)
				SET @SQL =	'DECLARE @GetDate DATETIME2; SELECT @GetDate = CONVERT(DATETIME2, ControlValue) FROM #DynamicSqlControl WHERE ControlType = ''GETDATE''; ' + CHAR(13) +
							'INSERT INTO	Merge_DM_Match.' + @tableName + '_Match_MajorValidation ' + CHAR(13) +
							'			(SrcSys_Major ' + CHAR(13) +
							'			,Src_UID_Major ' + CHAR(13) +
							'			,LastValidatedDttm ' + CHAR(13) +
							'			,LastValidatedBy ' + CHAR(13) +
							'			,ValidationStatus ' + CHAR(13) +
							'			) ' + CHAR(13) +
							'OUTPUT		inserted.SrcSys_Major ' + CHAR(13) +
							'			,inserted.Src_UID_Major ' + CHAR(13) +
							'INTO		#ConfirmMajor_inserted ' + CHAR(13) +
							'SELECT		cm.SrcSys_Major ' + CHAR(13) +
							'			,cm.Src_UID_Major ' + CHAR(13) +
							'			,@GetDate ' + CHAR(13) +
							'			,''' + @UserID + ''' ' + CHAR(13) +
							'			,''Confirmed'' ' + CHAR(13) +
							'FROM		#ConfirmMajor cm ' + CHAR(13) +
							'LEFT JOIN	Merge_DM_Match.' + @tableName + '_Match_MajorValidation mmv ' + CHAR(13) +
							'											ON	cm.SrcSys_Major = mmv.SrcSys_Major ' + CHAR(13) +
							'											AND	cm.Src_UID_Major = mmv.Src_UID_Major ' + CHAR(13) +
							'WHERE		mmv.SrcSys_Major IS NULL ' + CHAR(13) +
							'AND		cm.SrcSys_Major IS NOT NULL ' + CHAR(13) +
							'AND		cm.Src_UID_Major IS NOT NULL ' + CHAR(13) +
							' ' + CHAR(13) +
							'UPDATE		mmv ' + CHAR(13) +
							'SET		LastValidatedDttm = @GetDate ' + CHAR(13) +
							'			,LastValidatedBy = ''' + @UserID + ''' ' + CHAR(13) +
							'			,ValidationStatus = ''Confirmed'' ' + CHAR(13) +
							'OUTPUT		inserted.SrcSys_Major ' + CHAR(13) +
							'			,inserted.Src_UID_Major ' + CHAR(13) +
							'INTO		#ConfirmMajor_inserted ' + CHAR(13) +
							'FROM		#ConfirmMajor cm ' + CHAR(13) +
							'INNER JOIN	Merge_DM_Match.' + @tableName + '_Match_MajorValidation mmv ' + CHAR(13) +
							'											ON	cm.SrcSys_Major = mmv.SrcSys_Major ' + CHAR(13) +
							'											AND	cm.Src_UID_Major = mmv.Src_UID_Major '

				EXEC (@SQL)

				-- Create the Audit trail data for the successes
				INSERT INTO	#Aud_ConfirmMajor (Success,ErrorMessage,UserID,tableName,SrcSys_Major,Src_UID_Major)
				SELECT		1
							,''
							,@UserID
							,@tableName
							,cmi.SrcSys_Major
                            ,cmi.Src_UID_Major
				FROM		#ConfirmMajor_inserted cmi
				GROUP BY	cmi.SrcSys_Major
                            ,cmi.Src_UID_Major

				-- Create the Audit trail data for the failures
				INSERT INTO	#Aud_ConfirmMajor (Success,ErrorMessage,UserID,tableName,SrcSys_Major,Src_UID_Major)
				SELECT		0
							,'Did not achieve the cohort of inserted / updated major records for confirming the major'
							,@UserID
							,@tableName
							,cmi.SrcSys_Major
                            ,cmi.Src_UID_Major
				FROM		#ConfirmMajor cm
				LEFT JOIN	#ConfirmMajor_inserted cmi
														ON	cm.SrcSys_Major = cmi.SrcSys_Major
														AND	cm.Src_UID_Major = cmi.Src_UID_Major
				WHERE		cmi.SrcSys_Major IS NULL
				GROUP BY	cmi.SrcSys_Major
                            ,cmi.Src_UID_Major

				-- Update the audit trail
				EXEC Merge_DM_MatchAudit.uspConfirmMajor
				
			COMMIT TRANSACTION

			RETURN 0

		END TRY

		BEGIN CATCH
 
			DECLARE @ErrorMessage VARCHAR(MAX)
			SELECT @ErrorMessage = ERROR_MESSAGE()
			
			SELECT ERROR_NUMBER() AS ErrorNumber
			SELECT @ErrorMessage AS ErrorMessage
 
			PRINT ERROR_NUMBER()
			PRINT @ErrorMessage

			IF @@TRANCOUNT > 0 -- SELECT @@TRANCOUNT
					PRINT 'Rolling back because of error in Incremental Transaction'
			ROLLBACK TRANSACTION

			-- Create the Audit trail data for the failures
			INSERT INTO	#Aud_ConfirmMajor (Success,ErrorMessage,UserID,tableName,SrcSys_Major,Src_UID_Major)
			SELECT		0
						,@ErrorMessage
						,@UserID
						,@tableName
						,cm.SrcSys_Major
                        ,cm.Src_UID_Major
			FROM		#ConfirmMajor cm

			-- Update the audit trail
			EXEC Merge_DM_MatchAudit.uspConfirmMajor

			RAISERROR (@ErrorMessage, -- Message text.  
										15, -- Severity.  
										1 -- State.  
										);
			RETURN 1
 
		END CATCH

GO
