SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_Match].[MDT_uspMatchControlUpdateAndMatch] 
				(@SrcSys TINYINT = NULL
				,@Src_UID VARCHAR(255) = NULL
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

Original Work Created Date:	22/05/2024
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				A stored procedure to update the data used in the matching
							and validation process with changes in the source data
**************************************************************************************************************************************************/

-- Test me
-- EXEC Merge_DM_Match.MDT_uspMatchControlUpdateAndMatch
-- EXEC Merge_DM_Match.MDT_uspMatchControlUpdateAndMatch @SrcSys = 1, @Src_UID = '388974'

		-- Set up the variables for process auditing
		DECLARE	@CurrentUser VARCHAR(255)
				,@ProcIdName VARCHAR(255)
				,@CurrentSection VARCHAR(255)
				,@CurrentDttm DATETIME2

		SELECT	@CurrentUser = CURRENT_USER
				,@ProcIdName = ISNULL(OBJECT_NAME(@@PROCID), 'ad hoc')

/*******************************************************************************************************************************************************************************************************************************************************************************/
-- Find all related entities (if we have been provided paremeters to return a specific referral Major record)
/*******************************************************************************************************************************************************************************************************************************************************************************/

		-- Create the #RelatedEntities table
		IF OBJECT_ID('tempdb..#RelatedEntities') IS NOT NULL DROP TABLE #RelatedEntities
		CREATE TABLE #RelatedEntities (IsSCR BIT NOT NULL, SrcSys TINYINT NOT NULL, Src_UID VARCHAR(255) NOT NULL)

		-- Find the related entities
		IF	@SrcSys IS NOT NULL
		AND	@Src_UID IS NOT NULL
		BEGIN

				-- Insert the records that relate to the Major ID supplied
				-- DECLARE @SrcSys TINYINT = 1 , @Src_UID VARCHAR(255) = '388974'
				INSERT INTO	#RelatedEntities
							(IsSCR
							,SrcSys
							,Src_UID)
				SELECT		ISNULL(mc_minor.IsSCR, mc_major.IsSCR) AS IsSCR
							,ISNULL(mc_minor.SrcSys, mc_major.SrcSys) AS SrcSys
							,ISNULL(mc_minor.Src_UID, mc_major.Src_UID) AS Src_UID
				FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc_major
				LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc_minor
																	ON	mc_major.SrcSys_Major = mc_minor.SrcSys_Major
																	AND	mc_Major.Src_UID_Major = mc_minor.Src_UID_Major
				WHERE		(mc_major.SrcSys_Major = @SrcSys
				AND			mc_major.Src_UID_Major = @Src_UID)
				OR			(mc_major.SrcSys = @SrcSys
				AND			mc_major.Src_UID = @Src_UID)
				GROUP BY	ISNULL(mc_minor.IsSCR, mc_major.IsSCR)
							,ISNULL(mc_minor.SrcSys, mc_major.SrcSys)
							,ISNULL(mc_minor.Src_UID, mc_major.Src_UID) 

				-- Loop through the dataset to find any other records that were originally matched
				DECLARE @NoMoreUpdates SMALLINT = 0
				WHILE @NoMoreUpdates = 0
				BEGIN
			
						INSERT INTO	#RelatedEntities
									(IsSCR
									,SrcSys
									,Src_UID)
						SELECT		mc.IsSCR
									,IterateNext.SrcSys_Iterative
									,IterateNext.Src_UID_Iterative
						FROM		#RelatedEntities inc
						INNER JOIN	(SELECT		SrcSys_A AS SrcSys_Link
												,Src_UID_A AS Src_UID_Link
												,SrcSys_B AS SrcSys_Iterative
												,Src_UID_B AS Src_UID_Iterative
									FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_Unique ep_u
			
									UNION
			
									SELECT		SrcSys_B AS SrcSys_Link
												,Src_UID_B AS Src_UID_Link
												,SrcSys_A AS SrcSys_Iterative
												,Src_UID_A AS Src_UID_Iterative
									FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_Unique ep_u
												) IterateNext
																ON	inc.SrcSys = IterateNext.SrcSys_Link
																AND	inc.Src_UID = IterateNext.Src_UID_Link
						INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
															ON	IterateNext.SrcSys_Iterative = mc.SrcSys
															AND	IterateNext.Src_UID_Iterative = mc.Src_UID
						LEFT JOIN	#RelatedEntities inc_notPresent
															ON	IterateNext.SrcSys_Iterative = inc_notPresent.SrcSys
															AND	IterateNext.Src_UID_Iterative = inc_notPresent.Src_UID
						WHERE		inc_notPresent.SrcSys IS NULL
						GROUP BY	mc.IsSCR
									,IterateNext.SrcSys_Iterative
									,IterateNext.Src_UID_Iterative
			
						-- Exit the loop if there were no more instances to find
						IF @@ROWCOUNT = 0
						SET @NoMoreUpdates = 1
			
				END 
	
		END
		

/*************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
-- Prepare the working table
/*************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/

		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Create working match control table'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
		
		-- Insert all existing values to the match control table
		IF OBJECT_ID('tempdb..#MDT_Match_Control_Work') IS NOT NULL DROP TABLE #MDT_Match_Control_Work
		SELECT		mc.SrcSys
					,mc.tableName
					,mc.table_UID
					,mc.HashBytesValue
					,mc.ChangeLastDetected
					,mc.LastProcessed
					,mc.DeletedDttm
					,mc.Migrate
					,mc.LastValidatedDttm
					,mc.LastValidatedBy
					,mc.LastValidated_SrcSys_Major
					,mc.LastValidated_Src_UID_Major
		INTO		#MDT_Match_Control_Work
		FROM		Merge_DM_Match.MDT_Match_Control mc
		INNER JOIN	Merge_DM_Match.MDT_mvw_UH UH
														ON	mc.SrcSys = UH.Ref_SrcSys_Minor
														AND	mc.tableName = UH.tableName
														AND	mc.table_UID = UH.table_UID
		LEFT JOIN	#RelatedEntities re
										ON	UH.Ref_SrcSys_Minor = re.SrcSys
										AND	UH.Ref_Src_UID_Minor = re.Src_UID
		WHERE		re.SrcSys IS NOT NULL
		OR			@SrcSys IS NULL
		OR			@Src_UID IS NULL

		-- SELECT * FROM #MDT_Match_Control_Work

		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = NULL, @ErrorMessage = NULL

/*************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
-- Refresh the working table
/*************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/

		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'new records'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
		
		-- Create a table to keep a track of all inserted, updated or deleted records 
		IF OBJECT_ID('tempdb..#CRUD_MDT') IS NOT NULL DROP TABLE #CRUD_MDT
		CREATE TABLE #CRUD_MDT
				(UpdateType VARCHAR(10) NOT NULL
				,SrcSys TINYINT NOT NULL
				,tableName VARCHAR(255) NOT NULL
				,table_UID VARCHAR(255) NOT NULL
				)

		-- SELECT * FROM #CRUD_MDT

		-- Insert all new SCR values to the match control table
		-- DECLARE @SrcSys TINYINT = 1 , @Src_UID VARCHAR(255) = '388974'
		-- DECLARE @SrcSys TINYINT , @Src_UID VARCHAR(255)
		INSERT INTO	#MDT_Match_Control_Work
					(SrcSys
					,tableName
					,table_UID
					,HashBytesValue
					,ChangeLastDetected)
		OUTPUT		'INSERT' AS UpdateType
					,Inserted.SrcSys
					,Inserted.tableName
					,Inserted.table_UID
		INTO		#CRUD_MDT
		SELECT		uh.Ref_SrcSys_Minor
					,uh.tableName
					,uh.table_UID
					,uh.HashBytesValue
					,GETDATE()
		FROM		Merge_DM_Match.MDT_mvw_UH uh
		LEFT JOIN	#RelatedEntities re
										ON	UH.Ref_SrcSys_Minor = re.SrcSys
										AND	UH.Ref_Src_UID_Minor = re.Src_UID
		LEFT JOIN	#MDT_Match_Control_Work mc_work
																	ON	uh.Ref_SrcSys_Minor = mc_work.SrcSys
																	AND	uh.tableName = mc_work.tableName
																	AND	uh.table_UID = mc_work.table_UID
		WHERE		mc_work.SrcSys IS NULL
		AND			(re.SrcSys IS NOT NULL
		OR			@SrcSys IS NULL
		OR			@Src_UID IS NULL)

		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = NULL, @ErrorMessage = NULL
		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'update existing records'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

		-- Update existing match control records where a change has been detected
		UPDATE		mc_work
		SET			mc_work.HashBytesValue = uh.HashBytesValue
					,mc_work.ChangeLastDetected = GETDATE()
					,mc_work.LastProcessed = NULL
					,mc_work.DeletedDttm = NULL -- in case a treatment has come back into scope
		OUTPUT		'UPDATE' AS UpdateType
					,Deleted.SrcSys
					,Deleted.tableName
					,Deleted.table_UID
		INTO		#CRUD_MDT
		FROM		Merge_DM_Match.MDT_mvw_UH uh
		INNER JOIN	#MDT_Match_Control_Work mc_work
																	ON	uh.Ref_SrcSys_Minor = mc_work.SrcSys
																	AND	uh.tableName = mc_work.tableName
																	AND	uh.table_UID = mc_work.table_UID
		WHERE		mc_work.HashBytesValue != uh.HashBytesValue
		--OR			uh.LastUpdated >= mc_work.ChangeLastDetected

		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = NULL, @ErrorMessage = NULL
		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'deleted records'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

		-- Mark existing match control records deleted where the source has been deleted
		UPDATE		mc_work
		SET			mc_work.DeletedDttm = GETDATE()
					,mc_work.ChangeLastDetected = GETDATE()
					,mc_work.LastProcessed = NULL
		OUTPUT		'DELETE' AS UpdateType
					,Deleted.SrcSys
					,Deleted.tableName
					,Deleted.table_UID
		INTO		#CRUD_MDT
		FROM		#MDT_Match_Control_Work mc_work
		LEFT JOIN	Merge_DM_Match.MDT_mvw_UH uh
														ON	mc_work.SrcSys = uh.Ref_SrcSys_Minor
														AND	mc_work.tableName = uh.tableName
														AND	mc_work.table_UID = uh.table_UID
		WHERE		uh.Ref_SrcSys_Minor IS NULL
		
		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = NULL, @ErrorMessage = NULL

/*************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
-- Bring across validation data for MDT still in scope
/*************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/

		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Bring across validation data'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

		-- Any treatment still in scope can have the prior validation information brought across
		-- DECLARE @SrcSys TINYINT = 1 , @Src_UID VARCHAR(255) = '388974'
		-- DECLARE @SrcSys TINYINT , @Src_UID VARCHAR(255)
		UPDATE		mc_work
		SET			mc_work.Migrate							= mdt_scope.Migrate
					,mc_work.LastValidatedDttm				= mdt_scope.LastValidatedDttm
					,mc_work.LastValidatedBy				= mdt_scope.LastValidatedBy
					,mc_work.LastValidated_SrcSys_Major		= mdt_scope.LastValidated_SrcSys_Major
					,mc_work.LastValidated_Src_UID_Major	= mdt_scope.LastValidated_Src_UID_Major
					,mc_work.LastProcessed = NULL
		OUTPUT		CASE WHEN Deleted.Migrate IS NOT NULL AND Inserted.Migrate IS NULL THEN 'UNFLAG' ELSE 'REFLAG' END AS UpdateType
					,Deleted.SrcSys
					,Deleted.tableName
					,Deleted.table_UID
		INTO		#CRUD_MDT
		FROM		#MDT_Match_Control_Work mc_work
		LEFT JOIN	Merge_DM_MatchViews.MDT_vw_SCOPE(@SrcSys, @Src_UID) mdt_scope
																				ON	mc_work.SrcSys = mdt_scope.Ref_SrcSys_Minor
																				AND	mc_work.tableName = mdt_scope.tableName
																				AND	mc_work.table_UID = mdt_scope.table_UID
																				AND	mdt_scope.InScope = 1

		-- All records where the associated referral major has been changed but not unlinked / relinked can have their last validated major repointed
		-- DECLARE @SrcSys TINYINT = 1 , @Src_UID VARCHAR(255) = '388974'
		-- DECLARE @SrcSys TINYINT , @Src_UID VARCHAR(255)
		UPDATE		mc_work
		SET			mc_work.LastValidated_SrcSys_Major		= ChangedMajorNoLinking.Ref_SrcSys_Major
					,mc_work.LastValidated_Src_UID_Major	= ChangedMajorNoLinking.Ref_Src_UID_Major
		OUTPUT		'REMAJOR' AS UpdateType
					,Deleted.SrcSys
					,Deleted.tableName
					,Deleted.table_UID
		INTO		#CRUD_MDT
		FROM		#MDT_Match_Control_Work mc_work
		INNER JOIN	(SELECT		*
								,COUNT(*) OVER (PARTITION BY mdt_scope.InScope, mdt_scope.Ref_SrcSys_Major, mdt_scope.Ref_Src_UID_Major) AS RefMajorCount
								,COUNT(*) OVER (PARTITION BY mdt_scope.InScope, mdt_scope.LastValidated_SrcSys_Major, ISNULL(mdt_scope.LastValidated_SrcSys_Major, mdt_scope.Ref_SrcSys_Major), mdt_scope.LastValidated_Src_UID_Major, ISNULL(mdt_scope.LastValidated_Src_UID_Major, mdt_scope.Ref_Src_UID_Major)) AS LastValidatedMajorCount
					FROM		Merge_DM_MatchViews.MDT_vw_SCOPE(@SrcSys, @Src_UID) mdt_scope
					WHERE		mdt_scope.RefLastProcessed > mdt_scope.LastProcessed
								) ChangedMajorNoLinking
											ON	mc_work.SrcSys = ChangedMajorNoLinking.Ref_SrcSys_Minor
											AND	mc_work.tableName = ChangedMajorNoLinking.tableName
											AND	mc_work.table_UID = ChangedMajorNoLinking.table_UID
											AND	ChangedMajorNoLinking.RefMajorCount = ChangedMajorNoLinking.LastValidatedMajorCount
		WHERE		mc_work.LastValidated_SrcSys_Major	!= ChangedMajorNoLinking.Ref_SrcSys_Major
		OR			mc_work.LastValidated_Src_UID_Major	!= ChangedMajorNoLinking.Ref_Src_UID_Major
		
		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = NULL, @ErrorMessage = NULL
		
/*************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
-- Reset the migrate flag for records that are implicated by changes 
/*************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/

		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Reset the migrate flag'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

		-- All records with the same last validated major as an inserted / updated / unflagged record need to be revalidated
		UPDATE		mc_work
		SET			mc_work.Migrate							= NULL
					,mc_work.LastProcessed					= NULL
					,mc_work.LastValidatedDttm				= NULL
					,mc_work.LastValidatedBy				= NULL
					,mc_work.LastValidated_SrcSys_Major		= NULL
					,mc_work.LastValidated_Src_UID_Major	= NULL
		OUTPUT		'REVALIDATE' AS UpdateType
					,Deleted.SrcSys
					,Deleted.tableName
					,Deleted.table_UID
		INTO		#CRUD_MDT
		FROM		#MDT_Match_Control_Work mc_work
		INNER JOIN	(SELECT		mc_work_inner.LastValidated_SrcSys_Major
								,mc_work_inner.LastValidated_Src_UID_Major
					FROM		#MDT_Match_Control_Work mc_work_inner
					INNER JOIN	#CRUD_MDT crud
													ON	mc_work_inner.SrcSys = crud.SrcSys
													AND	mc_work_inner.tableName = crud.tableName
													AND	mc_work_inner.table_UID = crud.table_UID
													AND	crud.UpdateType IN ('INSERT','UPDATE','UNFLAG')
					GROUP BY	mc_work_inner.LastValidated_SrcSys_Major
								,mc_work_inner.LastValidated_Src_UID_Major
								) changed_record
												ON	mc_work.LastValidated_SrcSys_Major = changed_record.LastValidated_SrcSys_Major
												AND	mc_work.LastValidated_Src_UID_Major = changed_record.LastValidated_Src_UID_Major

		-- All records with the same last validated major as a deleted / unflagged record need to be revalidated
		UPDATE		mc_work
		SET			mc_work.Migrate							= NULL
					,mc_work.LastProcessed					= NULL
					,mc_work.LastValidatedDttm				= NULL
					,mc_work.LastValidatedBy				= NULL
					,mc_work.LastValidated_SrcSys_Major		= NULL
					,mc_work.LastValidated_Src_UID_Major	= NULL
		OUTPUT		'REVALIDATE' AS UpdateType
					,Deleted.SrcSys
					,Deleted.tableName
					,Deleted.table_UID
		INTO		#CRUD_MDT
		FROM		#MDT_Match_Control_Work mc_work
		INNER JOIN	(SELECT		mc_work_inner.LastValidated_SrcSys_Major
								,mc_work_inner.LastValidated_Src_UID_Major
					FROM		Merge_DM_Match.MDT_Match_Control mc_work_inner
					INNER JOIN	#CRUD_MDT crud
													ON	mc_work_inner.SrcSys = crud.SrcSys
													AND	mc_work_inner.tableName = crud.tableName
													AND	mc_work_inner.table_UID = crud.table_UID
													AND	crud.UpdateType IN ('DELETE','UNFLAG')
					GROUP BY	mc_work_inner.LastValidated_SrcSys_Major
								,mc_work_inner.LastValidated_Src_UID_Major
								) changed_record
												ON	mc_work.LastValidated_SrcSys_Major = changed_record.LastValidated_SrcSys_Major
												AND	mc_work.LastValidated_Src_UID_Major = changed_record.LastValidated_Src_UID_Major

		-- All records where the associated referral major has been unlinked / relinked need to be revalidated
		-- DECLARE @SrcSys TINYINT = 1 , @Src_UID VARCHAR(255) = '388974'
		UPDATE		mc_work
		SET			mc_work.Migrate							= NULL
					,mc_work.LastProcessed					= NULL
					,mc_work.LastValidatedDttm				= NULL
					,mc_work.LastValidatedBy				= NULL
					,mc_work.LastValidated_SrcSys_Major		= NULL
					,mc_work.LastValidated_Src_UID_Major	= NULL
		OUTPUT		'REVALIDATE' AS UpdateType
					,Deleted.SrcSys
					,Deleted.tableName
					,Deleted.table_UID
		INTO		#CRUD_MDT
		FROM		#MDT_Match_Control_Work mc_work
		INNER JOIN	(SELECT		*
								,COUNT(*) OVER (PARTITION BY mdt_scope.Ref_SrcSys_Major, mdt_scope.Ref_Src_UID_Major) AS RefMajorCount
								,COUNT(*) OVER (PARTITION BY mdt_scope.LastValidated_SrcSys_Major, ISNULL(mdt_scope.LastValidated_SrcSys_Major, mdt_scope.Ref_SrcSys_Major), mdt_scope.LastValidated_Src_UID_Major, ISNULL(mdt_scope.LastValidated_Src_UID_Major, mdt_scope.Ref_Src_UID_Major)) AS LastValidatedMajorCount
					FROM		Merge_DM_MatchViews.MDT_vw_SCOPE(@SrcSys, @Src_UID) mdt_scope
					WHERE		mdt_scope.RefLastProcessed > mdt_scope.LastProcessed
								) UnAndRelinkedReferrals
											ON	mc_work.SrcSys = UnAndRelinkedReferrals.Ref_SrcSys_Minor
											AND	mc_work.tableName = UnAndRelinkedReferrals.tableName
											AND	mc_work.table_UID = UnAndRelinkedReferrals.table_UID
											AND	UnAndRelinkedReferrals.RefMajorCount != UnAndRelinkedReferrals.LastValidatedMajorCount

		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = NULL, @ErrorMessage = NULL
		
		
/*************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
-- Set default values
/*************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/

		-- Update the last processed date
		UPDATE		#MDT_Match_Control_Work
		SET			LastProcessed = GETDATE()
		WHERE		LastProcessed IS NULL
        
		-- Any treatment in scope gets default validation values if it doesn't already have them
		-- DECLARE @SrcSys TINYINT = 1 , @Src_UID VARCHAR(255) = '388974'
		-- DECLARE @SrcSys TINYINT , @Src_UID VARCHAR(255)
		UPDATE		mc_work
		SET			mc_work.LastValidatedDttm				= ISNULL(mc_work.LastValidatedDttm, GETDATE())
					,mc_work.LastValidatedBy				= ISNULL(mc_work.LastValidatedBy, 'MDT_uspMatchControlUpdateAndMatch')
					,mc_work.LastValidated_SrcSys_Major		= ISNULL(mc_work.LastValidated_SrcSys_Major, mdt_scope.Ref_SrcSys_Major)
					,mc_work.LastValidated_Src_UID_Major	= ISNULL(mc_work.LastValidated_Src_UID_Major, mdt_scope.Ref_Src_UID_Major)
		OUTPUT		CASE WHEN Deleted.Migrate IS NOT NULL AND Inserted.Migrate IS NULL THEN 'UNFLAG' ELSE 'REFLAG' END AS UpdateType
					,Deleted.SrcSys
					,Deleted.tableName
					,Deleted.table_UID
		INTO		#CRUD_MDT
		FROM		#MDT_Match_Control_Work mc_work
		INNER JOIN	Merge_DM_MatchViews.MDT_vw_SCOPE(@SrcSys, @Src_UID) mdt_scope
																				ON	mc_work.SrcSys = mdt_scope.Ref_SrcSys_Minor
																				AND	mc_work.tableName = mdt_scope.tableName
																				AND	mc_work.table_UID = mdt_scope.table_UID
																				AND	mdt_scope.InScope = 1

/*************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
-- Replace the records in the Merge_DM_Match.MDT_Match_Control table
/*************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/

		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Replace'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
		
		-- Create a table of all records implicated by the update
		IF OBJECT_ID('tempdb..#Implicated') IS NOT NULL DROP TABLE #Implicated
		SELECT		*
		INTO		#Implicated
		FROM		(SELECT		SrcSys
								,tableName
								,table_UID
					FROM		#MDT_Match_Control_Work
					GROUP BY	SrcSys
								,tableName
								,table_UID
		
					UNION

					SELECT		SrcSys
								,tableName
								,table_UID
					FROM		#CRUD_MDT
					GROUP BY	SrcSys
								,tableName
								,table_UID
								) Implicated

		 BEGIN TRY

			 BEGIN TRANSACTION
		
					-- Delete any existing records from Merge_DM_Match.MDT_Match_Control
					DELETE
					FROM		mc
					FROM		Merge_DM_Match.MDT_Match_Control mc
					INNER JOIN	#Implicated imp
												ON	mc.SrcSys = imp.SrcSys
												AND	mc.tableName = imp.tableName
												AND	mc.table_UID = imp.table_UID

					-- Replace with the records from #MDT_Match_Control_Work
					INSERT INTO	Merge_DM_Match.MDT_Match_Control
								(SrcSys
								,tableName
								,table_UID
								,HashBytesValue
								,ChangeLastDetected
								,LastProcessed
								,DeletedDttm
								,Migrate
								,LastValidatedDttm
								,LastValidatedBy
								,LastValidated_SrcSys_Major
								,LastValidated_Src_UID_Major
								)
					SELECT		SrcSys
								,tableName
								,table_UID
								,HashBytesValue
								,ChangeLastDetected
								,LastProcessed
								,DeletedDttm
								,Migrate
								,LastValidatedDttm
								,LastValidatedBy
								,LastValidated_SrcSys_Major
								,LastValidated_Src_UID_Major
					FROM		#MDT_Match_Control_Work


			 COMMIT TRANSACTION

		 END TRY

		BEGIN CATCH
 
			DECLARE @ErrorMessage VARCHAR(MAX)
			SELECT @ErrorMessage = ERROR_MESSAGE()
			
			SELECT ERROR_NUMBER() AS ErrorNumber
			SELECT @ErrorMessage AS ErrorMessage
 
			PRINT ERROR_NUMBER()
			PRINT @ErrorMessage

			IF @@TRANCOUNT > 0 -- SELECT @@TRANCOUNT
			BEGIN
					PRINT 'Rolling back because of error in Incremental Transaction'
					ROLLBACK TRANSACTION
			END

			SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 0, @ErrorMessage = @ErrorMessage

			RAISERROR (@ErrorMessage, -- Message text.  
										15, -- Severity.  
										1 -- State.  
										);
 
		END CATCH

		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL


/*************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
-- Auto-drop/keep records that fit a recognised pattern
/*************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/

		-- Create the #DropOrKeep table
		IF OBJECT_ID('tempdb..#DropOrKeep') IS NOT NULL DROP TABLE #DropOrKeep
		CREATE TABLE #DropOrKeep
					(tableName VARCHAR(255)
					,SrcSys TINYINT
					,RecordID VARCHAR(255)
					,RecordVariant VARCHAR(255)
					,Migrate BIT
					)

		-- Populate the #DropOrKeep table with records to be auto-kept/dropped because they are Teletherapy in Brighton
		INSERT INTO	#DropOrKeep (tableName,SrcSys,RecordID,RecordVariant,Migrate)
		SELECT		'MDT'
					,mdt_vw.Ref_SrcSys_Minor
					,mdt_vw.table_UID
					,mdt_vw.tableName
					,CASE WHEN mdt_vw.Ref_SrcSys_Minor = 2 THEN 1 ELSE 0 END AS Migrate
		FROM		(SELECT		mdt_vw_inner.Ref_SrcSys_Major
								,mdt_vw_inner.Ref_Src_UID_Major
								,mdt_vw_inner.MDT_DATE
								,mdt_vw_inner.tableName
								,SUM(CASE WHEN mdt_vw_inner.Ref_SrcSys_Minor = 2 THEN 1 ELSE 0 END) AS BrightonCount
								,SUM(CASE WHEN mdt_vw_inner.Ref_SrcSys_Minor = 1 THEN 1 ELSE 0 END) AS WshtCount
					FROM		Merge_DM_MatchViews.MDT_vw_SCOPE(NULL, NULL) mdt_vw_inner
					WHERE		mdt_vw_inner.tableName IN ('tblGYNAECOLOGY_MDT','tblHEAD_NECK_MDT')
					AND			mdt_vw_inner.InScope = 1
					GROUP BY	mdt_vw_inner.Ref_SrcSys_Major
								,mdt_vw_inner.Ref_Src_UID_Major
								,mdt_vw_inner.MDT_DATE
								,mdt_vw_inner.tableName
					HAVING		SUM(CASE WHEN mdt_vw_inner.Ref_SrcSys_Minor = 2 THEN 1 ELSE 0 END) = 1
					AND			SUM(CASE WHEN mdt_vw_inner.Ref_SrcSys_Minor = 1 THEN 1 ELSE 0 END) = 1
								) BrightonIsSpecialist
		INNER JOIN	Merge_DM_MatchViews.MDT_vw_SCOPE (NULL, NULL) mdt_vw
																			ON	BrightonIsSpecialist.Ref_SrcSys_Major = mdt_vw.Ref_SrcSys_Major
																			AND	BrightonIsSpecialist.Ref_Src_UID_Major = mdt_vw.Ref_Src_UID_Major
																			AND	BrightonIsSpecialist.MDT_DATE = mdt_vw.MDT_DATE
																			AND	BrightonIsSpecialist.tableName = mdt_vw.tableName
																			AND	mdt_vw.Migrate IS NULL
																			AND	mdt_vw.InScope = 1

/*		-- Populate the #DropOrKeep table with records to be auto-kept/dropped because they are on the system as the site treated
		INSERT INTO	#DropOrKeep (tableName,SrcSys,RecordID,RecordVariant,Migrate)
		SELECT		'Treatments'
					,tx_vw.Ref_SrcSys_Minor
					,tx_vw.TreatmentID
					,tx_vw.Treatment
					,CASE	WHEN DefaultToSiteTreated.BsuhSiteCount = 2 AND tx_vw.Ref_SrcSys_Minor = 2
							THEN 1
							WHEN DefaultToSiteTreated.WshtSiteCount = 2 AND tx_vw.Ref_SrcSys_Minor = 1
							THEN 1
							ELSE 0
							END
		FROM		(SELECT		tx_vw_inner.Ref_SrcSys_Major
								,tx_vw_inner.Ref_Src_UID_Major
								,tx_vw_inner.TreatmentDate
								,SUM(CASE WHEN tx_vw_inner.TreatmentSite IN ('E0A3H','N6J7V') OR LEFT(tx_vw_inner.TreatmentSite, 3) = 'RXH' THEN 1 ELSE 0 END) AS BsuhSiteCount
								,SUM(CASE WHEN LEFT(tx_vw_inner.TreatmentSite, 3) = 'RYR' THEN 1 ELSE 0 END) AS WshtSiteCount
								,SUM(CASE WHEN tx_vw_inner.Ref_SrcSys_Minor = 2 THEN 1 ELSE 0 END) AS BsuhSrcSysCount
								,SUM(CASE WHEN tx_vw_inner.Ref_SrcSys_Minor = 1 THEN 1 ELSE 0 END) AS WshtSrcSysCount
								,MAX(CASE WHEN tx_vw_inner.Treatment = 'tblMAIN_CHEMOTHERAPY' THEN 1 ELSE 0 END)
								+ MAX(CASE WHEN tx_vw_inner.Treatment = 'tblMAIN_BRACHYTHERAPY' THEN 1 ELSE 0 END)
								+ MAX(CASE WHEN tx_vw_inner.Treatment = 'tblMAIN_PALLIATIVE' THEN 1 ELSE 0 END)
								+ MAX(CASE WHEN tx_vw_inner.Treatment = 'tblMAIN_SURGERY' THEN 1 ELSE 0 END)
								+ MAX(CASE WHEN tx_vw_inner.Treatment = 'tblMAIN_TELETHERAPY' THEN 1 ELSE 0 END)
								+ MAX(CASE WHEN tx_vw_inner.Treatment = 'tblMONITORING' THEN 1 ELSE 0 END)
								+ MAX(CASE WHEN tx_vw_inner.Treatment = 'tblOTHER_TREATMENT' THEN 1 ELSE 0 END) AS ModalityCount
								,MIN(tx_vw_inner.Treatment) AS FirstTreatmentModality
								,MAX(tx_vw_inner.Treatment) AS LastTreatmentModality
					FROM		Merge_DM_MatchViews.Treatments_vw_SCOPE (NULL, NULL) tx_vw_inner
					WHERE		tx_vw_inner.InScope = 1
					AND			tx_vw_inner.Migrate IS NULL
					GROUP BY	tx_vw_inner.Ref_SrcSys_Major
								,tx_vw_inner.Ref_Src_UID_Major
								,tx_vw_inner.TreatmentDate
								) DefaultToSiteTreated
		INNER JOIN	Merge_DM_MatchViews.Treatments_vw_SCOPE (NULL, NULL) tx_vw
																			ON	DefaultToSiteTreated.Ref_SrcSys_Major = tx_vw.Ref_SrcSys_Major
																			AND	DefaultToSiteTreated.Ref_Src_UID_Major = tx_vw.Ref_Src_UID_Major
																			AND	DefaultToSiteTreated.TreatmentDate = tx_vw.TreatmentDate
																			AND	tx_vw.Migrate IS NULL
		WHERE		(DefaultToSiteTreated.BsuhSiteCount = 2
		AND			DefaultToSiteTreated.WshtSiteCount = 0
		AND			DefaultToSiteTreated.BsuhSrcSysCount = 1
		AND			DefaultToSiteTreated.ModalityCount = 1)
		OR			(DefaultToSiteTreated.WshtSiteCount = 2
		AND			DefaultToSiteTreated.BsuhSiteCount = 0
		AND			DefaultToSiteTreated.WshtSrcSysCount = 1
		AND			DefaultToSiteTreated.ModalityCount = 1)

		EXCEPT

		SELECT		*
		FROM		#DropOrKeep
*/
		-- Auto-Drop/Keep the eligible records
		EXEC Merge_DM_Match.uspDropOrKeep @UserID = 'MDT_uspMatchControlUpdateAndMatch'
GO
