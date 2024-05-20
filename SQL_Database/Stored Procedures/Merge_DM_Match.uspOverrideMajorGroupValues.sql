SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_Match].[uspOverrideMajorGroupValues]

		(@tableName VARCHAR(255)
		,@SrcSys_Major TINYINT
		,@Src_UID_Major VARCHAR(255)
		,@CohortName VARCHAR(255)
		,@SrcSys_Donor TINYINT
		,@Src_UID_Donor VARCHAR(255)
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

Original Work Created Date:	30/04/2024
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				A stored procedure to decide whether to override a single column value for a major entity with a single column value 
							from a donor entity or to override multiple column values from the donor
**************************************************************************************************************************************************/

-- Test me
-- 

		/*****************************************************************************************************************************************/
		-- Decide the column override(s) to be executed, whether single or multiple
		/*****************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#columnOverrides') IS NOT NULL DROP TABLE #columnOverrides
		CREATE TABLE #columnOverrides	(OverrideIx SMALLINT IDENTITY(1,1)
										,tableName VARCHAR(255)
										,ColumnName VARCHAR(255)
										)

		-- Insert the columns from a column group if the cohort is a valid column group
		INSERT INTO #columnOverrides (tableName, ColumnName)
		SELECT		TableName
					,ColumnName
		FROM		Merge_DM_Match.Config_ColumnsAndGroups
		WHERE		TableName = @tableName
		AND			ColumnGroup = @CohortName

		-- Run through pre-determined column override blocks (if the cohort isn't a column group)
		IF (SELECT COUNT(*) FROM #columnOverrides) = 0
		BEGIN

				IF	@tableName = 'tblMAIN_REFERRALS'
				AND	@CohortName IN ('N2_9_FIRST_SEEN_DATE', 'FIRST_APPT_TIME')
				BEGIN
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'N2_9_FIRST_SEEN_DATE')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'FIRST_APPT_TIME')
				END

				ELSE IF	@tableName = 'tblMAIN_REFERRALS'
				AND	@CohortName IN ('N2_15_ADJ_REASON', 'L_FIRST_APPOINTMENT', 'L_NO_APP', 'N2_14_ADJ_TIME', 'L_CANCELLED_DATE')
				BEGIN
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'N2_15_ADJ_REASON')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'L_FIRST_APPOINTMENT')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'L_NO_APP')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'N2_14_ADJ_TIME')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'L_CANCELLED_DATE')
				END

				ELSE IF	@tableName = 'tblMAIN_REFERRALS'
				AND	@CohortName IN ('L_DIAGNOSIS', 'N4_2_DIAGNOSIS_CODE', 'N4_5_HISTOLOGY', 'N4_6_DIFFERENTIATION', 'N4_4_BASIS_DIAGNOSIS', 'L_TOPOGRAPHY', 'SNOMED_CT', 'SNOMEDCTDiagnosisID')
				BEGIN
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'L_DIAGNOSIS')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'N4_2_DIAGNOSIS_CODE')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'N4_5_HISTOLOGY')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'N4_6_DIFFERENTIATION')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'N4_4_BASIS_DIAGNOSIS')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'L_TOPOGRAPHY')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'SNOMED_CT')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'SNOMEDCTDiagnosisID')
				END

				ELSE IF	@tableName = 'tblMAIN_REFERRALS'
				AND	@CohortName IN ('ClinicalTStage','ClinicalTCertainty','ClinicalNStage','ClinicalNCertainty','ClinicalMStage','ClinicalMCertainty','ClinicalOverallCertainty','PathologicalTStage'
									,'PathologicalNStage','PathologicalMStage','PathologicalTNMDate','ClinicalTNMDate','ClinicalTLetter','ClinicalNLetter','ClinicalMLetter','PathologicalTLetter'
									,'PathologicalNLetter','PathologicalMLetter')
				BEGIN
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'ClinicalTStage')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'ClinicalTCertainty')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'ClinicalNStage')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'ClinicalNCertainty')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'ClinicalMStage')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'ClinicalMCertainty')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'ClinicalOverallCertainty')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'PathologicalTStage')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'PathologicalNStage')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'PathologicalMStage')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'PathologicalTNMDate')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'ClinicalTNMDate')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'ClinicalTLetter')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'ClinicalNLetter')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'ClinicalMLetter')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'PathologicalTLetter')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'PathologicalNLetter')
					INSERT INTO #columnOverrides (tableName, ColumnName) VALUES ('tblMAIN_REFERRALS', 'PathologicalMLetter')
				END

		END

		


		-- Just process the column (if the cohort isn't a column group or pre-determined column override block)
		IF (SELECT COUNT(*) FROM #columnOverrides) = 0
		AND (SELECT COUNT(*) FROM Merge_DM_Match.Config_ColumnsAndGroups WHERE TableName = @tableName AND ColumnName = @CohortName) > 0
		INSERT INTO #columnOverrides (tableName, ColumnName) VALUES (@tableName, @CohortName)
		
		/*****************************************************************************************************************************************/
		-- Execute the column override(s)
		/*****************************************************************************************************************************************/

		DECLARE @OverrideIx SMALLINT = 1
		DECLARE @_tableName VARCHAR(255)
		DECLARE @_ColumnName VARCHAR(255)

		-- Loop through each record in #columnOverrides and execute the column override for that row
		WHILE @OverrideIx <= (SELECT MAX(OverrideIx) FROM #columnOverrides)
		BEGIN
				-- Set the table name and column name parameters for this iteration
				SELECT		@_tableName = tableName
							,@_ColumnName = ColumnName
				FROM		#columnOverrides
				WHERE		OverrideIx = @OverrideIx

				-- execute the column override
				EXEC Merge_DM_Match.uspOverrideMajorColumnValue  @UserID = @UserID, @tableName = @_tableName, @SrcSys_Major = @SrcSys_Major, @Src_UID_Major = @Src_UID_Major, @ColumnName = @_ColumnName, @SrcSys_Donor = @SrcSys_Donor, @Src_UID_Donor = @Src_UID_Donor

				-- Increment @OverrideIx
				SET @OverrideIx = @OverrideIx + 1

		END
GO
