SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [Merge_DM_Match].[tblMAIN_REFERRALS_uspMatchEntityPairs] 

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
Description:				A template stored procedure to match records from different sources
							ready for deduplication
**************************************************************************************************************************************************/

-- Test me
-- EXEC Merge_DM_Match.tblMAIN_REFERRALS_uspMatchEntityPairs
-- EXEC Merge_DM_Match.tblMAIN_REFERRALS_uspMatchEntityPairs @MajorID_SrcSys = 1, @MajorID_Src_UID = 32
-- EXEC Merge_DM_Match.tblMAIN_REFERRALS_uspMatchEntityPairs @MajorID_SrcSys = 1, @MajorID_Src_UID = 31, @UseExistingMatches = 1

-- DECLARE	@CurrentUser VARCHAR(255),@ProcIdName VARCHAR(255),@CurrentSection VARCHAR(255),@CurrentDttm DATETIME2,@LoopCounter SMALLINT = 1,@SQL VARCHAR(MAX),@Guid VARCHAR(255),@UseExistingMatches BIT = 0	SELECT	@CurrentUser = CURRENT_USER, @ProcIdName = ISNULL(OBJECT_NAME(@@PROCID), 'ad hoc'), @Guid = CAST(NEWID() AS VARCHAR(255))

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

		-- Perform either an incremental load based on new / changed data or a selective refresh based on a 
		IF	@MajorID_SrcSys IS NULL
		OR	@MajorID_Src_UID IS NULL
		BEGIN
				-- Insert the new / changed records since the last refresh
				INSERT INTO	#Incremental
							(IsSCR
							,SrcSys
							,Src_UID)
				SELECT		mc.IsSCR AS IsSCR
							,mc.SrcSys AS SrcSys
							,mc.Src_UID AS Src_UID
				FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
				WHERE		mc.LastProcessed IS NULL
				OR			mc.LastProcessed < mc.ChangeLastDetected
				GROUP BY	mc.IsSCR
							,mc.SrcSys
							,mc.Src_UID
							
				-- Insert minors associated with the majors that have new / changed records since the last refresh
				INSERT INTO	#Incremental
							(IsSCR
							,SrcSys
							,Src_UID)
				SELECT		mc_minor.IsSCR AS IsSCR
							,mc_minor.SrcSys AS SrcSys
							,mc_minor.Src_UID AS Src_UID
				FROM		(SELECT		mc_inner.SrcSys_Major
										,mc_inner.Src_UID_Major
							FROM		#Incremental inc_inner
							INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc_inner
																							ON	inc_inner.SrcSys = mc_inner.SrcSys
																							AND	inc_inner.Src_UID = mc_inner.Src_UID
							GROUP BY	mc_inner.SrcSys_Major
										,mc_inner.Src_UID_Major
										) mc_major
				INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc_minor
																	ON	mc_major.SrcSys_Major = mc_minor.SrcSys_Major
																	AND	mc_Major.Src_UID_Major = mc_minor.Src_UID_Major
				LEFT JOIN	#Incremental inc
											ON	mc_minor.SrcSys = inc.SrcSys
											AND	mc_minor.Src_UID = inc.Src_UID
				WHERE		inc.SrcSys IS NULL
				GROUP BY	mc_minor.IsSCR
							,mc_minor.SrcSys
							,mc_minor.Src_UID
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
				FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc_major
				LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc_minor
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

		-- Create #tblMAIN_REFERRALS_Match_EntityPairs_All to be the same as the final target Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_All table
		IF OBJECT_ID('tempdb..#tblMAIN_REFERRALS_Match_EntityPairs_All') IS NOT NULL DROP TABLE #tblMAIN_REFERRALS_Match_EntityPairs_All
		CREATE TABLE	#tblMAIN_REFERRALS_Match_EntityPairs_All
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
		
		-- Populate #tblMAIN_REFERRALS_Match_EntityPairs_All with existing data if requested
		IF @UseExistingMatches = 1
		BEGIN

				SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
				SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'existing matches'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

				-- Insert the previously found entity pairs that relate to the A records in the incremental table
				INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All
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
				INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_All ep_a
											ON	(inc.SrcSys = ep_a.SrcSys_A
											AND	inc.Src_UID = ep_a.Src_UID_A)

				-- Insert the previously found entity pairs that relate to the B records in the incremental table
				INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All
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
				INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_All ep_a
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
				FROM		#tblMAIN_REFERRALS_Match_EntityPairs_All
				
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
				FROM		#tblMAIN_REFERRALS_Match_EntityPairs_All ep_a
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
				FROM		#tblMAIN_REFERRALS_Match_EntityPairs_All ep_a
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
				/*****************************************************************************************************************************************************************************************************************************************************************************************/
				-- Iterate through the matching process to peform a match on the desired combinations of columns for every record in #Incremental and every child match therein
				/*****************************************************************************************************************************************************************************************************************************************************************************************/

				-- DECLARE	@CurrentUser VARCHAR(255),@ProcIdName VARCHAR(255),@CurrentSection VARCHAR(255),@CurrentDttm DATETIME2,@LoopCounter SMALLINT = 1,@SQL VARCHAR(MAX),@Guid VARCHAR(255),@UseExistingMatches BIT = 0	SELECT	@CurrentUser = CURRENT_USER, @ProcIdName = ISNULL(OBJECT_NAME(@@PROCID), 'ad hoc'), @Guid = CAST(NEWID() AS VARCHAR(255))
				-- Set up the match variables that will tell us what columns to match and how
				DECLARE	@MatchType TINYINT
						,@MatchIntention VARCHAR(255)
						,@NoFurtherMatchesFound BIT = 0
						
						,@Srcsys TINYINT
						,@Not_Srcsys TINYINT
						,@Not_linkedCareID TINYINT
						,@PatientPathwayID TINYINT
						,@HospitalNumber TINYINT
						,@NHSNumber TINYINT
						,@L_CANCER_SITE TINYINT
						,@N2_4_PRIORITY_TYPE TINYINT
						,@N2_6_RECEIPT_DATE TINYINT
						,@N2_5_DECISION_DATE TINYINT
						,@ADT_REF_ID_SameSys TINYINT
						,@ADT_PLACER_ID_SameSys TINYINT
						,@N2_1_REFERRAL_SOURCE TINYINT
						,@N2_12_CANCER_TYPE TINYINT
						,@N2_13_CANCER_STATUS TINYINT
						,@N2_9_FIRST_SEEN_DATE TINYINT
						,@N1_3_ORG_CODE_SEEN TINYINT
						,@L_OTHER_DIAG_DATE TINYINT
						,@N_UPGRADE_DATE TINYINT
						,@N_UPGRADE_ORG_CODE TINYINT
						,@N4_1_DIAGNOSIS_DATE TINYINT
						,@L_DIAGNOSIS TINYINT
						,@L_ORG_CODE_DIAGNOSIS TINYINT
						,@N4_2_DIAGNOSIS_CODE TINYINT
						,@N4_3_LATERALITY TINYINT
						,@L_PT_INFORMED_DATE TINYINT
						,@FasterDiagnosisOrganisationCode TINYINT
						,@FasterDiagnosisExclusionReasonCode TINYINT
						,@NotRecurrence TINYINT
						,@ADT_REF_ID TINYINT
						,@ADT_PLACER_ID TINYINT
				
				WHILE @NoFurtherMatchesFound = 0
				BEGIN
		
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Incremental subset'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

						-- Create a subset of tblMAIN_REFERRALS_vw_UH that is to be used for matching to the full dataset of tblMAIN_REFERRALS_vw_UH
						IF OBJECT_ID('tempdb..#tblMAIN_REFERRALS_Incremental') IS NOT NULL DROP TABLE #tblMAIN_REFERRALS_Incremental 
						SELECT		uh.IsSCR
									,uh.SrcSys
									,uh.Src_UID
									,uh.linkedcareID
									,uh.PatientPathwayID
									,uh.HospitalNumber
									,uh.NHSNumber
									,uh.L_CANCER_SITE
									,uh.N2_4_PRIORITY_TYPE
									,uh.N2_6_RECEIPT_DATE
									,uh.N2_5_DECISION_DATE
									,uh.ADT_REF_ID_SameSys
									,uh.ADT_PLACER_ID_SameSys
									,uh.N2_1_REFERRAL_SOURCE
									,uh.N2_12_CANCER_TYPE
									,uh.N2_13_CANCER_STATUS
									,uh.N2_9_FIRST_SEEN_DATE
									,uh.N1_3_ORG_CODE_SEEN
									,uh.L_OTHER_DIAG_DATE
									,uh.N_UPGRADE_DATE
									,uh.N_UPGRADE_ORG_CODE
									,uh.N4_1_DIAGNOSIS_DATE
									,uh.L_DIAGNOSIS
									,uh.L_ORG_CODE_DIAGNOSIS
									,uh.N4_2_DIAGNOSIS_CODE
									,uh.N4_3_LATERALITY
									,uh.L_PT_INFORMED_DATE
									,uh.FasterDiagnosisOrganisationCode
									,uh.FasterDiagnosisExclusionReasonCode
									,uh.NotRecurrence 
									,uh.ADT_REF_ID
									,uh.ADT_PLACER_ID
						INTO		#tblMAIN_REFERRALS_Incremental
						FROM		Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
						INNER JOIN	#Incremental inc 
													ON	uh.SrcSys = inc.SrcSys 
													AND	uh.Src_UID = inc.Src_UID 
													AND	inc.ProcessIx IS NULL 

						-- Index the #tblMAIN_REFERRALS_Incremental table	
						SET @SQL =	'CREATE UNIQUE CLUSTERED INDEX [PK_tblMAIN_REFERRALS_Incremental_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (SrcSys ASC, Src_UID ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_IsSCR_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (IsSCR ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_linkedcareID_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (linkedcareID ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_PatientPathwayID_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (PatientPathwayID ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_HospitalNumber_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (HospitalNumber ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_NHSNumber_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (NHSNumber ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_L_CANCER_SITE_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (L_CANCER_SITE ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_N2_4_PRIORITY_TYPE_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (N2_4_PRIORITY_TYPE ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_N2_6_RECEIPT_DATE_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (N2_6_RECEIPT_DATE ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_N2_5_DECISION_DATE_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (N2_5_DECISION_DATE ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_ADT_REF_ID_SameSys_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (ADT_REF_ID_SameSys ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_ADT_PLACER_ID_SameSys_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (ADT_PLACER_ID_SameSys ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_N2_1_REFERRAL_SOURCE_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (N2_1_REFERRAL_SOURCE ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_N2_12_CANCER_TYPE_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (N2_12_CANCER_TYPE ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_N2_13_CANCER_STATUS_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (N2_13_CANCER_STATUS ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_N2_9_FIRST_SEEN_DATE_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (N2_9_FIRST_SEEN_DATE ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_N1_3_ORG_CODE_SEEN_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (N1_3_ORG_CODE_SEEN ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_L_OTHER_DIAG_DATE_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (L_OTHER_DIAG_DATE ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_N_UPGRADE_DATE_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (N_UPGRADE_DATE ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_N_UPGRADE_ORG_CODE_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (N_UPGRADE_ORG_CODE ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_N4_1_DIAGNOSIS_DATE_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (N4_1_DIAGNOSIS_DATE ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_L_DIAGNOSIS_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (L_DIAGNOSIS ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_L_ORG_CODE_DIAGNOSIS_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (L_ORG_CODE_DIAGNOSIS ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_N4_2_DIAGNOSIS_CODE_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (N4_2_DIAGNOSIS_CODE ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_N4_3_LATERALITY_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (N4_3_LATERALITY ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_L_PT_INFORMED_DATE_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (L_PT_INFORMED_DATE ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_FasterDiagnosisOrganisationCode_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (FasterDiagnosisOrganisationCode ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_FasterDiagnosisExclusionReasonCode_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (FasterDiagnosisExclusionReasonCode ASC) ' + CHAR(13) +
									'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Incremental_NotRecurrence_' + @Guid + '] ON #tblMAIN_REFERRALS_Incremental (NotRecurrence ASC) '

						EXEC (@SQL)
				
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 1'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
		
						/* Match type 1 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL, @Not_Srcsys = NULL, @Not_linkedcareID = NULL, @PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL, @L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Algorithmic'
								,@MatchType = 1
								-- Only set the variables for columns you want to match
								,@NHSNumber				= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('NHSNumber',1,NULL,NULL)
								,@L_CANCER_SITE			= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('L_CANCER_SITE',1,NULL,NULL)
								,@N2_4_PRIORITY_TYPE	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_4_PRIORITY_TYPE',1,NULL,NULL)
								,@N2_6_RECEIPT_DATE		= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_6_RECEIPT_DATE',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/
				
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 2'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 2 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Algorithmic'
								,@MatchType = 2
								-- Only set the variables for columns you want to match
								,@HospitalNumber		= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('HospitalNumber',1,NULL,NULL)
								,@L_CANCER_SITE			= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('L_CANCER_SITE',1,NULL,NULL)
								,@N2_4_PRIORITY_TYPE	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_4_PRIORITY_TYPE',1,NULL,NULL)
								,@N2_6_RECEIPT_DATE		= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_6_RECEIPT_DATE',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/
				
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 3'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 3 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Algorithmic'
								,@MatchType = 3
								-- Only set the variables for columns you want to match
								,@PatientPathwayID		= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('PatientPathwayID',1,NULL,NULL)
								,@L_CANCER_SITE			= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('L_CANCER_SITE',1,NULL,NULL)
								,@N2_6_RECEIPT_DATE		= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_6_RECEIPT_DATE',1,NULL,NULL)
								,@N2_9_FIRST_SEEN_DATE	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_9_FIRST_SEEN_DATE',1,NULL,NULL)
								,@N1_3_ORG_CODE_SEEN	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N1_3_ORG_CODE_SEEN',1,NULL,NULL)
								,@N_UPGRADE_DATE		= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N_UPGRADE_DATE',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/

/*Match type 4 removed and changed				
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 4'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
	
	

						/* Match type 4 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL, @Not_Srcsys = NULL,@Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL,         ,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 4
								-- Only set the variables for columns you want to match
								,@PatientPathwayID	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('PatientPathwayID',1,NULL,NULL)
								,@Not_linkedCareID =  Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('LinkedcareID',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/
	*/			
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 5'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
	
	
						/* Match type 5 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Algorithmic'
								,@MatchType = 5
								-- Only set the variables for columns you want to match
								,@ADT_REF_ID_SameSys	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('ADT_REF_ID_SameSys',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/
				
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 6'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 6 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 6
								-- Only set the variables for columns you want to match
								,@ADT_PLACER_ID_SameSys	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('ADT_PLACER_ID_SameSys',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/
				
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 7'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 7 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 7
								-- Only set the variables for columns you want to match
								,@HospitalNumber		= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('HospitalNumber',1,NULL,NULL)
								,@N2_9_FIRST_SEEN_DATE	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_9_FIRST_SEEN_DATE',1,NULL,NULL)
								,@N4_1_DIAGNOSIS_DATE	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N4_1_DIAGNOSIS_DATE',1,NULL,NULL)
								,@L_ORG_CODE_DIAGNOSIS	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('L_ORG_CODE_DIAGNOSIS',1,NULL,NULL)
								,@N4_2_DIAGNOSIS_CODE	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N4_2_DIAGNOSIS_CODE',1,NULL,NULL)
								,@N4_3_LATERALITY		= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N4_3_LATERALITY',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/
				
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 8'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 8 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 8
								-- Only set the variables for columns you want to match
								,@NHSNumber				= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('NHSNumber',1,NULL,NULL)
								,@N2_9_FIRST_SEEN_DATE	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_9_FIRST_SEEN_DATE',1,NULL,NULL)
								,@N4_1_DIAGNOSIS_DATE	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N4_1_DIAGNOSIS_DATE',1,NULL,NULL)
								,@L_ORG_CODE_DIAGNOSIS	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('L_ORG_CODE_DIAGNOSIS',1,NULL,NULL)
								,@N4_2_DIAGNOSIS_CODE	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N4_2_DIAGNOSIS_CODE',1,NULL,NULL)
								,@N4_3_LATERALITY		= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N4_3_LATERALITY',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/
				
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 9'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 9 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 9
								-- Only set the variables for columns you want to match
								,@L_CANCER_SITE						= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('L_CANCER_SITE',1,NULL,NULL)
								,@HospitalNumber					= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('HospitalNumber',1,NULL,NULL)
								,@L_PT_INFORMED_DATE				= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('L_PT_INFORMED_DATE',1,NULL,NULL)
								,@FasterDiagnosisOrganisationCode		= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('FasterDiagnosisOrganisationCode',1,NULL,NULL)
								,@FasterDiagnosisExclusionReasonCode	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('FasterDiagnosisExclusionReasonCode',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/
				
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 10'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 10 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 10
								-- Only set the variables for columns you want to match
								,@L_CANCER_SITE						= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('L_CANCER_SITE',1,NULL,NULL)
								,@NHSNumber							= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('NHSNumber',1,NULL,NULL)
								,@L_PT_INFORMED_DATE				= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('L_PT_INFORMED_DATE',1,NULL,NULL)
								,@FasterDiagnosisOrganisationCode		= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('FasterDiagnosisOrganisationCode',1,NULL,NULL)
								,@FasterDiagnosisExclusionReasonCode	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('FasterDiagnosisExclusionReasonCode',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/
				
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 11'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 11 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 11
								-- Only set the variables for columns you want to match
								,@HospitalNumber					= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('HospitalNumber',1,NULL,NULL)
								,@L_CANCER_SITE						= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('L_CANCER_SITE',1,NULL,NULL)
								,@N2_1_REFERRAL_SOURCE				= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_1_REFERRAL_SOURCE',1,NULL,NULL)
								,@N2_5_DECISION_DATE				= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_5_DECISION_DATE',1,NULL,NULL)
								,@Not_Srcsys	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('SrcSys',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/
				
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 12'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 12 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 12
								-- Only set the variables for columns you want to match
								,@NHSNumber							= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('NHSNumber',1,NULL,NULL)
								,@L_CANCER_SITE						= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('L_CANCER_SITE',1,NULL,NULL)
								,@N2_1_REFERRAL_SOURCE				= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_1_REFERRAL_SOURCE',1,NULL,NULL)
								,@N2_5_DECISION_DATE				= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_5_DECISION_DATE',1,NULL,NULL)
								,@Not_Srcsys	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('SrcSys',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						--/*########################################################################################################################################################################################################################*/
				
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 13'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 13 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 13
								-- Only set the variables for columns you want to match
								,@PatientPathwayID	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('PatientPathwayID',1,NULL,NULL)
								,@Not_linkedCareID =  Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('LinkedcareID',1,NULL,NULL)
								,@NHSNumber = Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('NHSNumber',1,NULL,NULL)
								,@Not_Srcsys	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('SrcSys',1,NULL,NULL)
								,@NotRecurrence = Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('NotRecurrence',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/
				
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 14'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 14 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 14
								-- Only set the variables for columns you want to match
								,@PatientPathwayID	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('PatientPathwayID',1,NULL,NULL)
								,@Not_linkedCareID =  Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('LinkedcareID',1,NULL,NULL)
								,@HospitalNumber	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('HospitalNumber',1,NULL,NULL)
								,@Not_Srcsys	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('SrcSys',1,NULL,NULL)
								,@NotRecurrence = Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('NotRecurrence',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						----/*########################################################################################################################################################################################################################*/
				
						--SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						--SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 15'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						--/* Match type 15 ##########################################################################################################################################################################################################*/

						---- Refresh the match variables and set the columns we want to match
						--SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
						--		,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
						--		,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
						--		,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL,         ,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						--SELECT	-- Required variables
						--		@MatchIntention = 'Validation'
						--		,@MatchType = 15
						--		-- Only set the variables for columns you want to match
						--		,@PatientPathwayID	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('PatientPathwayID',1,NULL,NULL)
						--		,@Not_linkedCareID =  Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('LinkedcareID',1,NULL,NULL)
						--		,@NHSNumber = Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('NHSNumber',1,NULL,NULL)
						--		,@L_CANCER_SITE			= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('L_CANCER_SITE',1,NULL,NULL)
						--		,@N2_4_PRIORITY_TYPE	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_4_PRIORITY_TYPE',1,NULL,NULL)
						--		,@N2_6_RECEIPT_DATE		= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_6_RECEIPT_DATE',1,NULL,NULL)
						--		,@Srcsys	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('SrcSys',1,NULL,NULL)

						--SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
						--														'			,A.SrcSys ' + CHAR(13) +
						--														'			,A.Src_UID ' + CHAR(13) +
						--														'			,B.IsSCR ' + CHAR(13) +
						--														'			,B.SrcSys ' + CHAR(13) +
						--														'			,B.Src_UID ' + CHAR(13) +
						--														'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
						--														'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
						--														'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
						--														'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
						--														'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						--CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						--CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						--CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						--CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						--CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						--CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						--CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						--CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
						--														'WHERE		1 = 1 ' + CHAR(13) +
						--CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						--CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						---- Debug dynamic SQL
						--PRINT @SQL
		
						---- Find all the matching entity pairs
						----IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						--INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						--EXEC (@SQL)
				
						----/*########################################################################################################################################################################################################################*/
				
						--SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						--SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 16'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						--/* Match type 16 ##########################################################################################################################################################################################################*/

						---- Refresh the match variables and set the columns we want to match
						--SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
						--		,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
						--		,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
						--		,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL,         ,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						--SELECT	-- Required variables
						--		@MatchIntention = 'Validation'
						--		,@MatchType = 16
						--		-- Only set the variables for columns you want to match
						--		,@PatientPathwayID	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('PatientPathwayID',1,NULL,NULL)
						--		,@Not_linkedCareID =  Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('LinkedcareID',1,NULL,NULL)
						--		,@HospitalNumber	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('HospitalNumber',1,NULL,NULL)
						--		,@L_CANCER_SITE			= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('L_CANCER_SITE',1,NULL,NULL)
						--		,@N2_4_PRIORITY_TYPE	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_4_PRIORITY_TYPE',1,NULL,NULL)
						--		,@N2_6_RECEIPT_DATE		= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N2_6_RECEIPT_DATE',1,NULL,NULL)
						--		,@Srcsys	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('SrcSys',1,NULL,NULL)

						--SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
						--														'			,A.SrcSys ' + CHAR(13) +
						--														'			,A.Src_UID ' + CHAR(13) +
						--														'			,B.IsSCR ' + CHAR(13) +
						--														'			,B.SrcSys ' + CHAR(13) +
						--														'			,B.Src_UID ' + CHAR(13) +
						--														'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
						--														'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
						--														'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
						--														'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
						--														'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						--CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						--CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						--CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						--CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						--CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						--CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						--CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						--CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
						--														'WHERE		1 = 1 ' + CHAR(13) +
						--CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						--CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						---- Debug dynamic SQL
						--PRINT @SQL
		
						---- Find all the matching entity pairs
						----IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						--INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						--EXEC (@SQL)
				
						----/*########################################################################################################################################################################################################################*/
				
						--SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						--SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 17'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						--/* Match type 17 ##########################################################################################################################################################################################################*/

						---- Refresh the match variables and set the columns we want to match
						--SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
						--		,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
						--		,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
						--		,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL,         ,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						--SELECT	-- Required variables
						--		@MatchIntention = 'Validation'
						--		,@MatchType = 17
						--		-- Only set the variables for columns you want to match
						--		,@PatientPathwayID	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('PatientPathwayID',1,NULL,NULL)
						--		,@Not_linkedCareID =  Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('LinkedcareID',1,NULL,NULL)
						--		,@NHSNumber = Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('NHSNumber',1,NULL,NULL)
						--		,@L_CANCER_SITE			= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('L_CANCER_SITE',1,NULL,NULL)
						--		,@N4_2_DIAGNOSIS_CODE			= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N4_2_DIAGNOSIS_CODE',1,NULL,NULL)
						--		,@N4_3_LATERALITY			= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N4_3_LATERALITY',1,NULL,NULL)
						--		,@N4_1_DIAGNOSIS_DATE			= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N4_1_DIAGNOSIS_DATE',1,NULL,NULL)
						--		,@Srcsys	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('SrcSys',1,NULL,NULL)

						--SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
						--														'			,A.SrcSys ' + CHAR(13) +
						--														'			,A.Src_UID ' + CHAR(13) +
						--														'			,B.IsSCR ' + CHAR(13) +
						--														'			,B.SrcSys ' + CHAR(13) +
						--														'			,B.Src_UID ' + CHAR(13) +
						--														'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
						--														'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
						--														'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
						--														'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
						--														'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						--CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						--CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						--CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						--CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						--CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						--CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						--CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						--CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
						--														'WHERE		1 = 1 ' + CHAR(13) +
						--CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						--CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						---- Debug dynamic SQL
						--PRINT @SQL
		
						---- Find all the matching entity pairs
						----IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						--INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						--EXEC (@SQL)
				
						----/*########################################################################################################################################################################################################################*/
				
						--SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						--SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 18'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						--/* Match type 18 ##########################################################################################################################################################################################################*/

						---- Refresh the match variables and set the columns we want to match
						--SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
						--		,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
						--		,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
						--		,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL,         ,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						--SELECT	-- Required variables
						--		@MatchIntention = 'Validation'
						--		,@MatchType = 18
						--		-- Only set the variables for columns you want to match
						--		,@PatientPathwayID	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('PatientPathwayID',1,NULL,NULL)
						--		,@Not_linkedCareID =  Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('LinkedcareID',1,NULL,NULL)
						--		,@HospitalNumber	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('HospitalNumber',1,NULL,NULL)
						--		,@L_CANCER_SITE			= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('L_CANCER_SITE',1,NULL,NULL)
						--		,@N4_2_DIAGNOSIS_CODE			= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N4_2_DIAGNOSIS_CODE',1,NULL,NULL)
						--		,@N4_3_LATERALITY			= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N4_3_LATERALITY',1,NULL,NULL)
						--		,@N4_1_DIAGNOSIS_DATE			= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('N4_1_DIAGNOSIS_DATE',1,NULL,NULL)
						--		,@Srcsys	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('SrcSys',1,NULL,NULL)

						--SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
						--														'			,A.SrcSys ' + CHAR(13) +
						--														'			,A.Src_UID ' + CHAR(13) +
						--														'			,B.IsSCR ' + CHAR(13) +
						--														'			,B.SrcSys ' + CHAR(13) +
						--														'			,B.Src_UID ' + CHAR(13) +
						--														'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
						--														'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
						--														'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
						--														'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
						--														'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						--CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						--CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						--CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						--CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						--CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						--CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						--CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						--CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
						--														'WHERE		1 = 1 ' + CHAR(13) +
						--CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						--CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						--CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						--CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						---- Debug dynamic SQL
						--PRINT @SQL
		
						---- Find all the matching entity pairs
						----IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						--INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						--EXEC (@SQL)
							
				
				
				
						/*########################################################################################################################################################################################################################*/

						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 19'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
	
	
						/* Match type 19 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Algorithmic'
								,@MatchType = 19
								-- Only set the variables for columns you want to match
								,@ADT_REF_ID	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('ADT_REF_ID',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/
				
				
						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Match 20'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
				
						/* Match type 20 ##########################################################################################################################################################################################################*/

						-- Refresh the match variables and set the columns we want to match
						SELECT	@Srcsys = NULL,@Not_Srcsys = NULL, @Not_linkedcareID = NULL,@PatientPathwayID = NULL,@HospitalNumber = NULL,@NHSNumber = NULL,@L_CANCER_SITE = NULL,@N2_4_PRIORITY_TYPE = NULL,@N2_6_RECEIPT_DATE = NULL,@ADT_REF_ID_SameSys = NULL,@ADT_PLACER_ID_SameSys = NULL
								,@N2_1_REFERRAL_SOURCE = NULL,@N2_12_CANCER_TYPE = NULL,@N2_13_CANCER_STATUS = NULL,@N2_9_FIRST_SEEN_DATE = NULL,@N1_3_ORG_CODE_SEEN = NULL,@L_OTHER_DIAG_DATE = NULL,@N_UPGRADE_DATE = NULL
								,@N_UPGRADE_ORG_CODE = NULL,@N4_1_DIAGNOSIS_DATE = NULL,@L_DIAGNOSIS = NULL,@L_ORG_CODE_DIAGNOSIS = NULL,@N4_2_DIAGNOSIS_CODE = NULL, @N4_3_LATERALITY = NULL,@L_PT_INFORMED_DATE = NULL,@FasterDiagnosisOrganisationCode = NULL
								,@FasterDiagnosisExclusionReasonCode = NULL, @N2_5_DECISION_DATE = NULL, @NotRecurrence = NULL, @ADT_REF_ID = NULL, @ADT_PLACER_ID = NULL

						SELECT	-- Required variables
								@MatchIntention = 'Validation'
								,@MatchType = 20
								-- Only set the variables for columns you want to match
								,@ADT_PLACER_ID	= Merge_DM_Match.tblMAIN_REFERRALS_fnCompare('ADT_PLACER_ID',1,NULL,NULL)

						SET @SQL =												'SELECT		A.IsSCR ' + CHAR(13) +
																				'			,A.SrcSys ' + CHAR(13) +
																				'			,A.Src_UID ' + CHAR(13) +
																				'			,B.IsSCR ' + CHAR(13) +
																				'			,B.SrcSys ' + CHAR(13) +
																				'			,B.Src_UID ' + CHAR(13) +
																				'			,' + CAST(@MatchType AS VARCHAR(255)) + ' AS MatchType ' + CHAR(13) +
																				'			,''' + @MatchIntention + ''' AS MatchType ' + CHAR(13) +
																				'FROM		#tblMAIN_REFERRALS_Incremental A ' + CHAR(13) +
																				'INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH B ' + CHAR(13) +
																				'									ON	CONCAT(CAST(1 - A.IsSCR AS VARCHAR(255)), ''|'', CAST(A.SrcSys AS VARCHAR(255)), ''|'', A.Src_UID) != CONCAT(CAST(1 - B.IsSCR AS VARCHAR(255)), ''|'', CAST(B.SrcSys AS VARCHAR(255)), ''|'', B.Src_UID) ' + -- Don't self join
						CASE WHEN @LoopCounter > 1 THEN							'									AND	B.IsSCR = 0 ' + CHAR(13) ELSE '' END + -- the first iteration will find all relationships with new / updated SCR records as they are fed into match control / #incremental - all subsequent loops are about consequent relationships between non-SCR systems as they may not already be in match control
						CASE WHEN @Not_Srcsys = 1 THEN							'                                   AND	A.Srcsys != B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Srcsys = 1 THEN								'                                   AND	A.Srcsys = B.Srcsys ' + CHAR(13) ELSE '' END +  
						CASE WHEN @Not_linkedcareID = 1 THEN					'									AND	A.linkedCareID != B.linkedCareID ' + CHAR(13) ELSE '' END +
						CASE WHEN @PatientPathwayID = 1 THEN					'									AND	A.PatientPathwayID = B.PatientPathwayID ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber = 1	THEN					'									AND	A.HospitalNumber = B.HospitalNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @NHSNumber = 1	THEN						'									AND	A.NHSNumber = B.NHSNumber ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE = 1 THEN						'									AND	A.L_CANCER_SITE = B.L_CANCER_SITE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE = 1	THEN				'									AND	A.N2_4_PRIORITY_TYPE = B.N2_4_PRIORITY_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_6_RECEIPT_DATE = 1	THEN				'									AND	A.N2_6_RECEIPT_DATE = B.N2_6_RECEIPT_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_5_DECISION_DATE = 1	THEN				'									AND	A.N2_5_DECISION_DATE = B.N2_5_DECISION_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys = 1 THEN					'									AND	A.ADT_REF_ID_SameSys = B.ADT_REF_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys = 1	THEN			'									AND	A.ADT_PLACER_ID_SameSys = B.ADT_PLACER_ID_SameSys ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_1_REFERRAL_SOURCE = 1	THEN				'									AND	A.N2_1_REFERRAL_SOURCE = B.N2_1_REFERRAL_SOURCE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE = 1 THEN					'									AND	A.N2_12_CANCER_TYPE = B.N2_12_CANCER_TYPE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS = 1	THEN				'									AND	A.N2_13_CANCER_STATUS = B.N2_13_CANCER_STATUS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_9_FIRST_SEEN_DATE = 1	THEN				'									AND	A.N2_9_FIRST_SEEN_DATE = B.N2_9_FIRST_SEEN_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN = 1 THEN					'									AND	A.N1_3_ORG_CODE_SEEN = B.N1_3_ORG_CODE_SEEN ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE = 1	THEN				'									AND	A.L_OTHER_DIAG_DATE = B.L_OTHER_DIAG_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_DATE = 1	THEN					'									AND	A.N_UPGRADE_DATE = B.N_UPGRADE_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE = 1 THEN					'									AND	A.N_UPGRADE_ORG_CODE = B.N_UPGRADE_ORG_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE = 1	THEN				'									AND	A.N4_1_DIAGNOSIS_DATE = B.N4_1_DIAGNOSIS_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_DIAGNOSIS = 1	THEN						'									AND	A.L_DIAGNOSIS = B.L_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS = 1 THEN				'									AND	A.L_ORG_CODE_DIAGNOSIS = B.L_ORG_CODE_DIAGNOSIS ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_2_DIAGNOSIS_CODE = 1	THEN				'									AND	A.N4_2_DIAGNOSIS_CODE = B.N4_2_DIAGNOSIS_CODE ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY = 1	THEN					'									AND	A.N4_3_LATERALITY = B.N4_3_LATERALITY ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_PT_INFORMED_DATE = 1	THEN				'									AND	A.L_PT_INFORMED_DATE = B.L_PT_INFORMED_DATE ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode = 1 THEN		'									AND	A.FasterDiagnosisOrganisationCode = B.FasterDiagnosisOrganisationCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode = 1 THEN	'									AND	A.FasterDiagnosisExclusionReasonCode = B.FasterDiagnosisExclusionReasonCode ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence = 1	THEN					'									AND	A.NotRecurrence = B.NotRecurrence ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID = 1	THEN						'									AND	A.ADT_REF_ID = B.ADT_REF_ID ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID = 1	THEN					'									AND	A.ADT_PLACER_ID = B.ADT_PLACER_ID ' + CHAR(13) ELSE '' END +
																				'WHERE		1 = 1 ' + CHAR(13) +
						CASE WHEN @Not_Srcsys >1 THEN							'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 0 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Srcsys >1 THEN								'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''Srcsys'', 0, A.Srcsys, B.Srcsys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @Not_linkedcareID > 1 THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''linkedCareID'', 0, A.linkedCareID, B.linkedCareID) = 0 ' + CHAR(13) ELSE '' END +						
						CASE WHEN @PatientPathwayID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''PatientPathwayID'', 0, A.PatientPathwayID, B.PatientPathwayID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @HospitalNumber > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''HospitalNumber'', 0, A.HospitalNumber, B.HospitalNumber) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @NHSNumber > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NHSNumber'', 0, A.NHSNumber, B.NHSNumber) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_CANCER_SITE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_CANCER_SITE'', 0, A.L_CANCER_SITE, B.L_CANCER_SITE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_4_PRIORITY_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_4_PRIORITY_TYPE'', 0, A.N2_4_PRIORITY_TYPE, B.N2_4_PRIORITY_TYPE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_6_RECEIPT_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_6_RECEIPT_DATE'', 0, A.N2_6_RECEIPT_DATE, B.N2_6_RECEIPT_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_5_DECISION_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_5_DECISION_DATE'', 0, A.N2_5_DECISION_DATE, B.N2_5_DECISION_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID_SameSys > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID_SameSys'', 0, A.ADT_REF_ID_SameSys, B.ADT_REF_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID_SameSys > 1	THEN			'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID_SameSys'', 0, A.ADT_PLACER_ID_SameSys, B.ADT_PLACER_ID_SameSys) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_1_REFERRAL_SOURCE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_1_REFERRAL_SOURCE'', 0, A.N2_1_REFERRAL_SOURCE, B.N2_1_REFERRAL_SOURCE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_12_CANCER_TYPE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_12_CANCER_TYPE'', 0, A.N2_12_CANCER_TYPE, B.N2_12_CANCER_TYPE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N2_13_CANCER_STATUS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_13_CANCER_STATUS'', 0, A.N2_13_CANCER_STATUS, B.N2_13_CANCER_STATUS) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N2_9_FIRST_SEEN_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N2_9_FIRST_SEEN_DATE'', 0, A.N2_9_FIRST_SEEN_DATE, B.N2_9_FIRST_SEEN_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N1_3_ORG_CODE_SEEN > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N1_3_ORG_CODE_SEEN'', 0, A.N1_3_ORG_CODE_SEEN, B.N1_3_ORG_CODE_SEEN) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_OTHER_DIAG_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_OTHER_DIAG_DATE'', 0, A.L_OTHER_DIAG_DATE, B.L_OTHER_DIAG_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N_UPGRADE_DATE > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_DATE'', 0, A.N_UPGRADE_DATE, B.N_UPGRADE_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N_UPGRADE_ORG_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N_UPGRADE_ORG_CODE'', 0, A.N_UPGRADE_ORG_CODE, B.N_UPGRADE_ORG_CODE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_1_DIAGNOSIS_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_1_DIAGNOSIS_DATE'', 0, A.N4_1_DIAGNOSIS_DATE, B.N4_1_DIAGNOSIS_DATE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_DIAGNOSIS > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_DIAGNOSIS'', 0, A.L_DIAGNOSIS, B.L_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @L_ORG_CODE_DIAGNOSIS > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_ORG_CODE_DIAGNOSIS'', 0, A.L_ORG_CODE_DIAGNOSIS, B.L_ORG_CODE_DIAGNOSIS) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @N4_3_LATERALITY > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_3_LATERALITY'', 0, A.N4_3_LATERALITY, B.N4_3_LATERALITY) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @N4_2_DIAGNOSIS_CODE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''N4_2_DIAGNOSIS_CODE'', 0, A.N4_2_DIAGNOSIS_CODE, B.N4_2_DIAGNOSIS_CODE) = 1 ' + CHAR(13) ELSE '' END + 
						CASE WHEN @L_PT_INFORMED_DATE > 1	THEN				'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''L_PT_INFORMED_DATE'', 0, A.L_PT_INFORMED_DATE, B.L_PT_INFORMED_DATE) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisOrganisationCode > 1	THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisOrganisationCode'', 0, A.FasterDiagnosisOrganisationCode, B.FasterDiagnosisOrganisationCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @FasterDiagnosisExclusionReasonCode > 1 THEN	'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''FasterDiagnosisExclusionReasonCode'', 0, A.FasterDiagnosisExclusionReasonCode, B.FasterDiagnosisExclusionReasonCode) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @NotRecurrence > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''NotRecurrence'', 0, A.NotRecurrence, B.NotRecurrence) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_REF_ID > 1	THEN						'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_REF_ID'', 0, A.ADT_REF_ID, B.ADT_REF_ID) = 1 ' + CHAR(13) ELSE '' END +
						CASE WHEN @ADT_PLACER_ID > 1	THEN					'AND		Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(''ADT_PLACER_ID'', 0, A.ADT_PLACER_ID, B.ADT_PLACER_ID) = 1 ' + CHAR(13) ELSE '' END

						-- Debug dynamic SQL
						PRINT @SQL
		
						-- Find all the matching entity pairs
						--IF @LoopCounter = 1 -- consider whether we only want to do high cost matches on the first iteration (to avoid doing lots of matching between non-SCR records)
						INSERT INTO	#tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A, SrcSys_A, Src_UID_A, IsSCR_B, SrcSys_B, Src_UID_B, MatchType, MatchIntention)
						EXEC (@SQL)
				
						/*########################################################################################################################################################################################################################*/
						/**************************************************************************************************************************************************************************************************************************/
						-- Post-match cleanup of #tblMAIN_REFERRALS_Match_EntityPairs_All and preparation of #Incremental for the next loop (if there is one)
						/**************************************************************************************************************************************************************************************************************************/

						SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
						SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Loop ' + CAST(@LoopCounter AS VARCHAR(255)) + ' - Finish match loop'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

					-- Mark all the incremental records as having been processed
						UPDATE		#Incremental
						SET			ProcessIx = (SELECT ISNULL(MAX(ProcessIx) + 1, 1) FROM #Incremental)
						WHERE		ProcessIx IS NULL
				
						-- Mark the matches from this loop as being finished but incomplete (i.e. 0) and record the iteration order
						UPDATE		#tblMAIN_REFERRALS_Match_EntityPairs_All
						SET			LoopFinished = 0
									,Iteration = (SELECT ISNULL(MAX(Iteration) + 1, 1) FROM #tblMAIN_REFERRALS_Match_EntityPairs_All)
						WHERE		LoopFinished IS NULL
				
						-- Remove any reverse pairs from this iteration 
						DELETE
						FROM		ReversePair
						FROM		#tblMAIN_REFERRALS_Match_EntityPairs_All ReversePair
						INNER JOIN	#tblMAIN_REFERRALS_Match_EntityPairs_All ForWardPair
																				ON	ReversePair.SrcSys_A = ForWardPair.SrcSys_B
																				AND	ReversePair.Src_UID_A = ForWardPair.Src_UID_B
																				AND	ReversePair.SrcSys_B = ForWardPair.SrcSys_A
																				AND	ReversePair.Src_UID_B = ForWardPair.Src_UID_A
						WHERE		CONCAT(CAST(1 - ReversePair.IsSCR_A AS VARCHAR(255)), '|', CAST(ReversePair.SrcSys_A AS VARCHAR(255)), '|', ReversePair.Src_UID_A) > CONCAT(CAST(1 - ReversePair.IsSCR_B AS VARCHAR(255)), '|', CAST(ReversePair.SrcSys_B AS VARCHAR(255)), '|', ReversePair.Src_UID_B)
				
						-- Remove any match pairs from this iteration that already existed in previous iterations
						DELETE
						FROM		ThisLoop
						FROM		#tblMAIN_REFERRALS_Match_EntityPairs_All ThisLoop
						INNER JOIN	#tblMAIN_REFERRALS_Match_EntityPairs_All PreviousLoops
																				ON	ThisLoop.SrcSys_A = PreviousLoops.SrcSys_A
																				AND	ThisLoop.Src_UID_A = PreviousLoops.Src_UID_A
																				AND	ThisLoop.SrcSys_B = PreviousLoops.SrcSys_B
																				AND	ThisLoop.Src_UID_B = PreviousLoops.Src_UID_B
																				AND	PreviousLoops.LoopFinished = 1
						WHERE		ThisLoop.LoopFinished = 0

						-- Check to see if there are any further child entities that can be searched for a further match
						IF (SELECT COUNT(*) FROM #tblMAIN_REFERRALS_Match_EntityPairs_All WHERE LoopFinished = 0) > 0 
						BEGIN
								-- Populate #Incremental table with any child entities that can be searched for a further match
								INSERT INTO #Incremental
											(IsSCR
											,SrcSys
											,Src_UID)
								SELECT		IsSCR_B
											,SrcSys_B
											,Src_UID_B
								FROM		#tblMAIN_REFERRALS_Match_EntityPairs_All
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
						UPDATE		#tblMAIN_REFERRALS_Match_EntityPairs_All
						SET			LoopFinished = 1
						WHERE		LoopFinished = 0

						-- Increment the loop
						SET @LoopCounter += 1

				-- Exit / restart the loop
				END

		-- End the update of the matches data (will end up in Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_All)
		END

		-- Create indexes on #tblMAIN_REFERRALS_Match_EntityPairs_All to improve late query performance	--		DECLARE	@SQL VARCHAR(MAX) ,@Guid VARCHAR(255), @CurrentUser VARCHAR(255), @ProcIdName VARCHAR(255), @CurrentSection VARCHAR(255), @CurrentDttm DATETIME2, @LoopCounter SMALLINT = 1 SELECT @Guid = CAST(NEWID() AS VARCHAR(255)), @CurrentUser = CURRENT_USER, @ProcIdName = ISNULL(OBJECT_NAME(@@PROCID), 'ad hoc')
		SET @SQL =	'CREATE UNIQUE CLUSTERED INDEX [PK_tblMAIN_REFERRALS_Match_EntityPairs_All_' + @Guid + '] ON #tblMAIN_REFERRALS_Match_EntityPairs_All (SrcSys_A ASC, Src_UID_A ASC, SrcSys_B ASC, Src_UID_B ASC, MatchType ASC, Iteration ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Match_EntityPairs_All_Src_UID_A_' + @Guid + '] ON #tblMAIN_REFERRALS_Match_EntityPairs_All (SrcSys_A ASC, Src_UID_A ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Match_EntityPairs_All_Src_UID_B_' + @Guid + '] ON #tblMAIN_REFERRALS_Match_EntityPairs_All (SrcSys_B ASC, Src_UID_B ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Match_EntityPairs_All_MatchType_' + @Guid + '] ON #tblMAIN_REFERRALS_Match_EntityPairs_All (MatchType ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Match_EntityPairs_All_Iteration_' + @Guid + '] ON #tblMAIN_REFERRALS_Match_EntityPairs_All (Iteration ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Match_EntityPairs_All_IsSCR_A_' + @Guid + '] ON #tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_A ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_Match_EntityPairs_All_IsSCR_B_' + @Guid + '] ON #tblMAIN_REFERRALS_Match_EntityPairs_All (IsSCR_B ASC) '
		EXEC (@SQL)
		
		/*****************************************************************************************************************************************************************************************************************************************************************************************/
		-- Prepare data for finding the major entity
		/*****************************************************************************************************************************************************************************************************************************************************************************************/

		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Prepare for find major'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

		-- Create the #FindMajor_Match_Control table to replace in the persistent tables
		IF OBJECT_ID('tempdb..#FindMajor_Match_Control') IS NOT NULL DROP TABLE #FindMajor_Match_Control
		SELECT		IDENTITY(INT,1,1) AS fmmcID
					,mc.SrcSys_Major AS SrcSys_Major_Pre
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
		INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
													ON	inc.SrcSys = mc.SrcSys
													AND	inc.Src_UID = mc.Src_UID
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv
														ON	mc.SrcSys_Major = mmv.SrcSys_Major
														AND	mc.Src_UID_Major = mmv.Src_UID_Major

		-- Add the records into #FindMajor_Match_Control table that aren't yet in Merge_DM_Match.tblMAIN_REFERRALS_Match_Control (i.e. external records not yet persisted)
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
					,uh.IsSCR
					,uh.SrcSys
					,uh.Src_UID
					,uh.HashBytesValue
					,GETDATE() AS ChangeLastDetected
					,CAST(NULL AS DATETIME2) AS LastProcessed_Pre
					,CAST(NULL AS DATETIME2) AS LastProcessed_Post
					,mmv.LastValidatedDttm
					,CAST(NULL AS DATETIME2) AS DeletedDttm
		FROM		#Incremental inc
		INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
												ON	inc.SrcSys = uh.SrcSys
												AND	inc.Src_UID = uh.Src_UID
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv
														ON	uh.SrcSys = mmv.SrcSys_Major
														AND	uh.Src_UID = mmv.Src_UID_Major
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
		SELECT		IDENTITY(INT, 1,1) AS fmm_epuID
					,CAST(NULL AS INT) AS fmmcID_A
					,CAST(NULL AS INT) AS fmmcID_B
					,ep_all_temp.IsScr_A
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
					FROM		#tblMAIN_REFERRALS_Match_EntityPairs_All ep_all_inner
					GROUP BY	ep_all_inner.IsScr_A
								,ep_all_inner.SrcSys_A
								,ep_all_inner.Src_UID_A
								,ep_all_inner.IsScr_B
								,ep_all_inner.SrcSys_B
								,ep_all_inner.Src_UID_B
								) ep_all_temp
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_Unique ep_u -- retrieve existing best intentions and unlink data captured through validation
																ON	ep_all_temp.SrcSys_A = ep_u.SrcSys_A
																AND	ep_all_temp.Src_UID_A = ep_u.Src_UID_A
																AND	ep_all_temp.SrcSys_B = ep_u.SrcSys_B
																AND	ep_all_temp.Src_UID_B = ep_u.Src_UID_B
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc_a
													ON	ep_all_temp.SrcSys_A = mc_a.SrcSys
													AND	ep_all_temp.Src_UID_A = mc_a.Src_UID
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv_a
														ON	mc_a.SrcSys = mmv_a.SrcSys_Major
														AND	mc_a.Src_UID = mmv_a.Src_UID_Major
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc_b
													ON	ep_all_temp.SrcSys_B = mc_b.SrcSys
													AND	ep_all_temp.Src_UID_B = mc_b.Src_UID
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv_b
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

		-- Update the "A" ID's from #FindMajor_Match_Control that represent each SrcSys / Src_UID combination
		UPDATE		ep_u
		SET			ep_u.fmmcID_A = mc_a.fmmcID
		FROM		#FindMajor_Match_EntityPairs_Unique ep_u
		INNER JOIN	#FindMajor_Match_Control mc_a
													ON	ep_u.SrcSys_A = mc_a.SrcSys
													AND	ep_u.Src_UID_A = mc_a.Src_UID

		-- Update the "B" ID's from #FindMajor_Match_Control that represent each SrcSys / Src_UID combination
		UPDATE		ep_u
		SET			ep_u.fmmcID_B = mc_b.fmmcID
		FROM		#FindMajor_Match_EntityPairs_Unique ep_u
		INNER JOIN	#FindMajor_Match_Control mc_b
													ON	ep_u.SrcSys_B = mc_b.SrcSys
													AND	ep_u.Src_UID_B = mc_b.Src_UID

		
		-- Create indexes on #FindMajor_Match_EntityPairs_Unique to improve performance	--		DECLARE	@SQL VARCHAR(MAX) ,@Guid VARCHAR(255), @CurrentUser VARCHAR(255), @ProcIdName VARCHAR(255), @CurrentSection VARCHAR(255), @CurrentDttm DATETIME2, @LoopCounter SMALLINT = 1 SELECT @Guid = CAST(NEWID() AS VARCHAR(255)), @CurrentUser = CURRENT_USER, @ProcIdName = ISNULL(OBJECT_NAME(@@PROCID), 'ad hoc')
		SET @SQL =	'CREATE UNIQUE CLUSTERED INDEX [PK_FindMajor_Match_EntityPairs_Unique_' + @Guid + '] ON #FindMajor_Match_EntityPairs_Unique (SrcSys_A ASC, Src_UID_A ASC, SrcSys_B ASC, Src_UID_B ASC) ' + CHAR(13) + 
					'CREATE NONCLUSTERED INDEX [Ix_FindMajor_Match_EntityPairs_Unique_fmm_epuID_' + @Guid + '] ON #FindMajor_Match_EntityPairs_Unique (fmm_epuID ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_FindMajor_Match_EntityPairs_Unique_fmmcID_' + @Guid + '] ON #FindMajor_Match_EntityPairs_Unique (fmmcID_A ASC, fmmcID_B ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_FindMajor_Match_EntityPairs_Unique_fmmcID_A_' + @Guid + '] ON #FindMajor_Match_EntityPairs_Unique (fmmcID_A ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_FindMajor_Match_EntityPairs_Unique_fmmcID_B_' + @Guid + '] ON #FindMajor_Match_EntityPairs_Unique (fmmcID_B ASC) ' + CHAR(13) +
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
						,fmmcID INT NOT NULL
						,PotentialMajorIx INT
						,IsSCR_PotentialMajor BIT NOT NULL
						,SrcSys_PotentialMajor TINYINT NOT NULL
						,Src_UID_PotentialMajor VARCHAR(255) NOT NULL
						,fmmcID_PotentialMajor INT NOT NULL
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
		
		--		DECLARE	@SQL VARCHAR(MAX) ,@Guid VARCHAR(255), @CurrentUser VARCHAR(255), @ProcIdName VARCHAR(255), @CurrentSection VARCHAR(255), @CurrentDttm DATETIME2, @LoopCounter SMALLINT = 1 SELECT @Guid = CAST(NEWID() AS VARCHAR(255)), @CurrentUser = CURRENT_USER, @ProcIdName = ISNULL(OBJECT_NAME(@@PROCID), 'ad hoc'), @CurrentSection = 'Adhoc start'

		-- Initialise the table of all related entity pairs with self-pairs
		INSERT INTO	#RelatedPairs
					(SrcSys
					,Src_UID
					,fmmcID
					,IsSCR_PotentialMajor
					,SrcSys_PotentialMajor
					,Src_UID_PotentialMajor
					,fmmcID_PotentialMajor
					,ChangeLastDetected_PotentialMajor
					,LastValidatedDttm_PotentialMajor
					,BestIntention
					,Iteration
					)
		SELECT		SrcSys								= SrcSys
					,Src_UID							= Src_UID
					,fmmcID								= fmmcID
					,IsSCR_PotentialMajor				= IsSCR
					,SrcSys_PotentialMajor				= SrcSys
					,Src_UID_PotentialMajor				= Src_UID
					,fmmcID_PotentialMajor				= fmmcID
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
					,fmmcID
					,IsSCR_PotentialMajor
					,SrcSys_PotentialMajor
					,Src_UID_PotentialMajor
					,fmmcID_PotentialMajor
					,ChangeLastDetected_PotentialMajor
					,LastValidatedDttm_PotentialMajor
					,BestIntention
					)
		SELECT		SrcSys								= ep_u.SrcSys_B
					,Src_UID							= ep_u.Src_UID_B
					,fmmcID								= ep_u.fmmcID_B
					,IsSCR_PotentialMajor				= ep_u.IsSCR_A
					,SrcSys_PotentialMajor				= ep_u.SrcSys_A
					,Src_UID_PotentialMajor				= ep_u.Src_UID_A
					,fmmcID_PotentialMajor				= ep_u.fmmcID_A
					,ChangeLastDetected_PotentialMajor	= ep_u.ChangeLastDetected_A
					,LastValidatedDttm_PotentialMajor	= ep_u.LastValidatedDttm_A
					,BestIntention						= ep_u.BestIntention_Post
		FROM		#FindMajor_Match_EntityPairs_Unique ep_u
		LEFT JOIN	#RelatedPairs rp
									ON	ep_u.fmmcID_B = rp.fmmcID
									AND	ep_u.fmmcID_A = rp.fmmcID_PotentialMajor
		WHERE		ep_u.UnlinkDttm_Pre IS NULL					-- Exclude entity pairs with an UnlinkDttm from the process
		AND			rp.SrcSys IS NULL							-- Don't add matches that we already have

		-- Add all UID pair matches from entity pairs unique table (with B as the potential major)
		INSERT INTO	#RelatedPairs
					(SrcSys
					,Src_UID
					,fmmcID
					,IsSCR_PotentialMajor
					,SrcSys_PotentialMajor
					,Src_UID_PotentialMajor
					,fmmcID_PotentialMajor
					,ChangeLastDetected_PotentialMajor
					,LastValidatedDttm_PotentialMajor
					,BestIntention
					)
		SELECT		SrcSys								= ep_u.SrcSys_A
					,Src_UID							= ep_u.Src_UID_A
					,fmmcID								= ep_u.fmmcID_A
					,IsSCR_PotentialMajor				= ep_u.IsSCR_B
					,SrcSys_PotentialMajor				= ep_u.SrcSys_B
					,Src_UID_PotentialMajor				= ep_u.Src_UID_B
					,fmmcID_PotentialMajor				= ep_u.fmmcID_B
					,ChangeLastDetected_PotentialMajor	= ep_u.ChangeLastDetected_B
					,LastValidatedDttm_PotentialMajor	= ep_u.LastValidatedDttm_B
					,BestIntention						= ep_u.BestIntention_Post
		FROM		#FindMajor_Match_EntityPairs_Unique ep_u
		LEFT JOIN	#RelatedPairs rp
									ON	ep_u.fmmcID_A = rp.fmmcID
									AND	ep_u.fmmcID_B = rp.fmmcID_PotentialMajor
		WHERE		ep_u.UnlinkDttm_Pre IS NULL					-- Exclude entity pairs with an UnlinkDttm from the process
		AND			rp.SrcSys IS NULL							-- Don't add matches that we already have

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
				IF OBJECT_ID('tempdb..#nthNearestPair_A') IS NOT NULL DROP TABLE #nthNearestPair_A
				SELECT		rp.RelatedPairsIx
							,ep_u.fmm_epuID
				INTO		#nthNearestPair_A
				FROM		#RelatedPairs rp
				INNER JOIN	#FindMajor_Match_EntityPairs_Unique ep_u
																	ON	rp.fmmcID_PotentialMajor = ep_u.fmmcID_B
																	AND	ep_u.UnlinkDttm_Pre IS NULL				-- Exclude entity pairs with an UnlinkDttm from the process
				LEFT JOIN	#RelatedPairs rp_alreadythere
											ON	rp.fmmcID = rp_alreadythere.fmmcID
											AND	ep_u.fmmcID_A = rp_alreadythere.fmmcID_PotentialMajor
				WHERE		rp.RelationsSearched = 0	-- relations that were found on the previous iteration
				AND			rp_alreadythere.fmmcID IS NULL

				-- Collate the full details into #RelatedPairs for nth nearest neighbour permutations that don't already exist (with RP UID as major and A as the minor) 
				INSERT INTO	#RelatedPairs
							(SrcSys
							,Src_UID
							,fmmcID
							,IsSCR_PotentialMajor
							,SrcSys_PotentialMajor
							,Src_UID_PotentialMajor
							,fmmcID_PotentialMajor
							,ChangeLastDetected_PotentialMajor
							,LastValidatedDttm_PotentialMajor
							,BestIntention
							)
				SELECT		SrcSys								= rp.SrcSys
							,Src_UID							= rp.Src_UID
							,fmmcID								= rp.fmmcID
							,IsSCR_PotentialMajor				= ep_u.IsSCR_A
							,SrcSys_PotentialMajor				= ep_u.SrcSys_A
							,Src_UID_PotentialMajor				= ep_u.Src_UID_A
							,fmmcID_PotentialMajor				= ep_u.fmmcID_A
							,ChangeLastDetected_PotentialMajor	= ep_u.ChangeLastDetected_A
							,LastValidatedDttm_PotentialMajor	= ep_u.LastValidatedDttm_A
							,BestIntention						= CASE WHEN rp.BestIntention = 'Scripted' AND ep_u.BestIntention_Post = 'Scripted' THEN 'Scripted' ELSE 'Manual' END
				FROM		#RelatedPairs rp
				INNER JOIN	#nthNearestPair_A nthNearestPair
														ON	rp.RelatedPairsIx = nthNearestPair.RelatedPairsIx
				INNER JOIN	#FindMajor_Match_EntityPairs_Unique ep_u
																	ON	nthNearestPair.fmm_epuID = ep_u.fmm_epuID

				-- Continue for another loop if there are more permutations found
				IF @@ROWCOUNT > 0
				SET @ConnectionsFound = ISNULL(@ConnectionsFound, 0) + 1

				-- Find the next nth nearest neighbour permutations (with RP UID as major and B as the minor)
				IF OBJECT_ID('tempdb..#nthNearestPair_B') IS NOT NULL DROP TABLE #nthNearestPair_B
				SELECT		rp.RelatedPairsIx
							,ep_u.fmm_epuID
				INTO		#nthNearestPair_B
				FROM		#RelatedPairs rp
				INNER JOIN	#FindMajor_Match_EntityPairs_Unique ep_u
																	ON	rp.fmmcID_PotentialMajor = ep_u.fmmcID_A
																	AND	ep_u.UnlinkDttm_Pre IS NULL				-- Exclude entity pairs with an UnlinkDttm from the process
				LEFT JOIN	#RelatedPairs rp_alreadythere
											ON	rp.fmmcID = rp_alreadythere.fmmcID
											AND	ep_u.fmmcID_B = rp_alreadythere.fmmcID_PotentialMajor
				WHERE		rp.RelationsSearched = 0	-- relations that were found on the previous iteration
				AND			rp_alreadythere.fmmcID IS NULL

				-- Collate the full details into #RelatedPairs for nth nearest neighbour permutations that don't already exist (with RP UID as major and B as the minor) 
				INSERT INTO	#RelatedPairs
							(SrcSys
							,Src_UID
							,fmmcID
							,IsSCR_PotentialMajor
							,SrcSys_PotentialMajor
							,Src_UID_PotentialMajor
							,fmmcID_PotentialMajor
							,ChangeLastDetected_PotentialMajor
							,LastValidatedDttm_PotentialMajor
							,BestIntention
							)
				SELECT		SrcSys								= rp.SrcSys
							,Src_UID							= rp.Src_UID
							,fmmcID								= rp.fmmcID
							,IsSCR_PotentialMajor				= ep_u.IsSCR_B
							,SrcSys_PotentialMajor				= ep_u.SrcSys_B
							,Src_UID_PotentialMajor				= ep_u.Src_UID_B
							,fmmcID_PotentialMajor				= ep_u.fmmcID_B
							,ChangeLastDetected_PotentialMajor	= ep_u.ChangeLastDetected_B
							,LastValidatedDttm_PotentialMajor	= ep_u.LastValidatedDttm_B
							,BestIntention						= CASE WHEN rp.BestIntention = 'Scripted' AND ep_u.BestIntention_Post = 'Scripted' THEN 'Scripted' ELSE 'Manual' END
				FROM		#RelatedPairs rp
				INNER JOIN	#nthNearestPair_B nthNearestPair
														ON	rp.RelatedPairsIx = nthNearestPair.RelatedPairsIx
				INNER JOIN	#FindMajor_Match_EntityPairs_Unique ep_u
																	ON	nthNearestPair.fmm_epuID = ep_u.fmm_epuID

				-- Continue for another loop if there are more permutations found
				IF @@ROWCOUNT > 0
				SET @ConnectionsFound = ISNULL(@ConnectionsFound, 0) + 1
				
				-- Find the next nth nearest neighbour permutations (with RP UID potential major as major and A as the minor)
				IF OBJECT_ID('tempdb..#nthNearestPair_AP') IS NOT NULL DROP TABLE #nthNearestPair_AP
				SELECT		rp.RelatedPairsIx
							,ep_u.fmm_epuID
				INTO		#nthNearestPair_AP
				FROM		#RelatedPairs rp
				INNER JOIN	#FindMajor_Match_EntityPairs_Unique ep_u
																	ON	rp.fmmcID_PotentialMajor = ep_u.fmmcID_B
																	AND	ep_u.UnlinkDttm_Pre IS NULL				-- Exclude entity pairs with an UnlinkDttm from the process
				LEFT JOIN	#RelatedPairs rp_alreadythere
											ON	rp.fmmcID_PotentialMajor = rp_alreadythere.fmmcID
											AND	ep_u.fmmcID_A = rp_alreadythere.fmmcID_PotentialMajor
				WHERE		rp.RelationsSearched = 0	-- relations that were found on the previous iteration
				AND			rp_alreadythere.fmmcID IS NULL

				-- Collate the full details into #RelatedPairs for nth nearest neighbour permutations that don't already exist (with RP UID as major and A as the minor) 
				INSERT INTO	#RelatedPairs
							(SrcSys
							,Src_UID
							,fmmcID
							,IsSCR_PotentialMajor
							,SrcSys_PotentialMajor
							,Src_UID_PotentialMajor
							,fmmcID_PotentialMajor
							,ChangeLastDetected_PotentialMajor
							,LastValidatedDttm_PotentialMajor
							,BestIntention
							)
				SELECT		SrcSys								= rp.SrcSys_PotentialMajor
							,Src_UID							= rp.Src_UID_PotentialMajor
							,fmmcID								= rp.fmmcID
							,IsSCR_PotentialMajor				= ep_u.IsSCR_A
							,SrcSys_PotentialMajor				= ep_u.SrcSys_A
							,Src_UID_PotentialMajor				= ep_u.Src_UID_A
							,fmmcID_PotentialMajor				= ep_u.fmmcID_A
							,ChangeLastDetected_PotentialMajor	= ep_u.ChangeLastDetected_A
							,LastValidatedDttm_PotentialMajor	= ep_u.LastValidatedDttm_A
							,BestIntention						= CASE WHEN rp.BestIntention = 'Scripted' AND ep_u.BestIntention_Post = 'Scripted' THEN 'Scripted' ELSE 'Manual' END
				FROM		#RelatedPairs rp
				INNER JOIN	#nthNearestPair_AP nthNearestPair
														ON	rp.RelatedPairsIx = nthNearestPair.RelatedPairsIx
				INNER JOIN	#FindMajor_Match_EntityPairs_Unique ep_u
																	ON	nthNearestPair.fmm_epuID = ep_u.fmm_epuID

				-- Continue for another loop if there are more permutations found
				IF @@ROWCOUNT > 0
				SET @ConnectionsFound = ISNULL(@ConnectionsFound, 0) + 1
				
				-- Find the next nth nearest neighbour permutations (with RP UID potential major as major and B as the minor)
				IF OBJECT_ID('tempdb..#nthNearestPair_BP') IS NOT NULL DROP TABLE #nthNearestPair_BP
				SELECT		rp.RelatedPairsIx
							,ep_u.fmm_epuID
				INTO		#nthNearestPair_BP
				FROM		#RelatedPairs rp
				INNER JOIN	#FindMajor_Match_EntityPairs_Unique ep_u
																	ON	rp.fmmcID_PotentialMajor = ep_u.fmmcID_A
																	AND	ep_u.UnlinkDttm_Pre IS NULL				-- Exclude entity pairs with an UnlinkDttm from the process
				LEFT JOIN	#RelatedPairs rp_alreadythere
											ON	rp.fmmcID_PotentialMajor = rp_alreadythere.fmmcID
											AND	ep_u.fmmcID_B = rp_alreadythere.fmmcID_PotentialMajor
				WHERE		rp.RelationsSearched = 0	-- relations that were found on the previous iteration
				AND			rp_alreadythere.fmmcID IS NULL

				-- Collate the full details into #RelatedPairs for nth nearest neighbour permutations that don't already exist (with RP UID as major and B as the minor) 
				INSERT INTO	#RelatedPairs
							(SrcSys
							,Src_UID
							,fmmcID
							,IsSCR_PotentialMajor
							,SrcSys_PotentialMajor
							,Src_UID_PotentialMajor
							,fmmcID_PotentialMajor
							,ChangeLastDetected_PotentialMajor
							,LastValidatedDttm_PotentialMajor
							,BestIntention
							)
				SELECT		SrcSys								= rp.SrcSys_PotentialMajor
							,Src_UID							= rp.Src_UID_PotentialMajor
							,fmmcID								= rp.fmmcID
							,IsSCR_PotentialMajor				= ep_u.IsSCR_B
							,SrcSys_PotentialMajor				= ep_u.SrcSys_B
							,Src_UID_PotentialMajor				= ep_u.Src_UID_B
							,fmmcID_PotentialMajor				= ep_u.fmmcID_B
							,ChangeLastDetected_PotentialMajor	= ep_u.ChangeLastDetected_B
							,LastValidatedDttm_PotentialMajor	= ep_u.LastValidatedDttm_B
							,BestIntention						= CASE WHEN rp.BestIntention = 'Scripted' AND ep_u.BestIntention_Post = 'Scripted' THEN 'Scripted' ELSE 'Manual' END
				FROM		#RelatedPairs rp
				INNER JOIN	#nthNearestPair_BP nthNearestPair
														ON	rp.RelatedPairsIx = nthNearestPair.RelatedPairsIx
				INNER JOIN	#FindMajor_Match_EntityPairs_Unique ep_u
																	ON	nthNearestPair.fmm_epuID = ep_u.fmm_epuID

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
					'CREATE NONCLUSTERED INDEX [Ix_RelatedPairs_fmmcIDs_' + @Guid + '] ON #RelatedPairs (fmmcID ASC, fmmcID_PotentialMajor ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_RelatedPairs_fmmcID_' + @Guid + '] ON #RelatedPairs (fmmcID ASC) ' + CHAR(13) +
					'CREATE NONCLUSTERED INDEX [Ix_RelatedPairs_fmmcID_PotentialMajor_' + @Guid + '] ON #RelatedPairs (fmmcID_PotentialMajor ASC) ' + CHAR(13) +
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
																	,CASE	WHEN	rp.SrcSys = 1
																			AND		uh.N1_3_ORG_CODE_SEEN IN ('RYR18','RYR16','RYR14','RYR07','RYR23')
																			THEN	1
																			WHEN	rp.SrcSys = 2
																			AND		LEFT(uh.N1_3_ORG_CODE_SEEN, 3) = 'RXH'
																			THEN	1
																			WHEN	rp.SrcSys = 2
																			AND		uh.N1_3_ORG_CODE_SEEN IN ('E0A3H','E0N1P')
																			THEN	1
																			ELSE	0
																			END DESC -- prioritise referrals where the site first seen belongs to the source system
																	,rp.ChangeLastDetected_PotentialMajor
																	,rp.SrcSys_PotentialMajor
																	,rp.Src_UID_PotentialMajor
																	) AS PotentialMajorIx
					FROM		#RelatedPairs rp
					LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv
																						ON	rp.SrcSys_PotentialMajor = mmv.SrcSys_Major
																						AND	rp.Src_UID_PotentialMajor = mmv.Src_UID_Major
																						AND	mmv.LastValidatedDttm IS NOT NULL
					LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																				ON	rp.SrcSys = uh.SrcSys
																				AND	rp.Src_UID = uh.Src_UID
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
		IF OBJECT_ID('tempdb..#tblMAIN_REFERRALS_Match_Control_Major_PrePost') IS NOT NULL DROP TABLE #tblMAIN_REFERRALS_Match_Control_Major_PrePost
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
		INTO		#tblMAIN_REFERRALS_Match_Control_Major_PrePost
		FROM		#FindMajor_Match_Control
		GROUP BY	SrcSys_Major_Pre
					,Src_UID_Major_Pre
					,SrcSys_Major_Post
					,Src_UID_Major_Post
		
		-- Create the #tblMAIN_REFERRALS_Match_MajorValidation table to replace in the persistent tables 
		IF OBJECT_ID('tempdb..#tblMAIN_REFERRALS_Match_MajorValidation') IS NOT NULL DROP TABLE #tblMAIN_REFERRALS_Match_MajorValidation
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
					,mmv.CARE_ID
					,mmv.PATIENT_ID
					,mmv.TEMP_ID
					,mmv.L_CANCER_SITE
					,mmv.N2_1_REFERRAL_SOURCE
					,mmv.N2_2_ORG_CODE_REF
					,mmv.N2_3_REFERRER_CODE
					,mmv.N2_4_PRIORITY_TYPE
					,mmv.N2_5_DECISION_DATE
					,mmv.N2_6_RECEIPT_DATE
					,mmv.N2_7_CONSULTANT
					,mmv.N2_8_SPECIALTY
					,mmv.N2_9_FIRST_SEEN_DATE
					,mmv.N1_3_ORG_CODE_SEEN
					,mmv.N2_10_FIRST_SEEN_DELAY
					,mmv.N2_12_CANCER_TYPE
					,mmv.N2_13_CANCER_STATUS
					,mmv.L_FIRST_APPOINTMENT
					,mmv.L_CANCELLED_DATE
					,mmv.N2_14_ADJ_TIME
					,mmv.N2_15_ADJ_REASON
					,mmv.L_REFERRAL_METHOD
					,mmv.N2_16_OP_REFERRAL
					,mmv.L_SPECIALIST_DATE
					,mmv.L_ORG_CODE_SPECIALIST
					,mmv.L_SPECIALIST_SEEN_DATE
					,mmv.N1_3_ORG_CODE_SPEC_SEEN
					,mmv.N_UPGRADE_DATE
					,mmv.N_UPGRADE_ORG_CODE
					,mmv.L_UPGRADE_WHEN
					,mmv.L_UPGRADE_WHO
					,mmv.N4_1_DIAGNOSIS_DATE
					,mmv.L_DIAGNOSIS
					,mmv.N4_2_DIAGNOSIS_CODE
					,mmv.L_ORG_CODE_DIAGNOSIS
					,mmv.L_PT_INFORMED_DATE
					,mmv.L_OTHER_DIAG_DATE
					,mmv.N4_3_LATERALITY
					,mmv.N4_4_BASIS_DIAGNOSIS
					,mmv.L_TOPOGRAPHY
					,mmv.L_HISTOLOGY_GROUP
					,mmv.N4_5_HISTOLOGY
					,mmv.N4_6_DIFFERENTIATION
					,mmv.ClinicalTStage
					,mmv.ClinicalTCertainty
					,mmv.ClinicalNStage
					,mmv.ClinicalNCertainty
					,mmv.ClinicalMStage
					,mmv.ClinicalMCertainty
					,mmv.ClinicalOverallCertainty
					,mmv.N6_9_SITE_CLASSIFICATION
					,mmv.PathologicalOverallCertainty
					,mmv.PathologicalTCertainty
					,mmv.PathologicalTStage
					,mmv.PathologicalNCertainty
					,mmv.PathologicalNStage
					,mmv.PathologicalMCertainty
					,mmv.PathologicalMStage
					,mmv.L_GP_INFORMED
					,mmv.L_GP_INFORMED_DATE
					,mmv.L_GP_NOT
					,mmv.L_REL_INFORMED
					,mmv.L_NURSE_PRESENT
					,mmv.L_SPEC_NURSE_DATE
					,mmv.L_SEEN_NURSE_DATE
					,mmv.N16_1_ADJ_DAYS
					,mmv.N16_2_ADJ_DAYS
					,mmv.N16_3_ADJ_DECISION_CODE
					,mmv.N16_4_ADJ_TREAT_CODE
					,mmv.N16_5_DECISION_REASON_CODE
					,mmv.N16_6_TREATMENT_REASON_CODE
					,mmv.PathologicalTNMDate
					,mmv.ClinicalTNMDate
					,mmv.L_FIRST_CONSULTANT
					,mmv.L_APPROPRIATE
					,mmv.L_TERTIARY_DATE
					,mmv.L_TERTIARY_TRUST
					,mmv.L_TERTIARY_REASON
					,mmv.L_INAP_REF
					,mmv.L_NEW_CA_SITE
					,mmv.L_AUTO_REF
					,mmv.L_SEC_DIAGNOSIS_G
					,mmv.L_SEC_DIAGNOSIS
					,mmv.L_WRONG_REF
					,mmv.L_WRONG_REASON
					,mmv.L_TUMOUR_STATUS
					,mmv.L_NON_CANCER
					,mmv.L_FIRST_APP
					,mmv.L_NO_APP
					,mmv.L_DIAG_WHO
					,mmv.L_RECURRENCE
					,mmv.L_OTHER_SYMPS
					,mmv.L_COMMENTS
					,mmv.N2_11_FIRST_SEEN_REASON
					,mmv.N16_7_DECISION_REASON
					,mmv.N16_8_TREATMENT_REASON
					,mmv.L_DIAGNOSIS_COMMENTS
					,mmv.GP_PRACTICE_CODE
					,mmv.ClinicalTNMGroup
					,mmv.PathologicalTNMGroup
					,mmv.L_KEY_WORKER_SEEN
					,mmv.L_PALLIATIVE_SPECIALIST_SEEN
					,mmv.GERM_CELL_NON_CNS_ID
					,mmv.RECURRENCE_CANCER_SITE_ID
					,mmv.ICD03_GROUP
					,mmv.ICD03
					,mmv.L_DATE_DIAGNOSIS_DAHNO_LUCADA
					,mmv.L_INDICATOR_CODE
					,mmv.PRIMARY_DIAGNOSIS_SUB_COMMENT
					,mmv.CONSULTANT_CODE_AT_DIAGNOSIS
					,mmv.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS
					,mmv.FETOPROTEIN
					,mmv.GONADOTROPIN
					,mmv.GONADOTROPIN_SERUM
					,mmv.FETOPROTEIN_SERUM
					,mmv.SARCOMA_TUMOUR_SITE_BONE
					,mmv.SARCOMA_TUMOUR_SITE_SOFT_TISSUE
					,mmv.SARCOMA_TUMOUR_SUBSITE_BONE
					,mmv.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
					,mmv.ROOT_DECISION_DATE_COMMENTS
					,mmv.ROOT_RECEIPT_DATE_COMMENTS
					,mmv.ROOT_FIRST_SEEN_DATE_COMMENTS
					,mmv.ROOT_DIAGNOSIS_DATE_COMMENTS
					,mmv.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS
					,mmv.ROOT_UPGRADE_COMMENTS
					,mmv.FIRST_APPT_TIME
					,mmv.TRANSFER_REASON
					,mmv.DATE_NEW_REFERRAL
					,mmv.TUMOUR_SITE_NEW
					,mmv.DATE_TRANSFER_ACTIONED
					,mmv.SOURCE_CARE_ID
					,mmv.ADT_REF_ID
					,mmv.ACTION_ID
					,mmv.DIAGNOSIS_ACTION_ID
					,mmv.ORIGINAL_SOURCE_CARE_ID
					,mmv.TRANSFER_DATE_COMMENTS
					,mmv.SPECIALIST_REFERRAL_COMMENTS
					,mmv.NON_CANCER_DIAGNOSIS_CHAPTER
					,mmv.NON_CANCER_DIAGNOSIS_GROUP
					,mmv.NON_CANCER_DIAGNOSIS_CODE
					,mmv.TNM_UNKNOWN
					,mmv.ReferringPractice
					,mmv.ReferringGP
					,mmv.ReferringBranch
					,mmv.BankedTissue
					,mmv.BankedTissueTumour
					,mmv.BankedTissueBlood
					,mmv.BankedTissueCSF
					,mmv.BankedTissueBoneMarrow
					,mmv.SNOMed_CT
					,mmv.ADT_PLACER_ID
					,mmv.SNOMEDCTDiagnosisID
					,mmv.FasterDiagnosisOrganisationID
					,mmv.FasterDiagnosisCancerSiteOverrideID
					,mmv.FasterDiagnosisExclusionDate
					,mmv.FasterDiagnosisExclusionReasonID
					,mmv.FasterDiagnosisDelayReasonID
					,mmv.FasterDiagnosisDelayReasonComments
					,mmv.FasterDiagnosisCommunicationMethodID
					,mmv.FasterDiagnosisInformingCareProfessionalID
					,mmv.FasterDiagnosisOtherCareProfessional
					,mmv.FasterDiagnosisOtherCommunicationMethod
					,mmv.NonPrimaryPathwayOptionsID
					,mmv.DiagnosisUncertainty
					,mmv.TNMOrganisation
					,mmv.FasterDiagnosisTargetRCComments
					,mmv.FasterDiagnosisEndRCComments
					,mmv.TNMOrganisation_Integrated
					,mmv.LDHValue
					,mmv.BankedTissueUrine
					,mmv.SubsiteID
					,mmv.PredictedBreachStatus
					,mmv.RMRefID
					,mmv.TertiaryReferralKey
					,mmv.ClinicalTLetter
					,mmv.ClinicalNLetter
					,mmv.ClinicalMLetter
					,mmv.PathologicalTLetter
					,mmv.PathologicalNLetter
					,mmv.PathologicalMLetter
					,mmv.FDPlannedInterval
					,mmv.LabReportDate
					,mmv.LabReportOrgID
					,mmv.ReferralRoute
					,mmv.ReferralOtherRoute
					,mmv.RelapseMorphology
					,mmv.RelapseFlow
					,mmv.RelapseMolecular
					,mmv.RelapseClinicalExamination
					,mmv.RelapseOther
					,mmv.RapidDiagnostic
					,mmv.PrimaryReferralFlag
					,mmv.OtherAssessedBy
					,mmv.SharedBreach
					,mmv.PredictedBreachYear
					,mmv.PredictedBreachMonth
		INTO		#tblMAIN_REFERRALS_Match_MajorValidation
		FROM		#tblMAIN_REFERRALS_Match_Control_Major_PrePost mc_mpp
		INNER JOIN	(SELECT		SrcSys_Major_Pre
								,Src_UID_Major_Pre
								,SUM(EntityCount) AS EntityCount
								,SUM(ChangeDetected) AS ChangeDetected
								,SUM(MajorChangeDetected) AS MajorChangeDetected
								,COUNT(*) AS SplitToGroupCount
					FROM		#tblMAIN_REFERRALS_Match_Control_Major_PrePost mc_mpp_inner
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
					FROM		#tblMAIN_REFERRALS_Match_Control_Major_PrePost mc_major_prepost
					GROUP BY	SrcSys_Major_Post
								,Src_UID_Major_Post
					HAVING		COUNT(*) = 1 -- only bring across major validations where the previous validations have not been merged
								) mc_post
														ON	mc_mpp.SrcSys_Major_Post = mc_post.SrcSys_Major_Post
														AND	mc_mpp.Src_UID_Major_Post = mc_post.Src_UID_Major_Post
		INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv
																ON	mc_mpp.SrcSys_Major_Pre = mmv.SrcSys_Major
																AND	mc_mpp.Src_UID_Major_Pre = mmv.Src_UID_Major
		WHERE		mc_pre.EntityCount >= mc_post.EntityCount	-- there are no extra entities as a part of the major group
		AND			mc_post.MajorChangeDetected = 0				-- the record underneath the major validation hasn't changed since it was last processed 
		
		-- Bring along the Major_MatchValidationColumns records for major validation records that will persist
		IF OBJECT_ID('tempdb..#tblMAIN_REFERRALS_Match_MajorValidationColumns') IS NOT NULL DROP TABLE #tblMAIN_REFERRALS_Match_MajorValidationColumns
		SELECT		mmv.SrcSys_Major_Pre
					,mmv.Src_UID_Major_Pre
					,mmvc.FieldName
					,mmvc.SrcSys
					,mmvc.Src_UID
		INTO		#tblMAIN_REFERRALS_Match_MajorValidationColumns
		FROM		(SELECT		SrcSys_Major_Pre
								,Src_UID_Major_Pre
					FROM		#tblMAIN_REFERRALS_Match_MajorValidation
					GROUP BY	SrcSys_Major_Pre
								,Src_UID_Major_Pre
								) mmv
		INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidationColumns mmvc
																					ON	mmv.SrcSys_Major_Pre = mmvc.SrcSys_Major
																					AND	mmv.Src_UID_Major_Pre = mmvc.Src_UID_Major


		-- Insert any major validation records that didn't exist before (or didn't meet the match persistence criteria above)
		INSERT INTO	#tblMAIN_REFERRALS_Match_MajorValidation
					(SrcSys_Major_Post
					,Src_UID_Major_Post
					,LastValidatedDttm_Pre
					,LastValidatedDttm_Post
					,LastValidatedBy_Pre
					,LastValidatedBy_Post
					,ValidationStatus_Pre
					,ValidationStatus_Post
					,CARE_ID
					,PATIENT_ID
					,TEMP_ID
					,L_CANCER_SITE
					,N2_1_REFERRAL_SOURCE
					,N2_2_ORG_CODE_REF
					,N2_3_REFERRER_CODE
					,N2_4_PRIORITY_TYPE
					,N2_5_DECISION_DATE
					,N2_6_RECEIPT_DATE
					,N2_7_CONSULTANT
					,N2_8_SPECIALTY
					,N2_9_FIRST_SEEN_DATE
					,N1_3_ORG_CODE_SEEN
					,N2_10_FIRST_SEEN_DELAY
					,N2_12_CANCER_TYPE
					,N2_13_CANCER_STATUS
					,L_FIRST_APPOINTMENT
					,L_CANCELLED_DATE
					,N2_14_ADJ_TIME
					,N2_15_ADJ_REASON
					,L_REFERRAL_METHOD
					,N2_16_OP_REFERRAL
					,L_SPECIALIST_DATE
					,L_ORG_CODE_SPECIALIST
					,L_SPECIALIST_SEEN_DATE
					,N1_3_ORG_CODE_SPEC_SEEN
					,N_UPGRADE_DATE
					,N_UPGRADE_ORG_CODE
					,L_UPGRADE_WHEN
					,L_UPGRADE_WHO
					,N4_1_DIAGNOSIS_DATE
					,L_DIAGNOSIS
					,N4_2_DIAGNOSIS_CODE
					,L_ORG_CODE_DIAGNOSIS
					,L_PT_INFORMED_DATE
					,L_OTHER_DIAG_DATE
					,N4_3_LATERALITY
					,N4_4_BASIS_DIAGNOSIS
					,L_TOPOGRAPHY
					,L_HISTOLOGY_GROUP
					,N4_5_HISTOLOGY
					,N4_6_DIFFERENTIATION
					,ClinicalTStage
					,ClinicalTCertainty
					,ClinicalNStage
					,ClinicalNCertainty
					,ClinicalMStage
					,ClinicalMCertainty
					,ClinicalOverallCertainty
					,N6_9_SITE_CLASSIFICATION
					,PathologicalOverallCertainty
					,PathologicalTCertainty
					,PathologicalTStage
					,PathologicalNCertainty
					,PathologicalNStage
					,PathologicalMCertainty
					,PathologicalMStage
					,L_GP_INFORMED
					,L_GP_INFORMED_DATE
					,L_GP_NOT
					,L_REL_INFORMED
					,L_NURSE_PRESENT
					,L_SPEC_NURSE_DATE
					,L_SEEN_NURSE_DATE
					,N16_1_ADJ_DAYS
					,N16_2_ADJ_DAYS
					,N16_3_ADJ_DECISION_CODE
					,N16_4_ADJ_TREAT_CODE
					,N16_5_DECISION_REASON_CODE
					,N16_6_TREATMENT_REASON_CODE
					,PathologicalTNMDate
					,ClinicalTNMDate
					,L_FIRST_CONSULTANT
					,L_APPROPRIATE
					,L_TERTIARY_DATE
					,L_TERTIARY_TRUST
					,L_TERTIARY_REASON
					,L_INAP_REF
					,L_NEW_CA_SITE
					,L_AUTO_REF
					,L_SEC_DIAGNOSIS_G
					,L_SEC_DIAGNOSIS
					,L_WRONG_REF
					,L_WRONG_REASON
					,L_TUMOUR_STATUS
					,L_NON_CANCER
					,L_FIRST_APP
					,L_NO_APP
					,L_DIAG_WHO
					,L_RECURRENCE
					,L_OTHER_SYMPS
					,L_COMMENTS
					,N2_11_FIRST_SEEN_REASON
					,N16_7_DECISION_REASON
					,N16_8_TREATMENT_REASON
					,L_DIAGNOSIS_COMMENTS
					,GP_PRACTICE_CODE
					,ClinicalTNMGroup
					,PathologicalTNMGroup
					,L_KEY_WORKER_SEEN
					,L_PALLIATIVE_SPECIALIST_SEEN
					,GERM_CELL_NON_CNS_ID
					,RECURRENCE_CANCER_SITE_ID
					,ICD03_GROUP
					,ICD03
					,L_DATE_DIAGNOSIS_DAHNO_LUCADA
					,L_INDICATOR_CODE
					,PRIMARY_DIAGNOSIS_SUB_COMMENT
					,CONSULTANT_CODE_AT_DIAGNOSIS
					,CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS
					,FETOPROTEIN
					,GONADOTROPIN
					,GONADOTROPIN_SERUM
					,FETOPROTEIN_SERUM
					,SARCOMA_TUMOUR_SITE_BONE
					,SARCOMA_TUMOUR_SITE_SOFT_TISSUE
					,SARCOMA_TUMOUR_SUBSITE_BONE
					,SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
					,ROOT_DECISION_DATE_COMMENTS
					,ROOT_RECEIPT_DATE_COMMENTS
					,ROOT_FIRST_SEEN_DATE_COMMENTS
					,ROOT_DIAGNOSIS_DATE_COMMENTS
					,ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS
					,ROOT_UPGRADE_COMMENTS
					,FIRST_APPT_TIME
					,TRANSFER_REASON
					,DATE_NEW_REFERRAL
					,TUMOUR_SITE_NEW
					,DATE_TRANSFER_ACTIONED
					,SOURCE_CARE_ID
					,ADT_REF_ID
					,ACTION_ID
					,DIAGNOSIS_ACTION_ID
					,ORIGINAL_SOURCE_CARE_ID
					,TRANSFER_DATE_COMMENTS
					,SPECIALIST_REFERRAL_COMMENTS
					,NON_CANCER_DIAGNOSIS_CHAPTER
					,NON_CANCER_DIAGNOSIS_GROUP
					,NON_CANCER_DIAGNOSIS_CODE
					,TNM_UNKNOWN
					,ReferringPractice
					,ReferringGP
					,ReferringBranch
					,BankedTissue
					,BankedTissueTumour
					,BankedTissueBlood
					,BankedTissueCSF
					,BankedTissueBoneMarrow
					,SNOMed_CT
					,ADT_PLACER_ID
					,SNOMEDCTDiagnosisID
					,FasterDiagnosisOrganisationID
					,FasterDiagnosisCancerSiteOverrideID
					,FasterDiagnosisExclusionDate
					,FasterDiagnosisExclusionReasonID
					,FasterDiagnosisDelayReasonID
					,FasterDiagnosisDelayReasonComments
					,FasterDiagnosisCommunicationMethodID
					,FasterDiagnosisInformingCareProfessionalID
					,FasterDiagnosisOtherCareProfessional
					,FasterDiagnosisOtherCommunicationMethod
					,NonPrimaryPathwayOptionsID
					,DiagnosisUncertainty
					,TNMOrganisation
					,FasterDiagnosisTargetRCComments
					,FasterDiagnosisEndRCComments
					,TNMOrganisation_Integrated
					,LDHValue
					,BankedTissueUrine
					,SubsiteID
					,PredictedBreachStatus
					,RMRefID
					,TertiaryReferralKey
					,ClinicalTLetter
					,ClinicalNLetter
					,ClinicalMLetter
					,PathologicalTLetter
					,PathologicalNLetter
					,PathologicalMLetter
					,FDPlannedInterval
					,LabReportDate
					,LabReportOrgID
					,ReferralRoute
					,ReferralOtherRoute
					,RelapseMorphology
					,RelapseFlow
					,RelapseMolecular
					,RelapseClinicalExamination
					,RelapseOther
					,RapidDiagnostic
					,PrimaryReferralFlag
					,OtherAssessedBy
					,SharedBreach
					,PredictedBreachYear
					,PredictedBreachMonth
					)
		SELECT		mc_post.SrcSys_Major_Post
					,mc_post.Src_UID_Major_Post
					,mmv.LastValidatedDttm AS LastValidatedDttm_Pre
					,mmv.LastValidatedDttm AS LastValidatedDttm_Post
					,mmv.LastValidatedBy AS LastValidatedBy_Pre
					,mmv.LastValidatedBy AS LastValidatedBy_Post
					,mmv.ValidationStatus AS ValidationStatus_Pre
					,mmv.ValidationStatus AS ValidationStatus_Post
					,mmv.CARE_ID
					,mmv.PATIENT_ID
					,mmv.TEMP_ID
					,mmv.L_CANCER_SITE
					,mmv.N2_1_REFERRAL_SOURCE
					,mmv.N2_2_ORG_CODE_REF
					,mmv.N2_3_REFERRER_CODE
					,mmv.N2_4_PRIORITY_TYPE
					,mmv.N2_5_DECISION_DATE
					,mmv.N2_6_RECEIPT_DATE
					,mmv.N2_7_CONSULTANT
					,mmv.N2_8_SPECIALTY
					,mmv.N2_9_FIRST_SEEN_DATE
					,mmv.N1_3_ORG_CODE_SEEN
					,mmv.N2_10_FIRST_SEEN_DELAY
					,mmv.N2_12_CANCER_TYPE
					,mmv.N2_13_CANCER_STATUS
					,mmv.L_FIRST_APPOINTMENT
					,mmv.L_CANCELLED_DATE
					,mmv.N2_14_ADJ_TIME
					,mmv.N2_15_ADJ_REASON
					,mmv.L_REFERRAL_METHOD
					,mmv.N2_16_OP_REFERRAL
					,mmv.L_SPECIALIST_DATE
					,mmv.L_ORG_CODE_SPECIALIST
					,mmv.L_SPECIALIST_SEEN_DATE
					,mmv.N1_3_ORG_CODE_SPEC_SEEN
					,mmv.N_UPGRADE_DATE
					,mmv.N_UPGRADE_ORG_CODE
					,mmv.L_UPGRADE_WHEN
					,mmv.L_UPGRADE_WHO
					,mmv.N4_1_DIAGNOSIS_DATE
					,mmv.L_DIAGNOSIS
					,mmv.N4_2_DIAGNOSIS_CODE
					,mmv.L_ORG_CODE_DIAGNOSIS
					,mmv.L_PT_INFORMED_DATE
					,mmv.L_OTHER_DIAG_DATE
					,mmv.N4_3_LATERALITY
					,mmv.N4_4_BASIS_DIAGNOSIS
					,mmv.L_TOPOGRAPHY
					,mmv.L_HISTOLOGY_GROUP
					,mmv.N4_5_HISTOLOGY
					,mmv.N4_6_DIFFERENTIATION
					,mmv.ClinicalTStage
					,mmv.ClinicalTCertainty
					,mmv.ClinicalNStage
					,mmv.ClinicalNCertainty
					,mmv.ClinicalMStage
					,mmv.ClinicalMCertainty
					,mmv.ClinicalOverallCertainty
					,mmv.N6_9_SITE_CLASSIFICATION
					,mmv.PathologicalOverallCertainty
					,mmv.PathologicalTCertainty
					,mmv.PathologicalTStage
					,mmv.PathologicalNCertainty
					,mmv.PathologicalNStage
					,mmv.PathologicalMCertainty
					,mmv.PathologicalMStage
					,mmv.L_GP_INFORMED
					,mmv.L_GP_INFORMED_DATE
					,mmv.L_GP_NOT
					,mmv.L_REL_INFORMED
					,mmv.L_NURSE_PRESENT
					,mmv.L_SPEC_NURSE_DATE
					,mmv.L_SEEN_NURSE_DATE
					,mmv.N16_1_ADJ_DAYS
					,mmv.N16_2_ADJ_DAYS
					,mmv.N16_3_ADJ_DECISION_CODE
					,mmv.N16_4_ADJ_TREAT_CODE
					,mmv.N16_5_DECISION_REASON_CODE
					,mmv.N16_6_TREATMENT_REASON_CODE
					,mmv.PathologicalTNMDate
					,mmv.ClinicalTNMDate
					,mmv.L_FIRST_CONSULTANT
					,mmv.L_APPROPRIATE
					,mmv.L_TERTIARY_DATE
					,mmv.L_TERTIARY_TRUST
					,mmv.L_TERTIARY_REASON
					,mmv.L_INAP_REF
					,mmv.L_NEW_CA_SITE
					,mmv.L_AUTO_REF
					,mmv.L_SEC_DIAGNOSIS_G
					,mmv.L_SEC_DIAGNOSIS
					,mmv.L_WRONG_REF
					,mmv.L_WRONG_REASON
					,mmv.L_TUMOUR_STATUS
					,mmv.L_NON_CANCER
					,mmv.L_FIRST_APP
					,mmv.L_NO_APP
					,mmv.L_DIAG_WHO
					,mmv.L_RECURRENCE
					,mmv.L_OTHER_SYMPS
					,mmv.L_COMMENTS
					,mmv.N2_11_FIRST_SEEN_REASON
					,mmv.N16_7_DECISION_REASON
					,mmv.N16_8_TREATMENT_REASON
					,mmv.L_DIAGNOSIS_COMMENTS
					,mmv.GP_PRACTICE_CODE
					,mmv.ClinicalTNMGroup
					,mmv.PathologicalTNMGroup
					,mmv.L_KEY_WORKER_SEEN
					,mmv.L_PALLIATIVE_SPECIALIST_SEEN
					,mmv.GERM_CELL_NON_CNS_ID
					,mmv.RECURRENCE_CANCER_SITE_ID
					,mmv.ICD03_GROUP
					,mmv.ICD03
					,mmv.L_DATE_DIAGNOSIS_DAHNO_LUCADA
					,mmv.L_INDICATOR_CODE
					,mmv.PRIMARY_DIAGNOSIS_SUB_COMMENT
					,mmv.CONSULTANT_CODE_AT_DIAGNOSIS
					,mmv.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS
					,mmv.FETOPROTEIN
					,mmv.GONADOTROPIN
					,mmv.GONADOTROPIN_SERUM
					,mmv.FETOPROTEIN_SERUM
					,mmv.SARCOMA_TUMOUR_SITE_BONE
					,mmv.SARCOMA_TUMOUR_SITE_SOFT_TISSUE
					,mmv.SARCOMA_TUMOUR_SUBSITE_BONE
					,mmv.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
					,mmv.ROOT_DECISION_DATE_COMMENTS
					,mmv.ROOT_RECEIPT_DATE_COMMENTS
					,mmv.ROOT_FIRST_SEEN_DATE_COMMENTS
					,mmv.ROOT_DIAGNOSIS_DATE_COMMENTS
					,mmv.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS
					,mmv.ROOT_UPGRADE_COMMENTS
					,mmv.FIRST_APPT_TIME
					,mmv.TRANSFER_REASON
					,mmv.DATE_NEW_REFERRAL
					,mmv.TUMOUR_SITE_NEW
					,mmv.DATE_TRANSFER_ACTIONED
					,mmv.SOURCE_CARE_ID
					,mmv.ADT_REF_ID
					,mmv.ACTION_ID
					,mmv.DIAGNOSIS_ACTION_ID
					,mmv.ORIGINAL_SOURCE_CARE_ID
					,mmv.TRANSFER_DATE_COMMENTS
					,mmv.SPECIALIST_REFERRAL_COMMENTS
					,mmv.NON_CANCER_DIAGNOSIS_CHAPTER
					,mmv.NON_CANCER_DIAGNOSIS_GROUP
					,mmv.NON_CANCER_DIAGNOSIS_CODE
					,mmv.TNM_UNKNOWN
					,mmv.ReferringPractice
					,mmv.ReferringGP
					,mmv.ReferringBranch
					,mmv.BankedTissue
					,mmv.BankedTissueTumour
					,mmv.BankedTissueBlood
					,mmv.BankedTissueCSF
					,mmv.BankedTissueBoneMarrow
					,mmv.SNOMed_CT
					,mmv.ADT_PLACER_ID
					,mmv.SNOMEDCTDiagnosisID
					,mmv.FasterDiagnosisOrganisationID
					,mmv.FasterDiagnosisCancerSiteOverrideID
					,mmv.FasterDiagnosisExclusionDate
					,mmv.FasterDiagnosisExclusionReasonID
					,mmv.FasterDiagnosisDelayReasonID
					,mmv.FasterDiagnosisDelayReasonComments
					,mmv.FasterDiagnosisCommunicationMethodID
					,mmv.FasterDiagnosisInformingCareProfessionalID
					,mmv.FasterDiagnosisOtherCareProfessional
					,mmv.FasterDiagnosisOtherCommunicationMethod
					,mmv.NonPrimaryPathwayOptionsID
					,mmv.DiagnosisUncertainty
					,mmv.TNMOrganisation
					,mmv.FasterDiagnosisTargetRCComments
					,mmv.FasterDiagnosisEndRCComments
					,mmv.TNMOrganisation_Integrated
					,mmv.LDHValue
					,mmv.BankedTissueUrine
					,mmv.SubsiteID
					,mmv.PredictedBreachStatus
					,mmv.RMRefID
					,mmv.TertiaryReferralKey
					,mmv.ClinicalTLetter
					,mmv.ClinicalNLetter
					,mmv.ClinicalMLetter
					,mmv.PathologicalTLetter
					,mmv.PathologicalNLetter
					,mmv.PathologicalMLetter
					,mmv.FDPlannedInterval
					,mmv.LabReportDate
					,mmv.LabReportOrgID
					,mmv.ReferralRoute
					,mmv.ReferralOtherRoute
					,mmv.RelapseMorphology
					,mmv.RelapseFlow
					,mmv.RelapseMolecular
					,mmv.RelapseClinicalExamination
					,mmv.RelapseOther
					,mmv.RapidDiagnostic
					,mmv.PrimaryReferralFlag
					,mmv.OtherAssessedBy
					,mmv.SharedBreach
					,mmv.PredictedBreachYear
					,mmv.PredictedBreachMonth
		FROM		(SELECT		SrcSys_Major_Post
								,Src_UID_Major_Post
					FROM		#tblMAIN_REFERRALS_Match_Control_Major_PrePost mc_major_prepost
					GROUP BY	SrcSys_Major_Post
								,Src_UID_Major_Post
								) mc_post
		INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv
																ON	mc_post.SrcSys_Major_Post = mmv.SrcSys_Major
																AND	mc_post.Src_UID_Major_Post = mmv.Src_UID_Major
		LEFT JOIN	#tblMAIN_REFERRALS_Match_MajorValidation mmv_alreadyThere
																ON	mc_post.SrcSys_Major_Post = mmv_alreadyThere.SrcSys_Major_Post
																AND	mc_post.Src_UID_Major_Post = mmv_alreadyThere.Src_UID_Major_Post
		WHERE		mmv_alreadyThere.SrcSys_Major_Post IS NULL -- we haven't already put the record into #tblMAIN_REFERRALS_Match_MajorValidation


		-- auto validate records where all the entities within a major entity have a scripted match intention
		INSERT INTO	#tblMAIN_REFERRALS_Match_MajorValidation
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
		LEFT JOIN	#tblMAIN_REFERRALS_Match_MajorValidation mmv
												ON	AutoValidate.SrcSys_Major_Post = mmv.SrcSys_Major_Post
												AND	AutoValidate.Src_UID_Major_Post = mmv.Src_UID_Major_Post
		WHERE		mmv.SrcSys_Major_Post IS NULL
		


		/*****************************************************************************************************************************************************************************************************************************************************************************************/
		-- Find the records to wipe from the persistent tables
		/*****************************************************************************************************************************************************************************************************************************************************************************************/

		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Prepare to replace'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

		-- Find all persistent match control records that relate to the initial incremental dataset (these will be for deletion)
		IF OBJECT_ID('tempdb..#tblMAIN_REFERRALS_Match_Control_ToDelete') IS NOT NULL DROP TABLE #tblMAIN_REFERRALS_Match_Control_ToDelete
		SELECT		mc.SrcSys
					,mc.Src_UID
		INTO		#tblMAIN_REFERRALS_Match_Control_ToDelete
		FROM		#Incremental inc
		INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
													ON	inc.SrcSys = mc.SrcSys
													AND	inc.Src_UID = mc.Src_UID
		--WHERE		inc.MoveMajorValidation = 0

		-- Find all persistent match control records that will be orphaned from their major UID by the new major UIDs (we will set them to be their own major record and mark these as changed so they will be processed again next time round)
		IF OBJECT_ID('tempdb..#tblMAIN_REFERRALS_Match_Control_ToReprocess') IS NOT NULL DROP TABLE #tblMAIN_REFERRALS_Match_Control_ToReprocess
		SELECT		mc.SrcSys
					,mc.Src_UID
		INTO		#tblMAIN_REFERRALS_Match_Control_ToReprocess
		FROM		#Incremental inc
		INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
													ON	inc.SrcSys = mc.SrcSys_Major
													AND	inc.Src_UID = mc.Src_UID_Major
		WHERE		inc.ProcessIx > 1
		AND			CONCAT(CAST(mc.SrcSys AS VARCHAR(255)), '|', mc.Src_UID) != CONCAT(CAST(mc.SrcSys_Major AS VARCHAR(255)), '|', mc.Src_UID_Major)
		--AND			inc.MoveMajorValidation = 0

		-- Find all persistent entity pairs all records that relate to the initial incremental dataset (these will be for deletion)
		IF OBJECT_ID('tempdb..#tblMAIN_REFERRALS_Match_EntityPairs_All_ToDelete') IS NOT NULL DROP TABLE #tblMAIN_REFERRALS_Match_EntityPairs_All_ToDelete
		SELECT		UnionAandB.SrcSys_A
					,UnionAandB.Src_UID_A
					,UnionAandB.SrcSys_B
					,UnionAandB.Src_UID_B
		INTO		#tblMAIN_REFERRALS_Match_EntityPairs_All_ToDelete
		FROM		(SELECT		ep_a.SrcSys_A
								,ep_a.Src_UID_A
								,ep_a.SrcSys_B
								,ep_a.Src_UID_B
					FROM		#tblMAIN_REFERRALS_Match_Control_ToDelete mc
					INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_All ep_a
																		ON	mc.SrcSys = ep_a.SrcSys_A
																		AND	mc.Src_UID = ep_a.Src_UID_A
					
					UNION
					
					SELECT		ep_a.SrcSys_A
								,ep_a.Src_UID_A
								,ep_a.SrcSys_B
								,ep_a.Src_UID_B
					FROM		#tblMAIN_REFERRALS_Match_Control_ToDelete mc
					INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_All ep_a
																		ON	mc.SrcSys = ep_a.SrcSys_B
																		AND	mc.Src_UID = ep_a.Src_UID_B
								) UnionAandB

		-- Find all persistent entity pairs unique records that relate to the initial incremental dataset (these will be for deletion)
		IF OBJECT_ID('tempdb..#tblMAIN_REFERRALS_Match_EntityPairs_Unique_ToDelete') IS NOT NULL DROP TABLE #tblMAIN_REFERRALS_Match_EntityPairs_Unique_ToDelete
		SELECT		UnionAandB.SrcSys_A
					,UnionAandB.Src_UID_A
					,UnionAandB.SrcSys_B
					,UnionAandB.Src_UID_B
		INTO		#tblMAIN_REFERRALS_Match_EntityPairs_Unique_ToDelete
		FROM		(SELECT		ep_u.SrcSys_A
								,ep_u.Src_UID_A
								,ep_u.SrcSys_B
								,ep_u.Src_UID_B
					FROM		#tblMAIN_REFERRALS_Match_Control_ToDelete mc
					INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_Unique ep_u
																		ON	mc.SrcSys = ep_u.SrcSys_A
																		AND	mc.Src_UID = ep_u.Src_UID_A
					
					UNION
					
					SELECT		ep_u.SrcSys_A
								,ep_u.Src_UID_A
								,ep_u.SrcSys_B
								,ep_u.Src_UID_B
					FROM		#tblMAIN_REFERRALS_Match_Control_ToDelete mc
					INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_Unique ep_u
																		ON	mc.SrcSys = ep_u.SrcSys_B
																		AND	mc.Src_UID = ep_u.Src_UID_B
								) UnionAandB

		-- Find all persistent major validation records that relate to the initial incremental dataset (these will be for deletion)
		IF OBJECT_ID('tempdb..#tblMAIN_REFERRALS_Match_MajorValidation_ToDelete') IS NOT NULL DROP TABLE #tblMAIN_REFERRALS_Match_MajorValidation_ToDelete
		SELECT		mmv.SrcSys_Major
					,mmv.Src_UID_Major
		INTO		#tblMAIN_REFERRALS_Match_MajorValidation_ToDelete
		FROM		(SELECT		SrcSys_Major_Pre
								,Src_UID_Major_Pre
					FROM		#tblMAIN_REFERRALS_Match_Control_Major_PrePost mc_mpp_inner
					GROUP BY	SrcSys_Major_Pre
								,Src_UID_Major_Pre

					UNION

					SELECT		mmv_inner.SrcSys_Major_Post
								,mmv_inner.Src_UID_Major_Post
					FROM		#tblMAIN_REFERRALS_Match_MajorValidation mmv_inner
					GROUP BY	mmv_inner.SrcSys_Major_Post
								,mmv_inner.Src_UID_Major_Post
								) mc_pre
		INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv
															ON	mc_pre.SrcSys_Major_Pre = mmv.SrcSys_Major
															AND	mc_pre.Src_UID_Major_Pre = mmv.Src_UID_Major


		-- Find all persistent major validation column override records that relate to the initial incremental dataset (these will be for deletion)
		IF OBJECT_ID('tempdb..#tblMAIN_REFERRALS_Match_MajorValidationColumns_ToDelete') IS NOT NULL DROP TABLE #tblMAIN_REFERRALS_Match_MajorValidationColumns_ToDelete
		SELECT		mmvc.SrcSys_Major
					,mmvc.Src_UID_Major
		INTO		#tblMAIN_REFERRALS_Match_MajorValidationColumns_ToDelete
		FROM		#tblMAIN_REFERRALS_Match_MajorValidation_ToDelete mmv
		INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidationColumns mmvc
															ON	mmv.SrcSys_Major = mmvc.SrcSys_Major
															AND	mmv.Src_UID_Major = mmvc.Src_UID_Major


		 BEGIN TRY

			 BEGIN TRANSACTION
		
				SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = 1, @ErrorMessage = NULL
				SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'Replace'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
		
				-- Delete all related records from match control
				DELETE
				FROM		mc
				FROM		#tblMAIN_REFERRALS_Match_Control_ToDelete mc_toDelete
				INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
															ON	mc_toDelete.SrcSys = mc.SrcSys
															AND	mc_toDelete.Src_UID = mc.Src_UID

				-- Delete all related records from entity pairs all
				IF		ISNULL(@UseExistingMatches, 0) = 0
				DELETE
				FROM		ep_a
				FROM		#tblMAIN_REFERRALS_Match_EntityPairs_All_ToDelete ep_a_toDelete
				INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_All ep_a
																	ON	ep_a_toDelete.SrcSys_A = ep_a.SrcSys_A
																	AND	ep_a_toDelete.Src_UID_A = ep_a.Src_UID_A
																	AND	ep_a_toDelete.SrcSys_B = ep_a.SrcSys_B
																	AND	ep_a_toDelete.Src_UID_B = ep_a.Src_UID_B

				-- Delete all related records from entity pairs unique
				DELETE
				FROM		ep_u
				FROM		#tblMAIN_REFERRALS_Match_EntityPairs_Unique_ToDelete ep_u_toDelete
				INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_Unique ep_u
																	ON	ep_u_toDelete.SrcSys_A = ep_u.SrcSys_A
																	AND	ep_u_toDelete.Src_UID_A = ep_u.Src_UID_A
																	AND	ep_u_toDelete.SrcSys_B = ep_u.SrcSys_B
																	AND	ep_u_toDelete.Src_UID_B = ep_u.Src_UID_B


				-- Delete all related records from major validation tables
				DELETE
				FROM		mmv
				FROM		#tblMAIN_REFERRALS_Match_MajorValidation_ToDelete mmv_toDelete
				INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv
																	ON	mmv_toDelete.SrcSys_Major = mmv.SrcSys_Major
																	AND	mmv_toDelete.Src_UID_Major = mmv.Src_UID_Major


				-- Delete all related records from major column values tables
				DELETE
				FROM		mmvc
				FROM		#tblMAIN_REFERRALS_Match_MajorValidationColumns_ToDelete mmvc_toDelete
				INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidationColumns mmvc
																	ON	mmvc_toDelete.SrcSys_Major = mmvc.SrcSys_Major
																	AND	mmvc_toDelete.Src_UID_Major = mmvc.Src_UID_Major


				-- Mark all persistent match control records that will be orphaned from their major UID by the new major UIDs for reprocessing
				UPDATE		mc
				SET			mc.SrcSys_Major = mc.SrcSys
							,mc.Src_UID_Major = mc.Src_UID
							,mc.LastProcessed = NULL
				FROM		#tblMAIN_REFERRALS_Match_Control_ToReprocess mc_toReprocess
				INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
															ON	mc_toReprocess.SrcSys = mc.SrcSys
															AND	mc_toReprocess.Src_UID = mc.Src_UID

				-- Insert all new records into match control
				INSERT INTO	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control
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
				INSERT INTO	Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_All
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
				FROM		#tblMAIN_REFERRALS_Match_EntityPairs_All ep_a

				-- Insert all new records into entity pairs unique
				INSERT INTO	Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_Unique
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
				INSERT INTO	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation
							(SrcSys_Major
							,Src_UID_Major
							,LastValidatedDttm
							,LastValidatedBy
							,ValidationStatus
							,CARE_ID
							,PATIENT_ID
							,TEMP_ID
							,L_CANCER_SITE
							,N2_1_REFERRAL_SOURCE
							,N2_2_ORG_CODE_REF
							,N2_3_REFERRER_CODE
							,N2_4_PRIORITY_TYPE
							,N2_5_DECISION_DATE
							,N2_6_RECEIPT_DATE
							,N2_7_CONSULTANT
							,N2_8_SPECIALTY
							,N2_9_FIRST_SEEN_DATE
							,N1_3_ORG_CODE_SEEN
							,N2_10_FIRST_SEEN_DELAY
							,N2_12_CANCER_TYPE
							,N2_13_CANCER_STATUS
							,L_FIRST_APPOINTMENT
							,L_CANCELLED_DATE
							,N2_14_ADJ_TIME
							,N2_15_ADJ_REASON
							,L_REFERRAL_METHOD
							,N2_16_OP_REFERRAL
							,L_SPECIALIST_DATE
							,L_ORG_CODE_SPECIALIST
							,L_SPECIALIST_SEEN_DATE
							,N1_3_ORG_CODE_SPEC_SEEN
							,N_UPGRADE_DATE
							,N_UPGRADE_ORG_CODE
							,L_UPGRADE_WHEN
							,L_UPGRADE_WHO
							,N4_1_DIAGNOSIS_DATE
							,L_DIAGNOSIS
							,N4_2_DIAGNOSIS_CODE
							,L_ORG_CODE_DIAGNOSIS
							,L_PT_INFORMED_DATE
							,L_OTHER_DIAG_DATE
							,N4_3_LATERALITY
							,N4_4_BASIS_DIAGNOSIS
							,L_TOPOGRAPHY
							,L_HISTOLOGY_GROUP
							,N4_5_HISTOLOGY
							,N4_6_DIFFERENTIATION
							,ClinicalTStage
							,ClinicalTCertainty
							,ClinicalNStage
							,ClinicalNCertainty
							,ClinicalMStage
							,ClinicalMCertainty
							,ClinicalOverallCertainty
							,N6_9_SITE_CLASSIFICATION
							,PathologicalOverallCertainty
							,PathologicalTCertainty
							,PathologicalTStage
							,PathologicalNCertainty
							,PathologicalNStage
							,PathologicalMCertainty
							,PathologicalMStage
							,L_GP_INFORMED
							,L_GP_INFORMED_DATE
							,L_GP_NOT
							,L_REL_INFORMED
							,L_NURSE_PRESENT
							,L_SPEC_NURSE_DATE
							,L_SEEN_NURSE_DATE
							,N16_1_ADJ_DAYS
							,N16_2_ADJ_DAYS
							,N16_3_ADJ_DECISION_CODE
							,N16_4_ADJ_TREAT_CODE
							,N16_5_DECISION_REASON_CODE
							,N16_6_TREATMENT_REASON_CODE
							,PathologicalTNMDate
							,ClinicalTNMDate
							,L_FIRST_CONSULTANT
							,L_APPROPRIATE
							,L_TERTIARY_DATE
							,L_TERTIARY_TRUST
							,L_TERTIARY_REASON
							,L_INAP_REF
							,L_NEW_CA_SITE
							,L_AUTO_REF
							,L_SEC_DIAGNOSIS_G
							,L_SEC_DIAGNOSIS
							,L_WRONG_REF
							,L_WRONG_REASON
							,L_TUMOUR_STATUS
							,L_NON_CANCER
							,L_FIRST_APP
							,L_NO_APP
							,L_DIAG_WHO
							,L_RECURRENCE
							,L_OTHER_SYMPS
							,L_COMMENTS
							,N2_11_FIRST_SEEN_REASON
							,N16_7_DECISION_REASON
							,N16_8_TREATMENT_REASON
							,L_DIAGNOSIS_COMMENTS
							,GP_PRACTICE_CODE
							,ClinicalTNMGroup
							,PathologicalTNMGroup
							,L_KEY_WORKER_SEEN
							,L_PALLIATIVE_SPECIALIST_SEEN
							,GERM_CELL_NON_CNS_ID
							,RECURRENCE_CANCER_SITE_ID
							,ICD03_GROUP
							,ICD03
							,L_DATE_DIAGNOSIS_DAHNO_LUCADA
							,L_INDICATOR_CODE
							,PRIMARY_DIAGNOSIS_SUB_COMMENT
							,CONSULTANT_CODE_AT_DIAGNOSIS
							,CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS
							,FETOPROTEIN
							,GONADOTROPIN
							,GONADOTROPIN_SERUM
							,FETOPROTEIN_SERUM
							,SARCOMA_TUMOUR_SITE_BONE
							,SARCOMA_TUMOUR_SITE_SOFT_TISSUE
							,SARCOMA_TUMOUR_SUBSITE_BONE
							,SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
							,ROOT_DECISION_DATE_COMMENTS
							,ROOT_RECEIPT_DATE_COMMENTS
							,ROOT_FIRST_SEEN_DATE_COMMENTS
							,ROOT_DIAGNOSIS_DATE_COMMENTS
							,ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS
							,ROOT_UPGRADE_COMMENTS
							,FIRST_APPT_TIME
							,TRANSFER_REASON
							,DATE_NEW_REFERRAL
							,TUMOUR_SITE_NEW
							,DATE_TRANSFER_ACTIONED
							,SOURCE_CARE_ID
							,ADT_REF_ID
							,ACTION_ID
							,DIAGNOSIS_ACTION_ID
							,ORIGINAL_SOURCE_CARE_ID
							,TRANSFER_DATE_COMMENTS
							,SPECIALIST_REFERRAL_COMMENTS
							,NON_CANCER_DIAGNOSIS_CHAPTER
							,NON_CANCER_DIAGNOSIS_GROUP
							,NON_CANCER_DIAGNOSIS_CODE
							,TNM_UNKNOWN
							,ReferringPractice
							,ReferringGP
							,ReferringBranch
							,BankedTissue
							,BankedTissueTumour
							,BankedTissueBlood
							,BankedTissueCSF
							,BankedTissueBoneMarrow
							,SNOMed_CT
							,ADT_PLACER_ID
							,SNOMEDCTDiagnosisID
							,FasterDiagnosisOrganisationID
							,FasterDiagnosisCancerSiteOverrideID
							,FasterDiagnosisExclusionDate
							,FasterDiagnosisExclusionReasonID
							,FasterDiagnosisDelayReasonID
							,FasterDiagnosisDelayReasonComments
							,FasterDiagnosisCommunicationMethodID
							,FasterDiagnosisInformingCareProfessionalID
							,FasterDiagnosisOtherCareProfessional
							,FasterDiagnosisOtherCommunicationMethod
							,NonPrimaryPathwayOptionsID
							,DiagnosisUncertainty
							,TNMOrganisation
							,FasterDiagnosisTargetRCComments
							,FasterDiagnosisEndRCComments
							,TNMOrganisation_Integrated
							,LDHValue
							,BankedTissueUrine
							,SubsiteID
							,PredictedBreachStatus
							,RMRefID
							,TertiaryReferralKey
							,ClinicalTLetter
							,ClinicalNLetter
							,ClinicalMLetter
							,PathologicalTLetter
							,PathologicalNLetter
							,PathologicalMLetter
							,FDPlannedInterval
							,LabReportDate
							,LabReportOrgID
							,ReferralRoute
							,ReferralOtherRoute
							,RelapseMorphology
							,RelapseFlow
							,RelapseMolecular
							,RelapseClinicalExamination
							,RelapseOther
							,RapidDiagnostic
							,PrimaryReferralFlag
							,OtherAssessedBy
							,SharedBreach
							,PredictedBreachYear
							,PredictedBreachMonth
							)
				SELECT		SrcSys_Major									= mmv.SrcSys_Major_Post
							,Src_UID_Major									= mmv.Src_UID_Major_Post
							,LastValidatedDttm								= mmv.LastValidatedDttm_Post
							,LastValidatedBy								= mmv.LastValidatedBy_Post
							,ValidationStatus								= mmv.ValidationStatus_Post
							,CARE_ID										= mmv.CARE_ID
							,PATIENT_ID										= mmv.PATIENT_ID
							,TEMP_ID										= mmv.TEMP_ID
							,L_CANCER_SITE									= mmv.L_CANCER_SITE
							,N2_1_REFERRAL_SOURCE							= mmv.N2_1_REFERRAL_SOURCE
							,N2_2_ORG_CODE_REF								= mmv.N2_2_ORG_CODE_REF
							,N2_3_REFERRER_CODE								= mmv.N2_3_REFERRER_CODE
							,N2_4_PRIORITY_TYPE								= mmv.N2_4_PRIORITY_TYPE
							,N2_5_DECISION_DATE								= mmv.N2_5_DECISION_DATE
							,N2_6_RECEIPT_DATE								= mmv.N2_6_RECEIPT_DATE
							,N2_7_CONSULTANT								= mmv.N2_7_CONSULTANT
							,N2_8_SPECIALTY									= mmv.N2_8_SPECIALTY
							,N2_9_FIRST_SEEN_DATE							= mmv.N2_9_FIRST_SEEN_DATE
							,N1_3_ORG_CODE_SEEN								= mmv.N1_3_ORG_CODE_SEEN
							,N2_10_FIRST_SEEN_DELAY							= mmv.N2_10_FIRST_SEEN_DELAY
							,N2_12_CANCER_TYPE								= mmv.N2_12_CANCER_TYPE
							,N2_13_CANCER_STATUS							= mmv.N2_13_CANCER_STATUS
							,L_FIRST_APPOINTMENT							= mmv.L_FIRST_APPOINTMENT
							,L_CANCELLED_DATE								= mmv.L_CANCELLED_DATE
							,N2_14_ADJ_TIME									= mmv.N2_14_ADJ_TIME
							,N2_15_ADJ_REASON								= mmv.N2_15_ADJ_REASON
							,L_REFERRAL_METHOD								= mmv.L_REFERRAL_METHOD
							,N2_16_OP_REFERRAL								= mmv.N2_16_OP_REFERRAL
							,L_SPECIALIST_DATE								= mmv.L_SPECIALIST_DATE
							,L_ORG_CODE_SPECIALIST							= mmv.L_ORG_CODE_SPECIALIST
							,L_SPECIALIST_SEEN_DATE							= mmv.L_SPECIALIST_SEEN_DATE
							,N1_3_ORG_CODE_SPEC_SEEN						= mmv.N1_3_ORG_CODE_SPEC_SEEN
							,N_UPGRADE_DATE									= mmv.N_UPGRADE_DATE
							,N_UPGRADE_ORG_CODE								= mmv.N_UPGRADE_ORG_CODE
							,L_UPGRADE_WHEN									= mmv.L_UPGRADE_WHEN
							,L_UPGRADE_WHO									= mmv.L_UPGRADE_WHO
							,N4_1_DIAGNOSIS_DATE							= mmv.N4_1_DIAGNOSIS_DATE
							,L_DIAGNOSIS									= mmv.L_DIAGNOSIS
							,N4_2_DIAGNOSIS_CODE							= mmv.N4_2_DIAGNOSIS_CODE
							,L_ORG_CODE_DIAGNOSIS							= mmv.L_ORG_CODE_DIAGNOSIS
							,L_PT_INFORMED_DATE								= mmv.L_PT_INFORMED_DATE
							,L_OTHER_DIAG_DATE								= mmv.L_OTHER_DIAG_DATE
							,N4_3_LATERALITY								= mmv.N4_3_LATERALITY
							,N4_4_BASIS_DIAGNOSIS							= mmv.N4_4_BASIS_DIAGNOSIS
							,L_TOPOGRAPHY									= mmv.L_TOPOGRAPHY
							,L_HISTOLOGY_GROUP								= mmv.L_HISTOLOGY_GROUP
							,N4_5_HISTOLOGY									= mmv.N4_5_HISTOLOGY
							,N4_6_DIFFERENTIATION							= mmv.N4_6_DIFFERENTIATION
							,ClinicalTStage									= mmv.ClinicalTStage
							,ClinicalTCertainty								= mmv.ClinicalTCertainty
							,ClinicalNStage									= mmv.ClinicalNStage
							,ClinicalNCertainty								= mmv.ClinicalNCertainty
							,ClinicalMStage									= mmv.ClinicalMStage
							,ClinicalMCertainty								= mmv.ClinicalMCertainty
							,ClinicalOverallCertainty						= mmv.ClinicalOverallCertainty
							,N6_9_SITE_CLASSIFICATION						= mmv.N6_9_SITE_CLASSIFICATION
							,PathologicalOverallCertainty					= mmv.PathologicalOverallCertainty
							,PathologicalTCertainty							= mmv.PathologicalTCertainty
							,PathologicalTStage								= mmv.PathologicalTStage
							,PathologicalNCertainty							= mmv.PathologicalNCertainty
							,PathologicalNStage								= mmv.PathologicalNStage
							,PathologicalMCertainty							= mmv.PathologicalMCertainty
							,PathologicalMStage								= mmv.PathologicalMStage
							,L_GP_INFORMED									= mmv.L_GP_INFORMED
							,L_GP_INFORMED_DATE								= mmv.L_GP_INFORMED_DATE
							,L_GP_NOT										= mmv.L_GP_NOT
							,L_REL_INFORMED									= mmv.L_REL_INFORMED
							,L_NURSE_PRESENT								= mmv.L_NURSE_PRESENT
							,L_SPEC_NURSE_DATE								= mmv.L_SPEC_NURSE_DATE
							,L_SEEN_NURSE_DATE								= mmv.L_SEEN_NURSE_DATE
							,N16_1_ADJ_DAYS									= mmv.N16_1_ADJ_DAYS
							,N16_2_ADJ_DAYS									= mmv.N16_2_ADJ_DAYS
							,N16_3_ADJ_DECISION_CODE						= mmv.N16_3_ADJ_DECISION_CODE
							,N16_4_ADJ_TREAT_CODE							= mmv.N16_4_ADJ_TREAT_CODE
							,N16_5_DECISION_REASON_CODE						= mmv.N16_5_DECISION_REASON_CODE
							,N16_6_TREATMENT_REASON_CODE					= mmv.N16_6_TREATMENT_REASON_CODE
							,PathologicalTNMDate							= mmv.PathologicalTNMDate
							,ClinicalTNMDate								= mmv.ClinicalTNMDate
							,L_FIRST_CONSULTANT								= mmv.L_FIRST_CONSULTANT
							,L_APPROPRIATE									= mmv.L_APPROPRIATE
							,L_TERTIARY_DATE								= mmv.L_TERTIARY_DATE
							,L_TERTIARY_TRUST								= mmv.L_TERTIARY_TRUST
							,L_TERTIARY_REASON								= mmv.L_TERTIARY_REASON
							,L_INAP_REF										= mmv.L_INAP_REF
							,L_NEW_CA_SITE									= mmv.L_NEW_CA_SITE
							,L_AUTO_REF										= mmv.L_AUTO_REF
							,L_SEC_DIAGNOSIS_G								= mmv.L_SEC_DIAGNOSIS_G
							,L_SEC_DIAGNOSIS								= mmv.L_SEC_DIAGNOSIS
							,L_WRONG_REF									= mmv.L_WRONG_REF
							,L_WRONG_REASON									= mmv.L_WRONG_REASON
							,L_TUMOUR_STATUS								= mmv.L_TUMOUR_STATUS
							,L_NON_CANCER									= mmv.L_NON_CANCER
							,L_FIRST_APP									= mmv.L_FIRST_APP
							,L_NO_APP										= mmv.L_NO_APP
							,L_DIAG_WHO										= mmv.L_DIAG_WHO
							,L_RECURRENCE									= mmv.L_RECURRENCE
							,L_OTHER_SYMPS									= mmv.L_OTHER_SYMPS
							,L_COMMENTS										= mmv.L_COMMENTS
							,N2_11_FIRST_SEEN_REASON						= mmv.N2_11_FIRST_SEEN_REASON
							,N16_7_DECISION_REASON							= mmv.N16_7_DECISION_REASON
							,N16_8_TREATMENT_REASON							= mmv.N16_8_TREATMENT_REASON
							,L_DIAGNOSIS_COMMENTS							= mmv.L_DIAGNOSIS_COMMENTS
							,GP_PRACTICE_CODE								= mmv.GP_PRACTICE_CODE
							,ClinicalTNMGroup								= mmv.ClinicalTNMGroup
							,PathologicalTNMGroup							= mmv.PathologicalTNMGroup
							,L_KEY_WORKER_SEEN								= mmv.L_KEY_WORKER_SEEN
							,L_PALLIATIVE_SPECIALIST_SEEN					= mmv.L_PALLIATIVE_SPECIALIST_SEEN
							,GERM_CELL_NON_CNS_ID							= mmv.GERM_CELL_NON_CNS_ID
							,RECURRENCE_CANCER_SITE_ID						= mmv.RECURRENCE_CANCER_SITE_ID
							,ICD03_GROUP									= mmv.ICD03_GROUP
							,ICD03											= mmv.ICD03
							,L_DATE_DIAGNOSIS_DAHNO_LUCADA					= mmv.L_DATE_DIAGNOSIS_DAHNO_LUCADA
							,L_INDICATOR_CODE								= mmv.L_INDICATOR_CODE
							,PRIMARY_DIAGNOSIS_SUB_COMMENT					= mmv.PRIMARY_DIAGNOSIS_SUB_COMMENT
							,CONSULTANT_CODE_AT_DIAGNOSIS					= mmv.CONSULTANT_CODE_AT_DIAGNOSIS
							,CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS			= mmv.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS
							,FETOPROTEIN									= mmv.FETOPROTEIN
							,GONADOTROPIN									= mmv.GONADOTROPIN
							,GONADOTROPIN_SERUM								= mmv.GONADOTROPIN_SERUM
							,FETOPROTEIN_SERUM								= mmv.FETOPROTEIN_SERUM
							,SARCOMA_TUMOUR_SITE_BONE						= mmv.SARCOMA_TUMOUR_SITE_BONE
							,SARCOMA_TUMOUR_SITE_SOFT_TISSUE				= mmv.SARCOMA_TUMOUR_SITE_SOFT_TISSUE
							,SARCOMA_TUMOUR_SUBSITE_BONE					= mmv.SARCOMA_TUMOUR_SUBSITE_BONE
							,SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE				= mmv.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
							,ROOT_DECISION_DATE_COMMENTS					= mmv.ROOT_DECISION_DATE_COMMENTS
							,ROOT_RECEIPT_DATE_COMMENTS						= mmv.ROOT_RECEIPT_DATE_COMMENTS
							,ROOT_FIRST_SEEN_DATE_COMMENTS					= mmv.ROOT_FIRST_SEEN_DATE_COMMENTS
							,ROOT_DIAGNOSIS_DATE_COMMENTS					= mmv.ROOT_DIAGNOSIS_DATE_COMMENTS
							,ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS			= mmv.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS
							,ROOT_UPGRADE_COMMENTS							= mmv.ROOT_UPGRADE_COMMENTS
							,FIRST_APPT_TIME								= mmv.FIRST_APPT_TIME
							,TRANSFER_REASON								= mmv.TRANSFER_REASON
							,DATE_NEW_REFERRAL								= mmv.DATE_NEW_REFERRAL
							,TUMOUR_SITE_NEW								= mmv.TUMOUR_SITE_NEW
							,DATE_TRANSFER_ACTIONED							= mmv.DATE_TRANSFER_ACTIONED
							,SOURCE_CARE_ID									= mmv.SOURCE_CARE_ID
							,ADT_REF_ID										= mmv.ADT_REF_ID
							,ACTION_ID										= mmv.ACTION_ID
							,DIAGNOSIS_ACTION_ID							= mmv.DIAGNOSIS_ACTION_ID
							,ORIGINAL_SOURCE_CARE_ID						= mmv.ORIGINAL_SOURCE_CARE_ID
							,TRANSFER_DATE_COMMENTS							= mmv.TRANSFER_DATE_COMMENTS
							,SPECIALIST_REFERRAL_COMMENTS					= mmv.SPECIALIST_REFERRAL_COMMENTS
							,NON_CANCER_DIAGNOSIS_CHAPTER					= mmv.NON_CANCER_DIAGNOSIS_CHAPTER
							,NON_CANCER_DIAGNOSIS_GROUP						= mmv.NON_CANCER_DIAGNOSIS_GROUP
							,NON_CANCER_DIAGNOSIS_CODE						= mmv.NON_CANCER_DIAGNOSIS_CODE
							,TNM_UNKNOWN									= mmv.TNM_UNKNOWN
							,ReferringPractice								= mmv.ReferringPractice
							,ReferringGP									= mmv.ReferringGP
							,ReferringBranch								= mmv.ReferringBranch
							,BankedTissue									= mmv.BankedTissue
							,BankedTissueTumour								= mmv.BankedTissueTumour
							,BankedTissueBlood								= mmv.BankedTissueBlood
							,BankedTissueCSF								= mmv.BankedTissueCSF
							,BankedTissueBoneMarrow							= mmv.BankedTissueBoneMarrow
							,SNOMed_CT										= mmv.SNOMed_CT
							,ADT_PLACER_ID									= mmv.ADT_PLACER_ID
							,SNOMEDCTDiagnosisID							= mmv.SNOMEDCTDiagnosisID
							,FasterDiagnosisOrganisationID					= mmv.FasterDiagnosisOrganisationID
							,FasterDiagnosisCancerSiteOverrideID			= mmv.FasterDiagnosisCancerSiteOverrideID
							,FasterDiagnosisExclusionDate					= mmv.FasterDiagnosisExclusionDate
							,FasterDiagnosisExclusionReasonID				= mmv.FasterDiagnosisExclusionReasonID
							,FasterDiagnosisDelayReasonID					= mmv.FasterDiagnosisDelayReasonID
							,FasterDiagnosisDelayReasonComments				= mmv.FasterDiagnosisDelayReasonComments
							,FasterDiagnosisCommunicationMethodID			= mmv.FasterDiagnosisCommunicationMethodID
							,FasterDiagnosisInformingCareProfessionalID		= mmv.FasterDiagnosisInformingCareProfessionalID
							,FasterDiagnosisOtherCareProfessional			= mmv.FasterDiagnosisOtherCareProfessional
							,FasterDiagnosisOtherCommunicationMethod		= mmv.FasterDiagnosisOtherCommunicationMethod
							,NonPrimaryPathwayOptionsID						= mmv.NonPrimaryPathwayOptionsID
							,DiagnosisUncertainty							= mmv.DiagnosisUncertainty
							,TNMOrganisation								= mmv.TNMOrganisation
							,FasterDiagnosisTargetRCComments				= mmv.FasterDiagnosisTargetRCComments
							,FasterDiagnosisEndRCComments					= mmv.FasterDiagnosisEndRCComments
							,TNMOrganisation_Integrated						= mmv.TNMOrganisation_Integrated
							,LDHValue										= mmv.LDHValue
							,BankedTissueUrine								= mmv.BankedTissueUrine
							,SubsiteID										= mmv.SubsiteID
							,PredictedBreachStatus							= mmv.PredictedBreachStatus
							,RMRefID										= mmv.RMRefID
							,TertiaryReferralKey							= mmv.TertiaryReferralKey
							,ClinicalTLetter								= mmv.ClinicalTLetter
							,ClinicalNLetter								= mmv.ClinicalNLetter
							,ClinicalMLetter								= mmv.ClinicalMLetter
							,PathologicalTLetter							= mmv.PathologicalTLetter
							,PathologicalNLetter							= mmv.PathologicalNLetter
							,PathologicalMLetter							= mmv.PathologicalMLetter
							,FDPlannedInterval								= mmv.FDPlannedInterval
							,LabReportDate									= mmv.LabReportDate
							,LabReportOrgID									= mmv.LabReportOrgID
							,ReferralRoute									= mmv.ReferralRoute
							,ReferralOtherRoute								= mmv.ReferralOtherRoute
							,RelapseMorphology								= mmv.RelapseMorphology
							,RelapseFlow									= mmv.RelapseFlow
							,RelapseMolecular								= mmv.RelapseMolecular
							,RelapseClinicalExamination						= mmv.RelapseClinicalExamination
							,RelapseOther									= mmv.RelapseOther
							,RapidDiagnostic								= mmv.RapidDiagnostic
							,PrimaryReferralFlag							= mmv.PrimaryReferralFlag
							,OtherAssessedBy								= mmv.OtherAssessedBy
							,SharedBreach									= mmv.SharedBreach
							,PredictedBreachYear							= mmv.PredictedBreachYear
							,PredictedBreachMonth							= mmv.PredictedBreachMonth
				FROM		#tblMAIN_REFERRALS_Match_MajorValidation mmv

				-- Insert all new records into major validation columns
				INSERT INTO	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidationColumns
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
				FROM		#tblMAIN_REFERRALS_Match_MajorValidationColumns mmvc



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
				INSERT INTO #MakeMajor (SrcSys_Major_Curr,Src_UID_Major_Curr)
				SELECT		mc.SrcSys_Major
							,mc.Src_UID_Major
				FROM		(SELECT		mc_inner.SrcSys_Major
										,mc_inner.Src_UID_Major
										,SUM(CASE WHEN mc_inner.SrcSys = 1 THEN 1 ELSE 0 END) AS SrcSys_WSHT
										,SUM(CASE WHEN mc_inner.SrcSys = 2 THEN 1 ELSE 0 END) AS SrcSys_BSUH
										,SUM(CASE WHEN mc_inner.SrcSys > 2 THEN 1 ELSE 0 END) AS SrcSys_Ext
										,SUM(CASE WHEN uh.N2_9_FIRST_SEEN_DATE IS NOT NULL THEN 1 ELSE 0 END) AS FirstSeenCount
										,SUM(CASE WHEN uh.N1_3_ORG_CODE_SEEN = 'RYR16' THEN 1 ELSE 0 END) AS SRH_Count
										,SUM(CASE WHEN uh.N1_3_ORG_CODE_SEEN = 'RYR18' THEN 1 ELSE 0 END) AS WOR_Count
							FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc_inner
							LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_All ep_allA
																									ON	mc_inner.SrcSys = ep_allA.SrcSys_A
																									AND	mc_inner.Src_UID = ep_allA.Src_UID_A
																									AND	ep_allA.MatchType = 5 -- ADT_Ref_ID match
							LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_All ep_allB
																									ON	mc_inner.SrcSys = ep_allB.SrcSys_B
																									AND	mc_inner.Src_UID = ep_allB.Src_UID_B
																									AND	ep_allB.MatchType = 5 -- ADT_Ref_ID match
							LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																						ON	mc_inner.SrcSys = uh.SrcSys
																						AND	mc_inner.Src_UID = uh.Src_UID
							WHERE		(ep_allA.SrcSys_A IS NOT NULL
							OR			ep_allB.SrcSys_B IS NOT NULL)
							AND			mc_inner.DeletedDttm IS NULL
							GROUP BY	mc_inner.SrcSys_Major
										,mc_inner.Src_UID_Major
										) mc
				LEFT JOIN	(SELECT		mc.SrcSys_Major
										,mc.Src_UID_Major
							FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_Unique ep_u
							INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
																						ON	ep_u.SrcSys_A = mc.SrcSys
																						AND	ep_u.Src_UID_A = mc.Src_UID
							WHERE		ep_u.BestIntention = 'Manual'
							GROUP BY	mc.SrcSys_Major
										,mc.Src_UID_Major
										) NonAlgorithmic
														ON	mc.SrcSys_Major = NonAlgorithmic.SrcSys_Major
														AND	mc.Src_UID_Major = NonAlgorithmic.Src_UID_Major
				LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv_confirmed
																					ON	mc.SrcSys_Major = mmv_confirmed.SrcSys_Major
																					AND	mc.Src_UID_Major = mmv_confirmed.Src_UID_Major
																					AND	mmv_confirmed.ValidationStatus = 'Confirmed'
				WHERE		mmv_confirmed.SrcSys_Major IS NULL
				AND			NonAlgorithmic.SrcSys_Major IS NULL
				AND			mc.SrcSys_BSUH = 0
				AND			mc.SrcSys_WSHT = 2		-- ADT referrals that were sent to each of the Worthing and SRH SCR's
				AND			mc.FirstSeenCount = 1	-- ADT referrals where only one was marked as seen
				AND			mc.SRH_Count = 1
				AND			mc.WOR_Count = 1
				
				-- Find the most recent minor record for each current major to be automatically confirmed
				UPDATE		mm
				SET			mm.SrcSys_Major_New = mostRecentMinor.SrcSys_Major_New
							,mm.Src_UID_Major_New = mostRecentMinor.Src_UID_Major_New
				FROM		(SELECT		mc.SrcSys_Major AS SrcSys_Major_Curr
										,mc.Src_UID_Major AS Src_UID_Major_Curr
										,mc.SrcSys AS SrcSys_Major_New
										,mc.Src_UID AS Src_UID_Major_New
										,McIx	= ROW_NUMBER() OVER(PARTITION BY mc.SrcSys_Major, mc.Src_UID_Major ORDER BY CASE WHEN uh.N2_9_FIRST_SEEN_DATE IS NOT NULL THEN 1 ELSE 2 END, uh.LastUpdated DESC)
							FROM		#MakeMajor mm_inner
							INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
																						ON	mm_inner.SrcSys_Major_Curr = mc.SrcSys_Major
																						AND	mm_inner.Src_UID_Major_Curr = mc.Src_UID_Major
							INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
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

				-- Remove any records that already have the correct major from #MakeMajor
				DELETE
				FROM		mm
				FROM		#MakeMajor mm
				WHERE		mm.SrcSys_Major_Curr = mm.SrcSys_Major_New
				AND			mm.Src_UID_Major_Curr = mm.Src_UID_Major_New

				-- Process the records that need their major changing
				EXEC Merge_DM_Match.uspMakeMajor @tableName = 'tblMAIN_REFERRALS', @UserID = 'tblMAIN_REFERRALS_uspMatchEntityPairs'
		
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
				EXEC Merge_DM_Match.uspConfirmMajor @tableName = 'tblMAIN_REFERRALS', @UserID = 'tblMAIN_REFERRALS_uspMatchEntityPairs'

		END



GO
