SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_Match].[uspOverrideMajorColumnValue]

		(@tableName VARCHAR(255)
		,@SrcSys_Major TINYINT
		,@Src_UID_Major VARCHAR(255)
		,@ColumnName VARCHAR(255)
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

Original Work Created Date:	31/01/2024
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				A stored procedure to override a column value for a major entity with the column value from a donor entity
**************************************************************************************************************************************************/

-- Test me
-- EXEC Merge_DM_Match.uspOverrideMajorColumnValue  @UserID = 'BSUH\matthew.bishop', @tableName = 'tbl_XXX', @SrcSys_Major = 1, @Src_UID_Major = 1, @ColumnName = 'email', @SrcSys_Donor = 1, @Src_UID_Donor = 2
-- EXEC Merge_DM_Match.uspOverrideMajorColumnValue  @UserID = 'BSUH\matthew.bishop', @tableName = 'tbl_XXX', @SrcSys_Major = 1, @Src_UID_Major = 1, @ColumnName = 'FullName', @SrcSys_Donor = 1, @Src_UID_Donor = 2
-- EXEC Merge_DM_Match.uspOverrideMajorColumnValue  @UserID = 'BSUH\matthew.bishop', @tableName = 'tbl_XXX', @SrcSys_Major = 1, @Src_UID_Major = 1, @ColumnName = 'username', @SrcSys_Donor = 1, @Src_UID_Donor = 2
-- EXEC Merge_DM_Match.uspOverrideMajorColumnValue  @UserID = 'BSUH\matthew.bishop', @tableName = 'tblDEMOGRAPHICS', @SrcSys_Major = 3, @Src_UID_Major = '57E87725-70BE-4B51-A8EE-F6FB9ADB653D', @ColumnName = 'N1_6_FORENAME', @SrcSys_Donor = 2, @Src_UID_Donor = '51200'

		/*****************************************************************************************************************************************/
		-- Prepare for the updates
		/*****************************************************************************************************************************************/
		
		DECLARE @SQL VARCHAR(MAX)

		-- Create a control table we will use to manage the dynamic SQL
		IF OBJECT_ID('tempdb..#DynamicSqlControl') IS NOT NULL DROP TABLE #DynamicSqlControl
		CREATE TABLE #DynamicSqlControl (ControlType VARCHAR(255), ControlValue SQL_VARIANT)

		-- Test whether the entity being confirmed is a major entity and is an SCR record
		SET @SQL =	'INSERT INTO #DynamicSqlControl (ControlType, ControlValue) ' + CHAR(13) +
					'SELECT ''ValidityTest'', COUNT(*) ' + CHAR(13) +
					'FROM Merge_DM_Match.' + @tableName + '_Match_Control ' + CHAR(13) +
					'WHERE SrcSys_Major = ' + CAST(@SrcSys_Major AS VARCHAR(255)) + ' ' + CHAR(13) +
					'AND Src_UID_Major = ''' + @Src_UID_Major + ''' ' + CHAR(13) +
					'AND IsScr = 1' + CHAR(13)
		EXEC (@SQL)

		-- Record a consistent getdate in the dynamic sql control table
		INSERT INTO #DynamicSqlControl (ControlType, ControlValue) SELECT 'GETDATE', GETDATE()

		/*****************************************************************************************************************************************/
		-- Create the SQL to insert a validation record if required
		/*****************************************************************************************************************************************/
		
		DECLARE @SQL_mmv VARCHAR(MAX) = ''

		SET @SQL_mmv =	'IF (SELECT COUNT(*) FROM Merge_DM_Match.' + @tableName + '_Match_MajorValidation WHERE SrcSys_Major = ' + CAST(@SrcSys_Major AS VARCHAR(255)) + ' AND Src_UID_Major = ''' + @Src_UID_Major + ''') = 0 ' + CHAR(13) +
						'INSERT INTO	Merge_DM_Match.' + @tableName + '_Match_MajorValidation ' + CHAR(13) +
						'			(SrcSys_Major ' + CHAR(13) +
						'			,Src_UID_Major ' + CHAR(13) +
						'			,LastValidatedDttm ' + CHAR(13) +
						'			,LastValidatedBy ' + CHAR(13) +
						'			,ValidationStatus ' + CHAR(13) +
						'			) ' + CHAR(13) +
						'SELECT		' + CAST(@SrcSys_Major AS VARCHAR(255)) + ' ' + CHAR(13) +
						'			,''' + @Src_UID_Major + ''' ' + CHAR(13) +
						'			,GETDATE() ' + CHAR(13) +
						'			,''' + @UserID + ''' ' + CHAR(13) +
						'			,''Column Override'' ' + CHAR(13) +
						'ELSE ' + CHAR(13) +
						'UPDATE		Merge_DM_Match.' + @tableName + '_Match_MajorValidation ' + CHAR(13) +
						'SET		LastValidatedDttm = GETDATE() ' + CHAR(13) +
						'			,LastValidatedBy = ''' + @UserID + ''' ' + CHAR(13) +
						'			,ValidationStatus = ''Column Override'' ' + CHAR(13) +
						'WHERE		SrcSys_Major = ' + CAST(@SrcSys_Major AS VARCHAR(255)) + ' ' + CHAR(13) +
						'AND		Src_UID_Major = ''' + @Src_UID_Major + ''' ' + CHAR(13)
		
		/*****************************************************************************************************************************************/
		-- Create the SQL to collect the donor column values, using _H views if there are any in preference to _UH views
		/*****************************************************************************************************************************************/
		
		DECLARE @SQL_ColumnOverrides VARCHAR(MAX) = ''
		
		-- Determine the views we will retrieve the donor column values from
		IF OBJECT_ID('tempdb..#donorViews') IS NOT NULL DROP TABLE #donorViews
		SELECT		donorViews.ViewName
					,donorViews.SchemaName
					,ROW_NUMBER() OVER (PARTITION BY donorViews.ViewStemName ORDER BY CASE WHEN donorViews.ViewName LIKE '%mvw%' THEN 1 ELSE 2 END, donorViews.ViewName) AS ViewNameIx
		INTO		#donorViews
		FROM		(SELECT		tv.name AS ViewName
								,s.name AS SchemaName
								,LEFT(tv.name, dbo.fnHighestIntFromArray(1, CHARINDEX('_vw',tv.name),CHARINDEX('_mvw',tv.name),0,0,0,0,0,0,0,0)) AS ViewStemName
								,CASE WHEN tv.name LIKE '%¿_mvw¿_%' ESCAPE '¿' THEN 1 ELSE 0 END AS Is_M_view
								,CASE WHEN tv.name LIKE '%¿_vw¿_UH' ESCAPE '¿' THEN 1 ELSE 0 END AS Is_UH_view
								,CASE WHEN tv.name LIKE '%¿_H¿_%' ESCAPE '¿' THEN 1 ELSE 0 END AS Is_H_view
								,MAX(CASE WHEN tv.name LIKE '%¿_mvw¿_%' ESCAPE '¿' THEN 1 ELSE 0 END) OVER (PARTITION BY LEFT(tv.name, dbo.fnHighestIntFromArray(1, CHARINDEX('_vw',tv.name),CHARINDEX('_mvw',tv.name),0,0,0,0,0,0,0,0))) AS Has_M_view
								,MAX(CASE WHEN tv.name LIKE '%¿_H¿_%' ESCAPE '¿' THEN 1 ELSE 0 END) OVER (PARTITION BY LEFT(tv.name, dbo.fnHighestIntFromArray(1, CHARINDEX('_vw',tv.name),CHARINDEX('_mvw',tv.name),0,0,0,0,0,0,0,0))) AS Has_H_view
					FROM		(SELECT schema_id, name, 't' AS TableSource FROM sys.tables UNION ALL SELECT schema_id, name, 'v' AS TableSource FROM sys.views) tv
					INNER JOIN	sys.schemas s
											ON	tv.schema_id = s.schema_id
											AND	s.name IN ('Merge_DM_Match','Merge_DM_MatchViews')
					WHERE		(tv.name LIKE '%¿_UH' ESCAPE '¿'
					OR			tv.name LIKE '%¿_H¿_%' ESCAPE '¿')
					AND			tv.name LIKE @tableName + '%'
								) donorViews
		WHERE		CASE	WHEN donorViews.Has_M_view = 1
							THEN donorViews.Is_M_view
							WHEN donorViews.Has_H_view = 1
							THEN donorViews.Is_H_view
							ELSE 1
							END = 1

		-- Drop the #ColumnOverride table if it exists
		IF OBJECT_ID('tempdb..#ColumnOverride') IS NOT NULL DROP TABLE #ColumnOverride

		-- Create the #ColumnOverride table
		SET	@SQL_ColumnOverrides = @SQL_ColumnOverrides +
					'SELECT ' + @ColumnName + ' INTO #ColumnOverride FROM Merge_DM_Match.' + @tableName + '_Match_MajorValidation WHERE 0 = 1 ' + CHAR(13) + CHAR(13)

		-- Loop through each donor column view and add the dynamic SQL that will be executed to collect the column override data
		DECLARE @donorViewsCounter TINYINT = 1
		WHILE @donorViewsCounter <= (SELECT MAX(ViewNameIx) FROM #donorViews)
		BEGIN
				-- Retrieve the donor column override value (and create the table if it doesn't exist)
				SELECT		@SQL_ColumnOverrides =	
							@SQL_ColumnOverrides +
							'INSERT INTO #ColumnOverride (' + @ColumnName + ') ' + CHAR(13) +
							'SELECT		' + @ColumnName + ' ' + CHAR(13) +
							'FROM		' + dv.SchemaName + '.' + dv.ViewName + ' uh ' + CHAR(13) +
							'WHERE		uh.SrcSys = ' + CAST(@SrcSys_Donor AS VARCHAR(255)) + ' ' + CHAR(13) +
							'AND		uh.Src_UID = ''' + @Src_UID_Donor + ''' ' + CHAR(13) + CHAR(13)
				FROM		#donorViews dv
				WHERE		dv.ViewNameIx = @donorViewsCounter
				
				-- Increment the @donorViewsCounter
				SET @donorViewsCounter = @donorViewsCounter + 1
		END

		-- Update the column override value in Match_MajorValidation
		SET @SQL_ColumnOverrides =
					@SQL_ColumnOverrides +
					'-- update the major validation record  ' + CHAR(13) +
					'UPDATE		mmv ' + CHAR(13) +
					'SET		mmv.' + @ColumnName + ' = co.' + @ColumnName + ' ' + CHAR(13) +
					'FROM		Merge_DM_Match.' + @tableName + '_Match_Control mc ' + CHAR(13) +
					'INNER JOIN	Merge_DM_Match.' + @tableName + '_Match_MajorValidation mmv ' + CHAR(13) +
					'																ON	mc.SrcSys_Major = mmv.SrcSys_Major ' + CHAR(13) +
					'																AND	mc.Src_UID_Major = mmv.Src_UID_Major ' + CHAR(13) +
					'CROSS JOIN	#ColumnOverride co ' + CHAR(13) +
					'WHERE		mc.SrcSys_Major = ' + CAST(@SrcSys_Major AS VARCHAR(255)) + ' ' + CHAR(13) +
					'AND		mc.Src_UID_Major = ''' + @Src_UID_Major + ''' ' + CHAR(13) +
					'AND		mc.SrcSys = ' + CAST(@SrcSys_Donor AS VARCHAR(255)) + ' ' + CHAR(13) +
					'AND		mc.Src_UID = ''' + @Src_UID_Donor + ''' ' + CHAR(13) + CHAR(13)

		-- Delete any column override presence in Match_MajorValidationColumns
		SET @SQL_ColumnOverrides =
					@SQL_ColumnOverrides +
					'-- Delete the column override record  ' + CHAR(13) +
					'DELETE ' + CHAR(13) +
					'FROM		mmvc ' + CHAR(13) +
					'FROM		Merge_DM_Match.' + @tableName + '_Match_MajorValidationColumns mmvc ' + CHAR(13) +
					'WHERE		mmvc.SrcSys_Major = ' + CAST(@SrcSys_Major AS VARCHAR(255)) + ' ' + CHAR(13) +
					'AND		mmvc.Src_UID_Major = ''' + @Src_UID_Major + ''' ' + CHAR(13) +
					'AND		mmvc.FieldName  = ''' + @ColumnName + ''' ' + CHAR(13) + CHAR(13)

		-- Insert the column override presence in Match_MajorValidationColumns
		SET @SQL_ColumnOverrides =
					@SQL_ColumnOverrides +
					'-- Insert the column override record  ' + CHAR(13) +
					'INSERT INTO Merge_DM_Match.' + @tableName + '_Match_MajorValidationColumns ' + CHAR(13) +
					'			(mmvc.SrcSys_Major ' + CHAR(13) +
					'			,mmvc.Src_UID_Major ' + CHAR(13) +
					'			,mmvc.SrcSys ' + CHAR(13) +
					'			,mmvc.Src_UID ' + CHAR(13) +
					'			,mmvc.FieldName ' + CHAR(13) +
					'			) ' + CHAR(13) +
					'VALUES		(' + CAST(@SrcSys_Major AS VARCHAR(255)) + ' ' + CHAR(13) +
					'			,''' + @Src_UID_Major + ''' ' + CHAR(13) +
					'			,' + CAST(@SrcSys_Donor AS VARCHAR(255)) + ' ' + CHAR(13) +
					'			,''' + @Src_UID_Donor + ''' ' + CHAR(13) +
					'			,''' + @ColumnName + ''' ' + CHAR(13) +
					'			) ' + CHAR(13) + CHAR(13)

		/*****************************************************************************************************************************************/
		-- Make the updates
		/*****************************************************************************************************************************************/
					
		IF (SELECT COUNT(*) FROM #DynamicSqlControl WHERE ControlType = 'ValidityTest' AND ControlValue > 0) = 1
		BEGIN TRY

			BEGIN TRANSACTION
			
				PRINT @SQL_mmv
				PRINT @SQL_ColumnOverrides

				EXEC (@SQL_mmv)
				EXEC (@SQL_ColumnOverrides)
		
			COMMIT TRANSACTION

			EXEC Merge_DM_MatchAudit.uspOverrideMajorColumnValue 1, NULL, @UserID, @tableName, @SrcSys_Major, @Src_UID_Major, @ColumnName, @SrcSys_Donor, @Src_UID_Donor

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
					PRINT 'Rolling back because of error in Merge_DM_Match.uspOverrideMajorColumnValue Transaction'
				ROLLBACK TRANSACTION

			EXEC Merge_DM_MatchAudit.uspOverrideMajorColumnValue 0, @ErrorMessage, @UserID, @tableName, @SrcSys_Major, @Src_UID_Major, @ColumnName, @SrcSys_Donor, @Src_UID_Donor

			RAISERROR (@ErrorMessage, -- Message text.  
										15, -- Severity.  
										1 -- State.  
										);
			
			RETURN 1

		END CATCH






GO
