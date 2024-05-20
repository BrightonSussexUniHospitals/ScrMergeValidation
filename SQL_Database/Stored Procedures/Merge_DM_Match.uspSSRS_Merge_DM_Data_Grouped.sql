SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [Merge_DM_Match].[uspSSRS_Merge_DM_Data_Grouped]

		(@tableName VARCHAR(255) = ''
		,@SrcSys TINYINT = NULL
		,@Src_UID VARCHAR(255) = NULL
		,@ClearUnlinks BIT = 0
		,@RecalcLinks BIT = 0
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

Original Work Created Date:	11/03/2024
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				A stored procedure to return the DM matching data for validation
**************************************************************************************************************************************************/

-- Test me
-- EXEC Merge_DM_Match.uspSSRS_Merge_DM_Data @tableName = 'tblDEMOGRAPHICS', @SrcSys = 1, @Src_UID = '47632'

		/*****************************************************************************************************************************************/
		-- Prepare for the updates
		/*****************************************************************************************************************************************/
		
		-- Declare a variable to contain the dynamic SQL -- DECLARE @tableName VARCHAR(255) = 'tblDEMOGRAPHICS', @SrcSys TINYINT = 1, @Src_UID VARCHAR(255) = '47632'
		DECLARE @SQL VARCHAR(MAX)

		-- Test whether @tableName is a valid table
		IF OBJECT_ID('Merge_DM_Match.' + @tableName + '_Match_Control') IS NULL
		BEGIN
				PRINT 'Table not valid'
				RETURN
		END
			-- Create a control table we will use to manage the dynamic SQL
		IF OBJECT_ID('tempdb..#DynamicSqlControl') IS NOT NULL DROP TABLE #DynamicSqlControl
		CREATE TABLE #DynamicSqlControl (ControlType VARCHAR(255), ControlValue SQL_VARIANT)

		-- Record a consistent getdate in the dynamic sql control table
		INSERT INTO #DynamicSqlControl (ControlType, ControlValue) SELECT 'GETDATE', GETDATE()
		INSERT INTO #DynamicSqlControl (ControlType, ControlValue) SELECT 'SrcSys', @SrcSys
		INSERT INTO #DynamicSqlControl (ControlType, ControlValue) SELECT 'Src_UID', @Src_UID

		/*****************************************************************************************************************************************/
		-- Find all the entities related to the SrcSys and Src_UID supplied
		/*****************************************************************************************************************************************/
		
		-- Create the #RelatedEntities table
		IF OBJECT_ID('tempdb..#RelatedEntities') IS NOT NULL DROP TABLE #RelatedEntities
		CREATE TABLE #RelatedEntities (IsSCR BIT NOT NULL, SrcSys TINYINT NOT NULL, Src_UID VARCHAR(255) NOT NULL)

		-- Insert the records that relate to the Major ID supplied
		SET @SQL = '' +
		'	DECLARE @SrcSys TINYINT; SELECT @SrcSys = CONVERT(TINYINT, ControlValue) FROM #DynamicSqlControl WHERE ControlType = ''SrcSys''; ' + CHAR(13) +
		'	DECLARE @Src_UID VARCHAR(255); SELECT @Src_UID = CONVERT(VARCHAR(255), ControlValue) FROM #DynamicSqlControl WHERE ControlType = ''Src_UID''; ' + CHAR(13) +
		'	INSERT INTO	#RelatedEntities ' + CHAR(13) +
		'				(IsSCR ' + CHAR(13) +
		'				,SrcSys ' + CHAR(13) +
		'				,Src_UID) ' + CHAR(13) +
		'	SELECT		ISNULL(mc_minor.IsSCR, mc_major.IsSCR) AS IsSCR ' + CHAR(13) +
		'				,ISNULL(mc_minor.SrcSys, mc_major.SrcSys) AS SrcSys ' + CHAR(13) +
		'				,ISNULL(mc_minor.Src_UID, mc_major.Src_UID) AS Src_UID ' + CHAR(13) +
		'	FROM		Merge_DM_Match.' + @tableName + '_Match_Control mc_major ' + CHAR(13) +
		'	LEFT JOIN	Merge_DM_Match.' + @tableName + '_Match_Control mc_minor ' + CHAR(13) +
		'														ON	mc_major.SrcSys_Major = mc_minor.SrcSys_Major ' + CHAR(13) +
		'														AND	mc_Major.Src_UID_Major = mc_minor.Src_UID_Major ' + CHAR(13) +
		'	WHERE		(mc_major.SrcSys_Major = @SrcSys ' + CHAR(13) +
		'	AND			mc_major.Src_UID_Major = @Src_UID) ' + CHAR(13) +
		'	OR			(mc_major.SrcSys = @SrcSys ' + CHAR(13) +
		'	AND			mc_major.Src_UID = @Src_UID) ' + CHAR(13) +
		'	GROUP BY	ISNULL(mc_minor.IsSCR, mc_major.IsSCR) ' + CHAR(13) +
		'				,ISNULL(mc_minor.SrcSys, mc_major.SrcSys) ' + CHAR(13) +
		'				,ISNULL(mc_minor.Src_UID, mc_major.Src_UID) '

		EXEC (@SQL)

		-- Loop through the dataset to find any other records that were originally matched
		SET @SQL = '' +
		'	DECLARE @NoMoreUpdates SMALLINT = 0 ' + CHAR(13) +
		'	WHILE @NoMoreUpdates = 0 ' + CHAR(13) +
		'	BEGIN ' + CHAR(13) +
		'	 ' + CHAR(13) +
		'			INSERT INTO	#RelatedEntities ' + CHAR(13) +
		'						(IsSCR ' + CHAR(13) +
		'						,SrcSys ' + CHAR(13) +
		'						,Src_UID) ' + CHAR(13) +
		'			SELECT		mc.IsSCR ' + CHAR(13) +
		'						,IterateNext.SrcSys_Iterative ' + CHAR(13) +
		'						,IterateNext.Src_UID_Iterative ' + CHAR(13) +
		'			FROM		#RelatedEntities inc ' + CHAR(13) +
		'			INNER JOIN	(SELECT		SrcSys_A AS SrcSys_Link ' + CHAR(13) +
		'									,Src_UID_A AS Src_UID_Link ' + CHAR(13) +
		'									,SrcSys_B AS SrcSys_Iterative ' + CHAR(13) +
		'									,Src_UID_B AS Src_UID_Iterative ' + CHAR(13) +
		'						FROM		Merge_DM_Match.' + @tableName + '_Match_EntityPairs_Unique ep_u ' + CHAR(13) +
		'	 ' + CHAR(13) +
		'						UNION ' + CHAR(13) +
		'	 ' + CHAR(13) +
		'						SELECT		SrcSys_B AS SrcSys_Link ' + CHAR(13) +
		'									,Src_UID_B AS Src_UID_Link ' + CHAR(13) +
		'									,SrcSys_A AS SrcSys_Iterative ' + CHAR(13) +
		'									,Src_UID_A AS Src_UID_Iterative ' + CHAR(13) +
		'						FROM		Merge_DM_Match.' + @tableName + '_Match_EntityPairs_Unique ep_u ' + CHAR(13) +
		'									) IterateNext ' + CHAR(13) +
		'													ON	inc.SrcSys = IterateNext.SrcSys_Link ' + CHAR(13) +
		'													AND	inc.Src_UID = IterateNext.Src_UID_Link ' + CHAR(13) +
		'			INNER JOIN	Merge_DM_Match.' + @tableName + '_Match_Control mc ' + CHAR(13) +
		'												ON	IterateNext.SrcSys_Iterative = mc.SrcSys ' + CHAR(13) +
		'												AND	IterateNext.Src_UID_Iterative = mc.Src_UID ' + CHAR(13) +
		'			LEFT JOIN	#RelatedEntities inc_notPresent ' + CHAR(13) +
		'												ON	IterateNext.SrcSys_Iterative = inc_notPresent.SrcSys ' + CHAR(13) +
		'												AND	IterateNext.Src_UID_Iterative = inc_notPresent.Src_UID ' + CHAR(13) +
		'			WHERE		inc_notPresent.SrcSys IS NULL ' + CHAR(13) +
		'			GROUP BY	mc.IsSCR ' + CHAR(13) +
		'						,IterateNext.SrcSys_Iterative ' + CHAR(13) +
		'						,IterateNext.Src_UID_Iterative ' + CHAR(13) +
		'	 ' + CHAR(13) +
		'			-- Exit the loop if there were no more instances to find ' + CHAR(13) +
		'			IF @@ROWCOUNT = 0 ' + CHAR(13) +
		'			SET @NoMoreUpdates = 1 ' + CHAR(13) +
		'	 ' + CHAR(13) +
		'	END '

		EXEC (@SQL)

		/*****************************************************************************************************************************************/
		-- Clear unlinks and / or recalculate links
		/*****************************************************************************************************************************************/

		-- Clear unlinks if requested
		IF @ClearUnlinks = 1
		BEGIN
				-- Update any matches with pair A
				SET @SQL = '' +
				'UPDATE		ep_u
				SET			UnlinkDttm = NULL
							,LastUnlinkedBy = NULL
							,UnlinkProcessed = NULL
				FROM		Merge_DM_Match.' + @tableName + '_Match_EntityPairs_Unique ep_u
				INNER JOIN	#RelatedEntities re
											ON	ep_u.SrcSys_A = re.SrcSys
											AND	ep_u.Src_UID_A = re.Src_UID'

				EXEC (@SQL)

				-- Update any matches with pair B
				SET @SQL = '' +
				'UPDATE		ep_u
				SET			UnlinkDttm = NULL
							,LastUnlinkedBy = NULL
							,UnlinkProcessed = NULL
				FROM		Merge_DM_Match.' + @tableName + '_Match_EntityPairs_Unique ep_u
				INNER JOIN	#RelatedEntities re
											ON	ep_u.SrcSys_B = re.SrcSys
											AND	ep_u.Src_UID_B = re.Src_UID'

				EXEC (@SQL)

		END
		
		-- Recalculate the links for all related majors
		IF @ClearUnlinks = 1 OR @RecalcLinks = 1
		BEGIN
				-- Recalculate the links for all related majors
				SET @SQL = '' +
				'EXEC Merge_DM_Match.' + @tableName + '_uspMatchEntityPairs @MajorID_SrcSys = ' + CAST(@SrcSys AS VARCHAR(255)) + ', @MajorID_Src_UID = ' + @Src_UID + ', @UseExistingMatches = 1 '

				EXEC (@SQL) -- EXEC Merge_DM_Match.tblDEMOGRAPHICS_uspMatchEntityPairs @MajorID_SrcSys = @SrcSys, @MajorID_Src_UID = @Src_UID, @UseExistingMatches = 1

		END


		/*****************************************************************************************************************************************/
		-- Return the SSRS output for the entities related to the SrcSys and Src_UID supplied
		/*****************************************************************************************************************************************/

		-- Drop the #ReportOutput if it exists
		IF OBJECT_ID('tempdb..#ReportOutput') IS NOT NULL DROP TABLE #ReportOutput
		
		-- Create a table to hold the report output (this will be populated by the validated data stored procedure)
		CREATE TABLE #ReportOutput
					(ReportingCohort VARCHAR(255)
					,SrcSys_MajorExt TINYINT
					,Src_UID_MajorExt VARCHAR(255)
					,SrcSys_Major TINYINT
					,Src_UID_Major VARCHAR(255)
					,IsValidatedMajor BIT
					,LastUpdated DATETIME
					,ScrHyperlink VARCHAR(255)
					,SrcSys TINYINT
					,Src_UID VARCHAR(255)
					,FieldName VARCHAR(255)
					,FieldValue VARCHAR(8000)
					,ColumnDesc VARCHAR(255)
					,ColumnGroup VARCHAR(255)
					,ColumnSort SMALLINT
					,ColumnGroupSort TINYINT
					,ColumnGroupSummary VARCHAR(1000)
					,UnseenColumnsWithDiffs SMALLINT
					,IsColumnOverride BIT
					)

		-- Insert the records that relate to the Major ID supplied -- DECLARE @SQL VARCHAR(MAX), @tableName VARCHAR(255) = 'tblDEMOGRAPHICS'
		SET @SQL = '' +
		'	INSERT INTO	#ReportOutput ' + CHAR(13) +
		'	EXEC Merge_DM_Match.' + @tableName + '_uspValidatedData @PivotForSSRS = 1 '

		EXEC (@SQL) -- EXEC Merge_DM_Match.tblDEMOGRAPHICS_uspValidatedData

		-- Return the output
		SELECT		*
		FROM		#ReportOutput ro
GO
