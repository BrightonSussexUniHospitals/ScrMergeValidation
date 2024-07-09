SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_Match].[uspDropOrKeep]

		(@tableName VARCHAR(255) = NULL
		,@SrcSys TINYINT = NULL
		,@RecordID VARCHAR(255) = NULL
		,@RecordVariant VARCHAR(255) = NULL
		,@UserID VARCHAR(255)
		,@Migrate BIT = NULL
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

Original Work Created Date:	03/06/2024
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				A stored procedure to confirm whether a record should be discarded or migrated
**************************************************************************************************************************************************/

-- Test me
-- EXEC Merge_DM_Match.uspDropOrKeep @tableName = 'Treatments', @SrcSys = 1, @RecordID = 51918, @RecordVariant = 'tblMAIN_SURGERY', @UserId = 'matthew.bishop', @Migrate = 1

/*****************************************************************************************************************************************/
-- Create and populate the #DropOrKeep table if it doesn't already exist
/*****************************************************************************************************************************************/
		
		IF OBJECT_ID('tempdb..#DropOrKeep') IS NULL 
		BEGIN
				-- Check all parameter values are present
				IF @SrcSys IS NULL
				OR @RecordID IS NULL
				OR @tableName IS NULL
				OR (@RecordVariant IS NULL AND @tableName IN ('Treatments','MDT'))
				OR @Migrate IS NULL
				BEGIN
						
						-- Record the error
						EXEC Merge_DM_MatchAudit.uspDropOrKeep 0, 'Null parameter(s) supplied', @UserID, @tableName, @SrcSys, @RecordID, @RecordVariant, @Migrate
						
						-- Exit the procedure
						RETURN

				END
				
				-- Create the #DropOrKeep table
				CREATE TABLE #DropOrKeep
							(tableName VARCHAR(255)
							,SrcSys TINYINT
							,RecordID VARCHAR(255)
							,RecordVariant VARCHAR(255)
							,Migrate BIT
							)

				-- Populate the #DropOrKeep table with the provided parameter values
				INSERT INTO	#DropOrKeep (tableName,SrcSys,RecordID,RecordVariant,Migrate)
				VALUES (@tableName, @SrcSys, @RecordID, @RecordVariant, @Migrate)
				SELECT * FROM #DropOrKeep
				
		END

		IF OBJECT_ID('tempdb..#Aud_DropOrKeep') IS NULL 
		BEGIN
				-- Create the #Aud_DropOrKeep table to pass successes / failures to the audit trail
				CREATE TABLE #Aud_DropOrKeep
							(Success BIT
							,ErrorMessage VARCHAR(MAX)
							,UserID VARCHAR(255)
							,tableName VARCHAR(255)
							,SrcSys TINYINT
							,RecordID VARCHAR(255)
							,RecordVariant VARCHAR(255)
							,Migrate BIT
							)

		END
		ELSE
		BEGIN
				-- Truncate the #Aud_DropOrKeep table so we only pass successes / failures from this execution to the audit trail
				TRUNCATE TABLE #Aud_DropOrKeep
		END

/*****************************************************************************************************************************************/
-- Make the updates
/*****************************************************************************************************************************************/
		
		BEGIN TRY

			BEGIN TRANSACTION

				-- Create a table to keep a record of entities that were inserted
				CREATE TABLE #DropOrKeep_inserted
							(DropOrKeepID INT IDENTITY(1,1)
							,tableName VARCHAR(255)
							,SrcSys TINYINT
							,RecordID VARCHAR(255)
							,RecordVariant VARCHAR(255)
							,Migrate BIT
							)
				
				-- Update the treatments match control table
				UPDATE		mc
				SET			Migrate = dk.Migrate
							,LastValidatedDttm = GETDATE()
							,LastValidatedBy = @UserID
							,LastValidated_SrcSys_Major = ref_mc.SrcSys_Major
							,LastValidated_Src_UID_Major = ref_mc.Src_UID_Major
				OUTPUT		dk.tableName
							,Inserted.SrcSys
							,Inserted.TreatmentID
							,Inserted.Treatment
							,Inserted.Migrate
				INTO		#DropOrKeep_inserted (tableName,SrcSys,RecordID,RecordVariant,Migrate)
				FROM		#DropOrKeep dk
				INNER JOIN	Merge_DM_Match.Treatments_Match_Control mc
											ON	dk.SrcSys = mc.SrcSys
											AND	CAST(dk.RecordID AS INT) = mc.TreatmentID
											AND	dk.RecordVariant = mc.Treatment
				INNER JOIN	Merge_DM_Match.Treatments_mvw_UH uh
																ON	dk.SrcSys = uh.Ref_SrcSys_Minor
																AND	dk.RecordID = uh.TreatmentID
																AND	dk.RecordVariant = uh.Treatment
				INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control ref_mc
																				ON	uh.Ref_SrcSys_Minor = ref_mc.SrcSys
																				AND	uh.Ref_Src_UID_Minor = ref_mc.Src_UID
				WHERE		dk.tableName = 'Treatments'


				-- Update the MDT match control table
				UPDATE		mc
				SET			Migrate = dk.Migrate
							,LastValidatedDttm = GETDATE()
							,LastValidatedBy = @UserID
							,LastValidated_SrcSys_Major = ref_mc.SrcSys_Major
							,LastValidated_Src_UID_Major = ref_mc.Src_UID_Major
				OUTPUT		dk.tableName
							,Inserted.SrcSys
							,Inserted.table_UID
							,Inserted.tableName
							,Inserted.Migrate
				INTO		#DropOrKeep_inserted (tableName,SrcSys,RecordID,RecordVariant,Migrate)
				FROM		#DropOrKeep dk
				INNER JOIN	Merge_DM_Match.MDT_Match_Control mc
											ON	dk.SrcSys = mc.SrcSys
											AND	dk.RecordID = mc.table_UID
											AND	dk.RecordVariant = mc.tableName
				INNER JOIN	Merge_DM_Match.MDT_mvw_UH uh
																ON	dk.SrcSys = uh.Ref_SrcSys_Minor
																AND	dk.RecordID = uh.table_UID
																AND	dk.RecordVariant = uh.tableName
				INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control ref_mc
																				ON	uh.Ref_SrcSys_Minor = ref_mc.SrcSys
																				AND	uh.Ref_Src_UID_Minor = ref_mc.Src_UID
				WHERE		dk.tableName = 'MDT'

				-- Update the IPT match control table

				-- Create the Audit trail data for the successes
				INSERT INTO	#Aud_DropOrKeep (Success,ErrorMessage,UserID,tableName,SrcSys,RecordID,RecordVariant,Migrate)
				SELECT		1
							,''
							,@UserID
							,@tableName
							,dki.SrcSys
                            ,dki.RecordID
							,dki.RecordVariant
							,dki.Migrate
				FROM		(SELECT		*
										,ROW_NUMBER() OVER (PARTITION BY SrcSys, RecordID, RecordVariant ORDER BY DropOrKeepID DESC) AS DropOrKeepIx
							FROM		#DropOrKeep_inserted
										) dki
				WHERE		dki.DropOrKeepIx = 1

				-- Create the Audit trail data for the failures
				INSERT INTO	#Aud_DropOrKeep (Success,ErrorMessage,UserID,tableName,SrcSys,RecordID,RecordVariant,Migrate)
				SELECT		0
							,'Did not achieve the cohort of updated drop / keep records for the ' + ISNULL(dk.tableName, 'unknown table') + ISNULL(' (' + dk.RecordVariant + ')', '') + ' table'
							,@UserID
							,@tableName
							,dk.SrcSys
                            ,dk.RecordID
							,dk.RecordVariant
							,dk.Migrate
				FROM		#DropOrKeep dk
				LEFT JOIN	#DropOrKeep_inserted dki
														ON	dk.tableName = dki.tableName
														AND	dk.SrcSys = dki.SrcSys
														AND	dk.RecordID = dki.RecordID
														AND	ISNULL(dk.RecordVariant,'') = ISNULL(dki.RecordVariant,'')
				WHERE		dki.tableName IS NULL

				-- Update the audit trail
				EXEC Merge_DM_MatchAudit.uspDropOrKeep
				
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

			WHILE @@TRANCOUNT > 0 -- SELECT @@TRANCOUNT
			BEGIN
					PRINT 'Rolling back because of error in Incremental Transaction'
					ROLLBACK TRANSACTION
			END

			-- Create the Audit trail data for the failures
			INSERT INTO	#Aud_DropOrKeep (Success,ErrorMessage,UserID,tableName,SrcSys,RecordID,RecordVariant,Migrate)
			SELECT		0
						,@ErrorMessage
						,@UserID
						,@tableName
						,dk.SrcSys
                        ,dk.RecordID
						,dk.RecordVariant
						,dk.Migrate
			FROM		#DropOrKeep dk

			-- Update the audit trail
			EXEC Merge_DM_MatchAudit.uspDropOrKeep

			RAISERROR (@ErrorMessage, -- Message text.  
										15, -- Severity.  
										1 -- State.  
										);
			RETURN 1
 
		END CATCH

GO
