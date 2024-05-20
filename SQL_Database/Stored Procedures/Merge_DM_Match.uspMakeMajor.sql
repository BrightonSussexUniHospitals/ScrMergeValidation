SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_Match].[uspMakeMajor]

		(@tableName VARCHAR(255)
		,@SrcSys_Major_Curr TINYINT = NULL
		,@Src_UID_Major_Curr VARCHAR(255) = NULL
		,@SrcSys_Major_New TINYINT = NULL
		,@Src_UID_Major_New VARCHAR(255) = NULL
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
Description:				A stored procedure to switch which record is considered the major record
							when there are matched duplicates
**************************************************************************************************************************************************/

-- Test me
-- EXEC Merge_DM_Match.uspMakeMajor @tableName = 'tbl_XXX', @SrcSys_Major_Curr = 1, @Src_UID_Major_Curr = 11, @SrcSys_Major_New = 2, @Src_UID_Major_New = 12, @UserId = 'BSUH\matthew.bishop'
-- EXEC Merge_DM_Match.uspMakeMajor @tableName = 'tbl_XXX', @SrcSys_Major_Curr = 2, @Src_UID_Major_Curr = 12, @SrcSys_Major_New = 1, @Src_UID_Major_New = 11, @UserId = 'BSUH\matthew.bishop'

/*****************************************************************************************************************************************/
-- Create and populate the #MakeMajor table if it doesn't already exist
/*****************************************************************************************************************************************/
		
		IF OBJECT_ID('tempdb..#MakeMajor') IS NULL 
		BEGIN
				-- Check all parameter values are present
				IF @SrcSys_Major_Curr IS NULL
				OR @Src_UID_Major_Curr IS NULL
				OR @SrcSys_Major_New IS NULL
				OR @Src_UID_Major_New IS NULL
				BEGIN
						
						-- Record the error
						EXEC Merge_DM_MatchAudit.uspMakeMajor 0, 'Null parameter(s) supplied', @UserID, @tableName, @SrcSys_Major_Curr, @Src_UID_Major_Curr, @SrcSys_Major_New, @Src_UID_Major_New
						
						-- Exit the procedure
						PRINT 'Exit procedure because null parameters have been supplied and there is no #MakeMajor table'
						RETURN

				END
				
				-- Create the #MakeMajor table
				CREATE TABLE #MakeMajor
							(SrcSys_Major_Curr TINYINT
							,Src_UID_Major_Curr VARCHAR(255)
							,SrcSys_Major_New TINYINT
							,Src_UID_Major_New VARCHAR(255)
							)

				-- Populate the #MakeMajor table with the provided parameter values
				INSERT INTO	#MakeMajor (SrcSys_Major_Curr,Src_UID_Major_Curr,SrcSys_Major_New,Src_UID_Major_New)
				VALUES (@SrcSys_Major_Curr, @Src_UID_Major_Curr, @SrcSys_Major_New, @Src_UID_Major_New)
				
		END

		IF OBJECT_ID('tempdb..#Aud_MakeMajor') IS NULL 
		BEGIN
				-- Create the #Aud_MakeMajor table to pass successes / failures to the audit trail
				CREATE TABLE #Aud_MakeMajor
							(Success BIT
							,ErrorMessage VARCHAR(MAX)
							,UserID VARCHAR(255)
							,tableName VARCHAR(255)
							,SrcSys_Major_Curr TINYINT
							,Src_UID_Major_Curr VARCHAR(255)
							,SrcSys_Major_New TINYINT
							,Src_UID_Major_New VARCHAR(255)
							)

		END
		ELSE
		BEGIN
				-- Truncate the #Aud_MakeMajor table so we only pass successes / failures from this execution to the audit trail
				TRUNCATE TABLE #Aud_MakeMajor
		END

/*****************************************************************************************************************************************/
-- Prepare for the updates
/*****************************************************************************************************************************************/
		
		DECLARE @SQL VARCHAR(MAX)

		-- Create a control table we will use to manage the dynamic SQL
		IF OBJECT_ID('tempdb..#DynamicSqlControl') IS NOT NULL DROP TABLE #DynamicSqlControl
		CREATE TABLE #DynamicSqlControl (ControlType VARCHAR(255), ControlValue SQL_VARIANT)

		-- Test whether the new major record is within the group of the current major record and that the new major is an SCR record
		SET @SQL =	'INSERT INTO #DynamicSqlControl (ControlType, ControlValue) ' + 
					'SELECT ''ValidityTest'', COUNT(*) ' + 
					'FROM		Merge_DM_Match.' + @tableName + '_Match_Control mc ' + CHAR(13) +
					'INNER JOIN	#MakeMajor mm ' + CHAR(13) +
					'						ON	mc.SrcSys_Major = mm.SrcSys_Major_Curr ' + CHAR(13) +
					'						AND	mc.Src_UID_Major = mm.Src_UID_Major_Curr ' + CHAR(13)

		EXEC (@SQL)

/*****************************************************************************************************************************************/
-- Make the updates
/*****************************************************************************************************************************************/
		
		IF (SELECT COUNT(*) FROM #DynamicSqlControl WHERE ControlType = 'ValidityTest') = 1
		BEGIN TRY

			BEGIN TRANSACTION

				-- Create a table to keep a record of entities that were inserted
				CREATE TABLE #MakeMajor_inserted
							(SrcSys_Major_Curr TINYINT
							,Src_UID_Major_Curr VARCHAR(255)
							,SrcSys_Major_New TINYINT
							,Src_UID_Major_New VARCHAR(255)
							)
				
				-- update all records in Control table with the current major value to use the new major value
				SET @SQL =	'UPDATE		mc ' + CHAR(13) +
							'SET		SrcSys_Major = mm.SrcSys_Major_New ' + CHAR(13) +
							'			,Src_UID_Major = mm.Src_UID_Major_New ' + CHAR(13) +
							'OUTPUT		deleted.SrcSys_Major ' + CHAR(13) +
							'			,deleted.Src_UID_Major ' + CHAR(13) +
							'			,inserted.SrcSys_Major ' + CHAR(13) +
							'			,inserted.Src_UID_Major ' + CHAR(13) +
							'INTO		#MakeMajor_inserted ' + CHAR(13) +
							'FROM		Merge_DM_Match.' + @tableName + '_Match_Control mc ' + CHAR(13) +
							'INNER JOIN	#MakeMajor mm ' + CHAR(13) +
							'						ON	mc.SrcSys_Major = mm.SrcSys_Major_Curr ' + CHAR(13) +
							'						AND	mc.Src_UID_Major = mm.Src_UID_Major_Curr ' + CHAR(13)

				EXEC (@SQL)

				-- update all records in MajorValidation table with the current major value to use the new major value and LastValidatedDttm
				SET @SQL =	'UPDATE		mmv ' + CHAR(13) +
							'SET		SrcSys_Major = mm.SrcSys_Major_New ' + CHAR(13) +
							'			,Src_UID_Major = mm.Src_UID_Major_New ' + CHAR(13) +
							'OUTPUT		deleted.SrcSys_Major ' + CHAR(13) +
							'			,deleted.Src_UID_Major ' + CHAR(13) +
							'			,inserted.SrcSys_Major ' + CHAR(13) +
							'			,inserted.Src_UID_Major ' + CHAR(13) +
							'INTO		#MakeMajor_inserted ' + CHAR(13) +
							'FROM		Merge_DM_Match.' + @tableName + '_Match_MajorValidation mmv ' + CHAR(13) +
							'INNER JOIN	#MakeMajor mm ' + CHAR(13) +
							'						ON	mmv.SrcSys_Major = mm.SrcSys_Major_Curr ' + CHAR(13) +
							'						AND	mmv.Src_UID_Major = mm.Src_UID_Major_Curr ' + CHAR(13)

				EXEC (@SQL)

				-- update all records in MajorValidationColumns table with the current major value to use the new major value and LastValidatedDttm
				SET @SQL =	'UPDATE		mmvc ' + CHAR(13) +
							'SET		SrcSys_Major = mm.SrcSys_Major_New ' + CHAR(13) +
							'			,Src_UID_Major = mm.Src_UID_Major_New ' + CHAR(13) +
							'OUTPUT		deleted.SrcSys_Major ' + CHAR(13) +
							'			,deleted.Src_UID_Major ' + CHAR(13) +
							'			,inserted.SrcSys_Major ' + CHAR(13) +
							'			,inserted.Src_UID_Major ' + CHAR(13) +
							'INTO		#MakeMajor_inserted ' + CHAR(13) +
							'FROM		Merge_DM_Match.' + @tableName + '_Match_MajorValidationColumns mmvc ' + CHAR(13) +
							'INNER JOIN	#MakeMajor mm ' + CHAR(13) +
							'						ON	mmvc.SrcSys_Major = mm.SrcSys_Major_Curr ' + CHAR(13) +
							'						AND	mmvc.Src_UID_Major = mm.Src_UID_Major_Curr ' + CHAR(13)

				EXEC (@SQL)

				-- Create the Audit trail data for the successes
				INSERT INTO	#Aud_MakeMajor (Success,ErrorMessage,UserID,tableName,SrcSys_Major_Curr,Src_UID_Major_Curr,SrcSys_Major_New,Src_UID_Major_New)
				SELECT		1
							,''
							,@UserID
							,@tableName
							,mmi.SrcSys_Major_Curr
                            ,mmi.Src_UID_Major_Curr
							,mmi.SrcSys_Major_New
							,mmi.Src_UID_Major_New
				FROM		#MakeMajor_inserted mmi
				GROUP BY	mmi.SrcSys_Major_Curr
                            ,mmi.Src_UID_Major_Curr
							,mmi.SrcSys_Major_New
							,mmi.Src_UID_Major_New

				-- Create the Audit trail data for the failures
				INSERT INTO	#Aud_MakeMajor (Success,ErrorMessage,UserID,tableName,SrcSys_Major_Curr,Src_UID_Major_Curr,SrcSys_Major_New,Src_UID_Major_New)
				SELECT		0
							,'Did not achieve the cohort of inserted / updated major records for confirming the major'
							,@UserID
							,@tableName
							,mmi.SrcSys_Major_Curr
                            ,mmi.Src_UID_Major_Curr
							,mmi.SrcSys_Major_New
							,mmi.Src_UID_Major_New
				FROM		#MakeMajor mm
				LEFT JOIN	#MakeMajor_inserted mmi
														ON	mm.SrcSys_Major_Curr = mmi.SrcSys_Major_Curr
														AND	mm.Src_UID_Major_Curr = mmi.Src_UID_Major_Curr
														AND	mm.SrcSys_Major_New = mmi.SrcSys_Major_New
														AND	mm.Src_UID_Major_New = mmi.Src_UID_Major_New
				WHERE		mmi.SrcSys_Major_Curr IS NULL
				GROUP BY	mmi.SrcSys_Major_Curr
                            ,mmi.Src_UID_Major_Curr
							,mmi.SrcSys_Major_New
							,mmi.Src_UID_Major_New

				-- Update the audit trail
				EXEC Merge_DM_MatchAudit.uspMakeMajor
		
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
			INSERT INTO	#Aud_MakeMajor (Success,ErrorMessage,UserID,tableName,SrcSys_Major_Curr,Src_UID_Major_Curr,SrcSys_Major_New,Src_UID_Major_New)
			SELECT		0
						,@ErrorMessage
						,@UserID
						,@tableName
						,mm.SrcSys_Major_Curr
                        ,mm.Src_UID_Major_Curr
						,mm.SrcSys_Major_New
						,mm.Src_UID_Major_New
			FROM		#MakeMajor mm

			-- Update the audit trail
			EXEC Merge_DM_MatchAudit.uspMakeMajor

			RAISERROR (@ErrorMessage, -- Message text.  
										15, -- Severity.  
										1 -- State.  
										);
			RETURN 1

		END CATCH

GO
