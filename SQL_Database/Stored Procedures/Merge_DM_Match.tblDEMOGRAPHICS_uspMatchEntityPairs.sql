SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_Match].[tblDEMOGRAPHICS_uspMatchEntityPairs] 

		(@MajorID_SrcSys TINYINT = NULL
		,@MajorID_Src_UID VARCHAR(255) = NULL
		,@UseExistingMatches BIT = 0
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
Description:				A stored procedure to match tblDEMOGRAPHICS records from different sources
							ready for deduplication
**************************************************************************************************************************************************/

-- Test me
-- EXEC Merge_DM_Match.tblDEMOGRAPHICS_uspMatchEntityPairs
-- EXEC Merge_DM_Match.tblDEMOGRAPHICS_uspMatchEntityPairs @MajorID_SrcSys = 1, @MajorID_Src_UID = 32
-- EXEC Merge_DM_Match.tblDEMOGRAPHICS_uspMatchEntityPairs @MajorID_SrcSys = 1, @MajorID_Src_UID = 31, @UseExistingMatches = 1

		-- Set up the variables for process auditing
		DECLARE	@CurrentUser VARCHAR(255)
				,@ProcIdName VARCHAR(255)
				,@CurrentSection VARCHAR(255)
				,@CurrentDttm DATETIME2
				,@LoopCounter SMALLINT = 1

		SELECT	@CurrentUser = CURRENT_USER
				,@ProcIdName = ISNULL(OBJECT_NAME(@@PROCID), 'ad hoc')	
				
		-- Set up the variables for any dynamic SQL
		DECLARE	@SQL VARCHAR(MAX)
				,@Guid VARCHAR(255)
				
		SELECT @Guid = CAST(NEWID() AS VARCHAR(255))
		
		/*****************************************************************************************************************************************************************************************************************************************************************************************/
		-- Handle parameter data quality
		/*****************************************************************************************************************************************************************************************************************************************************************************************/

		-- Return an error if there is a partial provision of parameter values
		IF	@MajorID_SrcSys IS NOT NULL AND @MajorID_Src_UID IS NULL
		OR	@MajorID_SrcSys IS NULL AND @MajorID_Src_UID IS NOT NULL
		RETURN

		/*****************************************************************************************************************************************************************************************************************************************************************************************/
		-- Populate #Incremental table
		/*****************************************************************************************************************************************************************************************************************************************************************************************/

		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Incremental table'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

		-- Create the #Incremental table
		IF OBJECT_ID('tempdb..#Incremental') IS NOT NULL DROP TABLE #Incremental
		CREATE TABLE #Incremental (IsSCR BIT NOT NULL, SrcSys TINYINT NOT NULL, Src_UID VARCHAR(255) NOT NULL, ProcessIx TINYINT, MoveMajorValidation BIT NULL DEFAULT 0)

		-- Perform either an incremental load based on new / changed data or a selective refresh based on a provided src sys and src UID
		IF	@MajorID_SrcSys IS NULL
		OR	@MajorID_Src_UID IS NULL
		BEGIN
				-- Insert the new / changed records since the last refresh
				INSERT INTO	#Incremental
							(IsSCR
							,SrcSys
							,Src_UID)
				SELECT		ISNULL(mc_minor.IsSCR, mc_major.IsSCR) AS IsSCR
							,ISNULL(mc_minor.SrcSys, mc_major.SrcSys) AS SrcSys
							,ISNULL(mc_minor.Src_UID, mc_major.Src_UID) AS Src_UID
				FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc_major
				LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc_minor
																	ON	mc_major.SrcSys_Major = mc_minor.SrcSys_Major
																	AND	mc_Major.Src_UID_Major = mc_minor.Src_UID_Major
				LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv_confirmed
																					ON	mc_major.SrcSys_Major = mmv_confirmed.SrcSys_Major
																					AND	mc_major.Src_UID_Major = mmv_confirmed.Src_UID_Major
																					AND	mmv_confirmed.ValidationStatus IN ('Confirmed','Dont Merge')
				WHERE		mc_major.LastProcessed IS NULL
				OR			(mc_major.LastProcessed < mc_major.ChangeLastDetected	-- re-process changes
				AND			mmv_confirmed.SrcSys_Major IS NULL)						-- if the major hasn't yet been confirmed
				GROUP BY	ISNULL(mc_minor.IsSCR, mc_major.IsSCR)
							,ISNULL(mc_minor.SrcSys, mc_major.SrcSys)
							,ISNULL(mc_minor.Src_UID, mc_major.Src_UID)

				-- Refresh records related to majors with a deleted record since the last refresh
				INSERT INTO	#Incremental
							(IsSCR
							,SrcSys
							,Src_UID)
				SELECT		mc.IsSCR
							,mc.SrcSys
							,mc.Src_UID
				FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
				INNER JOIN	(SELECT		mc_inner.SrcSys_Major
										,mc_inner.Src_UID_Major
										,mc_inner.DeletedDttm
							FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc_inner
							WHERE		mc_inner.DeletedDttm IS NOT NULL
							GROUP BY	mc_inner.SrcSys_Major
										,mc_inner.Src_UID_Major
										,mc_inner.DeletedDttm
										) mc_deleted
													ON	mc.SrcSys_Major = mc_deleted.SrcSys_Major
													AND	mc.Src_UID_Major = mc_deleted.Src_UID_Major
													AND	mc.LastProcessed <= mc_deleted.DeletedDttm
				LEFT JOIN	#Incremental inc
											ON	mc.SrcSys = inc.SrcSys
											AND	mc.Src_UID = inc.Src_UID
				WHERE		mc.DeletedDttm IS NULL
				AND			inc.SrcSys IS NULL
				GROUP BY	mc.IsSCR
							,mc.SrcSys
							,mc.Src_UID

				-- Refresh records related to orphaned minors (minors whose major no longer exists)
				INSERT INTO	#Incremental
							(IsSCR
							,SrcSys
							,Src_UID)
				SELECT		mc.IsSCR
							,mc.SrcSys
							,mc.Src_UID
				FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
				LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc_major
																				ON	mc.SrcSys_Major = mc_major.SrcSys
																				AND	mc.Src_UID_Major = mc_major.Src_UID
				LEFT JOIN	#Incremental inc
											ON	mc.SrcSys = inc.SrcSys
											AND	mc.Src_UID = inc.Src_UID
				WHERE		mc.DeletedDttm IS NULL
				AND			mc_major.SrcSys IS NULL
				AND			inc.SrcSys IS NULL
				GROUP BY	mc.IsSCR
							,mc.SrcSys
							,mc.Src_UID

		END
		ELSE
		BEGIN
				-- Insert the records that relate to the Major ID supplied
				INSERT INTO	#Incremental
							(IsSCR
							,SrcSys
							,Src_UID)
				SELECT		ISNULL(mc_minor.IsSCR, mc_major.IsSCR) AS IsSCR
							,ISNULL(mc_minor.SrcSys, mc_major.SrcSys) AS SrcSys
							,ISNULL(mc_minor.Src_UID, mc_major.Src_UID) AS Src_UID
				FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc_major
				LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc_minor
																	ON	mc_major.SrcSys_Major = mc_minor.SrcSys_Major
																	AND	mc_Major.Src_UID_Major = mc_minor.Src_UID_Major
				WHERE		(mc_major.SrcSys_Major = @MajorID_SrcSys
				AND			mc_major.Src_UID_Major = @MajorID_Src_UID)
				OR			(mc_major.SrcSys = @MajorID_SrcSys
				AND			mc_major.Src_UID = @MajorID_Src_UID)
				GROUP BY	ISNULL(mc_minor.IsSCR, mc_major.IsSCR)
							,ISNULL(mc_minor.SrcSys, mc_major.SrcSys)
							,ISNULL(mc_minor.Src_UID, mc_major.Src_UID)

				-- Loop through the dataset to find any other records that need to be included
				DECLARE @NoMoreUpdates SMALLINT = 0
				WHILE @NoMoreUpdates = 0
				BEGIN

						INSERT INTO	#Incremental
									(IsSCR
									,SrcSys
									,Src_UID)
						SELECT		mc.IsSCR
									,IterateNext.SrcSys_Iterative
									,IterateNext.Src_UID_Iterative
						FROM		#Incremental inc
						INNER JOIN	(SELECT		SrcSys_A AS SrcSys_Link
												,Src_UID_A AS Src_UID_Link
												,SrcSys_B AS SrcSys_Iterative
												,Src_UID_B AS Src_UID_Iterative
									FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_Unique ep_u

									UNION

									SELECT		SrcSys_B AS SrcSys_Link
												,Src_UID_B AS Src_UID_Link
												,SrcSys_A AS SrcSys_Iterative
												,Src_UID_A AS Src_UID_Iterative
									FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_Unique ep_u
												) IterateNext
																ON	inc.SrcSys = IterateNext.SrcSys_Link
																AND	inc.Src_UID = IterateNext.Src_UID_Link
						INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
															ON	IterateNext.SrcSys_Iterative = mc.SrcSys
															AND	IterateNext.Src_UID_Iterative = mc.Src_UID
						LEFT JOIN	#Incremental inc_notPresent
															ON	IterateNext.SrcSys_Iterative = inc_notPresent.SrcSys
															AND	IterateNext.Src_UID_Iterative = inc_notPresent.Src_UID
						WHERE		inc_notPresent.SrcSys IS NULL
						GROUP BY	mc.IsSCR
									,IterateNext.SrcSys_Iterative
									,IterateNext.Src_UID_Iterative

						-- Exit the loop if there were no more distances to find
						IF @@ROWCOUNT = 0
						SET @NoMoreUpdates = 1

				END

		END

		-- Index the #Increnemtal table		--		DECLARE	@SQL VARCHAR(MAX) ,@Guid VARCHAR(255) SELECT @Guid = CAST(NEWID() AS VARCHAR(255))
		SET @SQL =	'CREATE UNIQUE CLUSTERED INDEX [PK_Incremental_' + @Guid + '] ON #Incremental (SrcSys ASC, Src_UID ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_Incremental_IsScr_' + @Guid + '] ON #Incremental (IsScr ASC) '
		EXEC (@SQL)

		/*****************************************************************************************************************************************************************************************************************************************************************************************/
		-- Match the entities from each source
		/*****************************************************************************************************************************************************************************************************************************************************************************************/

		-- Create #tblDEMOGRAPHICS_Match_EntityPairs_All to be the same as the final target Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_All table
		IF OBJECT_ID('tempdb..#tblDEMOGRAPHICS_Match_EntityPairs_All') IS NOT NULL DROP TABLE #tblDEMOGRAPHICS_Match_EntityPairs_All
		CREATE TABLE	#tblDEMOGRAPHICS_Match_EntityPairs_All
						(IsScr_A BIT NOT NULL
						,SrcSys_A TINYINT NOT NULL
						,Src_UID_A VARCHAR(255) NOT NULL
						,IsScr_B BIT NOT NULL
						,SrcSys_B TINYINT NOT NULL
						,Src_UID_B VARCHAR(255) NOT NULL
						,MatchType SMALLINT NOT NULL
						,MatchIntention VARCHAR(255) NOT NULL
						,LoopFinished BIT
						,Iteration SMALLINT NOT NULL DEFAULT 0
						)
		
		-- Populate #tblDEMOGRAPHICS_Match_EntityPairs_All with existing data if requested
		IF @UseExistingMatches = 1
		BEGIN

				SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
				SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'existing matches'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

				-- Insert the previously found entity pairs that relate to the A records in the incremental table
				INSERT INTO	#tblDEMOGRAPHICS_Match_EntityPairs_All
							(IsSCR_A
							,SrcSys_A
							,Src_UID_A
							,IsSCR_B
							,SrcSys_B
							,Src_UID_B
							,MatchType
							,MatchIntention
							)
				SELECT		IsSCR_A
							,SrcSys_A
							,Src_UID_A
							,IsSCR_B
							,SrcSys_B
							,Src_UID_B
							,MatchType
							,MatchIntention
				FROM		#Incremental inc
				INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_All ep_a
											ON	(inc.SrcSys = ep_a.SrcSys_A
											AND	inc.Src_UID = ep_a.Src_UID_A)

				-- Insert the previously found entity pairs that relate to the B records in the incremental table
				INSERT INTO	#tblDEMOGRAPHICS_Match_EntityPairs_All
							(IsSCR_A
							,SrcSys_A
							,Src_UID_A
							,IsSCR_B
							,SrcSys_B
							,Src_UID_B
							,MatchType
							,MatchIntention
							)
				SELECT		IsSCR_A
							,SrcSys_A
							,Src_UID_A
							,IsSCR_B
							,SrcSys_B
							,Src_UID_B
							,MatchType
							,MatchIntention
				FROM		#Incremental inc
				INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_All ep_a
											ON	(inc.SrcSys = ep_a.SrcSys_B
											AND	inc.Src_UID = ep_a.Src_UID_B)
				EXCEPT		
				SELECT		IsSCR_A
							,SrcSys_A
							,Src_UID_A
							,IsSCR_B
							,SrcSys_B
							,Src_UID_B
							,MatchType
							,MatchIntention
				FROM		#tblDEMOGRAPHICS_Match_EntityPairs_All
				
				-- Add any additional "A" ID's found in the entity pairs to the incremental table (for use in the find major process but not fo records to be written back to the persisted tables)
				INSERT INTO	#Incremental
							(IsSCR
							,SrcSys
							,Src_UID
							,MoveMajorValidation
							)
				SELECT		ep_a.IsSCR_A
							,ep_a.SrcSys_A
							,ep_a.Src_UID_A
							,1
				FROM		#tblDEMOGRAPHICS_Match_EntityPairs_All ep_a
				LEFT JOIN	#Incremental inc
											ON	ep_a.IsSCR_A = Inc.IsSCR
											AND	ep_a.SrcSys_A = Inc.SrcSys
											AND	ep_a.Src_UID_A = Inc.Src_UID
				WHERE		Inc.SrcSys IS NULL
				GROUP BY	ep_a.IsSCR_A
							,ep_a.SrcSys_A
							,ep_a.Src_UID_A
				
				-- Add any additional "B" ID's found in the entity pairs to the incremental table (for use in the find major process but not fo records to be written back to the persisted tables)
				INSERT INTO	#Incremental
							(IsSCR
							,SrcSys
							,Src_UID
							,MoveMajorValidation
							)
				SELECT		ep_a.IsSCR_B
							,ep_a.SrcSys_B
							,ep_a.Src_UID_B
							,1
				FROM		#tblDEMOGRAPHICS_Match_EntityPairs_All ep_a
				LEFT JOIN	#Incremental inc
											ON	ep_a.IsSCR_B = Inc.IsSCR
											AND	ep_a.SrcSys_B = Inc.SrcSys
											AND	ep_a.Src_UID_B = Inc.Src_UID
				WHERE		Inc.SrcSys IS NULL
				GROUP BY	ep_a.IsSCR_B
							,ep_a.SrcSys_B
							,ep_a.Src_UID_B

		END

		ELSE	-- refresh matches / don't use existing match data

		BEGIN	
				

				--		DECLARE	@SQL VARCHAR(MAX) ,@Guid VARCHAR(255), @CurrentUser VARCHAR(255), @ProcIdName VARCHAR(255), @CurrentSection VARCHAR(255), @CurrentDttm DATETIME2, @LoopCounter SMALLINT = 1 SELECT @Guid = CAST(NEWID() AS VARCHAR(255)), @CurrentUser = CURRENT_USER, @ProcIdName = ISNULL(OBJECT_NAME(@@PROCID), 'ad hoc')
				/*****************************************************************************************************************************************************************************************************************************************************************************************/
				-- Iterate through the matching process to peform a match on the desired combinations of columns for every record in #Incremental and every child match therein
				/*****************************************************************************************************************************************************************************************************************************************************************************************/

				-- Set up the match variables that will tell us what columns to match and how
				DECLARE	@MatchType TINYINT
						,@MatchIntention VARCHAR(255)
						,@NoFurtherMatchesFound BIT = 0

						,@IsMostRecent TINYINT
						,@NhsNumber TINYINT
						,@OriginalNhsNo TINYINT
						,@OriginalPasId TINYINT
						,@PasId TINYINT
						,@CasenoteId TINYINT
						,@DoB TINYINT
						,@DoD TINYINT
						,@Surname TINYINT
						,@Forename TINYINT
						,@Postcode TINYINT
						,@Sex TINYINT
						,@Address1 TINYINT
						,@Address2 TINYINT
						,@Address3 TINYINT
						,@Address4 TINYINT
						,@Address5 TINYINT
						,@DeathStatus TINYINT
						,@Title TINYINT
						,@Ethnicity TINYINT
						,@ReligionCode TINYINT

				WHILE @NoFurtherMatchesFound = 0
				BEGIN

						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Incremental subset'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

						-- Create a subset of tblDEMOGRAPHICS_vw_h_scr that is to be used for matching to the full dataset of tblDEMOGRAPHICS_vw_h_scr
						IF OBJECT_ID('tempdb..#tblDEMOGRAPHICS_Incremental') IS NOT NULL DROP TABLE #tblDEMOGRAPHICS_Incremental 
						SELECT		uh.IsSCR
									,uh.IsMostRecent
									,uh.SrcSys
									,uh.Src_UID
									,uh.NhsNumber
									,uh.OriginalNhsNo
									,uh.OriginalPasId
									,uh.PasId
									,uh.CasenoteId
									,uh.DoB
									,uh.DoD
									,uh.Surname
									,uh.Forename
									,uh.Postcode
									,uh.Sex
									,uh.Address1
									,uh.Address2
									,uh.Address3
									,uh.Address4
									,uh.Address5
									,uh.DeathStatus
									,uh.Title
									,uh.Ethnicity
									,uh.ReligionCode
						INTO		#tblDEMOGRAPHICS_Incremental
						FROM		Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH uh
						INNER JOIN	#Incremental inc 
													ON	uh.SrcSys = inc.SrcSys 
													AND	uh.Src_UID = inc.Src_UID 
													AND	inc.ProcessIx IS NULL

						-- Index the demographics incremental table		--		DECLARE	@SQL VARCHAR(MAX) ,@Guid VARCHAR(255) SELECT @Guid = CAST(NEWID() AS VARCHAR(255))
						SET @SQL =	'CREATE UNIQUE CLUSTERED INDEX [PK_DemIncremental_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (SrcSys ASC, Src_UID ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_IsSCR_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (IsSCR ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_IsMostRecent_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (IsMostRecent ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_NhsNumber_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (NhsNumber ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_OrignalNhsNo_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (OriginalNhsNo ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_OriginalPasId_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (OriginalPasId ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_PasId_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (PasId ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_CasenoteId_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (CasenoteId ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_DoB_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (DoB ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_DoD_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (DoD ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_Surname_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (Surname ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_Forename_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (Forename ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_Postcode_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (Postcode ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_Sex_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (Sex ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_Address1_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (Address1 ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_Address2_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (Address2 ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_Address3_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (Address3 ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_Address4_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (Address4 ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_Address5_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (Address5 ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_DeathStatus_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (DeathStatus ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_Title_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (Title ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_Ethnicity_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (Ethnicity ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_DemIncremental_ReligionCode_' + @Guid + '] ON #tblDEMOGRAPHICS_Incremental (ReligionCode ASC) '

						EXEC (@SQL)
				
								---- match variables available
								--,@NhsNumber		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('NhsNumber',1,NULL,NULL)
								--,@OriginalNhsNo		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('OriginalNhsNo',1,NULL,NULL)
								--,@OriginalPasId	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('OriginalPasId',1,NULL,NULL)
								--,@PasId			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('PasId',1,NULL,NULL)
								--,@CasenoteId	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('CasenoteId',1,NULL,NULL)
								--,@DoB			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DoB',1,NULL,NULL)
								--,@DoD			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DoD',1,NULL,NULL)
								--,@Surname		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Surname',1,NULL,NULL)
								--,@Forename		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Forename',1,NULL,NULL)
								--,@Postcode		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Postcode',1,NULL,NULL)
								--,@Sex			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Sex',1,NULL,NULL)
								--,@Address1		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Address1',1,NULL,NULL)
								--,@Address2		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Address2',1,NULL,NULL)
								--,@Address3		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Address3',1,NULL,NULL)
								--,@Address4		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Address4',1,NULL,NULL)
								--,@Address5		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Address5',1,NULL,NULL)
								--,@DeathStatus	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DeathStatus',1,NULL,NULL)
								--,@Title			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Title',1,NULL,NULL)
								--,@Ethnicity		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Ethnicity',1,NULL,NULL)
								--,@ReligionCode	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('ReligionCode',1,NULL,NULL)

						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 1'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
		
						/* Match type 1 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@MatchIntention = NULL, @MatchType = NULL, @SQL = NULL, @IsMostRecent = NULL, @OriginalNhsNo = NULL, @NhsNumber = NULL, @OriginalPasId = NULL, @PasId = NULL, @CasenoteId = NULL, @DoB = NULL, @DoD = NULL, @Surname = NULL
								, @Forename = NULL, @Postcode = NULL, @Sex = NULL, @Address1 = NULL, @Address2 = NULL, @Address3 = NULL, @Address4 = NULL, @Address5 = NULL, @DeathStatus = NULL, @Title = NULL, @Ethnicity = NULL, @ReligionCode = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Algorithmic'
								,@MatchType = 1
								-- Only set the variables for columns you want to match
								,@OriginalNhsNo	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('OriginalNhsNo',1,NULL,NULL)
								,@DoB			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DoB',1,NULL,NULL)
								,@Surname		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Surname',1,NULL,NULL)
								,@Forename		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Forename',1,NULL,NULL)

						SET @SQL =								'SELECT		A.IsSCR ' + CHAR(13) +
																'			,A.SrcSys ' + CHAR(13) +
																'			,A.Src_UID ' + CHAR(13) +
																'			,B.IsSCR ' + CHAR(13) +
																'			,B.SrcSys ' + CHAR(13) +
																'			,B.Src_UID ' + CHAR(13) +
																'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																'FROM		#tblDEMOGRAPHICS_Incremental A ' + CHAR(13) +
																'INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH B ' + CHAR(13) +
																'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + CHAR(13) + -- Don't self join
						CASE WHEN @LoopCounter > 1		THEN	'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @IsMostRecent = 1		THEN	'									AND A.IsMostRecent	= B.IsMostRecent ' + CHAR(13) ELSE '' END +
						CASE WHEN @NhsNumber = 1		THEN	'									AND A.NhsNumber		= B.NhsNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo = 1	THEN	'									AND A.OriginalNhsNo	= B.OriginalNhsNo ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId = 1	THEN	'									AND A.OriginalPasId	= B.OriginalPasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId = 1			THEN	'									AND A.PasId			= B.PasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId = 1		THEN	'									AND A.CasenoteId	= B.CasenoteId ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB = 1				THEN	'									AND A.DoB			= B.DoB ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD = 1				THEN	'									AND A.DoD			= B.DoD ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname = 1			THEN	'									AND A.Surname		= B.Surname ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename = 1			THEN	'									AND A.Forename		= B.Forename ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode = 1			THEN	'									AND A.Postcode		= B.Postcode ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex = 1				THEN	'									AND A.Sex			= B.Sex ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 = 1			THEN	'									AND A.Address1		= B.Address1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 = 1			THEN	'									AND A.Address2		= B.Address2 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 = 1			THEN	'									AND A.Address3		= B.Address3 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 = 1			THEN	'									AND A.Address4		= B.Address4 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 = 1			THEN	'									AND A.Address5		= B.Address5 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus = 1		THEN	'									AND A.DeathStatus	= B.DeathStatus ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title = 1			THEN	'									AND A.Title			= B.Title ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity = 1		THEN	'									AND A.Ethnicity		= B.Ethnicity ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode = 1		THEN	'									AND A.ReligionCode	= B.ReligionCode ' + CHAR(13) ELSE '' END +

																'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @NhsNumber > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''NhsNumber''		,0, A.NhsNumber		, B.NhsNumber		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @IsMostRecent > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''IsMostRecent''	,0, A.IsMostRecent	, B.IsMostRecent	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalNhsNo''	,0, A.OriginalNhsNo	, B.OriginalNhsNo	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalPasId''	,0, A.OriginalPasId	, B.OriginalPasId	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''PasId''			,0, A.PasId			, B.PasId			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''CasenoteId''		,0, A.CasenoteId	, B.CasenoteId		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoB''			,0, A.DoB			, B.DoB				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoD''			,0, A.DoD			, B.DoD				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Surname''		,0, A.Surname		, B.Surname			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Forename''		,0, A.Forename		, B.Forename		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Postcode''		,0, A.Postcode		, B.Postcode		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Sex''			,0, A.Sex			, B.Sex				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address1''		,0, A.Address1		, B.Address1		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address2''		,0, A.Address2		, B.Address2		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address3''		,0, A.Address3		, B.Address3		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address4''		,0, A.Address4		, B.Address4		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address5''		,0, A.Address5		, B.Address5		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DeathStatus''	,0, A.DeathStatus	, B.DeathStatus		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Title''			,0, A.Title			, B.Title			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Ethnicity''		,0, A.Ethnicity		, B.Ethnicity		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''ReligionCode''	,0, A.ReligionCode	, B.ReligionCode	) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						INSERT INTO	#tblDEMOGRAPHICS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/

						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 2'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 2 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@MatchIntention = NULL, @MatchType = NULL, @SQL = NULL, @IsMostRecent = NULL, @OriginalNhsNo = NULL, @NhsNumber = NULL, @OriginalPasId = NULL, @PasId = NULL, @CasenoteId = NULL, @DoB = NULL, @DoD = NULL, @Surname = NULL
								, @Forename = NULL, @Postcode = NULL, @Sex = NULL, @Address1 = NULL, @Address2 = NULL, @Address3 = NULL, @Address4 = NULL, @Address5 = NULL, @DeathStatus = NULL, @Title = NULL, @Ethnicity = NULL, @ReligionCode = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Algorithmic'
								,@MatchType = 2
								-- Only set the variables for columns you want to match
								,@PasId			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('PasId',1,NULL,NULL)
								,@NhsNumber		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('NhsNumber',1,NULL,NULL)
								,@DoB			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DoB',1,NULL,NULL)

						SET @SQL =								'SELECT		A.IsSCR ' + CHAR(13) +
																'			,A.SrcSys ' + CHAR(13) +
																'			,A.Src_UID ' + CHAR(13) +
																'			,B.IsSCR ' + CHAR(13) +
																'			,B.SrcSys ' + CHAR(13) +
																'			,B.Src_UID ' + CHAR(13) +
																'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																'FROM		#tblDEMOGRAPHICS_Incremental A ' + CHAR(13) +
																'INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH B ' + CHAR(13) +
																'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + CHAR(13) + -- Don't self join
						CASE WHEN @LoopCounter > 1		THEN	'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @IsMostRecent = 1		THEN	'									AND A.IsMostRecent	= B.IsMostRecent ' + CHAR(13) ELSE '' END +
						CASE WHEN @NhsNumber = 1		THEN	'									AND A.NhsNumber		= B.NhsNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo = 1	THEN	'									AND A.OriginalNhsNo	= B.OriginalNhsNo ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId = 1	THEN	'									AND A.OriginalPasId	= B.OriginalPasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId = 1			THEN	'									AND A.PasId			= B.PasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId = 1		THEN	'									AND A.CasenoteId	= B.CasenoteId ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB = 1				THEN	'									AND A.DoB			= B.DoB ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD = 1				THEN	'									AND A.DoD			= B.DoD ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname = 1			THEN	'									AND A.Surname		= B.Surname ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename = 1			THEN	'									AND A.Forename		= B.Forename ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode = 1			THEN	'									AND A.Postcode		= B.Postcode ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex = 1				THEN	'									AND A.Sex			= B.Sex ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 = 1			THEN	'									AND A.Address1		= B.Address1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 = 1			THEN	'									AND A.Address2		= B.Address2 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 = 1			THEN	'									AND A.Address3		= B.Address3 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 = 1			THEN	'									AND A.Address4		= B.Address4 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 = 1			THEN	'									AND A.Address5		= B.Address5 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus = 1		THEN	'									AND A.DeathStatus	= B.DeathStatus ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title = 1			THEN	'									AND A.Title			= B.Title ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity = 1		THEN	'									AND A.Ethnicity		= B.Ethnicity ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode = 1		THEN	'									AND A.ReligionCode	= B.ReligionCode ' + CHAR(13) ELSE '' END +

																'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @NhsNumber > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''NhsNumber''		,0, A.NhsNumber		, B.NhsNumber		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @IsMostRecent > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''IsMostRecent''	,0, A.IsMostRecent	, B.IsMostRecent	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalNhsNo''	,0, A.OriginalNhsNo	, B.OriginalNhsNo	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalPasId''	,0, A.OriginalPasId	, B.OriginalPasId	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''PasId''			,0, A.PasId			, B.PasId			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''CasenoteId''		,0, A.CasenoteId	, B.CasenoteId		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoB''			,0, A.DoB			, B.DoB				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoD''			,0, A.DoD			, B.DoD				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Surname''		,0, A.Surname		, B.Surname			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Forename''		,0, A.Forename		, B.Forename		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Postcode''		,0, A.Postcode		, B.Postcode		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Sex''			,0, A.Sex			, B.Sex				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address1''		,0, A.Address1		, B.Address1		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address2''		,0, A.Address2		, B.Address2		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address3''		,0, A.Address3		, B.Address3		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address4''		,0, A.Address4		, B.Address4		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address5''		,0, A.Address5		, B.Address5		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DeathStatus''	,0, A.DeathStatus	, B.DeathStatus		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Title''			,0, A.Title			, B.Title			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Ethnicity''		,0, A.Ethnicity		, B.Ethnicity		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''ReligionCode''	,0, A.ReligionCode	, B.ReligionCode	) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						INSERT INTO	#tblDEMOGRAPHICS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)

				
						/*########################################################################################################################################################################################################################*/

						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 3'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 3 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@MatchIntention = NULL, @MatchType = NULL, @SQL = NULL, @IsMostRecent = NULL, @OriginalNhsNo = NULL, @NhsNumber = NULL, @OriginalPasId = NULL, @PasId = NULL, @CasenoteId = NULL, @DoB = NULL, @DoD = NULL, @Surname = NULL
								, @Forename = NULL, @Postcode = NULL, @Sex = NULL, @Address1 = NULL, @Address2 = NULL, @Address3 = NULL, @Address4 = NULL, @Address5 = NULL, @DeathStatus = NULL, @Title = NULL, @Ethnicity = NULL, @ReligionCode = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Algorithmic'
								,@MatchType = 3
								-- Only set the variables for columns you want to match
								,@OriginalPasId	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('OriginalPasId',1,NULL,NULL)
								,@DoB			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DoB',1,NULL,NULL)
								,@Surname		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Surname',1,NULL,NULL)
								,@Forename		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Forename',1,NULL,NULL)

						SET @SQL =								'SELECT		A.IsSCR ' + CHAR(13) +
																'			,A.SrcSys ' + CHAR(13) +
																'			,A.Src_UID ' + CHAR(13) +
																'			,B.IsSCR ' + CHAR(13) +
																'			,B.SrcSys ' + CHAR(13) +
																'			,B.Src_UID ' + CHAR(13) +
																'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																'FROM		#tblDEMOGRAPHICS_Incremental A ' + CHAR(13) +
																'INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH B ' + CHAR(13) +
																'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + CHAR(13) + -- Don't self join
						CASE WHEN @LoopCounter > 1		THEN	'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @IsMostRecent = 1		THEN	'									AND A.IsMostRecent	= B.IsMostRecent ' + CHAR(13) ELSE '' END +
						CASE WHEN @NhsNumber = 1		THEN	'									AND A.NhsNumber		= B.NhsNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo = 1	THEN	'									AND A.OriginalNhsNo	= B.OriginalNhsNo ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId = 1	THEN	'									AND A.OriginalPasId	= B.OriginalPasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId = 1			THEN	'									AND A.PasId			= B.PasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId = 1		THEN	'									AND A.CasenoteId	= B.CasenoteId ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB = 1				THEN	'									AND A.DoB			= B.DoB ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD = 1				THEN	'									AND A.DoD			= B.DoD ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname = 1			THEN	'									AND A.Surname		= B.Surname ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename = 1			THEN	'									AND A.Forename		= B.Forename ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode = 1			THEN	'									AND A.Postcode		= B.Postcode ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex = 1				THEN	'									AND A.Sex			= B.Sex ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 = 1			THEN	'									AND A.Address1		= B.Address1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 = 1			THEN	'									AND A.Address2		= B.Address2 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 = 1			THEN	'									AND A.Address3		= B.Address3 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 = 1			THEN	'									AND A.Address4		= B.Address4 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 = 1			THEN	'									AND A.Address5		= B.Address5 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus = 1		THEN	'									AND A.DeathStatus	= B.DeathStatus ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title = 1			THEN	'									AND A.Title			= B.Title ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity = 1		THEN	'									AND A.Ethnicity		= B.Ethnicity ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode = 1		THEN	'									AND A.ReligionCode	= B.ReligionCode ' + CHAR(13) ELSE '' END +

																'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @NhsNumber > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''NhsNumber''		,0, A.NhsNumber		, B.NhsNumber		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @IsMostRecent > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''IsMostRecent''	,0, A.IsMostRecent	, B.IsMostRecent	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalNhsNo''	,0, A.OriginalNhsNo	, B.OriginalNhsNo	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalPasId''	,0, A.OriginalPasId	, B.OriginalPasId	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''PasId''			,0, A.PasId			, B.PasId			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''CasenoteId''		,0, A.CasenoteId	, B.CasenoteId		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoB''			,0, A.DoB			, B.DoB				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoD''			,0, A.DoD			, B.DoD				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Surname''		,0, A.Surname		, B.Surname			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Forename''		,0, A.Forename		, B.Forename		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Postcode''		,0, A.Postcode		, B.Postcode		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Sex''			,0, A.Sex			, B.Sex				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address1''		,0, A.Address1		, B.Address1		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address2''		,0, A.Address2		, B.Address2		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address3''		,0, A.Address3		, B.Address3		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address4''		,0, A.Address4		, B.Address4		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address5''		,0, A.Address5		, B.Address5		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DeathStatus''	,0, A.DeathStatus	, B.DeathStatus		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Title''			,0, A.Title			, B.Title			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Ethnicity''		,0, A.Ethnicity		, B.Ethnicity		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''ReligionCode''	,0, A.ReligionCode	, B.ReligionCode	) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						INSERT INTO	#tblDEMOGRAPHICS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/

						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 4'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 4 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@MatchIntention = NULL, @MatchType = NULL, @SQL = NULL, @IsMostRecent = NULL, @OriginalNhsNo = NULL, @NhsNumber = NULL, @OriginalPasId = NULL, @PasId = NULL, @CasenoteId = NULL, @DoB = NULL, @DoD = NULL, @Surname = NULL
								, @Forename = NULL, @Postcode = NULL, @Sex = NULL, @Address1 = NULL, @Address2 = NULL, @Address3 = NULL, @Address4 = NULL, @Address5 = NULL, @DeathStatus = NULL, @Title = NULL, @Ethnicity = NULL, @ReligionCode = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Algorithmic'
								,@MatchType = 4
								-- Only set the variables for columns you want to match
								,@CasenoteId	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('CasenoteId',1,NULL,NULL)
								,@DoB			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DoB',1,NULL,NULL)
								,@Surname		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Surname',1,NULL,NULL)
								,@Forename		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Forename',1,NULL,NULL)

						SET @SQL =								'SELECT		A.IsSCR ' + CHAR(13) +
																'			,A.SrcSys ' + CHAR(13) +
																'			,A.Src_UID ' + CHAR(13) +
																'			,B.IsSCR ' + CHAR(13) +
																'			,B.SrcSys ' + CHAR(13) +
																'			,B.Src_UID ' + CHAR(13) +
																'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																'FROM		#tblDEMOGRAPHICS_Incremental A ' + CHAR(13) +
																'INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH B ' + CHAR(13) +
																'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + CHAR(13) + -- Don't self join
						CASE WHEN @LoopCounter > 1		THEN	'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @IsMostRecent = 1		THEN	'									AND A.IsMostRecent	= B.IsMostRecent ' + CHAR(13) ELSE '' END +
						CASE WHEN @NhsNumber = 1		THEN	'									AND A.NhsNumber		= B.NhsNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo = 1	THEN	'									AND A.OriginalNhsNo	= B.OriginalNhsNo ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId = 1	THEN	'									AND A.OriginalPasId	= B.OriginalPasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId = 1			THEN	'									AND A.PasId			= B.PasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId = 1		THEN	'									AND A.CasenoteId	= B.CasenoteId ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB = 1				THEN	'									AND A.DoB			= B.DoB ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD = 1				THEN	'									AND A.DoD			= B.DoD ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname = 1			THEN	'									AND A.Surname		= B.Surname ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename = 1			THEN	'									AND A.Forename		= B.Forename ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode = 1			THEN	'									AND A.Postcode		= B.Postcode ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex = 1				THEN	'									AND A.Sex			= B.Sex ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 = 1			THEN	'									AND A.Address1		= B.Address1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 = 1			THEN	'									AND A.Address2		= B.Address2 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 = 1			THEN	'									AND A.Address3		= B.Address3 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 = 1			THEN	'									AND A.Address4		= B.Address4 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 = 1			THEN	'									AND A.Address5		= B.Address5 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus = 1		THEN	'									AND A.DeathStatus	= B.DeathStatus ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title = 1			THEN	'									AND A.Title			= B.Title ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity = 1		THEN	'									AND A.Ethnicity		= B.Ethnicity ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode = 1		THEN	'									AND A.ReligionCode	= B.ReligionCode ' + CHAR(13) ELSE '' END +

																'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @NhsNumber > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''NhsNumber''		,0, A.NhsNumber		, B.NhsNumber		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @IsMostRecent > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''IsMostRecent''	,0, A.IsMostRecent	, B.IsMostRecent	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalNhsNo''	,0, A.OriginalNhsNo	, B.OriginalNhsNo	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalPasId''	,0, A.OriginalPasId	, B.OriginalPasId	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''PasId''			,0, A.PasId			, B.PasId			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''CasenoteId''		,0, A.CasenoteId	, B.CasenoteId		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoB''			,0, A.DoB			, B.DoB				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoD''			,0, A.DoD			, B.DoD				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Surname''		,0, A.Surname		, B.Surname			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Forename''		,0, A.Forename		, B.Forename		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Postcode''		,0, A.Postcode		, B.Postcode		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Sex''			,0, A.Sex			, B.Sex				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address1''		,0, A.Address1		, B.Address1		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address2''		,0, A.Address2		, B.Address2		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address3''		,0, A.Address3		, B.Address3		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address4''		,0, A.Address4		, B.Address4		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address5''		,0, A.Address5		, B.Address5		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DeathStatus''	,0, A.DeathStatus	, B.DeathStatus		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Title''			,0, A.Title			, B.Title			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Ethnicity''		,0, A.Ethnicity		, B.Ethnicity		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''ReligionCode''	,0, A.ReligionCode	, B.ReligionCode	) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						INSERT INTO	#tblDEMOGRAPHICS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/

						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 5'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 5 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@MatchIntention = NULL, @MatchType = NULL, @SQL = NULL, @IsMostRecent = NULL, @OriginalNhsNo = NULL, @NhsNumber = NULL, @OriginalPasId = NULL, @PasId = NULL, @CasenoteId = NULL, @DoB = NULL, @DoD = NULL, @Surname = NULL
								, @Forename = NULL, @Postcode = NULL, @Sex = NULL, @Address1 = NULL, @Address2 = NULL, @Address3 = NULL, @Address4 = NULL, @Address5 = NULL, @DeathStatus = NULL, @Title = NULL, @Ethnicity = NULL, @ReligionCode = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 5
								-- Only set the variables for columns you want to match
								,@OriginalPasId	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('OriginalPasId',1,NULL,NULL)
								,@DoB			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DoB',1,NULL,NULL)

						SET @SQL =								'SELECT		A.IsSCR ' + CHAR(13) +
																'			,A.SrcSys ' + CHAR(13) +
																'			,A.Src_UID ' + CHAR(13) +
																'			,B.IsSCR ' + CHAR(13) +
																'			,B.SrcSys ' + CHAR(13) +
																'			,B.Src_UID ' + CHAR(13) +
																'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																'FROM		#tblDEMOGRAPHICS_Incremental A ' + CHAR(13) +
																'INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH B ' + CHAR(13) +
																'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + CHAR(13) + -- Don't self join
						CASE WHEN @LoopCounter > 1		THEN	'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @IsMostRecent = 1		THEN	'									AND A.IsMostRecent	= B.IsMostRecent ' + CHAR(13) ELSE '' END +
						CASE WHEN @NhsNumber = 1		THEN	'									AND A.NhsNumber		= B.NhsNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo = 1	THEN	'									AND A.OriginalNhsNo	= B.OriginalNhsNo ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId = 1	THEN	'									AND A.OriginalPasId	= B.OriginalPasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId = 1			THEN	'									AND A.PasId			= B.PasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId = 1		THEN	'									AND A.CasenoteId	= B.CasenoteId ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB = 1				THEN	'									AND A.DoB			= B.DoB ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD = 1				THEN	'									AND A.DoD			= B.DoD ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname = 1			THEN	'									AND A.Surname		= B.Surname ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename = 1			THEN	'									AND A.Forename		= B.Forename ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode = 1			THEN	'									AND A.Postcode		= B.Postcode ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex = 1				THEN	'									AND A.Sex			= B.Sex ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 = 1			THEN	'									AND A.Address1		= B.Address1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 = 1			THEN	'									AND A.Address2		= B.Address2 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 = 1			THEN	'									AND A.Address3		= B.Address3 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 = 1			THEN	'									AND A.Address4		= B.Address4 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 = 1			THEN	'									AND A.Address5		= B.Address5 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus = 1		THEN	'									AND A.DeathStatus	= B.DeathStatus ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title = 1			THEN	'									AND A.Title			= B.Title ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity = 1		THEN	'									AND A.Ethnicity		= B.Ethnicity ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode = 1		THEN	'									AND A.ReligionCode	= B.ReligionCode ' + CHAR(13) ELSE '' END +

																'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @NhsNumber > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''NhsNumber''		,0, A.NhsNumber		, B.NhsNumber		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @IsMostRecent > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''IsMostRecent''	,0, A.IsMostRecent	, B.IsMostRecent	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalNhsNo''	,0, A.OriginalNhsNo	, B.OriginalNhsNo	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalPasId''	,0, A.OriginalPasId	, B.OriginalPasId	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''PasId''			,0, A.PasId			, B.PasId			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''CasenoteId''		,0, A.CasenoteId	, B.CasenoteId		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoB''			,0, A.DoB			, B.DoB				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoD''			,0, A.DoD			, B.DoD				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Surname''		,0, A.Surname		, B.Surname			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Forename''		,0, A.Forename		, B.Forename		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Postcode''		,0, A.Postcode		, B.Postcode		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Sex''			,0, A.Sex			, B.Sex				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address1''		,0, A.Address1		, B.Address1		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address2''		,0, A.Address2		, B.Address2		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address3''		,0, A.Address3		, B.Address3		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address4''		,0, A.Address4		, B.Address4		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address5''		,0, A.Address5		, B.Address5		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DeathStatus''	,0, A.DeathStatus	, B.DeathStatus		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Title''			,0, A.Title			, B.Title			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Ethnicity''		,0, A.Ethnicity		, B.Ethnicity		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''ReligionCode''	,0, A.ReligionCode	, B.ReligionCode	) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						INSERT INTO	#tblDEMOGRAPHICS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/

						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 6'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 6 ##########################################################################################################################################################################################################*/

						---- Refresh the match variables and set the columns we want to match
						--SELECT	@MatchIntention = NULL, @MatchType = NULL, @SQL = NULL, @IsMostRecent = NULL, @OriginalNhsNo = NULL, @NhsNumber = NULL, @OriginalPasId = NULL, @PasId = NULL, @CasenoteId = NULL, @DoB = NULL, @DoD = NULL, @Surname = NULL
						--		, @Forename = NULL, @Postcode = NULL, @Sex = NULL, @Address1 = NULL, @Address2 = NULL, @Address3 = NULL, @Address4 = NULL, @Address5 = NULL, @DeathStatus = NULL, @Title = NULL, @Ethnicity = NULL, @ReligionCode = NULL

						--SELECT	-- Required variables
						--		@MatchIntention = 'Validation'
						--		,@MatchType = 6
						--		-- Only set the variables for columns you want to match
						--		,@NhsNumber		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('NhsNumber',1,NULL,NULL)

						--SET @SQL =								'SELECT		A.IsSCR ' + CHAR(13) +
						--										'			,A.SrcSys ' + CHAR(13) +
						--										'			,A.Src_UID ' + CHAR(13) +
						--										'			,B.IsSCR ' + CHAR(13) +
						--										'			,B.SrcSys ' + CHAR(13) +
						--										'			,B.Src_UID ' + CHAR(13) +
						--										'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
						--										'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
						--										'FROM		#tblDEMOGRAPHICS_Incremental A ' + CHAR(13) +
						--										'INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH B ' + CHAR(13) +
						--										'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + CHAR(13) + -- Don't self join
						--CASE WHEN @LoopCounter > 1		THEN	'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						--CASE WHEN @IsMostRecent = 1		THEN	'									AND A.IsMostRecent	= B.IsMostRecent ' + CHAR(13) ELSE '' END +
						--CASE WHEN @NhsNumber = 1		THEN	'									AND A.NhsNumber		= B.NhsNumber ' + CHAR(13) ELSE '' END +
						--CASE WHEN @OriginalNhsNo = 1	THEN	'									AND A.OriginalNhsNo	= B.OriginalNhsNo ' + CHAR(13) ELSE '' END +
						--CASE WHEN @OriginalPasId = 1	THEN	'									AND A.OriginalPasId	= B.OriginalPasId ' + CHAR(13) ELSE '' END +
						--CASE WHEN @PasId = 1			THEN	'									AND A.PasId			= B.PasId ' + CHAR(13) ELSE '' END +
						--CASE WHEN @CasenoteId = 1		THEN	'									AND A.CasenoteId	= B.CasenoteId ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DoB = 1				THEN	'									AND A.DoB			= B.DoB ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DoD = 1				THEN	'									AND A.DoD			= B.DoD ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Surname = 1			THEN	'									AND A.Surname		= B.Surname ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Forename = 1			THEN	'									AND A.Forename		= B.Forename ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Postcode = 1			THEN	'									AND A.Postcode		= B.Postcode ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Sex = 1				THEN	'									AND A.Sex			= B.Sex ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address1 = 1			THEN	'									AND A.Address1		= B.Address1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address2 = 1			THEN	'									AND A.Address2		= B.Address2 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address3 = 1			THEN	'									AND A.Address3		= B.Address3 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address4 = 1			THEN	'									AND A.Address4		= B.Address4 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address5 = 1			THEN	'									AND A.Address5		= B.Address5 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DeathStatus = 1		THEN	'									AND A.DeathStatus	= B.DeathStatus ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Title = 1			THEN	'									AND A.Title			= B.Title ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Ethnicity = 1		THEN	'									AND A.Ethnicity		= B.Ethnicity ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ReligionCode = 1		THEN	'									AND A.ReligionCode	= B.ReligionCode ' + CHAR(13) ELSE '' END +

						--										'WHERE		1 = 1 ' + CHAR(13) +
						--CASE WHEN @NhsNumber > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''NhsNumber''		,0, A.NhsNumber		, B.NhsNumber		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @IsMostRecent > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''IsMostRecent''	,0, A.IsMostRecent	, B.IsMostRecent	) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @OriginalNhsNo > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalNhsNo''	,0, A.OriginalNhsNo	, B.OriginalNhsNo	) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @OriginalPasId > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalPasId''	,0, A.OriginalPasId	, B.OriginalPasId	) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @PasId > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''PasId''			,0, A.PasId			, B.PasId			) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @CasenoteId > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''CasenoteId''		,0, A.CasenoteId	, B.CasenoteId		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DoB > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoB''			,0, A.DoB			, B.DoB				) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DoD > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoD''			,0, A.DoD			, B.DoD				) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Surname > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Surname''		,0, A.Surname		, B.Surname			) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Forename > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Forename''		,0, A.Forename		, B.Forename		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Postcode > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Postcode''		,0, A.Postcode		, B.Postcode		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Sex > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Sex''			,0, A.Sex			, B.Sex				) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address1 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address1''		,0, A.Address1		, B.Address1		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address2 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address2''		,0, A.Address2		, B.Address2		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address3 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address3''		,0, A.Address3		, B.Address3		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address4 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address4''		,0, A.Address4		, B.Address4		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address5 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address5''		,0, A.Address5		, B.Address5		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DeathStatus > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DeathStatus''	,0, A.DeathStatus	, B.DeathStatus		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Title > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Title''			,0, A.Title			, B.Title			) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Ethnicity > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Ethnicity''		,0, A.Ethnicity		, B.Ethnicity		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ReligionCode > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''ReligionCode''	,0, A.ReligionCode	, B.ReligionCode	) = 1 ' + CHAR(13) ELSE '' END

						---- Debug dynamic SQL
						--PRINT @SQL
		
						---- Find all the matching entity pairs
						--INSERT INTO	#tblDEMOGRAPHICS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						--EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/

						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 7'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 7 ##########################################################################################################################################################################################################*/

						---- Refresh the match variables and set the columns we want to match
						--SELECT	@MatchIntention = NULL, @MatchType = NULL, @SQL = NULL, @IsMostRecent = NULL, @OriginalNhsNo = NULL, @NhsNumber = NULL, @OriginalPasId = NULL, @PasId = NULL, @CasenoteId = NULL, @DoB = NULL, @DoD = NULL, @Surname = NULL
						--		, @Forename = NULL, @Postcode = NULL, @Sex = NULL, @Address1 = NULL, @Address2 = NULL, @Address3 = NULL, @Address4 = NULL, @Address5 = NULL, @DeathStatus = NULL, @Title = NULL, @Ethnicity = NULL, @ReligionCode = NULL

						--SELECT	-- Required variables
						--		@MatchIntention = 'Validation'
						--		,@MatchType = 7
						--		-- Only set the variables for columns you want to match
						--		,@PasId	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('PasId',1,NULL,NULL)

						--SET @SQL =								'SELECT		A.IsSCR ' + CHAR(13) +
						--										'			,A.SrcSys ' + CHAR(13) +
						--										'			,A.Src_UID ' + CHAR(13) +
						--										'			,B.IsSCR ' + CHAR(13) +
						--										'			,B.SrcSys ' + CHAR(13) +
						--										'			,B.Src_UID ' + CHAR(13) +
						--										'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
						--										'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
						--										'FROM		#tblDEMOGRAPHICS_Incremental A ' + CHAR(13) +
						--										'INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH B ' + CHAR(13) +
						--										'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + CHAR(13) + -- Don't self join
						--CASE WHEN @LoopCounter > 1		THEN	'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						--CASE WHEN @IsMostRecent = 1		THEN	'									AND A.IsMostRecent	= B.IsMostRecent ' + CHAR(13) ELSE '' END +
						--CASE WHEN @NhsNumber = 1		THEN	'									AND A.NhsNumber		= B.NhsNumber ' + CHAR(13) ELSE '' END +
						--CASE WHEN @OriginalNhsNo = 1	THEN	'									AND A.OriginalNhsNo	= B.OriginalNhsNo ' + CHAR(13) ELSE '' END +
						--CASE WHEN @OriginalPasId = 1	THEN	'									AND A.OriginalPasId	= B.OriginalPasId ' + CHAR(13) ELSE '' END +
						--CASE WHEN @PasId = 1			THEN	'									AND A.PasId			= B.PasId ' + CHAR(13) ELSE '' END +
						--CASE WHEN @CasenoteId = 1		THEN	'									AND A.CasenoteId	= B.CasenoteId ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DoB = 1				THEN	'									AND A.DoB			= B.DoB ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DoD = 1				THEN	'									AND A.DoD			= B.DoD ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Surname = 1			THEN	'									AND A.Surname		= B.Surname ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Forename = 1			THEN	'									AND A.Forename		= B.Forename ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Postcode = 1			THEN	'									AND A.Postcode		= B.Postcode ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Sex = 1				THEN	'									AND A.Sex			= B.Sex ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address1 = 1			THEN	'									AND A.Address1		= B.Address1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address2 = 1			THEN	'									AND A.Address2		= B.Address2 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address3 = 1			THEN	'									AND A.Address3		= B.Address3 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address4 = 1			THEN	'									AND A.Address4		= B.Address4 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address5 = 1			THEN	'									AND A.Address5		= B.Address5 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DeathStatus = 1		THEN	'									AND A.DeathStatus	= B.DeathStatus ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Title = 1			THEN	'									AND A.Title			= B.Title ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Ethnicity = 1		THEN	'									AND A.Ethnicity		= B.Ethnicity ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ReligionCode = 1		THEN	'									AND A.ReligionCode	= B.ReligionCode ' + CHAR(13) ELSE '' END +

						--										'WHERE		1 = 1 ' + CHAR(13) +
						--CASE WHEN @NhsNumber > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''NhsNumber''		,0, A.NhsNumber		, B.NhsNumber		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @IsMostRecent > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''IsMostRecent''	,0, A.IsMostRecent	, B.IsMostRecent	) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @OriginalNhsNo > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalNhsNo''	,0, A.OriginalNhsNo	, B.OriginalNhsNo	) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @OriginalPasId > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalPasId''	,0, A.OriginalPasId	, B.OriginalPasId	) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @PasId > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''PasId''			,0, A.PasId			, B.PasId			) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @CasenoteId > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''CasenoteId''		,0, A.CasenoteId	, B.CasenoteId		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DoB > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoB''			,0, A.DoB			, B.DoB				) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DoD > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoD''			,0, A.DoD			, B.DoD				) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Surname > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Surname''		,0, A.Surname		, B.Surname			) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Forename > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Forename''		,0, A.Forename		, B.Forename		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Postcode > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Postcode''		,0, A.Postcode		, B.Postcode		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Sex > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Sex''			,0, A.Sex			, B.Sex				) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address1 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address1''		,0, A.Address1		, B.Address1		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address2 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address2''		,0, A.Address2		, B.Address2		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address3 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address3''		,0, A.Address3		, B.Address3		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address4 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address4''		,0, A.Address4		, B.Address4		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address5 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address5''		,0, A.Address5		, B.Address5		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DeathStatus > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DeathStatus''	,0, A.DeathStatus	, B.DeathStatus		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Title > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Title''			,0, A.Title			, B.Title			) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Ethnicity > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Ethnicity''		,0, A.Ethnicity		, B.Ethnicity		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ReligionCode > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''ReligionCode''	,0, A.ReligionCode	, B.ReligionCode	) = 1 ' + CHAR(13) ELSE '' END

						---- Debug dynamic SQL
						--PRINT @SQL
		
						---- Find all the matching entity pairs
						--IF @LoopCounter = 1
						--INSERT INTO	#tblDEMOGRAPHICS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						--EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/

						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 8'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 8 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@MatchIntention = NULL, @MatchType = NULL, @SQL = NULL, @IsMostRecent = NULL, @OriginalNhsNo = NULL, @NhsNumber = NULL, @OriginalPasId = NULL, @PasId = NULL, @CasenoteId = NULL, @DoB = NULL, @DoD = NULL, @Surname = NULL
								, @Forename = NULL, @Postcode = NULL, @Sex = NULL, @Address1 = NULL, @Address2 = NULL, @Address3 = NULL, @Address4 = NULL, @Address5 = NULL, @DeathStatus = NULL, @Title = NULL, @Ethnicity = NULL, @ReligionCode = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 8
								-- Only set the variables for columns you want to match
								,@DoB				= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DoB',1,NULL,NULL)
								,@Surname			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Surname',1,NULL,NULL)
								,@Forename			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Forename',1,NULL,NULL)
								,@Postcode			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Postcode',1,NULL,NULL)
								,@Address1			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Address1',1,NULL,NULL)
								,@IsMostRecent	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('IsMostRecent',1,NULL,NULL)

						SET @SQL =								'SELECT		A.IsSCR ' + CHAR(13) +
																'			,A.SrcSys ' + CHAR(13) +
																'			,A.Src_UID ' + CHAR(13) +
																'			,B.IsSCR ' + CHAR(13) +
																'			,B.SrcSys ' + CHAR(13) +
																'			,B.Src_UID ' + CHAR(13) +
																'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																'FROM		#tblDEMOGRAPHICS_Incremental A ' + CHAR(13) +
																'INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH B ' + CHAR(13) +
																'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + CHAR(13) + -- Don't self join
						CASE WHEN @LoopCounter > 1		THEN	'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @IsMostRecent = 1		THEN	'									AND A.IsMostRecent	= B.IsMostRecent ' + CHAR(13) ELSE '' END +
						CASE WHEN @NhsNumber = 1		THEN	'									AND A.NhsNumber		= B.NhsNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo = 1	THEN	'									AND A.OriginalNhsNo	= B.OriginalNhsNo ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId = 1	THEN	'									AND A.OriginalPasId	= B.OriginalPasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId = 1			THEN	'									AND A.PasId			= B.PasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId = 1		THEN	'									AND A.CasenoteId	= B.CasenoteId ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB = 1				THEN	'									AND A.DoB			= B.DoB ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD = 1				THEN	'									AND A.DoD			= B.DoD ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname = 1			THEN	'									AND A.Surname		= B.Surname ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename = 1			THEN	'									AND A.Forename		= B.Forename ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode = 1			THEN	'									AND A.Postcode		= B.Postcode ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex = 1				THEN	'									AND A.Sex			= B.Sex ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 = 1			THEN	'									AND A.Address1		= B.Address1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 = 1			THEN	'									AND A.Address2		= B.Address2 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 = 1			THEN	'									AND A.Address3		= B.Address3 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 = 1			THEN	'									AND A.Address4		= B.Address4 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 = 1			THEN	'									AND A.Address5		= B.Address5 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus = 1		THEN	'									AND A.DeathStatus	= B.DeathStatus ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title = 1			THEN	'									AND A.Title			= B.Title ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity = 1		THEN	'									AND A.Ethnicity		= B.Ethnicity ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode = 1		THEN	'									AND A.ReligionCode	= B.ReligionCode ' + CHAR(13) ELSE '' END +

																'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @NhsNumber > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''NhsNumber''		,0, A.NhsNumber		, B.NhsNumber		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @IsMostRecent > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''IsMostRecent''	,0, A.IsMostRecent	, B.IsMostRecent	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalNhsNo''	,0, A.OriginalNhsNo	, B.OriginalNhsNo	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalPasId''	,0, A.OriginalPasId	, B.OriginalPasId	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''PasId''			,0, A.PasId			, B.PasId			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''CasenoteId''		,0, A.CasenoteId	, B.CasenoteId		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoB''			,0, A.DoB			, B.DoB				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoD''			,0, A.DoD			, B.DoD				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Surname''		,0, A.Surname		, B.Surname			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Forename''		,0, A.Forename		, B.Forename		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Postcode''		,0, A.Postcode		, B.Postcode		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Sex''			,0, A.Sex			, B.Sex				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address1''		,0, A.Address1		, B.Address1		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address2''		,0, A.Address2		, B.Address2		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address3''		,0, A.Address3		, B.Address3		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address4''		,0, A.Address4		, B.Address4		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address5''		,0, A.Address5		, B.Address5		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DeathStatus''	,0, A.DeathStatus	, B.DeathStatus		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Title''			,0, A.Title			, B.Title			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Ethnicity''		,0, A.Ethnicity		, B.Ethnicity		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''ReligionCode''	,0, A.ReligionCode	, B.ReligionCode	) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						IF @LoopCounter = 1
						INSERT INTO	#tblDEMOGRAPHICS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/

						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 9'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 9 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@MatchIntention = NULL, @MatchType = NULL, @SQL = NULL, @IsMostRecent = NULL, @OriginalNhsNo = NULL, @NhsNumber = NULL, @OriginalPasId = NULL, @PasId = NULL, @CasenoteId = NULL, @DoB = NULL, @DoD = NULL, @Surname = NULL
								, @Forename = NULL, @Postcode = NULL, @Sex = NULL, @Address1 = NULL, @Address2 = NULL, @Address3 = NULL, @Address4 = NULL, @Address5 = NULL, @DeathStatus = NULL, @Title = NULL, @Ethnicity = NULL, @ReligionCode = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 9
								-- Only set the variables for columns you want to match
								,@DoB				= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DoB',1,NULL,NULL)
								,@Surname			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Surname',1,NULL,NULL)
								,@Postcode			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Postcode',1,NULL,NULL)
								,@Address1			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Address1',1,NULL,NULL)
								,@Sex				= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Sex',1,NULL,NULL)
								,@Title				= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Title',1,NULL,NULL)
								,@Ethnicity			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Ethnicity',1,NULL,NULL)
								,@ReligionCode		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('ReligionCode',1,NULL,NULL)
								,@IsMostRecent	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('IsMostRecent',1,NULL,NULL)

						SET @SQL =								'SELECT		A.IsSCR ' + CHAR(13) +
																'			,A.SrcSys ' + CHAR(13) +
																'			,A.Src_UID ' + CHAR(13) +
																'			,B.IsSCR ' + CHAR(13) +
																'			,B.SrcSys ' + CHAR(13) +
																'			,B.Src_UID ' + CHAR(13) +
																'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																'FROM		#tblDEMOGRAPHICS_Incremental A ' + CHAR(13) +
																'INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH B ' + CHAR(13) +
																'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + CHAR(13) + -- Don't self join
						CASE WHEN @LoopCounter > 1		THEN	'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @IsMostRecent = 1		THEN	'									AND A.IsMostRecent	= B.IsMostRecent ' + CHAR(13) ELSE '' END +
						CASE WHEN @NhsNumber = 1		THEN	'									AND A.NhsNumber		= B.NhsNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo = 1	THEN	'									AND A.OriginalNhsNo	= B.OriginalNhsNo ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId = 1	THEN	'									AND A.OriginalPasId	= B.OriginalPasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId = 1			THEN	'									AND A.PasId			= B.PasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId = 1		THEN	'									AND A.CasenoteId	= B.CasenoteId ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB = 1				THEN	'									AND A.DoB			= B.DoB ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD = 1				THEN	'									AND A.DoD			= B.DoD ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname = 1			THEN	'									AND A.Surname		= B.Surname ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename = 1			THEN	'									AND A.Forename		= B.Forename ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode = 1			THEN	'									AND A.Postcode		= B.Postcode ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex = 1				THEN	'									AND A.Sex			= B.Sex ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 = 1			THEN	'									AND A.Address1		= B.Address1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 = 1			THEN	'									AND A.Address2		= B.Address2 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 = 1			THEN	'									AND A.Address3		= B.Address3 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 = 1			THEN	'									AND A.Address4		= B.Address4 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 = 1			THEN	'									AND A.Address5		= B.Address5 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus = 1		THEN	'									AND A.DeathStatus	= B.DeathStatus ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title = 1			THEN	'									AND A.Title			= B.Title ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity = 1		THEN	'									AND A.Ethnicity		= B.Ethnicity ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode = 1		THEN	'									AND A.ReligionCode	= B.ReligionCode ' + CHAR(13) ELSE '' END +

																'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @NhsNumber > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''NhsNumber''		,0, A.NhsNumber		, B.NhsNumber		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @IsMostRecent > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''IsMostRecent''	,0, A.IsMostRecent	, B.IsMostRecent	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalNhsNo''	,0, A.OriginalNhsNo	, B.OriginalNhsNo	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalPasId''	,0, A.OriginalPasId	, B.OriginalPasId	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''PasId''			,0, A.PasId			, B.PasId			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''CasenoteId''		,0, A.CasenoteId	, B.CasenoteId		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoB''			,0, A.DoB			, B.DoB				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoD''			,0, A.DoD			, B.DoD				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Surname''		,0, A.Surname		, B.Surname			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Forename''		,0, A.Forename		, B.Forename		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Postcode''		,0, A.Postcode		, B.Postcode		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Sex''			,0, A.Sex			, B.Sex				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address1''		,0, A.Address1		, B.Address1		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address2''		,0, A.Address2		, B.Address2		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address3''		,0, A.Address3		, B.Address3		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address4''		,0, A.Address4		, B.Address4		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address5''		,0, A.Address5		, B.Address5		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DeathStatus''	,0, A.DeathStatus	, B.DeathStatus		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Title''			,0, A.Title			, B.Title			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Ethnicity''		,0, A.Ethnicity		, B.Ethnicity		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''ReligionCode''	,0, A.ReligionCode	, B.ReligionCode	) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						IF @LoopCounter = 1
						INSERT INTO	#tblDEMOGRAPHICS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/

						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 10'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 10 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@MatchIntention = NULL, @MatchType = NULL, @SQL = NULL, @IsMostRecent = NULL, @OriginalNhsNo = NULL, @NhsNumber = NULL, @OriginalPasId = NULL, @PasId = NULL, @CasenoteId = NULL, @DoB = NULL, @DoD = NULL, @Surname = NULL
								, @Forename = NULL, @Postcode = NULL, @Sex = NULL, @Address1 = NULL, @Address2 = NULL, @Address3 = NULL, @Address4 = NULL, @Address5 = NULL, @DeathStatus = NULL, @Title = NULL, @Ethnicity = NULL, @ReligionCode = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 10
								-- Only set the variables for columns you want to match
								,@DoB				= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DoB',1,NULL,NULL)
								,@DoD				= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DoD',1,NULL,NULL)
								,@Forename			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Forename',1,NULL,NULL)
								,@Postcode			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Postcode',1,NULL,NULL)
								,@Sex				= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Sex',1,NULL,NULL)
								,@Address1			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Address1',1,NULL,NULL)
								,@Title				= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Title',1,NULL,NULL)
								,@Ethnicity			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Ethnicity',1,NULL,NULL)
								,@ReligionCode		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('ReligionCode',1,NULL,NULL)
								,@IsMostRecent	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('IsMostRecent',1,NULL,NULL)

						SET @SQL =								'SELECT		A.IsSCR ' + CHAR(13) +
																'			,A.SrcSys ' + CHAR(13) +
																'			,A.Src_UID ' + CHAR(13) +
																'			,B.IsSCR ' + CHAR(13) +
																'			,B.SrcSys ' + CHAR(13) +
																'			,B.Src_UID ' + CHAR(13) +
																'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																'FROM		#tblDEMOGRAPHICS_Incremental A ' + CHAR(13) +
																'INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH B ' + CHAR(13) +
																'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + CHAR(13) + -- Don't self join
						CASE WHEN @LoopCounter > 1		THEN	'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @IsMostRecent = 1		THEN	'									AND A.IsMostRecent	= B.IsMostRecent ' + CHAR(13) ELSE '' END +
						CASE WHEN @NhsNumber = 1		THEN	'									AND A.NhsNumber		= B.NhsNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo = 1	THEN	'									AND A.OriginalNhsNo	= B.OriginalNhsNo ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId = 1	THEN	'									AND A.OriginalPasId	= B.OriginalPasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId = 1			THEN	'									AND A.PasId			= B.PasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId = 1		THEN	'									AND A.CasenoteId	= B.CasenoteId ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB = 1				THEN	'									AND A.DoB			= B.DoB ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD = 1				THEN	'									AND A.DoD			= B.DoD ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname = 1			THEN	'									AND A.Surname		= B.Surname ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename = 1			THEN	'									AND A.Forename		= B.Forename ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode = 1			THEN	'									AND A.Postcode		= B.Postcode ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex = 1				THEN	'									AND A.Sex			= B.Sex ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 = 1			THEN	'									AND A.Address1		= B.Address1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 = 1			THEN	'									AND A.Address2		= B.Address2 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 = 1			THEN	'									AND A.Address3		= B.Address3 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 = 1			THEN	'									AND A.Address4		= B.Address4 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 = 1			THEN	'									AND A.Address5		= B.Address5 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus = 1		THEN	'									AND A.DeathStatus	= B.DeathStatus ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title = 1			THEN	'									AND A.Title			= B.Title ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity = 1		THEN	'									AND A.Ethnicity		= B.Ethnicity ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode = 1		THEN	'									AND A.ReligionCode	= B.ReligionCode ' + CHAR(13) ELSE '' END +

																'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @NhsNumber > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''NhsNumber''		,0, A.NhsNumber		, B.NhsNumber		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @IsMostRecent > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''IsMostRecent''	,0, A.IsMostRecent	, B.IsMostRecent	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalNhsNo''	,0, A.OriginalNhsNo	, B.OriginalNhsNo	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalPasId''	,0, A.OriginalPasId	, B.OriginalPasId	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''PasId''			,0, A.PasId			, B.PasId			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''CasenoteId''		,0, A.CasenoteId	, B.CasenoteId		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoB''			,0, A.DoB			, B.DoB				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoD''			,0, A.DoD			, B.DoD				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Surname''		,0, A.Surname		, B.Surname			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Forename''		,0, A.Forename		, B.Forename		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Postcode''		,0, A.Postcode		, B.Postcode		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Sex''			,0, A.Sex			, B.Sex				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address1''		,0, A.Address1		, B.Address1		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address2''		,0, A.Address2		, B.Address2		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address3''		,0, A.Address3		, B.Address3		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address4''		,0, A.Address4		, B.Address4		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address5''		,0, A.Address5		, B.Address5		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DeathStatus''	,0, A.DeathStatus	, B.DeathStatus		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Title''			,0, A.Title			, B.Title			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Ethnicity''		,0, A.Ethnicity		, B.Ethnicity		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''ReligionCode''	,0, A.ReligionCode	, B.ReligionCode	) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						IF @LoopCounter = 1
						INSERT INTO	#tblDEMOGRAPHICS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/
				
				
						/* Match type 11 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@MatchIntention = NULL, @MatchType = NULL, @SQL = NULL, @IsMostRecent = NULL, @OriginalNhsNo = NULL, @NhsNumber = NULL, @OriginalPasId = NULL, @PasId = NULL, @CasenoteId = NULL, @DoB = NULL, @DoD = NULL, @Surname = NULL
								, @Forename = NULL, @Postcode = NULL, @Sex = NULL, @Address1 = NULL, @Address2 = NULL, @Address3 = NULL, @Address4 = NULL, @Address5 = NULL, @DeathStatus = NULL, @Title = NULL, @Ethnicity = NULL, @ReligionCode = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 11
								-- Only set the variables for columns you want to match
								,@OriginalNhsNo	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('OriginalNhsNo',1,NULL,NULL)
								,@DoB			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DoB',1,NULL,NULL)

						SET @SQL =								'SELECT		A.IsSCR ' + CHAR(13) +
																'			,A.SrcSys ' + CHAR(13) +
																'			,A.Src_UID ' + CHAR(13) +
																'			,B.IsSCR ' + CHAR(13) +
																'			,B.SrcSys ' + CHAR(13) +
																'			,B.Src_UID ' + CHAR(13) +
																'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																'FROM		#tblDEMOGRAPHICS_Incremental A ' + CHAR(13) +
																'INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH B ' + CHAR(13) +
																'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + CHAR(13) + -- Don't self join
						CASE WHEN @LoopCounter > 1		THEN	'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @IsMostRecent = 1		THEN	'									AND A.IsMostRecent	= B.IsMostRecent ' + CHAR(13) ELSE '' END +
						CASE WHEN @NhsNumber = 1		THEN	'									AND A.NhsNumber		= B.NhsNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo = 1	THEN	'									AND A.OriginalNhsNo	= B.OriginalNhsNo ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId = 1	THEN	'									AND A.OriginalPasId	= B.OriginalPasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId = 1			THEN	'									AND A.PasId			= B.PasId ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId = 1		THEN	'									AND A.CasenoteId	= B.CasenoteId ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB = 1				THEN	'									AND A.DoB			= B.DoB ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD = 1				THEN	'									AND A.DoD			= B.DoD ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname = 1			THEN	'									AND A.Surname		= B.Surname ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename = 1			THEN	'									AND A.Forename		= B.Forename ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode = 1			THEN	'									AND A.Postcode		= B.Postcode ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex = 1				THEN	'									AND A.Sex			= B.Sex ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 = 1			THEN	'									AND A.Address1		= B.Address1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 = 1			THEN	'									AND A.Address2		= B.Address2 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 = 1			THEN	'									AND A.Address3		= B.Address3 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 = 1			THEN	'									AND A.Address4		= B.Address4 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 = 1			THEN	'									AND A.Address5		= B.Address5 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus = 1		THEN	'									AND A.DeathStatus	= B.DeathStatus ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title = 1			THEN	'									AND A.Title			= B.Title ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity = 1		THEN	'									AND A.Ethnicity		= B.Ethnicity ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode = 1		THEN	'									AND A.ReligionCode	= B.ReligionCode ' + CHAR(13) ELSE '' END +

																'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @NhsNumber > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''NhsNumber''		,0, A.NhsNumber		, B.NhsNumber		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @IsMostRecent > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''IsMostRecent''	,0, A.IsMostRecent	, B.IsMostRecent	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalNhsNo > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalNhsNo''	,0, A.OriginalNhsNo	, B.OriginalNhsNo	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @OriginalPasId > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalPasId''	,0, A.OriginalPasId	, B.OriginalPasId	) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @PasId > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''PasId''			,0, A.PasId			, B.PasId			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @CasenoteId > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''CasenoteId''		,0, A.CasenoteId	, B.CasenoteId		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoB > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoB''			,0, A.DoB			, B.DoB				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DoD > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoD''			,0, A.DoD			, B.DoD				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Surname > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Surname''		,0, A.Surname		, B.Surname			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Forename > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Forename''		,0, A.Forename		, B.Forename		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Postcode > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Postcode''		,0, A.Postcode		, B.Postcode		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Sex > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Sex''			,0, A.Sex			, B.Sex				) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address1 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address1''		,0, A.Address1		, B.Address1		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address2 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address2''		,0, A.Address2		, B.Address2		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address3 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address3''		,0, A.Address3		, B.Address3		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address4 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address4''		,0, A.Address4		, B.Address4		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Address5 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address5''		,0, A.Address5		, B.Address5		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @DeathStatus > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DeathStatus''	,0, A.DeathStatus	, B.DeathStatus		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Title > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Title''			,0, A.Title			, B.Title			) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Ethnicity > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Ethnicity''		,0, A.Ethnicity		, B.Ethnicity		) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ReligionCode > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''ReligionCode''	,0, A.ReligionCode	, B.ReligionCode	) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						-- PRINT @SQL
		
						-- Find all the matching entity pairs
						INSERT INTO	#tblDEMOGRAPHICS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/

						/* Match type 12 ##########################################################################################################################################################################################################*/

						---- Refresh the match variables and set the columns we want to match
						--SELECT	@MatchIntention = NULL, @MatchType = NULL, @SQL = NULL, @IsMostRecent = NULL, @OriginalNhsNo = NULL, @NhsNumber = NULL, @OriginalPasId = NULL, @PasId = NULL, @CasenoteId = NULL, @DoB = NULL, @DoD = NULL, @Surname = NULL
						--		, @Forename = NULL, @Postcode = NULL, @Sex = NULL, @Address1 = NULL, @Address2 = NULL, @Address3 = NULL, @Address4 = NULL, @Address5 = NULL, @DeathStatus = NULL, @Title = NULL, @Ethnicity = NULL, @ReligionCode = NULL

						--SELECT	-- Required variables
						--		@MatchIntention = 'Validation'
						--		,@MatchType = 12
						--		-- Only set the variables for columns you want to match
						--		,@NhsNumber		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('NhsNumber',1,NULL,NULL)
						--		,@OriginalNhsNo	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('OriginalNhsNo',1,NULL,NULL)
						--		,@OriginalPasId	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('OriginalPasId',1,NULL,NULL)
						--		,@PasId			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('PasId',1,NULL,NULL)
						--		,@CasenoteId	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('CasenoteId',1,NULL,NULL)
						--		,@DoB			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DoB',1,NULL,NULL)
						--		,@DoD			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DoD',1,NULL,NULL)
						--		,@Surname		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Surname',1,NULL,NULL)
						--		,@Forename		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Forename',1,NULL,NULL)
						--		,@Postcode		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Postcode',1,NULL,NULL)
						--		,@Sex			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Sex',1,NULL,NULL)
						--		,@Address1		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Address1',1,NULL,NULL)
						--		,@Address2		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Address2',1,NULL,NULL)
						--		,@Address3		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Address3',1,NULL,NULL)
						--		,@Address4		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Address4',1,NULL,NULL)
						--		,@Address5		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Address5',1,NULL,NULL)
						--		,@DeathStatus	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('DeathStatus',1,NULL,NULL)
						--		,@Title			= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Title',1,NULL,NULL)
						--		,@Ethnicity		= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('Ethnicity',1,NULL,NULL)
						--		,@ReligionCode	= Merge_DM_Match.tblDEMOGRAPHICS_fnCompare('ReligionCode',1,NULL,NULL)

						--SET @SQL =								'SELECT		A.IsSCR ' + CHAR(13) +
						--										'			,A.SrcSys ' + CHAR(13) +
						--										'			,A.Src_UID ' + CHAR(13) +
						--										'			,B.IsSCR ' + CHAR(13) +
						--										'			,B.SrcSys ' + CHAR(13) +
						--										'			,B.Src_UID ' + CHAR(13) +
						--										'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
						--										'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
						--										'FROM		#tblDEMOGRAPHICS_Incremental A ' + CHAR(13) +
						--										'INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH B ' + CHAR(13) +
						--										'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + CHAR(13) + -- Don't self join
						--CASE WHEN @LoopCounter > 1		THEN	'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						--CASE WHEN @IsMostRecent = 1		THEN	'									AND A.IsMostRecent	= B.IsMostRecent ' + CHAR(13) ELSE '' END +
						--CASE WHEN @NhsNumber = 1		THEN	'									AND A.NhsNumber		= B.NhsNumber ' + CHAR(13) ELSE '' END +
						--CASE WHEN @OriginalNhsNo = 1	THEN	'									AND A.OriginalNhsNo	= B.OriginalNhsNo ' + CHAR(13) ELSE '' END +
						--CASE WHEN @OriginalPasId = 1	THEN	'									AND A.OriginalPasId	= B.OriginalPasId ' + CHAR(13) ELSE '' END +
						--CASE WHEN @PasId = 1			THEN	'									AND A.PasId			= B.PasId ' + CHAR(13) ELSE '' END +
						--CASE WHEN @CasenoteId = 1		THEN	'									AND A.CasenoteId	= B.CasenoteId ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DoB = 1				THEN	'									AND A.DoB			= B.DoB ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DoD = 1				THEN	'									AND A.DoD			= B.DoD ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Surname = 1			THEN	'									AND A.Surname		= B.Surname ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Forename = 1			THEN	'									AND A.Forename		= B.Forename ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Postcode = 1			THEN	'									AND A.Postcode		= B.Postcode ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Sex = 1				THEN	'									AND A.Sex			= B.Sex ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address1 = 1			THEN	'									AND A.Address1		= B.Address1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address2 = 1			THEN	'									AND A.Address2		= B.Address2 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address3 = 1			THEN	'									AND A.Address3		= B.Address3 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address4 = 1			THEN	'									AND A.Address4		= B.Address4 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address5 = 1			THEN	'									AND A.Address5		= B.Address5 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DeathStatus = 1		THEN	'									AND A.DeathStatus	= B.DeathStatus ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Title = 1			THEN	'									AND A.Title			= B.Title ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Ethnicity = 1		THEN	'									AND A.Ethnicity		= B.Ethnicity ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ReligionCode = 1		THEN	'									AND A.ReligionCode	= B.ReligionCode ' + CHAR(13) ELSE '' END +

						--										'WHERE		1 = 1 ' + CHAR(13) +
						--CASE WHEN @NhsNumber > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''NhsNumber''		,0, A.NhsNumber		, B.NhsNumber		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @IsMostRecent > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''IsMostRecent''	,0, A.IsMostRecent	, B.IsMostRecent	) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @OriginalNhsNo > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalNhsNo''	,0, A.OriginalNhsNo	, B.OriginalNhsNo	) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @OriginalPasId > 1	THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''OriginalPasId''	,0, A.OriginalPasId	, B.OriginalPasId	) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @PasId > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''PasId''			,0, A.PasId			, B.PasId			) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @CasenoteId > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''CasenoteId''		,0, A.CasenoteId	, B.CasenoteId		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DoB > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoB''			,0, A.DoB			, B.DoB				) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DoD > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DoD''			,0, A.DoD			, B.DoD				) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Surname > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Surname''		,0, A.Surname		, B.Surname			) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Forename > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Forename''		,0, A.Forename		, B.Forename		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Postcode > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Postcode''		,0, A.Postcode		, B.Postcode		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Sex > 1				THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Sex''			,0, A.Sex			, B.Sex				) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address1 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address1''		,0, A.Address1		, B.Address1		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address2 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address2''		,0, A.Address2		, B.Address2		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address3 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address3''		,0, A.Address3		, B.Address3		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address4 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address4''		,0, A.Address4		, B.Address4		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Address5 > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Address5''		,0, A.Address5		, B.Address5		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @DeathStatus > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''DeathStatus''	,0, A.DeathStatus	, B.DeathStatus		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Title > 1			THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Title''			,0, A.Title			, B.Title			) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Ethnicity > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''Ethnicity''		,0, A.Ethnicity		, B.Ethnicity		) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ReligionCode > 1		THEN	'AND		Merge_DM_Match.tblDEMOGRAPHICS_fnCompare(''ReligionCode''	,0, A.ReligionCode	, B.ReligionCode	) = 1 ' + CHAR(13) ELSE '' END

						---- Debug dynamic SQL
						---- PRINT @SQL
		
						---- Find all the matching entity pairs
						--INSERT INTO	#tblDEMOGRAPHICS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						--EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/

						/**************************************************************************************************************************************************************************************************************************/
						-- Post-match cleanup of #tblDEMOGRAPHICS_Match_EntityPairs_All and preparation of #Incremental for the next loop (if there is one)
						/**************************************************************************************************************************************************************************************************************************/

						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Finish match loop'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

						-- Mark all the incremental records as having been processed
						UPDATE		#Incremental
						SET			ProcessIx = (SELECT ISNULL(MAX(ProcessIx) + 1, 1) FROM #Incremental)
						WHERE		ProcessIx IS NULL
				
						-- Mark the matches from this loop as being finished but incomplete (i.e. 0) and record the iteration order
						UPDATE		#tblDEMOGRAPHICS_Match_EntityPairs_All
						SET			LoopFinished = 0
									,Iteration = (SELECT ISNULL(MAX(Iteration) + 1, 1) FROM #tblDEMOGRAPHICS_Match_EntityPairs_All)
						WHERE		LoopFinished IS NULL
				
						-- Remove any reverse pairs from this iteration 
						DELETE
						FROM		ReversePair
						FROM		#tblDEMOGRAPHICS_Match_EntityPairs_All ReversePair
						INNER JOIN	#tblDEMOGRAPHICS_Match_EntityPairs_All ForWardPair
																				ON	ReversePair.SrcSys_A = ForWardPair.SrcSys_B
																				AND	ReversePair.Src_UID_A = ForWardPair.Src_UID_B
																				AND	ReversePair.SrcSys_B = ForWardPair.SrcSys_A
																				AND	ReversePair.Src_UID_B = ForWardPair.Src_UID_A
						WHERE		CONCAT(CAST(1 - ReversePair.IsSCR_A AS VARCHAR(255)), '|', CAST(ReversePair.SrcSys_A AS VARCHAR(255)), '|', ReversePair.Src_UID_A) > CONCAT(CAST(1 - ReversePair.IsSCR_B AS VARCHAR(255)), '|', CAST(ReversePair.SrcSys_B AS VARCHAR(255)), '|', ReversePair.Src_UID_B)
				
						-- Remove any match pairs from this iteration that already existed in previous iterations
						DELETE
						FROM		ThisLoop
						FROM		#tblDEMOGRAPHICS_Match_EntityPairs_All ThisLoop
						INNER JOIN	#tblDEMOGRAPHICS_Match_EntityPairs_All PreviousLoops
																				ON	ThisLoop.SrcSys_A = PreviousLoops.SrcSys_A
																				AND	ThisLoop.Src_UID_A = PreviousLoops.Src_UID_A
																				AND	ThisLoop.SrcSys_B = PreviousLoops.SrcSys_B
																				AND	ThisLoop.Src_UID_B = PreviousLoops.Src_UID_B
																				AND	PreviousLoops.LoopFinished = 1
						WHERE		ThisLoop.LoopFinished = 0

						-- Check to see if there are any further child entities that can be searched for a further match
						IF (SELECT COUNT(*) FROM #tblDEMOGRAPHICS_Match_EntityPairs_All WHERE LoopFinished = 0) > 0 
						BEGIN
								-- Populate #Incremental table with any child entities that can be searched for a further match
								INSERT INTO #Incremental
											(IsSCR
											,SrcSys
											,Src_UID)
								SELECT		IsSCR_B
											,SrcSys_B
											,Src_UID_B
								FROM		#tblDEMOGRAPHICS_Match_EntityPairs_All
								WHERE		LoopFinished = 0
								GROUP BY	IsSCR_B
											,SrcSys_B
											,Src_UID_B
								EXCEPT		-- Don't add entities to #Incremental that are already there
								SELECT		IsSCR
											,SrcSys
											,Src_UID
								FROM		#Incremental
				
						END
						ELSE
						BEGIN
								-- Set the loop to exit
								SET @NoFurtherMatchesFound = 1
						END

						-- Mark the matches from this loop as being complete
						UPDATE		#tblDEMOGRAPHICS_Match_EntityPairs_All
						SET			LoopFinished = 1
						WHERE		LoopFinished = 0

						-- Increment the loop
						SET @LoopCounter += 1

				-- Exit / restart the loop
				END

		-- End the update of the matches data (will end up in Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_All)
		END

		-- Create indexes on #tblDEMOGRAPHICS_Match_EntityPairs_All to improve performance	--		DECLARE	@SQL VARCHAR(MAX) ,@Guid VARCHAR(255), @CurrentUser VARCHAR(255), @ProcIdName VARCHAR(255), @CurrentSection VARCHAR(255), @CurrentDttm DATETIME2, @LoopCounter SMALLINT = 1 SELECT @Guid = CAST(NEWID() AS VARCHAR(255)), @CurrentUser = CURRENT_USER, @ProcIdName = ISNULL(OBJECT_NAME(@@PROCID), 'ad hoc')
		SET @SQL =	'CREATE UNIQUE CLUSTERED INDEX [PK_tblDEMOGRAPHICS_Match_EntityPairs_All_' + @Guid + '] ON #tblDEMOGRAPHICS_Match_EntityPairs_All (SrcSys_A ASC, Src_UID_A ASC, SrcSys_B ASC, Src_UID_B ASC, MatchType ASC, Iteration ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_tblDEMOGRAPHICS_Match_EntityPairs_All_Src_UID_A_' + @Guid + '] ON #tblDEMOGRAPHICS_Match_EntityPairs_All (SrcSys_A ASC, Src_UID_A ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_tblDEMOGRAPHICS_Match_EntityPairs_All_Src_UID_B_' + @Guid + '] ON #tblDEMOGRAPHICS_Match_EntityPairs_All (SrcSys_B ASC, Src_UID_B ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_tblDEMOGRAPHICS_Match_EntityPairs_All_MatchType_' + @Guid + '] ON #tblDEMOGRAPHICS_Match_EntityPairs_All (MatchType ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_tblDEMOGRAPHICS_Match_EntityPairs_All_Iteration_' + @Guid + '] ON #tblDEMOGRAPHICS_Match_EntityPairs_All (Iteration ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_tblDEMOGRAPHICS_Match_EntityPairs_All_IsSCR_A_' + @Guid + '] ON #tblDEMOGRAPHICS_Match_EntityPairs_All (IsSCR_A ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_tblDEMOGRAPHICS_Match_EntityPairs_All_IsSCR_B_' + @Guid + '] ON #tblDEMOGRAPHICS_Match_EntityPairs_All (IsSCR_B ASC) '
		EXEC (@SQL)
		
		/*****************************************************************************************************************************************************************************************************************************************************************************************/
		-- Prepare data for finding the major entity
		/*****************************************************************************************************************************************************************************************************************************************************************************************/

		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Prepare for find major'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

		-- Create the #FindMajor_Match_Control table to replace in the persistent tables
		IF OBJECT_ID('tempdb..#FindMajor_Match_Control') IS NOT NULL DROP TABLE #FindMajor_Match_Control
		SELECT		mc.SrcSys_Major AS SrcSys_Major_Pre
					,mc.Src_UID_Major AS Src_UID_Major_Pre
					,CAST(NULL AS TINYINT) AS SrcSys_Major_Post
					,CAST(NULL AS VARCHAR(255)) AS Src_UID_Major_Post
					,mc.IsSCR
					,mc.SrcSys
					,mc.Src_UID
					,mc.HashBytesValue
					,mc.ChangeLastDetected
					,mc.LastProcessed AS LastProcessed_Pre
					,CAST(NULL AS DATETIME2) AS LastProcessed_Post
					,mmv.LastValidatedDttm
					,mc.DeletedDttm
					,CAST(NULL AS VARCHAR(255)) AS BestIntention
					,inc.MoveMajorValidation
		INTO		#FindMajor_Match_Control
		FROM		#Incremental inc
		INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
													ON	inc.SrcSys = mc.SrcSys
													AND	inc.Src_UID = mc.Src_UID
		LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv
														ON	mc.SrcSys_Major = mmv.SrcSys_Major
														AND	mc.Src_UID_Major = mmv.Src_UID_Major

		-- Add the records into #FindMajor_Match_Control table that aren't yet in Merge_DM_Match.tblDEMOGRAPHICS_Match_Control (i.e. external records not yet persisted)
		INSERT INTO	#FindMajor_Match_Control
					(SrcSys_Major_Pre
					,Src_UID_Major_Pre
					,SrcSys_Major_Post
					,Src_UID_Major_Post
					,IsSCR
					,SrcSys
					,Src_UID
					,HashBytesValue
					,ChangeLastDetected
					,LastProcessed_Pre
					,LastProcessed_Post
					,mmv.LastValidatedDttm
					,DeletedDttm
					)
		SELECT		CAST(NULL AS TINYINT) AS SrcSys_Major_Pre
					,CAST(NULL AS VARCHAR(255)) AS Src_UID_Major_Pre
					,CAST(NULL AS TINYINT) AS SrcSys_Major_Post
					,CAST(NULL AS VARCHAR(255)) AS Src_UID_Major_Post
					,H_SCR.IsSCR
					,H_SCR.SrcSys
					,H_SCR.Src_UID
					,H_SCR.HashBytesValue
					,GETDATE() AS ChangeLastDetected
					,CAST(NULL AS DATETIME2) AS LastProcessed_Pre
					,CAST(NULL AS DATETIME2) AS LastProcessed_Post
					,mmv.LastValidatedDttm
					,CAST(NULL AS DATETIME2) AS DeletedDttm
		FROM		#Incremental inc
		INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH H_SCR
												ON	inc.SrcSys = H_SCR.SrcSys
												AND	inc.Src_UID = H_SCR.Src_UID
												AND	H_SCR.SrcSys IN (1,2)
		LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv
														ON	H_SCR.SrcSys = mmv.SrcSys_Major
														AND	H_SCR.Src_UID = mmv.Src_UID_Major
		LEFT JOIN	#FindMajor_Match_Control mc
												ON	inc.SrcSys = mc.SrcSys
												AND	inc.Src_UID = mc.Src_UID
		WHERE		inc.IsSCR = 0
		AND			mc.SrcSys IS NULL

		-- Add the records into #FindMajor_Match_Control table that aren't yet in Merge_DM_Match.tblDEMOGRAPHICS_Match_Control (i.e. external records not yet persisted)
		INSERT INTO	#FindMajor_Match_Control
					(SrcSys_Major_Pre
					,Src_UID_Major_Pre
					,SrcSys_Major_Post
					,Src_UID_Major_Post
					,IsSCR
					,SrcSys
					,Src_UID
					,HashBytesValue
					,ChangeLastDetected
					,LastProcessed_Pre
					,LastProcessed_Post
					,mmv.LastValidatedDttm
					,DeletedDttm
					)
		SELECT		CAST(NULL AS TINYINT) AS SrcSys_Major_Pre
					,CAST(NULL AS VARCHAR(255)) AS Src_UID_Major_Pre
					,CAST(NULL AS TINYINT) AS SrcSys_Major_Post
					,CAST(NULL AS VARCHAR(255)) AS Src_UID_Major_Post
					,H_CF.IsSCR
					,H_CF.SrcSys
					,H_CF.Src_UID
					,H_CF.HashBytesValue
					,GETDATE() AS ChangeLastDetected
					,CAST(NULL AS DATETIME2) AS LastProcessed_Pre
					,CAST(NULL AS DATETIME2) AS LastProcessed_Post
					,mmv.LastValidatedDttm
					,CAST(NULL AS DATETIME2) AS DeletedDttm
		FROM		#Incremental inc
		INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH H_CF
												ON	inc.SrcSys = H_CF.SrcSys
												AND	inc.Src_UID = H_CF.Src_UID
												AND	H_CF.SrcSys = 3
		LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv
														ON	H_CF.SrcSys = mmv.SrcSys_Major
														AND	H_CF.Src_UID = mmv.Src_UID_Major
		LEFT JOIN	#FindMajor_Match_Control mc
												ON	inc.SrcSys = mc.SrcSys
												AND	inc.Src_UID = mc.Src_UID
		WHERE		inc.IsSCR = 0
		AND			mc.SrcSys IS NULL

		-- Create indexes on #FindMajor_Match_EntityPairs_Unique to improve performance	--		DECLARE	@SQL VARCHAR(MAX) ,@Guid VARCHAR(255), @CurrentUser VARCHAR(255), @ProcIdName VARCHAR(255), @CurrentSection VARCHAR(255), @CurrentDttm DATETIME2, @LoopCounter SMALLINT = 1 SELECT @Guid = CAST(NEWID() AS VARCHAR(255)), @CurrentUser = CURRENT_USER, @ProcIdName = ISNULL(OBJECT_NAME(@@PROCID), 'ad hoc')
		SET @SQL =	'CREATE UNIQUE CLUSTERED INDEX [PK_FindMajor_Match_Control_' + @Guid + '] ON #FindMajor_Match_Control (SrcSys ASC, Src_UID ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_FindMajor_Match_Control_' + @Guid + '] ON #FindMajor_Match_Control (SrcSys ASC, Src_UID ASC) INCLUDE (IsSCR, ChangeLastDetected) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_FindMajor_Match_Control_Src_UID_Major_Pre_' + @Guid + '] ON #FindMajor_Match_Control (SrcSys_Major_Pre ASC, Src_UID_Major_Pre ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_FindMajor_Match_Control_Src_ChangeLastDetected_' + @Guid + '] ON #FindMajor_Match_Control (ChangeLastDetected ASC) '

		EXEC (@SQL)

		-- Create the #FindMajor_Match_EntityPairs_Unique table to replace in the persistent tables (from #FindMajor_Match_EntityPairs_All)
		IF OBJECT_ID('tempdb..#FindMajor_Match_EntityPairs_Unique') IS NOT NULL DROP TABLE #FindMajor_Match_EntityPairs_Unique
		SELECT		ep_all_temp.IsScr_A
					,ep_all_temp.SrcSys_A
					,ep_all_temp.Src_UID_A
					,ep_all_temp.IsScr_B
					,ep_all_temp.SrcSys_B
					,ep_all_temp.Src_UID_B
					,ep_u.BestIntention AS BestIntention_Pre
					,ep_all_temp.BestIntention AS BestIntention_Post
					,ep_u.UnlinkDttm AS UnlinkDttm_Pre
					,ep_u.UnlinkDttm AS UnlinkDttm_Post
					,ep_u.LastUnlinkedBy
					,ep_u.UnlinkProcessed AS UnlinkProcessed_Pre
					,CASE WHEN ep_u.UnlinkDttm IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(NULL AS BIT) END AS UnlinkProcessed_Post
					,mc_a.ChangeLastDetected AS ChangeLastDetected_A
					,mc_a.LastProcessed AS LastProcessed_A
					,mmv_a.LastValidatedDttm AS LastValidatedDttm_A
					,mc_b.ChangeLastDetected AS ChangeLastDetected_B
					,mc_b.LastProcessed AS LastProcessed_B
					,mmv_b.LastValidatedDttm AS LastValidatedDttm_B
		INTO		#FindMajor_Match_EntityPairs_Unique
		FROM		(SELECT		ep_all_inner.IsScr_A
								,ep_all_inner.SrcSys_A
								,ep_all_inner.Src_UID_A
								,ep_all_inner.IsScr_B
								,ep_all_inner.SrcSys_B
								,ep_all_inner.Src_UID_B
								,CASE WHEN SUM(CASE WHEN ep_all_inner.MatchIntention IN ('Algorithmic') THEN 1 ELSE 0 END) > 0 THEN 'Scripted' ELSE 'Manual' END AS BestIntention
					FROM		#tblDEMOGRAPHICS_Match_EntityPairs_All ep_all_inner
					GROUP BY	ep_all_inner.IsScr_A
								,ep_all_inner.SrcSys_A
								,ep_all_inner.Src_UID_A
								,ep_all_inner.IsScr_B
								,ep_all_inner.SrcSys_B
								,ep_all_inner.Src_UID_B
								) ep_all_temp
		LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_Unique ep_u -- retrieve existing best intentions and unlink data captured through validation
																ON	ep_all_temp.SrcSys_A = ep_u.SrcSys_A
																AND	ep_all_temp.Src_UID_A = ep_u.Src_UID_A
																AND	ep_all_temp.SrcSys_B = ep_u.SrcSys_B
																AND	ep_all_temp.Src_UID_B = ep_u.Src_UID_B
		LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc_a
													ON	ep_all_temp.SrcSys_A = mc_a.SrcSys
													AND	ep_all_temp.Src_UID_A = mc_a.Src_UID
		LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv_a
														ON	mc_a.SrcSys = mmv_a.SrcSys_Major
														AND	mc_a.Src_UID = mmv_a.Src_UID_Major
		LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc_b
													ON	ep_all_temp.SrcSys_B = mc_b.SrcSys
													AND	ep_all_temp.Src_UID_B = mc_b.Src_UID
		LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv_b
														ON	mc_b.SrcSys = mmv_b.SrcSys_Major
														AND	mc_b.Src_UID = mmv_b.Src_UID_Major

		-- Wipe the UnlinkDttm when there has been a change either of the entities in a pair and the BestIntention has changed from manual to scripted
		UPDATE		ep_u
		SET			ep_u.UnlinkDttm_Post = NULL
		FROM		#FindMajor_Match_EntityPairs_Unique ep_u
		WHERE		ep_u.BestIntention_Post = 'Scripted'
		AND			ISNULL(ep_u.BestIntention_Pre, '') != 'Scripted'
		AND			((ep_u.ChangeLastDetected_A > ep_u.LastProcessed_A)
		OR			(ep_u.ChangeLastDetected_B > ep_u.LastProcessed_B))
		
		-- Create indexes on #FindMajor_Match_EntityPairs_Unique to improve performance	--		DECLARE	@SQL VARCHAR(MAX) ,@Guid VARCHAR(255), @CurrentUser VARCHAR(255), @ProcIdName VARCHAR(255), @CurrentSection VARCHAR(255), @CurrentDttm DATETIME2, @LoopCounter SMALLINT = 1 SELECT @Guid = CAST(NEWID() AS VARCHAR(255)), @CurrentUser = CURRENT_USER, @ProcIdName = ISNULL(OBJECT_NAME(@@PROCID), 'ad hoc')
		SET @SQL =	'CREATE UNIQUE CLUSTERED INDEX [PK_FindMajor_Match_EntityPairs_Unique_' + @Guid + '] ON #FindMajor_Match_EntityPairs_Unique (SrcSys_A ASC, Src_UID_A ASC, SrcSys_B ASC, Src_UID_B ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_FindMajor_Match_EntityPairs_Unique_Src_UID_A_' + @Guid + '] ON #FindMajor_Match_EntityPairs_Unique (SrcSys_A ASC, Src_UID_A ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_FindMajor_Match_EntityPairs_Unique_Src_UID_B_' + @Guid + '] ON #FindMajor_Match_EntityPairs_Unique (SrcSys_B ASC, Src_UID_B ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_FindMajor_Match_EntityPairs_Unique_UnlinkDttm_Post_' + @Guid + '] ON #FindMajor_Match_EntityPairs_Unique (UnlinkDttm_Post ASC) '
		EXEC (@SQL)

		-- Create the temporary table to hold all related entity pairs
		IF OBJECT_ID('tempdb..#RelatedPairs') IS NOT NULL DROP TABLE #RelatedPairs
		CREATE TABLE	#RelatedPairs
						(RelatedPairsIx INT IDENTITY(1,1)
						,SrcSys TINYINT NOT NULL
						,Src_UID VARCHAR(255) NOT NULL
						,PotentialMajorIx INT
						,IsSCR_PotentialMajor BIT NOT NULL
						,SrcSys_PotentialMajor TINYINT NOT NULL
						,Src_UID_PotentialMajor VARCHAR(255) NOT NULL
						,ChangeLastDetected_PotentialMajor DATETIME2
						,LastValidatedDttm_PotentialMajor DATETIME2
						,BestIntention VARCHAR(255)
						,RelationsSearched BIT
						,Iteration SMALLINT
						)

		/************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
		-- Find the Major entity (@tableName VARCHAR(255), @MajorID_SrcSys TINYINT = NULL, @MajorID_Src_UID VARCHAR(255) = NULL)
		/************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/

		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Find major'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

		/*#########################################################################################################################################################################################################################*/
		-- Find all Nth nearest neighbours (match of a match... ...of a match x n...), ensuring we consider all permutations of each UID pair matches we have found (i.e. A = major and B = major)
		/*#########################################################################################################################################################################################################################*/
		
		-- Initialise the table of all related entity pairs with self-pairs
		INSERT INTO	#RelatedPairs
					(SrcSys
					,Src_UID
					,IsSCR_PotentialMajor
					,SrcSys_PotentialMajor
					,Src_UID_PotentialMajor
					,ChangeLastDetected_PotentialMajor
					,LastValidatedDttm_PotentialMajor
					,BestIntention
					,Iteration
					)
		SELECT		SrcSys								= SrcSys
					,Src_UID							= Src_UID
					,IsSCR_PotentialMajor				= IsSCR
					,SrcSys_PotentialMajor				= SrcSys
					,Src_UID_PotentialMajor				= Src_UID
					,ChangeLastDetected_PotentialMajor	= ChangeLastDetected
					,LastValidatedDttm_PotentialMajor	= LastValidatedDttm
					,BestIntention						= CAST('Scripted' AS VARCHAR(255)) -- self-pairs are a 100% certain match
					,Iteration							= 1
		FROM		#FindMajor_Match_Control
		WHERE		DeletedDttm IS NULL

		-- Add all UID pair matches from entity pairs unique table (with A as the potential major)
		INSERT INTO	#RelatedPairs
					(SrcSys
					,Src_UID
					,IsSCR_PotentialMajor
					,SrcSys_PotentialMajor
					,Src_UID_PotentialMajor
					,ChangeLastDetected_PotentialMajor
					,LastValidatedDttm_PotentialMajor
					,BestIntention
					)
		SELECT		SrcSys								= ep_u.SrcSys_B
					,Src_UID							= ep_u.Src_UID_B
					,IsSCR_PotentialMajor				= ep_u.IsSCR_A
					,SrcSys_PotentialMajor				= ep_u.SrcSys_A
					,Src_UID_PotentialMajor				= ep_u.Src_UID_A
					,ChangeLastDetected_PotentialMajor	= ep_u.ChangeLastDetected_A
					,LastValidatedDttm_PotentialMajor	= ep_u.LastValidatedDttm_A
					,BestIntention						= ep_u.BestIntention_Post
		FROM		#FindMajor_Match_EntityPairs_Unique ep_u
		WHERE		ep_u.UnlinkDttm_Pre IS NULL					-- Exclude entity pairs with an UnlinkDttm from the process
		EXCEPT		-- Don't add matches that we already have
		SELECT		SrcSys
					,Src_UID
					,IsSCR_PotentialMajor
					,SrcSys_PotentialMajor
					,Src_UID_PotentialMajor
					,ChangeLastDetected_PotentialMajor
					,LastValidatedDttm_PotentialMajor
					,BestIntention
		FROM		#RelatedPairs

		-- Add all UID pair matches from entity pairs unique table (with B as the potential major)
		INSERT INTO	#RelatedPairs
					(SrcSys
					,Src_UID
					,IsSCR_PotentialMajor
					,SrcSys_PotentialMajor
					,Src_UID_PotentialMajor
					,ChangeLastDetected_PotentialMajor
					,LastValidatedDttm_PotentialMajor
					,BestIntention
					)
		SELECT		SrcSys								= ep_u.SrcSys_A
					,Src_UID							= ep_u.Src_UID_A
					,IsSCR_PotentialMajor				= ep_u.IsSCR_B
					,SrcSys_PotentialMajor				= ep_u.SrcSys_B
					,Src_UID_PotentialMajor				= ep_u.Src_UID_B
					,ChangeLastDetected_PotentialMajor	= ep_u.ChangeLastDetected_B
					,LastValidatedDttm_PotentialMajor	= ep_u.LastValidatedDttm_B
					,BestIntention						= ep_u.BestIntention_Post
		FROM		#FindMajor_Match_EntityPairs_Unique ep_u
		WHERE		ep_u.UnlinkDttm_Pre IS NULL					-- Exclude entity pairs with an UnlinkDttm from the process
		EXCEPT		-- Don't add matches that we already have
		SELECT		SrcSys
					,Src_UID
					,IsSCR_PotentialMajor
					,SrcSys_PotentialMajor
					,Src_UID_PotentialMajor
					,ChangeLastDetected_PotentialMajor
					,LastValidatedDttm_PotentialMajor
					,BestIntention
		FROM		#RelatedPairs

		-- Mark relations searched on this iteration
		UPDATE #RelatedPairs SET RelationsSearched = 1 WHERE RelationsSearched = 0

		-- Mark pending relations to be searched on the next iteration (to differentiate from new relations found on the next iteration)
		UPDATE #RelatedPairs SET RelationsSearched = 0 WHERE RelationsSearched IS NULL

		-- Update the iteration number
		UPDATE #RelatedPairs SET Iteration = (SELECT ISNULL(MAX(Iteration), 0) + 1 FROM #RelatedPairs) WHERE Iteration IS NULL
		
		-- Loop through the nth nearest neighbour permutations until none more are found
		DECLARE @ConnectionsFound INT

		WHILE ISNULL(@ConnectionsFound, 1) > 0
		BEGIN

				-- Reset the connections found counter
				SET @ConnectionsFound = 0
				
				-- Find the next nth nearest neighbour permutations (with RP UID as major and A as the minor)
				INSERT INTO	#RelatedPairs
							(SrcSys
							,Src_UID
							,IsSCR_PotentialMajor
							,SrcSys_PotentialMajor
							,Src_UID_PotentialMajor
							,ChangeLastDetected_PotentialMajor
							,LastValidatedDttm_PotentialMajor
							,BestIntention
							)
				SELECT		SrcSys								= rp.SrcSys
							,Src_UID							= rp.Src_UID
							,IsSCR_PotentialMajor				= ep_u.IsSCR_A
							,SrcSys_PotentialMajor				= ep_u.SrcSys_A
							,Src_UID_PotentialMajor				= ep_u.Src_UID_A
							,ChangeLastDetected_PotentialMajor	= ep_u.ChangeLastDetected_A
							,LastValidatedDttm_PotentialMajor	= ep_u.LastValidatedDttm_A
							,BestIntention						= CASE WHEN rp.BestIntention = 'Scripted' AND ep_u.BestIntention_Post = 'Scripted' THEN 'Scripted' ELSE 'Manual' END
				FROM		#RelatedPairs rp
				INNER JOIN	#FindMajor_Match_EntityPairs_Unique ep_u
																	ON	rp.SrcSys_PotentialMajor = ep_u.SrcSys_B
																	AND	rp.Src_UID_PotentialMajor = ep_u.Src_UID_B
																	AND	ep_u.UnlinkDttm_Pre IS NULL				-- Exclude entity pairs with an UnlinkDttm from the process
				WHERE		rp.RelationsSearched = 0	-- relations that were found on the previous iteration
				EXCEPT		-- Don't add matches that we already have
				SELECT		SrcSys
							,Src_UID
							,IsSCR_PotentialMajor
							,SrcSys_PotentialMajor
							,Src_UID_PotentialMajor
							,ChangeLastDetected_PotentialMajor
							,LastValidatedDttm_PotentialMajor
							,BestIntention
				FROM		#RelatedPairs

				-- Continue for another loop if there are more permutations found
				IF @@ROWCOUNT > 0
				SET @ConnectionsFound = ISNULL(@ConnectionsFound, 0) + 1
				
				-- Find the next nth nearest neighbour permutations (with RP UID as major and B as the minor)
				INSERT INTO	#RelatedPairs
							(SrcSys
							,Src_UID
							,IsSCR_PotentialMajor
							,SrcSys_PotentialMajor
							,Src_UID_PotentialMajor
							,ChangeLastDetected_PotentialMajor
							,LastValidatedDttm_PotentialMajor
							,BestIntention
							)
				SELECT		SrcSys								= rp.SrcSys
							,Src_UID							= rp.Src_UID
							,IsSCR_PotentialMajor				= ep_u.IsSCR_B
							,SrcSys_PotentialMajor				= ep_u.SrcSys_B
							,Src_UID_PotentialMajor				= ep_u.Src_UID_B
							,ChangeLastDetected_PotentialMajor	= ep_u.ChangeLastDetected_B
							,LastValidatedDttm_PotentialMajor	= ep_u.LastValidatedDttm_B
							,BestIntention						= CASE WHEN rp.BestIntention = 'Scripted' AND ep_u.BestIntention_Post = 'Scripted' THEN 'Scripted' ELSE 'Manual' END
				FROM		#RelatedPairs rp
				INNER JOIN	#FindMajor_Match_EntityPairs_Unique ep_u
																	ON	rp.SrcSys_PotentialMajor = ep_u.SrcSys_A
																	AND	rp.Src_UID_PotentialMajor = ep_u.Src_UID_A
																	AND	ep_u.UnlinkDttm_Pre IS NULL				-- Exclude entity pairs with an UnlinkDttm from the process
				WHERE		rp.RelationsSearched = 0	-- relations that were found on the previous iteration
				EXCEPT		-- Don't add matches that we already have
				SELECT		SrcSys
							,Src_UID
							,IsSCR_PotentialMajor
							,SrcSys_PotentialMajor
							,Src_UID_PotentialMajor
							,ChangeLastDetected_PotentialMajor
							,LastValidatedDttm_PotentialMajor
							,BestIntention
				FROM		#RelatedPairs

				-- Continue for another loop if there are more permutations found
				IF @@ROWCOUNT > 0
				SET @ConnectionsFound = ISNULL(@ConnectionsFound, 0) + 1
				
				-- Find the next nth nearest neighbour permutations (with RP UID potential major as major and A as the minor)
				INSERT INTO	#RelatedPairs
							(SrcSys
							,Src_UID
							,IsSCR_PotentialMajor
							,SrcSys_PotentialMajor
							,Src_UID_PotentialMajor
							,ChangeLastDetected_PotentialMajor
							,LastValidatedDttm_PotentialMajor
							,BestIntention
							)
				SELECT		SrcSys								= rp.SrcSys_PotentialMajor
							,Src_UID							= rp.Src_UID_PotentialMajor
							,IsSCR_PotentialMajor				= ep_u.IsSCR_A
							,SrcSys_PotentialMajor				= ep_u.SrcSys_A
							,Src_UID_PotentialMajor				= ep_u.Src_UID_A
							,ChangeLastDetected_PotentialMajor	= ep_u.ChangeLastDetected_A
							,LastValidatedDttm_PotentialMajor	= ep_u.LastValidatedDttm_A
							,BestIntention						= CASE WHEN rp.BestIntention = 'Scripted' AND ep_u.BestIntention_Post = 'Scripted' THEN 'Scripted' ELSE 'Manual' END
				FROM		#RelatedPairs rp
				INNER JOIN	#FindMajor_Match_EntityPairs_Unique ep_u
																	ON	rp.SrcSys = ep_u.SrcSys_B
																	AND	rp.Src_UID = ep_u.Src_UID_B
																	AND	ep_u.UnlinkDttm_Pre IS NULL				-- Exclude entity pairs with an UnlinkDttm from the process
				WHERE		rp.RelationsSearched = 0	-- relations that were found on the previous iteration
				EXCEPT		-- Don't add matches that we already have
				SELECT		SrcSys
							,Src_UID
							,IsSCR_PotentialMajor
							,SrcSys_PotentialMajor
							,Src_UID_PotentialMajor
							,ChangeLastDetected_PotentialMajor
							,LastValidatedDttm_PotentialMajor
							,BestIntention
				FROM		#RelatedPairs

				-- Continue for another loop if there are more permutations found
				IF @@ROWCOUNT > 0
				SET @ConnectionsFound = ISNULL(@ConnectionsFound, 0) + 1
				
				-- Find the next nth nearest neighbour permutations (with RP UID potential major as major and B as the minor)
				INSERT INTO	#RelatedPairs
							(SrcSys
							,Src_UID
							,IsSCR_PotentialMajor
							,SrcSys_PotentialMajor
							,Src_UID_PotentialMajor
							,ChangeLastDetected_PotentialMajor
							,LastValidatedDttm_PotentialMajor
							,BestIntention
							)
				SELECT		SrcSys								= rp.SrcSys_PotentialMajor
							,Src_UID							= rp.Src_UID_PotentialMajor
							,IsSCR_PotentialMajor				= ep_u.IsSCR_B
							,SrcSys_PotentialMajor				= ep_u.SrcSys_B
							,Src_UID_PotentialMajor				= ep_u.Src_UID_B
							,ChangeLastDetected_PotentialMajor	= ep_u.ChangeLastDetected_B
							,LastValidatedDttm_PotentialMajor	= ep_u.LastValidatedDttm_B
							,BestIntention						= CASE WHEN rp.BestIntention = 'Scripted' AND ep_u.BestIntention_Post = 'Scripted' THEN 'Scripted' ELSE 'Manual' END
				FROM		#RelatedPairs rp
				INNER JOIN	#FindMajor_Match_EntityPairs_Unique ep_u
																	ON	rp.SrcSys = ep_u.SrcSys_A
																	AND	rp.Src_UID = ep_u.Src_UID_A
																	AND	ep_u.UnlinkDttm_Pre IS NULL				-- Exclude entity pairs with an UnlinkDttm from the process
				WHERE		rp.RelationsSearched = 0	-- relations that were found on the previous iteration
				EXCEPT		-- Don't add matches that we already have
				SELECT		SrcSys
							,Src_UID
							,IsSCR_PotentialMajor
							,SrcSys_PotentialMajor
							,Src_UID_PotentialMajor
							,ChangeLastDetected_PotentialMajor
							,LastValidatedDttm_PotentialMajor
							,BestIntention
				FROM		#RelatedPairs

				-- Continue for another loop if there are more permutations found
				IF @@ROWCOUNT > 0
				SET @ConnectionsFound = ISNULL(@ConnectionsFound, 0) + 1

				-- Mark relations searched on this iteration
				UPDATE #RelatedPairs SET RelationsSearched = 1 WHERE RelationsSearched = 0

				-- Mark pending relations to be searched on the next iteration (to differentiate from new relations found on the next iteration)
				UPDATE #RelatedPairs SET RelationsSearched = 0 WHERE RelationsSearched IS NULL

				-- Update the iteration number
				UPDATE #RelatedPairs SET Iteration = (SELECT ISNULL(MAX(Iteration), 0) + 1 FROM #RelatedPairs) WHERE Iteration IS NULL

		
		-- End loop through the nth nearest neighbour permutations
		END

		-- Create indexes on #RelatedPairs to improve performance	--		DECLARE	@SQL VARCHAR(MAX) ,@Guid VARCHAR(255), @CurrentUser VARCHAR(255), @ProcIdName VARCHAR(255), @CurrentSection VARCHAR(255), @CurrentDttm DATETIME2, @LoopCounter SMALLINT = 1 SELECT @Guid = CAST(NEWID() AS VARCHAR(255)), @CurrentUser = CURRENT_USER, @ProcIdName = ISNULL(OBJECT_NAME(@@PROCID), 'ad hoc')
		SET @SQL =	'CREATE UNIQUE CLUSTERED INDEX [PK_RelatedPairs_' + @Guid + '] ON #RelatedPairs (RelatedPairsIx ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_RelatedPairs_' + @Guid + '] ON #RelatedPairs (SrcSys ASC, Src_UID ASC, SrcSys_PotentialMajor ASC, Src_UID_PotentialMajor ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_RelatedPairs_Src_UID_PotentialMajor_' + @Guid + '] ON #RelatedPairs (SrcSys_PotentialMajor ASC, Src_UID_PotentialMajor ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_RelatedPairs_Src_UID_' + @Guid + '] ON #RelatedPairs (SrcSys ASC, Src_UID ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_RelatedPairs_ChangeLastDetected_PotentialMajor_' + @Guid + '] ON #RelatedPairs (ChangeLastDetected_PotentialMajor ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_RelatedPairs_LastValidatedDttm_PotentialMajor_' + @Guid + '] ON #RelatedPairs (LastValidatedDttm_PotentialMajor ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_RelatedPairs_BestIntention_' + @Guid + '] ON #RelatedPairs (BestIntention ASC) '
		
		EXEC (@SQL)

		/*#########################################################################################################################################################################################################################*/
		-- Prioritise the order of the potential major entities for each entity
		/*#########################################################################################################################################################################################################################*/
		

		-- Prioritise the order of the potential major entities for each entity
		-- Change the order by clause of this ROW_NUMBER function below if you want to change the way records are prioritised as the "major" record. The recommended approach would be to feed the data in to the query via the #FindMajor_Match_EntityPairs_Unique or #FindMajor_Match_Control tables
		UPDATE		rp
		SET			rp.PotentialMajorIx = PotentialMajorIx.PotentialMajorIx
		FROM		#RelatedPairs rp
		INNER JOIN	(SELECT		RelatedPairsIx
								,ROW_NUMBER() OVER	(PARTITION BY	rp.SrcSys --RelatedPairsIx 
																	,rp.Src_UID
													ORDER BY		rp.IsSCR_PotentialMajor DESC
																	,CASE WHEN mmv.SrcSys_Major IS NOT NULL THEN 1 ELSE 0 END DESC -- previously validated major comes first. Keep this otherwise uspMakeMajor won't stick
																	,rp.ChangeLastDetected_PotentialMajor
																	,rp.SrcSys_PotentialMajor
																	,rp.Src_UID_PotentialMajor
																	) AS PotentialMajorIx
					FROM		#RelatedPairs rp
					LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv
																						ON	rp.SrcSys_PotentialMajor = mmv.SrcSys_Major
																						AND	rp.Src_UID_PotentialMajor = mmv.Src_UID_Major
																						AND	mmv.LastValidatedDttm IS NOT NULL
								) PotentialMajorIx
														ON	rp.RelatedPairsIx = PotentialMajorIx.RelatedPairsIx


		/*#########################################################################################################################################################################################################################*/
		-- Write the major entity data back to match control
		/*#########################################################################################################################################################################################################################*/
		
		-- Write SrcSys_Major_Post and Src_UID_Major_Post back to #FindMajor_Match_Control
		UPDATE		mc
		SET			SrcSys_Major_Post = ISNULL(rp.SrcSys_PotentialMajor, mc.SrcSys)
					,Src_UID_Major_Post = ISNULL(rp.Src_UID_PotentialMajor, mc.Src_UID)
					,mc.LastProcessed_Post = GETDATE()
		FROM		#FindMajor_Match_Control mc
		LEFT JOIN	#RelatedPairs rp
											ON	mc.SrcSys = rp.SrcSys
											AND	mc.Src_UID = rp.Src_UID
											AND	rp.PotentialMajorIx = 1
		
		-- Write the best intention back to #FindMajor_Match_Control
		UPDATE		mc
		SET			mc.BestIntention = CASE WHEN BestIntention.SrcSys IS NOT NULL THEN 'Scripted' ELSE 'Manual' END
		FROM		#FindMajor_Match_Control mc
		LEFT JOIN	(SELECT		SrcSys
								,Src_UID
								,SrcSys_PotentialMajor
								,Src_UID_PotentialMajor
					FROM		#RelatedPairs rp
					GROUP BY	SrcSys
								,Src_UID
								,SrcSys_PotentialMajor
								,Src_UID_PotentialMajor
					HAVING		SUM(CASE WHEN BestIntention = 'Scripted' THEN 1 ELSE 0 END) > 0
								) BestIntention
												ON	mc.SrcSys = BestIntention.SrcSys
												AND	mc.Src_UID = BestIntention.Src_UID
												AND	mc.SrcSys_Major_Post = BestIntention.SrcSys_PotentialMajor
												AND	mc.Src_UID_Major_Post = BestIntention.Src_UID_PotentialMajor
		
		-- Delete any records in match control where none of the records in a major record are SCR records
		DELETE		mc
		FROM		#FindMajor_Match_Control mc
		INNER JOIN	(SELECT		SrcSys_Major_Post
								,Src_UID_Major_Post
					FROM		#FindMajor_Match_Control mc_major_inner
					GROUP BY	SrcSys_Major_Post
								,Src_UID_Major_Post
					HAVING		SUM(CAST(IsSCR AS INT)) = 0
								) mc_hasScr
											ON	mc.SrcSys_Major_Post = mc_hasScr.SrcSys_Major_Post
											AND	mc.Src_UID_Major_Post = mc_hasScr.Src_UID_Major_Post


		/************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
		-- Repopulate the MajorValidation table
		/************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/

		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Prepare mew match data'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

		-- Find the mappings between the pre & post Major UID's (so we can check whether prior validations still remain valid)
		IF OBJECT_ID('tempdb..#tblDEMOGRAPHICS_Match_Control_Major_PrePost') IS NOT NULL DROP TABLE #tblDEMOGRAPHICS_Match_Control_Major_PrePost
		SELECT		SrcSys_Major_Pre
					,Src_UID_Major_Pre
					,SrcSys_Major_Post
					,Src_UID_Major_Post
					,COUNT(*) AS EntityCount
					,SUM(CASE	WHEN	(ChangeLastDetected > LastProcessed_Pre 
								OR		LastProcessed_Pre IS NULL)
								THEN	1
								ELSE	0
								END) AS ChangeDetected
					,SUM(CASE	WHEN	(ChangeLastDetected > LastProcessed_Pre 
								OR		LastProcessed_Pre IS NULL)
								AND		SrcSys_Major_Pre = SrcSys
								AND		Src_UID_Major_Pre = Src_UID
								THEN	1
								ELSE	0
								END) AS MajorChangeDetected
					,SUM(CASE WHEN SrcSys = SrcSys_Major_Pre AND Src_UID = Src_UID_Major_Post THEN 1 ELSE 0 END) AS OldMajorStillWithinCohort
					,MAX(LastProcessed_Post) AS MaxLastProcessed_Post
		INTO		#tblDEMOGRAPHICS_Match_Control_Major_PrePost
		FROM		#FindMajor_Match_Control
		GROUP BY	SrcSys_Major_Pre
					,Src_UID_Major_Pre
					,SrcSys_Major_Post
					,Src_UID_Major_Post 
		
		-- Create the #tblDEMOGRAPHICS_Match_MajorValidation table to replace in the persistent tables 
		IF OBJECT_ID('tempdb..#tblDEMOGRAPHICS_Match_MajorValidation') IS NOT NULL DROP TABLE #tblDEMOGRAPHICS_Match_MajorValidation
		SELECT		mc_mpp.SrcSys_Major_Pre
					,mc_mpp.Src_UID_Major_Pre
					,mc_mpp.SrcSys_Major_Post
					,mc_mpp.Src_UID_Major_Post
					,mmv.LastValidatedDttm AS LastValidatedDttm_Pre
					,mmv.LastValidatedDttm AS LastValidatedDttm_Post
					,mmv.LastValidatedBy AS LastValidatedBy_Pre
					,mmv.LastValidatedBy AS LastValidatedBy_Post
					,mmv.ValidationStatus AS ValidationStatus_Pre
					,mmv.ValidationStatus AS ValidationStatus_Post
					,mmv.PATIENT_ID
					,mmv.N1_1_NHS_NUMBER
					,mmv.NHS_NUMBER_STATUS
					,mmv.L_RA3_RID
					,mmv.L_RA7_RID
					,mmv.L_RVJ01_RID
					,mmv.TEMP_ID
					,mmv.L_NSTS_STATUS
					,mmv.N1_2_HOSPITAL_NUMBER
					,mmv.L_TITLE
					,mmv.N1_5_SURNAME
					,mmv.N1_6_FORENAME
					,mmv.N1_7_ADDRESS_1
					,mmv.N1_7_ADDRESS_2
					,mmv.N1_7_ADDRESS_3
					,mmv.N1_7_ADDRESS_4
					,mmv.N1_7_ADDRESS_5
					,mmv.N1_8_POSTCODE
					,mmv.N1_9_SEX
					,mmv.N1_10_DATE_BIRTH
					,mmv.N1_11_GP_CODE
					,mmv.N1_12_GP_PRACTICE_CODE
					,mmv.N1_13_PCT
					,mmv.N1_14_SURNAME_BIRTH
					,mmv.N1_15_ETHNICITY
					,mmv.PAT_PREF_NAME
					,mmv.PAT_OCCUPATION
					,mmv.PAT_SOCIAL_CLASS
					,mmv.PAT_LIVES_ALONE
					,mmv.MARITAL_STATUS
					,mmv.PAT_PREF_LANGUAGE
					,mmv.PAT_PREF_CONTACT
					,mmv.L_DEATH_STATUS
					,mmv.N15_1_DATE_DEATH
					,mmv.N15_2_DEATH_LOCATION
					,mmv.N15_3_DEATH_CAUSE
					,mmv.N15_4_DEATH_CANCER
					,mmv.N15_5_DEATH_CODE_1
					,mmv.N15_6_DEATH_CODE_2
					,mmv.N15_7_DEATH_CODE_3
					,mmv.N15_8_DEATH_CODE_4
					,mmv.N15_9_DEATH_DISCREPANCY
					,mmv.N_CC4_TOWN
					,mmv.N_CC5_COUNTRY
					,mmv.N_CC6_M_SURNAME
					,mmv.N_CC7_M_CLASS
					,mmv.N_CC8_M_FORENAME
					,mmv.N_CC9_M_DOB
					,mmv.N_CC10_M_TOWN
					,mmv.N_CC11_M_COUNTRY
					,mmv.N_CC12_M_OCC
					,mmv.N_CC13_M_OCC_DIAG
					,mmv.N_CC6_F_SURNAME
					,mmv.N_CC7_F_CLASS
					,mmv.N_CC8_F_FORENAME
					,mmv.N_CC9_F_DOB
					,mmv.N_CC10_F_TOWN
					,mmv.N_CC11_F_COUNTRY
					,mmv.N_CC12_F_OCC
					,mmv.N_CC13_F_OCC_DIAG
					,mmv.N_CC14_MULTI_BIRTH
					,mmv.R_POST_MORTEM
					,mmv.R_DAY_PHONE
					,mmv.DAY_PHONE_EXT
					,mmv.R_EVE_PHONE
					,mmv.EVE_PHONE_EXT
					,mmv.R_DEATH_TREATMENT
					,mmv.R_PM_DETAILS
					,mmv.L_IATROGENIC_DEATH
					,mmv.L_INFECTION_DEATH
					,mmv.L_DEATH_COMMENTS
					,mmv.RELIGION
					,mmv.CONTACT_DETAILS
					,mmv.NOK_NAME
					,mmv.NOK_ADDRESS_1
					,mmv.NOK_ADDRESS_2
					,mmv.NOK_ADDRESS_3
					,mmv.NOK_ADDRESS_4
					,mmv.NOK_ADDRESS_5
					,mmv.NOK_POSTCODE
					,mmv.NOK_CONTACT
					,mmv.NOK_RELATIONSHIP
					,mmv.PAT_DEPENDANTS
					,mmv.CARER_NAME
					,mmv.CARER_ADDRESS_1
					,mmv.CARER_ADDRESS_2
					,mmv.CARER_ADDRESS_3
					,mmv.CARER_ADDRESS_4
					,mmv.CARER_ADDRESS_5
					,mmv.CARER_POSTCODE
					,mmv.CARER_CONTACT
					,mmv.CARER_RELATIONSHIP
					,mmv.CARER1_TYPE
					,mmv.CARER2_NAME
					,mmv.CARER2_ADDRESS_1
					,mmv.CARER2_ADDRESS_2
					,mmv.CARER2_ADDRESS_3
					,mmv.CARER2_ADDRESS_4
					,mmv.CARER2_ADDRESS_5
					,mmv.CARER2_POSTCODE
					,mmv.CARER2_CONTACT
					,mmv.CARER2_RELATIONSHIP
					,mmv.CARER2_TYPE
					,mmv.PT_AT_RISK
					,mmv.REASON_RISK
					,mmv.GESTATION
					,mmv.CAUSE_OF_DEATH_UROLOGY
					,mmv.AVOIDABLE_DEATH
					,mmv.AVOIDABLE_DETAILS
					,mmv.OTHER_DEATH_CAUSE_UROLOGY
					,mmv.ACTION_ID
					,mmv.STATED_GENDER_CODE
					,mmv.CAUSE_OF_DEATH_UROLOGY_FUP
					,mmv.DEATH_WITHIN_30_DAYS_OF_TREAT
					,mmv.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT
					,mmv.DEATH_CAUSE_LATER_DATE
					,mmv.RegisteredPractice
					,mmv.RegisteredGP
					,mmv.PersonSexualOrientation
		INTO		#tblDEMOGRAPHICS_Match_MajorValidation
		FROM		#tblDEMOGRAPHICS_Match_Control_Major_PrePost mc_mpp
		INNER JOIN	(SELECT		SrcSys_Major_Pre
								,Src_UID_Major_Pre
								,SUM(EntityCount) AS EntityCount
								,SUM(ChangeDetected) AS ChangeDetected
								,SUM(MajorChangeDetected) AS MajorChangeDetected
								,COUNT(*) AS SplitToGroupCount
					FROM		#tblDEMOGRAPHICS_Match_Control_Major_PrePost mc_mpp_inner
					GROUP BY	SrcSys_Major_Pre
								,Src_UID_Major_Pre
					--HAVING		COUNT(*) = 1 -- only bring across major validations where the previous validations have not been split
								) mc_pre
														ON	mc_mpp.SrcSys_Major_Pre = mc_pre.SrcSys_Major_Pre
														AND	mc_mpp.Src_UID_Major_Pre = mc_pre.Src_UID_Major_Pre
		INNER JOIN	(SELECT		SrcSys_Major_Post
								,Src_UID_Major_Post
								,SUM(EntityCount) AS EntityCount
								,SUM(ChangeDetected) AS ChangeDetected
								,SUM(MajorChangeDetected) AS MajorChangeDetected
								,COUNT(*) AS MergeFromGroupCount
					FROM		#tblDEMOGRAPHICS_Match_Control_Major_PrePost mc_major_prepost
					GROUP BY	SrcSys_Major_Post
								,Src_UID_Major_Post
					HAVING		COUNT(*) = 1 -- only bring across major validations where the previous validations have not been merged
								) mc_post
														ON	mc_mpp.SrcSys_Major_Post = mc_post.SrcSys_Major_Post
														AND	mc_mpp.Src_UID_Major_Post = mc_post.Src_UID_Major_Post
		INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv
																ON	mc_mpp.SrcSys_Major_Pre = mmv.SrcSys_Major
																AND	mc_mpp.Src_UID_Major_Pre = mmv.Src_UID_Major
		WHERE		mc_pre.EntityCount >= mc_post.EntityCount	-- there are no extra entities as a part of the major group
		AND			mc_post.MajorChangeDetected = 0				-- the record underneath the major validation hasn't changed since it was last processed 

		-- SELECT * FROM #tblDEMOGRAPHICS_Match_MajorValidation WHERE SrcSys_Major_Post IS NULL

		-- Bring along the Major_MatchValidationColumns records for major validation records that will persist
		IF OBJECT_ID('tempdb..#tblDEMOGRAPHICS_Match_MajorValidationColumns') IS NOT NULL DROP TABLE #tblDEMOGRAPHICS_Match_MajorValidationColumns
		SELECT		mmv.SrcSys_Major_Pre
					,mmv.Src_UID_Major_Pre
					,mmvc.FieldName
					,mmvc.SrcSys
					,mmvc.Src_UID
		INTO		#tblDEMOGRAPHICS_Match_MajorValidationColumns
		FROM		(SELECT		SrcSys_Major_Pre
								,Src_UID_Major_Pre
					FROM		#tblDEMOGRAPHICS_Match_MajorValidation
					GROUP BY	SrcSys_Major_Pre
								,Src_UID_Major_Pre
								) mmv
		INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidationColumns mmvc
																					ON	mmv.SrcSys_Major_Pre = mmvc.SrcSys_Major
																					AND	mmv.Src_UID_Major_Pre = mmvc.Src_UID_Major

		-- Insert any major validation records that didn't exist before (or didn't meet the match persistence criteria above)
		INSERT INTO	#tblDEMOGRAPHICS_Match_MajorValidation
					(SrcSys_Major_Post
					,Src_UID_Major_Post
					,LastValidatedDttm_Pre
					,LastValidatedDttm_Post
					,LastValidatedBy_Pre
					,LastValidatedBy_Post
					,ValidationStatus_Pre
					,ValidationStatus_Post
					,PATIENT_ID
					,N1_1_NHS_NUMBER
					,NHS_NUMBER_STATUS
					,L_RA3_RID
					,L_RA7_RID
					,L_RVJ01_RID
					,TEMP_ID
					,L_NSTS_STATUS
					,N1_2_HOSPITAL_NUMBER
					,L_TITLE
					,N1_5_SURNAME
					,N1_6_FORENAME
					,N1_7_ADDRESS_1
					,N1_7_ADDRESS_2
					,N1_7_ADDRESS_3
					,N1_7_ADDRESS_4
					,N1_7_ADDRESS_5
					,N1_8_POSTCODE
					,N1_9_SEX
					,N1_10_DATE_BIRTH
					,N1_11_GP_CODE
					,N1_12_GP_PRACTICE_CODE
					,N1_13_PCT
					,N1_14_SURNAME_BIRTH
					,N1_15_ETHNICITY
					,PAT_PREF_NAME
					,PAT_OCCUPATION
					,PAT_SOCIAL_CLASS
					,PAT_LIVES_ALONE
					,MARITAL_STATUS
					,PAT_PREF_LANGUAGE
					,PAT_PREF_CONTACT
					,L_DEATH_STATUS
					,N15_1_DATE_DEATH
					,N15_2_DEATH_LOCATION
					,N15_3_DEATH_CAUSE
					,N15_4_DEATH_CANCER
					,N15_5_DEATH_CODE_1
					,N15_6_DEATH_CODE_2
					,N15_7_DEATH_CODE_3
					,N15_8_DEATH_CODE_4
					,N15_9_DEATH_DISCREPANCY
					,N_CC4_TOWN
					,N_CC5_COUNTRY
					,N_CC6_M_SURNAME
					,N_CC7_M_CLASS
					,N_CC8_M_FORENAME
					,N_CC9_M_DOB
					,N_CC10_M_TOWN
					,N_CC11_M_COUNTRY
					,N_CC12_M_OCC
					,N_CC13_M_OCC_DIAG
					,N_CC6_F_SURNAME
					,N_CC7_F_CLASS
					,N_CC8_F_FORENAME
					,N_CC9_F_DOB
					,N_CC10_F_TOWN
					,N_CC11_F_COUNTRY
					,N_CC12_F_OCC
					,N_CC13_F_OCC_DIAG
					,N_CC14_MULTI_BIRTH
					,R_POST_MORTEM
					,R_DAY_PHONE
					,DAY_PHONE_EXT
					,R_EVE_PHONE
					,EVE_PHONE_EXT
					,R_DEATH_TREATMENT
					,R_PM_DETAILS
					,L_IATROGENIC_DEATH
					,L_INFECTION_DEATH
					,L_DEATH_COMMENTS
					,RELIGION
					,CONTACT_DETAILS
					,NOK_NAME
					,NOK_ADDRESS_1
					,NOK_ADDRESS_2
					,NOK_ADDRESS_3
					,NOK_ADDRESS_4
					,NOK_ADDRESS_5
					,NOK_POSTCODE
					,NOK_CONTACT
					,NOK_RELATIONSHIP
					,PAT_DEPENDANTS
					,CARER_NAME
					,CARER_ADDRESS_1
					,CARER_ADDRESS_2
					,CARER_ADDRESS_3
					,CARER_ADDRESS_4
					,CARER_ADDRESS_5
					,CARER_POSTCODE
					,CARER_CONTACT
					,CARER_RELATIONSHIP
					,CARER1_TYPE
					,CARER2_NAME
					,CARER2_ADDRESS_1
					,CARER2_ADDRESS_2
					,CARER2_ADDRESS_3
					,CARER2_ADDRESS_4
					,CARER2_ADDRESS_5
					,CARER2_POSTCODE
					,CARER2_CONTACT
					,CARER2_RELATIONSHIP
					,CARER2_TYPE
					,PT_AT_RISK
					,REASON_RISK
					,GESTATION
					,CAUSE_OF_DEATH_UROLOGY
					,AVOIDABLE_DEATH
					,AVOIDABLE_DETAILS
					,OTHER_DEATH_CAUSE_UROLOGY
					,ACTION_ID
					,STATED_GENDER_CODE
					,CAUSE_OF_DEATH_UROLOGY_FUP
					,DEATH_WITHIN_30_DAYS_OF_TREAT
					,DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT
					,DEATH_CAUSE_LATER_DATE
					,RegisteredPractice
					,RegisteredGP
					,PersonSexualOrientation
					)
		SELECT		mc_post.SrcSys_Major_Post
					,mc_post.Src_UID_Major_Post
					,mmv.LastValidatedDttm AS LastValidatedDttm_Pre
					,mmv.LastValidatedDttm AS LastValidatedDttm_Post
					,mmv.LastValidatedBy AS LastValidatedBy_Pre
					,mmv.LastValidatedBy AS LastValidatedBy_Post
					,mmv.ValidationStatus AS ValidationStatus_Pre
					,mmv.ValidationStatus AS ValidationStatus_Post
					,mmv.PATIENT_ID
					,mmv.N1_1_NHS_NUMBER
					,mmv.NHS_NUMBER_STATUS
					,mmv.L_RA3_RID
					,mmv.L_RA7_RID
					,mmv.L_RVJ01_RID
					,mmv.TEMP_ID
					,mmv.L_NSTS_STATUS
					,mmv.N1_2_HOSPITAL_NUMBER
					,mmv.L_TITLE
					,mmv.N1_5_SURNAME
					,mmv.N1_6_FORENAME
					,mmv.N1_7_ADDRESS_1
					,mmv.N1_7_ADDRESS_2
					,mmv.N1_7_ADDRESS_3
					,mmv.N1_7_ADDRESS_4
					,mmv.N1_7_ADDRESS_5
					,mmv.N1_8_POSTCODE
					,mmv.N1_9_SEX
					,mmv.N1_10_DATE_BIRTH
					,mmv.N1_11_GP_CODE
					,mmv.N1_12_GP_PRACTICE_CODE
					,mmv.N1_13_PCT
					,mmv.N1_14_SURNAME_BIRTH
					,mmv.N1_15_ETHNICITY
					,mmv.PAT_PREF_NAME
					,mmv.PAT_OCCUPATION
					,mmv.PAT_SOCIAL_CLASS
					,mmv.PAT_LIVES_ALONE
					,mmv.MARITAL_STATUS
					,mmv.PAT_PREF_LANGUAGE
					,mmv.PAT_PREF_CONTACT
					,mmv.L_DEATH_STATUS
					,mmv.N15_1_DATE_DEATH
					,mmv.N15_2_DEATH_LOCATION
					,mmv.N15_3_DEATH_CAUSE
					,mmv.N15_4_DEATH_CANCER
					,mmv.N15_5_DEATH_CODE_1
					,mmv.N15_6_DEATH_CODE_2
					,mmv.N15_7_DEATH_CODE_3
					,mmv.N15_8_DEATH_CODE_4
					,mmv.N15_9_DEATH_DISCREPANCY
					,mmv.N_CC4_TOWN
					,mmv.N_CC5_COUNTRY
					,mmv.N_CC6_M_SURNAME
					,mmv.N_CC7_M_CLASS
					,mmv.N_CC8_M_FORENAME
					,mmv.N_CC9_M_DOB
					,mmv.N_CC10_M_TOWN
					,mmv.N_CC11_M_COUNTRY
					,mmv.N_CC12_M_OCC
					,mmv.N_CC13_M_OCC_DIAG
					,mmv.N_CC6_F_SURNAME
					,mmv.N_CC7_F_CLASS
					,mmv.N_CC8_F_FORENAME
					,mmv.N_CC9_F_DOB
					,mmv.N_CC10_F_TOWN
					,mmv.N_CC11_F_COUNTRY
					,mmv.N_CC12_F_OCC
					,mmv.N_CC13_F_OCC_DIAG
					,mmv.N_CC14_MULTI_BIRTH
					,mmv.R_POST_MORTEM
					,mmv.R_DAY_PHONE
					,mmv.DAY_PHONE_EXT
					,mmv.R_EVE_PHONE
					,mmv.EVE_PHONE_EXT
					,mmv.R_DEATH_TREATMENT
					,mmv.R_PM_DETAILS
					,mmv.L_IATROGENIC_DEATH
					,mmv.L_INFECTION_DEATH
					,mmv.L_DEATH_COMMENTS
					,mmv.RELIGION
					,mmv.CONTACT_DETAILS
					,mmv.NOK_NAME
					,mmv.NOK_ADDRESS_1
					,mmv.NOK_ADDRESS_2
					,mmv.NOK_ADDRESS_3
					,mmv.NOK_ADDRESS_4
					,mmv.NOK_ADDRESS_5
					,mmv.NOK_POSTCODE
					,mmv.NOK_CONTACT
					,mmv.NOK_RELATIONSHIP
					,mmv.PAT_DEPENDANTS
					,mmv.CARER_NAME
					,mmv.CARER_ADDRESS_1
					,mmv.CARER_ADDRESS_2
					,mmv.CARER_ADDRESS_3
					,mmv.CARER_ADDRESS_4
					,mmv.CARER_ADDRESS_5
					,mmv.CARER_POSTCODE
					,mmv.CARER_CONTACT
					,mmv.CARER_RELATIONSHIP
					,mmv.CARER1_TYPE
					,mmv.CARER2_NAME
					,mmv.CARER2_ADDRESS_1
					,mmv.CARER2_ADDRESS_2
					,mmv.CARER2_ADDRESS_3
					,mmv.CARER2_ADDRESS_4
					,mmv.CARER2_ADDRESS_5
					,mmv.CARER2_POSTCODE
					,mmv.CARER2_CONTACT
					,mmv.CARER2_RELATIONSHIP
					,mmv.CARER2_TYPE
					,mmv.PT_AT_RISK
					,mmv.REASON_RISK
					,mmv.GESTATION
					,mmv.CAUSE_OF_DEATH_UROLOGY
					,mmv.AVOIDABLE_DEATH
					,mmv.AVOIDABLE_DETAILS
					,mmv.OTHER_DEATH_CAUSE_UROLOGY
					,mmv.ACTION_ID
					,mmv.STATED_GENDER_CODE
					,mmv.CAUSE_OF_DEATH_UROLOGY_FUP
					,mmv.DEATH_WITHIN_30_DAYS_OF_TREAT
					,mmv.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT
					,mmv.DEATH_CAUSE_LATER_DATE
					,mmv.RegisteredPractice
					,mmv.RegisteredGP
					,mmv.PersonSexualOrientation
		FROM		(SELECT		SrcSys_Major_Post
								,Src_UID_Major_Post
					FROM		#tblDEMOGRAPHICS_Match_Control_Major_PrePost mc_major_prepost
					GROUP BY	SrcSys_Major_Post
								,Src_UID_Major_Post
								) mc_post
		INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv
																ON	mc_post.SrcSys_Major_Post = mmv.SrcSys_Major
																AND	mc_post.Src_UID_Major_Post = mmv.Src_UID_Major
		LEFT JOIN	#tblDEMOGRAPHICS_Match_MajorValidation mmv_alreadyThere
																ON	mc_post.SrcSys_Major_Post = mmv_alreadyThere.SrcSys_Major_Post
																AND	mc_post.Src_UID_Major_Post = mmv_alreadyThere.Src_UID_Major_Post
		WHERE		mmv_alreadyThere.SrcSys_Major_Post IS NULL -- we haven't already put the record into #tblDEMOGRAPHICS_Match_MajorValidation


		-- auto validate records where all the entities within a major entity have a scripted match intention
		INSERT INTO	#tblDEMOGRAPHICS_Match_MajorValidation
					(SrcSys_Major_Post
					,Src_UID_Major_Post
					,LastValidatedDttm_Post
					,LastValidatedBy_Post
					,ValidationStatus_Post
					)
		SELECT		AutoValidate.SrcSys_Major_Post
					,AutoValidate.Src_UID_Major_Post
					,GETDATE() AS LastValidatedDttm_Post
					,'All Matches Algorithmic' AS LastValidatedBy_Post
					,'All Matches Algorithmic' AS ValidationStatus_Post
		FROM		(SELECT		SrcSys_Major_Post
								,Src_UID_Major_Post
					FROM		#FindMajor_Match_Control mc_major_prepost
					GROUP BY	SrcSys_Major_Post
								,Src_UID_Major_Post
					HAVING		SUM(CASE WHEN BestIntention = 'Scripted' THEN 1 ELSE 0 END) > 0
					AND			SUM(CASE WHEN BestIntention = 'Manual' THEN 1 ELSE 0 END) = 0
								) AutoValidate
		LEFT JOIN	#tblDEMOGRAPHICS_Match_MajorValidation mmv
												ON	AutoValidate.SrcSys_Major_Post = mmv.SrcSys_Major_Post
												AND	AutoValidate.Src_UID_Major_Post = mmv.Src_UID_Major_Post
		WHERE		mmv.SrcSys_Major_Post IS NULL



		/*****************************************************************************************************************************************************************************************************************************************************************************************/
		-- Find the records to wipe from the persistent tables
		/*****************************************************************************************************************************************************************************************************************************************************************************************/

		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Prepare to replace'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

		-- Find all persistent match control records that relate to the initial incremental dataset (these will be for deletion)
		IF OBJECT_ID('tempdb..#tblDEMOGRAPHICS_Match_Control_ToDelete') IS NOT NULL DROP TABLE #tblDEMOGRAPHICS_Match_Control_ToDelete
		SELECT		mc.SrcSys
					,mc.Src_UID
		INTO		#tblDEMOGRAPHICS_Match_Control_ToDelete
		FROM		#Incremental inc
		INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
													ON	inc.SrcSys = mc.SrcSys
													AND	inc.Src_UID = mc.Src_UID

		-- Find all persistent match control records that will be orphaned from their major UID by the new major UIDs (we will set them to be their own major record and mark these as changed so they will be processed again next time round)
		IF OBJECT_ID('tempdb..#tblDEMOGRAPHICS_Match_Control_ToReprocess') IS NOT NULL DROP TABLE #tblDEMOGRAPHICS_Match_Control_ToReprocess
		SELECT		mc.SrcSys
					,mc.Src_UID
		INTO		#tblDEMOGRAPHICS_Match_Control_ToReprocess
		FROM		#Incremental inc
		INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
													ON	inc.SrcSys = mc.SrcSys_Major
													AND	inc.Src_UID = mc.Src_UID_Major
		WHERE		inc.ProcessIx > 1
		AND			CONCAT(CAST(mc.SrcSys AS VARCHAR(255)), '|', mc.Src_UID) != CONCAT(CAST(mc.SrcSys_Major AS VARCHAR(255)), '|', mc.Src_UID_Major)

		-- Find all persistent entity pairs all records that relate to the initial incremental dataset (these will be for deletion)
		IF OBJECT_ID('tempdb..#tblDEMOGRAPHICS_Match_EntityPairs_All_ToDelete') IS NOT NULL DROP TABLE #tblDEMOGRAPHICS_Match_EntityPairs_All_ToDelete
		SELECT		UnionAorB.SrcSys_A
					,UnionAorB.Src_UID_A
					,UnionAorB.SrcSys_B
					,UnionAorB.Src_UID_B
		INTO		#tblDEMOGRAPHICS_Match_EntityPairs_All_ToDelete
		FROM		(SELECT		ep_a.SrcSys_A
								,ep_a.Src_UID_A
								,ep_a.SrcSys_B
								,ep_a.Src_UID_B
					FROM		#tblDEMOGRAPHICS_Match_Control_ToDelete mc
					INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_All ep_a
																		ON	mc.SrcSys = ep_a.SrcSys_A
																		AND	mc.Src_UID = ep_a.Src_UID_A

					UNION
					
					SELECT		ep_a.SrcSys_A
								,ep_a.Src_UID_A
								,ep_a.SrcSys_B
								,ep_a.Src_UID_B
					FROM		#tblDEMOGRAPHICS_Match_Control_ToDelete mc
					INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_All ep_a
																		ON	mc.SrcSys = ep_a.SrcSys_B
																		AND	mc.Src_UID = ep_a.Src_UID_B
								) UnionAorB

		-- Find all persistent entity pairs unique records that relate to the initial incremental dataset (these will be for deletion)
		IF OBJECT_ID('tempdb..#tblDEMOGRAPHICS_Match_EntityPairs_Unique_ToDelete') IS NOT NULL DROP TABLE #tblDEMOGRAPHICS_Match_EntityPairs_Unique_ToDelete
		SELECT		UnionAorB.SrcSys_A
					,UnionAorB.Src_UID_A
					,UnionAorB.SrcSys_B
					,UnionAorB.Src_UID_B
		INTO		#tblDEMOGRAPHICS_Match_EntityPairs_Unique_ToDelete
		FROM		(SELECT		ep_u.SrcSys_A
								,ep_u.Src_UID_A
								,ep_u.SrcSys_B
								,ep_u.Src_UID_B
					FROM		#tblDEMOGRAPHICS_Match_Control_ToDelete mc
					INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_Unique ep_u
																		ON	mc.SrcSys = ep_u.SrcSys_A
																		AND	mc.Src_UID = ep_u.Src_UID_A

					UNION

					SELECT		ep_u.SrcSys_A
								,ep_u.Src_UID_A
								,ep_u.SrcSys_B
								,ep_u.Src_UID_B
					FROM		#tblDEMOGRAPHICS_Match_Control_ToDelete mc
					INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_Unique ep_u
																		ON	mc.SrcSys = ep_u.SrcSys_B
																		AND	mc.Src_UID = ep_u.Src_UID_B
								) UnionAorB

		-- Find all persistent major validation records that relate to the initial incremental dataset (these will be for deletion)
		IF OBJECT_ID('tempdb..#tblDEMOGRAPHICS_Match_MajorValidation_ToDelete') IS NOT NULL DROP TABLE #tblDEMOGRAPHICS_Match_MajorValidation_ToDelete
		SELECT		mmv.SrcSys_Major
					,mmv.Src_UID_Major
		INTO		#tblDEMOGRAPHICS_Match_MajorValidation_ToDelete
		FROM		(SELECT		SrcSys_Major_Pre
								,Src_UID_Major_Pre
					FROM		#tblDEMOGRAPHICS_Match_Control_Major_PrePost mc_mpp_inner
					GROUP BY	SrcSys_Major_Pre
								,Src_UID_Major_Pre

					UNION

					SELECT		mmv_inner.SrcSys_Major_Post
								,mmv_inner.Src_UID_Major_Post
					FROM		#tblDEMOGRAPHICS_Match_MajorValidation mmv_inner
					GROUP BY	mmv_inner.SrcSys_Major_Post
								,mmv_inner.Src_UID_Major_Post
								) mc_pre
		INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv
															ON	mc_pre.SrcSys_Major_Pre = mmv.SrcSys_Major
															AND	mc_pre.Src_UID_Major_Pre = mmv.Src_UID_Major

		-- Find all persistent major validation column overrid records that relate to the initial incremental dataset (these will be for deletion)
		IF OBJECT_ID('tempdb..#tblDEMOGRAPHICS_Match_MajorValidationColumns_ToDelete') IS NOT NULL DROP TABLE #tblDEMOGRAPHICS_Match_MajorValidationColumns_ToDelete
		SELECT		mmvc.SrcSys_Major
					,mmvc.Src_UID_Major
		INTO		#tblDEMOGRAPHICS_Match_MajorValidationColumns_ToDelete
		FROM		#tblDEMOGRAPHICS_Match_MajorValidation_ToDelete mmv
		INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidationColumns mmvc
															ON	mmv.SrcSys_Major = mmvc.SrcSys_Major
															AND	mmv.Src_UID_Major = mmvc.Src_UID_Major


		 BEGIN TRY

			 BEGIN TRANSACTION
		
				SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
				SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Replace'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
		
				-- Delete all related records from match control
				DELETE
				FROM		mc
				FROM		#tblDEMOGRAPHICS_Match_Control_ToDelete mc_toDelete
				INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
															ON	mc_toDelete.SrcSys = mc.SrcSys
															AND	mc_toDelete.Src_UID = mc.Src_UID

				-- Delete all related records from entity pairs all
				IF		ISNULL(@UseExistingMatches, 0) = 0
				DELETE
				FROM		ep_a
				FROM		#tblDEMOGRAPHICS_Match_EntityPairs_All_ToDelete ep_a_toDelete
				INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_All ep_a
																	ON	ep_a_toDelete.SrcSys_A = ep_a.SrcSys_A
																	AND	ep_a_toDelete.Src_UID_A = ep_a.Src_UID_A
																	AND	ep_a_toDelete.SrcSys_B = ep_a.SrcSys_B
																	AND	ep_a_toDelete.Src_UID_B = ep_a.Src_UID_B

				-- Delete all related records from entity pairs unique
				DELETE
				FROM		ep_u
				FROM		#tblDEMOGRAPHICS_Match_EntityPairs_Unique_ToDelete ep_u_toDelete
				INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_Unique ep_u
																	ON	ep_u_toDelete.SrcSys_A = ep_u.SrcSys_A
																	AND	ep_u_toDelete.Src_UID_A = ep_u.Src_UID_A
																	AND	ep_u_toDelete.SrcSys_B = ep_u.SrcSys_B
																	AND	ep_u_toDelete.Src_UID_B = ep_u.Src_UID_B

				-- Delete all related records from major validation tables
				DELETE
				FROM		mmv
				FROM		#tblDEMOGRAPHICS_Match_MajorValidation_ToDelete mmv_toDelete
				INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv
																	ON	mmv_toDelete.SrcSys_Major = mmv.SrcSys_Major
																	AND	mmv_toDelete.Src_UID_Major = mmv.Src_UID_Major

				-- Delete all related records from major column values tables
				DELETE
				FROM		mmvc
				FROM		#tblDEMOGRAPHICS_Match_MajorValidationColumns_ToDelete mmvc_toDelete
				INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidationColumns mmvc
																	ON	mmvc_toDelete.SrcSys_Major = mmvc.SrcSys_Major
																	AND	mmvc_toDelete.Src_UID_Major = mmvc.Src_UID_Major


				-- Mark all persistent match control records that will be orphaned from their major UID by the new major UIDs for reprocessing
				UPDATE		mc
				SET			mc.SrcSys_Major = mc.SrcSys
							,mc.Src_UID_Major = mc.Src_UID
							,mc.LastProcessed = NULL
				FROM		#tblDEMOGRAPHICS_Match_Control_ToReprocess mc_toReprocess
				INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
															ON	mc_toReprocess.SrcSys = mc.SrcSys
															AND	mc_toReprocess.Src_UID = mc.Src_UID

				-- Insert all new records into match control
				INSERT INTO	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control
							(SrcSys_Major
							,Src_UID_Major
							,IsSCR
							,SrcSys
							,Src_UID
							,HashBytesValue
							,ChangeLastDetected
							,LastProcessed
							,DeletedDttm
							)
				SELECT		SrcSys_Major		= mc.SrcSys_Major_Post
							,Src_UID_Major		= mc.Src_UID_Major_Post
							,IsSCR				= mc.IsSCR
							,SrcSys				= mc.SrcSys
							,Src_UID			= mc.Src_UID
							,HashBytesValue		= mc.HashBytesValue
							,ChangeLastDetected	= mc.ChangeLastDetected
							,LastProcessed		= mc.LastProcessed_Post
							,DeletedDttm		= mc.DeletedDttm
				FROM		#FindMajor_Match_Control mc

				-- Insert all new records into entity pairs all
				IF		ISNULL(@UseExistingMatches, 0) = 0
				INSERT INTO	Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_All
							(IsSCR_A
							,SrcSys_A
							,Src_UID_A
							,IsSCR_B
							,SrcSys_B
							,Src_UID_B
							,MatchType
							,MatchIntention
							)
				SELECT		IsSCR_A					= ep_a.IsSCR_A
							,SrcSys_A				= ep_a.SrcSys_A
							,Src_UID_A				= ep_a.Src_UID_A
							,IsSCR_B				= ep_a.IsSCR_B
							,SrcSys_B				= ep_a.SrcSys_B
							,Src_UID_B				= ep_a.Src_UID_B
							,MatchType				= ep_a.MatchType
							,MatchIntention			= ep_a.MatchIntention
				FROM		#tblDEMOGRAPHICS_Match_EntityPairs_All ep_a

				-- Insert all new records into entity pairs unique
				INSERT INTO	Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_Unique
							(SrcSys_A
							,Src_UID_A
							,SrcSys_B
							,Src_UID_B
							,BestIntention
							,UnlinkDttm
							,LastUnlinkedBy
							,UnlinkProcessed
							)
				SELECT		SrcSys_A					= ep_u.SrcSys_A
							,SrcSys_A					= ep_u.Src_UID_A
							,Src_UID_A					= ep_u.SrcSys_B
							,SrcSys_B					= ep_u.Src_UID_B
							,Src_UID_B					= ep_u.BestIntention_Post
							,BestIntention				= ep_u.UnlinkDttm_Post
							,UnlinkDttm					= ep_u.LastUnlinkedBy
							,UnlinkProcessed			= ep_u.UnlinkProcessed_Post
				FROM		#FindMajor_Match_EntityPairs_Unique ep_u

				-- Insert all new records into major validation
				INSERT INTO	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation
							(SrcSys_Major
							,Src_UID_Major
							,LastValidatedDttm
							,LastValidatedBy
							,ValidationStatus
							,PATIENT_ID
							,N1_1_NHS_NUMBER
							,NHS_NUMBER_STATUS
							,L_RA3_RID
							,L_RA7_RID
							,L_RVJ01_RID
							,TEMP_ID
							,L_NSTS_STATUS
							,N1_2_HOSPITAL_NUMBER
							,L_TITLE
							,N1_5_SURNAME
							,N1_6_FORENAME
							,N1_7_ADDRESS_1
							,N1_7_ADDRESS_2
							,N1_7_ADDRESS_3
							,N1_7_ADDRESS_4
							,N1_7_ADDRESS_5
							,N1_8_POSTCODE
							,N1_9_SEX
							,N1_10_DATE_BIRTH
							,N1_11_GP_CODE
							,N1_12_GP_PRACTICE_CODE
							,N1_13_PCT
							,N1_14_SURNAME_BIRTH
							,N1_15_ETHNICITY
							,PAT_PREF_NAME
							,PAT_OCCUPATION
							,PAT_SOCIAL_CLASS
							,PAT_LIVES_ALONE
							,MARITAL_STATUS
							,PAT_PREF_LANGUAGE
							,PAT_PREF_CONTACT
							,L_DEATH_STATUS
							,N15_1_DATE_DEATH
							,N15_2_DEATH_LOCATION
							,N15_3_DEATH_CAUSE
							,N15_4_DEATH_CANCER
							,N15_5_DEATH_CODE_1
							,N15_6_DEATH_CODE_2
							,N15_7_DEATH_CODE_3
							,N15_8_DEATH_CODE_4
							,N15_9_DEATH_DISCREPANCY
							,N_CC4_TOWN
							,N_CC5_COUNTRY
							,N_CC6_M_SURNAME
							,N_CC7_M_CLASS
							,N_CC8_M_FORENAME
							,N_CC9_M_DOB
							,N_CC10_M_TOWN
							,N_CC11_M_COUNTRY
							,N_CC12_M_OCC
							,N_CC13_M_OCC_DIAG
							,N_CC6_F_SURNAME
							,N_CC7_F_CLASS
							,N_CC8_F_FORENAME
							,N_CC9_F_DOB
							,N_CC10_F_TOWN
							,N_CC11_F_COUNTRY
							,N_CC12_F_OCC
							,N_CC13_F_OCC_DIAG
							,N_CC14_MULTI_BIRTH
							,R_POST_MORTEM
							,R_DAY_PHONE
							,DAY_PHONE_EXT
							,R_EVE_PHONE
							,EVE_PHONE_EXT
							,R_DEATH_TREATMENT
							,R_PM_DETAILS
							,L_IATROGENIC_DEATH
							,L_INFECTION_DEATH
							,L_DEATH_COMMENTS
							,RELIGION
							,CONTACT_DETAILS
							,NOK_NAME
							,NOK_ADDRESS_1
							,NOK_ADDRESS_2
							,NOK_ADDRESS_3
							,NOK_ADDRESS_4
							,NOK_ADDRESS_5
							,NOK_POSTCODE
							,NOK_CONTACT
							,NOK_RELATIONSHIP
							,PAT_DEPENDANTS
							,CARER_NAME
							,CARER_ADDRESS_1
							,CARER_ADDRESS_2
							,CARER_ADDRESS_3
							,CARER_ADDRESS_4
							,CARER_ADDRESS_5
							,CARER_POSTCODE
							,CARER_CONTACT
							,CARER_RELATIONSHIP
							,CARER1_TYPE
							,CARER2_NAME
							,CARER2_ADDRESS_1
							,CARER2_ADDRESS_2
							,CARER2_ADDRESS_3
							,CARER2_ADDRESS_4
							,CARER2_ADDRESS_5
							,CARER2_POSTCODE
							,CARER2_CONTACT
							,CARER2_RELATIONSHIP
							,CARER2_TYPE
							,PT_AT_RISK
							,REASON_RISK
							,GESTATION
							,CAUSE_OF_DEATH_UROLOGY
							,AVOIDABLE_DEATH
							,AVOIDABLE_DETAILS
							,OTHER_DEATH_CAUSE_UROLOGY
							,ACTION_ID
							,STATED_GENDER_CODE
							,CAUSE_OF_DEATH_UROLOGY_FUP
							,DEATH_WITHIN_30_DAYS_OF_TREAT
							,DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT
							,DEATH_CAUSE_LATER_DATE
							,RegisteredPractice
							,RegisteredGP
							,PersonSexualOrientation
							)
				SELECT		SrcSys_Major							= mmv.SrcSys_Major_Post
							,Src_UID_Major							= mmv.Src_UID_Major_Post
							,LastValidatedDttm						= mmv.LastValidatedDttm_Post
							,LastValidatedBy						= mmv.LastValidatedBy_Post
							,ValidationStatus						= mmv.ValidationStatus_Post
							,PATIENT_ID								= mmv.PATIENT_ID
							,N1_1_NHS_NUMBER						= mmv.N1_1_NHS_NUMBER
							,NHS_NUMBER_STATUS						= mmv.NHS_NUMBER_STATUS
							,L_RA3_RID								= mmv.L_RA3_RID
							,L_RA7_RID								= mmv.L_RA7_RID
							,L_RVJ01_RID							= mmv.L_RVJ01_RID
							,TEMP_ID								= mmv.TEMP_ID
							,L_NSTS_STATUS							= mmv.L_NSTS_STATUS
							,N1_2_HOSPITAL_NUMBER					= mmv.N1_2_HOSPITAL_NUMBER
							,L_TITLE								= mmv.L_TITLE
							,N1_5_SURNAME							= mmv.N1_5_SURNAME
							,N1_6_FORENAME							= mmv.N1_6_FORENAME
							,N1_7_ADDRESS_1							= mmv.N1_7_ADDRESS_1
							,N1_7_ADDRESS_2							= mmv.N1_7_ADDRESS_2
							,N1_7_ADDRESS_3							= mmv.N1_7_ADDRESS_3
							,N1_7_ADDRESS_4							= mmv.N1_7_ADDRESS_4
							,N1_7_ADDRESS_5							= mmv.N1_7_ADDRESS_5
							,N1_8_POSTCODE							= mmv.N1_8_POSTCODE
							,N1_9_SEX								= mmv.N1_9_SEX
							,N1_10_DATE_BIRTH						= mmv.N1_10_DATE_BIRTH
							,N1_11_GP_CODE							= mmv.N1_11_GP_CODE
							,N1_12_GP_PRACTICE_CODE					= mmv.N1_12_GP_PRACTICE_CODE
							,N1_13_PCT								= mmv.N1_13_PCT
							,N1_14_SURNAME_BIRTH					= mmv.N1_14_SURNAME_BIRTH
							,N1_15_ETHNICITY						= mmv.N1_15_ETHNICITY
							,PAT_PREF_NAME							= mmv.PAT_PREF_NAME
							,PAT_OCCUPATION							= mmv.PAT_OCCUPATION
							,PAT_SOCIAL_CLASS						= mmv.PAT_SOCIAL_CLASS
							,PAT_LIVES_ALONE						= mmv.PAT_LIVES_ALONE
							,MARITAL_STATUS							= mmv.MARITAL_STATUS
							,PAT_PREF_LANGUAGE						= mmv.PAT_PREF_LANGUAGE
							,PAT_PREF_CONTACT						= mmv.PAT_PREF_CONTACT
							,L_DEATH_STATUS							= mmv.L_DEATH_STATUS
							,N15_1_DATE_DEATH						= mmv.N15_1_DATE_DEATH
							,N15_2_DEATH_LOCATION					= mmv.N15_2_DEATH_LOCATION
							,N15_3_DEATH_CAUSE						= mmv.N15_3_DEATH_CAUSE
							,N15_4_DEATH_CANCER						= mmv.N15_4_DEATH_CANCER
							,N15_5_DEATH_CODE_1						= mmv.N15_5_DEATH_CODE_1
							,N15_6_DEATH_CODE_2						= mmv.N15_6_DEATH_CODE_2
							,N15_7_DEATH_CODE_3						= mmv.N15_7_DEATH_CODE_3
							,N15_8_DEATH_CODE_4						= mmv.N15_8_DEATH_CODE_4
							,N15_9_DEATH_DISCREPANCY				= mmv.N15_9_DEATH_DISCREPANCY
							,N_CC4_TOWN								= mmv.N_CC4_TOWN
							,N_CC5_COUNTRY							= mmv.N_CC5_COUNTRY
							,N_CC6_M_SURNAME						= mmv.N_CC6_M_SURNAME
							,N_CC7_M_CLASS							= mmv.N_CC7_M_CLASS
							,N_CC8_M_FORENAME						= mmv.N_CC8_M_FORENAME
							,N_CC9_M_DOB							= mmv.N_CC9_M_DOB
							,N_CC10_M_TOWN							= mmv.N_CC10_M_TOWN
							,N_CC11_M_COUNTRY						= mmv.N_CC11_M_COUNTRY
							,N_CC12_M_OCC							= mmv.N_CC12_M_OCC
							,N_CC13_M_OCC_DIAG						= mmv.N_CC13_M_OCC_DIAG
							,N_CC6_F_SURNAME						= mmv.N_CC6_F_SURNAME
							,N_CC7_F_CLASS							= mmv.N_CC7_F_CLASS
							,N_CC8_F_FORENAME						= mmv.N_CC8_F_FORENAME
							,N_CC9_F_DOB							= mmv.N_CC9_F_DOB
							,N_CC10_F_TOWN							= mmv.N_CC10_F_TOWN
							,N_CC11_F_COUNTRY						= mmv.N_CC11_F_COUNTRY
							,N_CC12_F_OCC							= mmv.N_CC12_F_OCC
							,N_CC13_F_OCC_DIAG						= mmv.N_CC13_F_OCC_DIAG
							,N_CC14_MULTI_BIRTH						= mmv.N_CC14_MULTI_BIRTH
							,R_POST_MORTEM							= mmv.R_POST_MORTEM
							,R_DAY_PHONE							= mmv.R_DAY_PHONE
							,DAY_PHONE_EXT							= mmv.DAY_PHONE_EXT
							,R_EVE_PHONE							= mmv.R_EVE_PHONE
							,EVE_PHONE_EXT							= mmv.EVE_PHONE_EXT
							,R_DEATH_TREATMENT						= mmv.R_DEATH_TREATMENT
							,R_PM_DETAILS							= mmv.R_PM_DETAILS
							,L_IATROGENIC_DEATH						= mmv.L_IATROGENIC_DEATH
							,L_INFECTION_DEATH						= mmv.L_INFECTION_DEATH
							,L_DEATH_COMMENTS						= mmv.L_DEATH_COMMENTS
							,RELIGION								= mmv.RELIGION
							,CONTACT_DETAILS						= mmv.CONTACT_DETAILS
							,NOK_NAME								= mmv.NOK_NAME
							,NOK_ADDRESS_1							= mmv.NOK_ADDRESS_1
							,NOK_ADDRESS_2							= mmv.NOK_ADDRESS_2
							,NOK_ADDRESS_3							= mmv.NOK_ADDRESS_3
							,NOK_ADDRESS_4							= mmv.NOK_ADDRESS_4
							,NOK_ADDRESS_5							= mmv.NOK_ADDRESS_5
							,NOK_POSTCODE							= mmv.NOK_POSTCODE
							,NOK_CONTACT							= mmv.NOK_CONTACT
							,NOK_RELATIONSHIP						= mmv.NOK_RELATIONSHIP
							,PAT_DEPENDANTS							= mmv.PAT_DEPENDANTS
							,CARER_NAME								= mmv.CARER_NAME
							,CARER_ADDRESS_1						= mmv.CARER_ADDRESS_1
							,CARER_ADDRESS_2						= mmv.CARER_ADDRESS_2
							,CARER_ADDRESS_3						= mmv.CARER_ADDRESS_3
							,CARER_ADDRESS_4						= mmv.CARER_ADDRESS_4
							,CARER_ADDRESS_5						= mmv.CARER_ADDRESS_5
							,CARER_POSTCODE							= mmv.CARER_POSTCODE
							,CARER_CONTACT							= mmv.CARER_CONTACT
							,CARER_RELATIONSHIP						= mmv.CARER_RELATIONSHIP
							,CARER1_TYPE							= mmv.CARER1_TYPE
							,CARER2_NAME							= mmv.CARER2_NAME
							,CARER2_ADDRESS_1						= mmv.CARER2_ADDRESS_1
							,CARER2_ADDRESS_2						= mmv.CARER2_ADDRESS_2
							,CARER2_ADDRESS_3						= mmv.CARER2_ADDRESS_3
							,CARER2_ADDRESS_4						= mmv.CARER2_ADDRESS_4
							,CARER2_ADDRESS_5						= mmv.CARER2_ADDRESS_5
							,CARER2_POSTCODE						= mmv.CARER2_POSTCODE
							,CARER2_CONTACT							= mmv.CARER2_CONTACT
							,CARER2_RELATIONSHIP					= mmv.CARER2_RELATIONSHIP
							,CARER2_TYPE							= mmv.CARER2_TYPE
							,PT_AT_RISK								= mmv.PT_AT_RISK
							,REASON_RISK							= mmv.REASON_RISK
							,GESTATION								= mmv.GESTATION
							,CAUSE_OF_DEATH_UROLOGY					= mmv.CAUSE_OF_DEATH_UROLOGY
							,AVOIDABLE_DEATH						= mmv.AVOIDABLE_DEATH
							,AVOIDABLE_DETAILS						= mmv.AVOIDABLE_DETAILS
							,OTHER_DEATH_CAUSE_UROLOGY				= mmv.OTHER_DEATH_CAUSE_UROLOGY
							,ACTION_ID								= mmv.ACTION_ID
							,STATED_GENDER_CODE						= mmv.STATED_GENDER_CODE
							,CAUSE_OF_DEATH_UROLOGY_FUP				= mmv.CAUSE_OF_DEATH_UROLOGY_FUP
							,DEATH_WITHIN_30_DAYS_OF_TREAT			= mmv.DEATH_WITHIN_30_DAYS_OF_TREAT
							,DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT	= mmv.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT
							,DEATH_CAUSE_LATER_DATE					= mmv.DEATH_CAUSE_LATER_DATE
							,RegisteredPractice						= mmv.RegisteredPractice
							,RegisteredGP							= mmv.RegisteredGP
							,PersonSexualOrientation				= mmv.PersonSexualOrientation
				FROM		#tblDEMOGRAPHICS_Match_MajorValidation mmv

				-- Insert all new records into major validation columns
				INSERT INTO	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidationColumns
							(SrcSys_Major
							,Src_UID_Major
							,FieldName
							,SrcSys
							,Src_UID
							)
				SELECT		SrcSys_Major	= mmvc.SrcSys_Major_Pre
							,Src_UID_Major	= mmvc.Src_UID_Major_Pre
							,FieldName		= mmvc.FieldName
							,SrcSys			= mmvc.SrcSys
							,Src_UID		= mmvc.Src_UID
				FROM		#tblDEMOGRAPHICS_Match_MajorValidationColumns mmvc



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

		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 0, @ErrorMessage = @ErrorMessage

		/*****************************************************************************************************************************************************************************************************************************************************************************************/
		-- Automatically confirm validation records that have been sampled and authorised as suitable for handling without manual intervention (only when bulk processing records)
		/*****************************************************************************************************************************************************************************************************************************************************************************************/

		-- Only automatically confirm validation records when we are bulk processing
		IF	@MajorID_SrcSys IS NULL
		OR	@MajorID_Src_UID IS NULL
		BEGIN

				PRINT 'Starting Auto-Validation' + CHAR(13) + CHAR(13)
				
				-- Create the #MakeMajor table
				IF OBJECT_ID('tempdb..#MakeMajor') IS NOT NULL DROP TABLE #MakeMajor
				CREATE TABLE #MakeMajor
							(SrcSys_Major_Curr TINYINT
							,Src_UID_Major_Curr VARCHAR(255)
							,SrcSys_Major_New TINYINT
							,Src_UID_Major_New VARCHAR(255)
							)
							
				-- Create the #Aud_MakeMajor table to pass successes / failures to the audit trail
				IF OBJECT_ID('tempdb..#Aud_MakeMajor') IS NOT NULL DROP TABLE #Aud_MakeMajor
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

				-- Create the #ConfirmMajor table
				IF OBJECT_ID('tempdb..#ConfirmMajor') IS NOT NULL DROP TABLE #ConfirmMajor
				CREATE TABLE #ConfirmMajor
							(SrcSys_Major TINYINT
							,Src_UID_Major VARCHAR(255)
							)

				-- Insert the current major records for which we wish to automatically find and confirm the major
				-- Algorithmic matches that have no more than 1 record on either SCR and no more than 4 PAS records
				INSERT INTO #MakeMajor (SrcSys_Major_Curr,Src_UID_Major_Curr)
				SELECT		mc.SrcSys_Major
							,mc.Src_UID_Major
				FROM		(SELECT		mc_inner.SrcSys_Major
										,mc_inner.Src_UID_Major
										,SUM(CASE WHEN mc_inner.SrcSys = 1 THEN 1 ELSE 0 END) AS SrcSys_WSHT
										,SUM(CASE WHEN mc_inner.SrcSys = 2 THEN 1 ELSE 0 END) AS SrcSys_BSUH
										,SUM(CASE WHEN mc_inner.SrcSys > 2 THEN 1 ELSE 0 END) AS SrcSys_Ext
							FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc_inner
							WHERE		mc_inner.DeletedDttm IS NULL
							GROUP BY	mc_inner.SrcSys_Major
										,mc_inner.Src_UID_Major
										) mc
				LEFT JOIN	(SELECT		mc.SrcSys_Major
										,mc.Src_UID_Major
							FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_EntityPairs_Unique ep_u
							INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
																						ON	ep_u.SrcSys_A = mc.SrcSys
																						AND	ep_u.Src_UID_A = mc.Src_UID
							WHERE		ep_u.BestIntention = 'Manual'
							GROUP BY	mc.SrcSys_Major
										,mc.Src_UID_Major
										) NonAlgorithmic
														ON	mc.SrcSys_Major = NonAlgorithmic.SrcSys_Major
														AND	mc.Src_UID_Major = NonAlgorithmic.Src_UID_Major
				LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv_confirmed
																					ON	mc.SrcSys_Major = mmv_confirmed.SrcSys_Major
																					AND	mc.Src_UID_Major = mmv_confirmed.Src_UID_Major
																					AND	mmv_confirmed.ValidationStatus = 'Confirmed'
				WHERE		mmv_confirmed.SrcSys_Major IS NULL
				AND			NonAlgorithmic.SrcSys_Major IS NULL
				AND			mc.SrcSys_BSUH <= 1
				AND			mc.SrcSys_WSHT <= 1
				AND			mc.SrcSys_Ext <= 4

				-- Insert the current major records for which we wish to automatically find and confirm the major
				-- Any matches that have a single record on one SCR only that has been updated by PAS
				INSERT INTO #MakeMajor (SrcSys_Major_Curr,Src_UID_Major_Curr)
				SELECT		mc.SrcSys_Major
							,mc.Src_UID_Major
				FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
				LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv
																					ON	mc.SrcSys_Major = mmv.SrcSys_Major
																					AND	mc.Src_UID_Major = mmv.Src_UID_Major
																					AND	mmv.ValidationStatus IN ('Confirmed','Dont Merge')
				LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH UH
																	ON	mc.SrcSys = UH.SrcSys
																	AND	mc.Src_UID = UH.Src_UID
				WHERE		mc.DeletedDttm IS NULL
				GROUP BY	mc.SrcSys_Major
							,mc.Src_UID_Major
				HAVING		COUNT(*) > 1
				AND			MAX(CASE WHEN mmv.SrcSys_Major IS NOT NULL THEN 1 ELSE 0 END) = 0
				AND			((SUM(CASE WHEN mc.SrcSys = 1 AND UH.UpdateByPas = 1 THEN 1 ELSE 0 END) = 1	-- a single WHST record updated by PAS
						AND	SUM(CASE WHEN mc.SrcSys = 2 THEN 1 ELSE 0 END) = 0							-- no BSUH record
						AND	SUM(CASE WHEN mc.SrcSys = 3 THEN 1 ELSE 0 END) <= 4)						-- no more than 4 PAS records
						OR	(SUM(CASE WHEN mc.SrcSys = 2 AND UH.UpdateByPas = 1 THEN 1 ELSE 0 END) = 1	-- a single BSUH record updated by PAS
						AND	SUM(CASE WHEN mc.SrcSys = 1 THEN 1 ELSE 0 END) = 0)							-- no WSHT record
						AND	SUM(CASE WHEN mc.SrcSys = 3 THEN 1 ELSE 0 END) <= 4)						-- no more than 4 PAS records


				
				-- Remove any records where there are multiple dates of death across minors
				DELETE
				FROM		mm
				FROM		#MakeMajor mm
				INNER JOIN	(SELECT		vd_multiNHS.SrcSys_Major
										,vd_multiNHS.Src_UID_Major
							FROM		(SELECT		mc_inner.SrcSys_Major
													,mc_inner.Src_UID_Major
													,ISNULL(h_scr.N15_1_DATE_DEATH, h_cf.N15_1_DATE_DEATH) AS N15_1_DATE_DEATH
										FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc_inner
										LEFT JOIN	Merge_DM_MatchViews.tblDEMOGRAPHICS_vw_H_SCR h_scr
																										ON	mc_inner.SrcSys = h_scr.SrcSys
																										AND	mc_inner.Src_UID = h_scr.Src_UID
																										AND	h_scr.N15_1_DATE_DEATH IS NOT NULL
										LEFT JOIN	Merge_DM_MatchViews.tblDEMOGRAPHICS_vw_H_Careflow h_cf
																										ON	mc_inner.SrcSys = h_cf.SrcSys
																										AND	mc_inner.Src_UID = h_cf.Src_UID
																										AND	h_cf.N15_1_DATE_DEATH IS NOT NULL
										LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv_inner
																													ON	mc_inner.SrcSys_Major = mmv_inner.SrcSys_Major
																													AND	mc_inner.Src_UID_Major = mmv_inner.Src_UID_Major
																													AND	mmv_inner.ValidationStatus = 'Confirmed'
										WHERE		mmv_inner.SrcSys_Major IS NULL
										AND			ISNULL(h_scr.SrcSys, h_cf.SrcSys) IS NOT NULL
										GROUP BY	mc_inner.SrcSys_Major
													,mc_inner.Src_UID_Major
													,ISNULL(h_scr.N15_1_DATE_DEATH, h_cf.N15_1_DATE_DEATH)
													) vd_multiNHS
							GROUP BY	vd_multiNHS.SrcSys_Major
										,vd_multiNHS.Src_UID_Major
							HAVING		COUNT(*) > 1
										) multi_DoD
													ON	mm.SrcSys_Major_Curr = multi_DoD.SrcSys_Major
													AND	mm.Src_UID_Major_Curr = multi_DoD.Src_UID_Major

				-- Remove any records where there are multiple sexes across minors
				DELETE
				FROM		mm
				FROM		#MakeMajor mm
				INNER JOIN	(SELECT		vd_multiNHS.SrcSys_Major
										,vd_multiNHS.Src_UID_Major
							FROM		(SELECT		mc_inner.SrcSys_Major
													,mc_inner.Src_UID_Major
													,ISNULL(h_scr.N1_9_SEX, h_cf.N1_9_SEX) AS N1_9_SEX
										FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc_inner
										LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH h_scr
																										ON	mc_inner.SrcSys = h_scr.SrcSys
																										AND	mc_inner.Src_UID = h_scr.Src_UID
																										AND	h_scr.N1_9_SEX IS NOT NULL
																										AND	h_scr.SrcSys IN (1,2)
										LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH h_cf
																										ON	mc_inner.SrcSys = h_cf.SrcSys
																										AND	mc_inner.Src_UID = h_cf.Src_UID
																										AND	ISNULL(h_cf.N1_9_SEX, '') != ''
																										AND	h_cf.SrcSys = 3
										LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv_inner
																													ON	mc_inner.SrcSys_Major = mmv_inner.SrcSys_Major
																													AND	mc_inner.Src_UID_Major = mmv_inner.Src_UID_Major
																													AND	mmv_inner.ValidationStatus = 'Confirmed'
										WHERE		mmv_inner.SrcSys_Major IS NULL
										AND			ISNULL(h_scr.SrcSys, h_cf.SrcSys) IS NOT NULL
										GROUP BY	mc_inner.SrcSys_Major
													,mc_inner.Src_UID_Major
													,ISNULL(h_scr.N1_9_SEX, h_cf.N1_9_SEX)
													) vd_multiNHS
							GROUP BY	vd_multiNHS.SrcSys_Major
										,vd_multiNHS.Src_UID_Major
							HAVING		COUNT(*) > 1
										) multi_Sex
													ON	mm.SrcSys_Major_Curr = multi_Sex.SrcSys_Major
													AND	mm.Src_UID_Major_Curr = multi_Sex.Src_UID_Major

				-- Remove any records where there are multiple ethnicities across minors
				DELETE
				FROM		mm
				FROM		#MakeMajor mm
				INNER JOIN	(SELECT		vd_multiNHS.SrcSys_Major
										,vd_multiNHS.Src_UID_Major
							FROM		(SELECT		mc_inner.SrcSys_Major
													,mc_inner.Src_UID_Major
													,ISNULL(h_scr.N1_15_ETHNICITY, h_cf.N1_15_ETHNICITY) AS N1_15_ETHNICITY
										FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc_inner
										LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH h_scr
																										ON	mc_inner.SrcSys = h_scr.SrcSys
																										AND	mc_inner.Src_UID = h_scr.Src_UID
																										AND	h_scr.N1_15_ETHNICITY IS NOT NULL
																										AND	ISNULL(h_scr.N1_15_ETHNICITY, '') NOT IN ('','Z','99')
																										AND	h_scr.SrcSys IN (1,2)
										LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH h_cf
																										ON	mc_inner.SrcSys = h_cf.SrcSys
																										AND	mc_inner.Src_UID = h_cf.Src_UID
																										AND	ISNULL(h_cf.N1_15_ETHNICITY, '') NOT IN ('','Z','XXXX')
																										AND	h_cf.SrcSys = 3
										LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv_inner
																													ON	mc_inner.SrcSys_Major = mmv_inner.SrcSys_Major
																													AND	mc_inner.Src_UID_Major = mmv_inner.Src_UID_Major
																													AND	mmv_inner.ValidationStatus = 'Confirmed'
										WHERE		mmv_inner.SrcSys_Major IS NULL
										AND			ISNULL(h_scr.SrcSys, h_cf.SrcSys) IS NOT NULL
										GROUP BY	mc_inner.SrcSys_Major
													,mc_inner.Src_UID_Major
													,ISNULL(h_scr.N1_15_ETHNICITY, h_cf.N1_15_ETHNICITY)
													) vd_multiNHS
							GROUP BY	vd_multiNHS.SrcSys_Major
										,vd_multiNHS.Src_UID_Major
							HAVING		COUNT(*) > 1
										) multi_ethnic
													ON	mm.SrcSys_Major_Curr = multi_ethnic.SrcSys_Major
													AND	mm.Src_UID_Major_Curr = multi_ethnic.Src_UID_Major
				
				-- Find the most recent minor record for each current major to be automatically confirmed
				UPDATE		mm
				SET			mm.SrcSys_Major_New = mostRecentMinor.SrcSys_Major_New
							,mm.Src_UID_Major_New = mostRecentMinor.Src_UID_Major_New
				FROM		(SELECT		mc.SrcSys_Major AS SrcSys_Major_Curr
										,mc.Src_UID_Major AS Src_UID_Major_Curr
										,mc.SrcSys AS SrcSys_Major_New
										,mc.Src_UID AS Src_UID_Major_New
										,McIx	= ROW_NUMBER() OVER(PARTITION BY mc.SrcSys_Major, mc.Src_UID_Major ORDER BY uh.LastUpdated DESC)
							FROM		#MakeMajor mm_inner
							INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
																						ON	mm_inner.SrcSys_Major_Curr = mc.SrcSys_Major
																						AND	mm_inner.Src_UID_Major_Curr = mc.Src_UID_Major
							INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH uh
																				ON	mc.SrcSys = uh.SrcSys
																				AND	mc.Src_UID = uh.Src_UID
										) mostRecentMinor
				INNER JOIN	#MakeMajor mm
											ON	mostRecentMinor.SrcSys_Major_Curr = mm.SrcSys_Major_Curr
											AND	mostRecentMinor.Src_UID_Major_Curr = mm.Src_UID_Major_Curr
											AND	mostRecentMinor.McIx = 1

				-- Add any records that already have the correct major to the #ConfirmMajor table
				INSERT INTO	#ConfirmMajor (SrcSys_Major,Src_UID_Major)
				SELECT		mm.SrcSys_Major_Curr
							,mm.Src_UID_Major_Curr
				FROM		#MakeMajor mm
				WHERE		mm.SrcSys_Major_Curr = mm.SrcSys_Major_New
				AND			mm.Src_UID_Major_Curr = mm.Src_UID_Major_New
				GROUP BY	mm.SrcSys_Major_Curr
							,mm.Src_UID_Major_Curr

				-- Remove any records that already have the correct major from #MakeMajor
				DELETE
				FROM		mm
				FROM		#MakeMajor mm
				WHERE		mm.SrcSys_Major_Curr = mm.SrcSys_Major_New
				AND			mm.Src_UID_Major_Curr = mm.Src_UID_Major_New

				-- Process the records that need their major changing
				EXEC Merge_DM_Match.uspMakeMajor @tableName = 'tblDEMOGRAPHICS', @UserID = 'tblDEMOGRAPHICS_uspMatchEntityPairs'
		
				-- Add any records that were successfully made the major to the #ConfirmMajor table (as long as they're not already in there)
				INSERT INTO	#ConfirmMajor (SrcSys_Major,Src_UID_Major)
				SELECT		aud_mm.SrcSys_Major_New
							,aud_mm.Src_UID_Major_New
				FROM		#Aud_MakeMajor aud_mm
				WHERE		Success = 1
				EXCEPT
				SELECT		SrcSys_Major
							,Src_UID_Major
				FROM		#ConfirmMajor

				-- Process the records that need their major confirming
				EXEC Merge_DM_Match.uspConfirmMajor @tableName = 'tblDEMOGRAPHICS', @UserID = 'tblDEMOGRAPHICS_uspMatchEntityPairs'

		END
GO
