SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






-- =======================================================================================================================================
-- Author:		<Author, Emily Welsby>
-- Create date: <Create Date, 16/02/2024>
-- Description:	<Description, Compare each column in PREMERGE CancerReporting to MERGE CancerReporting and insert differences into [Merge_R_Compare].[ReportingMergeDifferences] table>
-- =======================================================================================================================================
CREATE PROCEDURE [Merge_R_Compare].[CreateReportingMergeDifferences]

-- EXEC Merge_R_Compare.CreateReportingMergeDifferences
	
AS


		SET NOCOUNT ON;
		DECLARE @ErrorMessage VARCHAR(MAX)

/********************************************************************************************************************************************************************************************************************************/
-- Drop any _work tables used in the reconciliation
/********************************************************************************************************************************************************************************************************************************/

		PRINT CHAR(13) + '-- Take copies of the SCR_DW and SCR_ETL tables we need for reconciliation' + CHAR(13)
			
		-- Drop Column & Differences tables & view temp tables
		IF OBJECT_ID('Merge_R_Compare.ReportingMergeColumns_Work') IS NOT NULL DROP TABLE Merge_R_Compare.ReportingMergeColumns_Work
		IF OBJECT_ID('Merge_R_Compare.ReportingMergeDifferences_Work') IS NOT NULL DROP TABLE Merge_R_Compare.ReportingMergeDifferences_Work

		-- Drop the copies of the merge view _work tables
		IF OBJECT_ID('Merge_R_Compare.pre_scr_referrals_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_referrals_Work
		IF OBJECT_ID('Merge_R_Compare.pre_scr_cwt_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_cwt_Work
		IF OBJECT_ID('Merge_R_Compare.pre_OpenTargetDates_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_OpenTargetDates_Work
		IF OBJECT_ID('Merge_R_Compare.pre_scr_assessments_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_assessments_Work
		IF OBJECT_ID('Merge_R_Compare.pre_scr_comments_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_comments_Work
		IF OBJECT_ID('Merge_R_Compare.pre_scr_InterProviderTransfers_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_InterProviderTransfers_Work_Work
		IF OBJECT_ID('Merge_R_Compare.pre_scr_NextActions_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_NextActions_Work
		IF OBJECT_ID('Merge_R_Compare.pre_Workflow_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_Workflow_Work

/********************************************************************************************************************************************************************************************************************************/
-- Take copies of the SCR_DW and SCR_ETL tables we need for reconciliation
/********************************************************************************************************************************************************************************************************************************/

		-- Drop the copies of the SCR_DW _work tables
		IF OBJECT_ID('Merge_R_Compare.dbo_AspNetUsers_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_AspNetUsers_work
		IF OBJECT_ID('Merge_R_Compare.dbo_Organisations_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_Organisations_work
		IF OBJECT_ID('Merge_R_Compare.dbo_OrganisationSites_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_OrganisationSites_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblAllTreatmentDeclined_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblAllTreatmentDeclined_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblAUDIT_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblAUDIT_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblDEFINITIVE_TREATMENT_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblDEFINITIVE_TREATMENT_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblDEMOGRAPHICS_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblDEMOGRAPHICS_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblMAIN_ASSESSMENT_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMAIN_ASSESSMENT_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblMAIN_BRACHYTHERAPY_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMAIN_BRACHYTHERAPY_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblMAIN_CHEMOTHERAPY_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMAIN_CHEMOTHERAPY_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblMAIN_PALLIATIVE_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMAIN_PALLIATIVE_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblMAIN_REFERRALS_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMAIN_REFERRALS_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblMAIN_SURGERY_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMAIN_SURGERY_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblMAIN_TELETHERAPY_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMAIN_TELETHERAPY_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblMONITORING_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMONITORING_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblOTHER_TREATMENT_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblOTHER_TREATMENT_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblPathwayUpdateEvents_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblPathwayUpdateEvents_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblTERTIARY_REFERRALS_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblTERTIARY_REFERRALS_work
		IF OBJECT_ID('Merge_R_Compare.dbo_tblTRACKING_COMMENTS_work') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblTRACKING_COMMENTS_work

		-- Drop the copies of the SCR_ETL tables _work tables
		IF OBJECT_ID('Merge_R_Compare.tblDEMOGRAPHICS_tblValidatedData_work') IS NOT NULL DROP TABLE Merge_R_Compare.tblDEMOGRAPHICS_tblValidatedData_work
		IF OBJECT_ID('Merge_R_Compare.tblMAIN_REFERRALS_tblValidatedData_work') IS NOT NULL DROP TABLE Merge_R_Compare.tblMAIN_REFERRALS_tblValidatedData_work
		IF OBJECT_ID('Merge_R_Compare.Treatments_tblValidatedData_work') IS NOT NULL DROP TABLE Merge_R_Compare.Treatments_tblValidatedData_work
		IF OBJECT_ID('Merge_R_Compare.MDT_tblValidatedData_work') IS NOT NULL DROP TABLE Merge_R_Compare.MDT_tblValidatedData_work

		-- Take copies of the SCR_DW tables used for renumbering
		SELECT * INTO Merge_R_Compare.dbo_AspNetUsers_work FROM SCR_DW.SCR.dbo_AspNetUsers
		SELECT * INTO Merge_R_Compare.dbo_Organisations_work FROM SCR_DW.SCR.dbo_Organisations
		SELECT * INTO Merge_R_Compare.dbo_OrganisationSites_work FROM SCR_DW.SCR.dbo_OrganisationSites
		SELECT * INTO Merge_R_Compare.dbo_tblAllTreatmentDeclined_work FROM SCR_DW.SCR.dbo_tblAllTreatmentDeclined
		SELECT * INTO Merge_R_Compare.dbo_tblAUDIT_work FROM SCR_DW.SCR.dbo_tblAUDIT
		SELECT * INTO Merge_R_Compare.dbo_tblDEFINITIVE_TREATMENT_work FROM SCR_DW.SCR.dbo_tblDEFINITIVE_TREATMENT
		SELECT * INTO Merge_R_Compare.dbo_tblDEMOGRAPHICS_work FROM SCR_DW.SCR.dbo_tblDEMOGRAPHICS
		SELECT * INTO Merge_R_Compare.dbo_tblMAIN_ASSESSMENT_work FROM SCR_DW.SCR.dbo_tblMAIN_ASSESSMENT
		SELECT * INTO Merge_R_Compare.dbo_tblMAIN_BRACHYTHERAPY_work FROM SCR_DW.SCR.dbo_tblMAIN_BRACHYTHERAPY
		SELECT * INTO Merge_R_Compare.dbo_tblMAIN_CHEMOTHERAPY_work FROM SCR_DW.SCR.dbo_tblMAIN_CHEMOTHERAPY
		SELECT * INTO Merge_R_Compare.dbo_tblMAIN_PALLIATIVE_work FROM SCR_DW.SCR.dbo_tblMAIN_PALLIATIVE
		SELECT * INTO Merge_R_Compare.dbo_tblMAIN_REFERRALS_work FROM SCR_DW.SCR.dbo_tblMAIN_REFERRALS
		SELECT * INTO Merge_R_Compare.dbo_tblMAIN_SURGERY_work FROM SCR_DW.SCR.dbo_tblMAIN_SURGERY
		SELECT * INTO Merge_R_Compare.dbo_tblMAIN_TELETHERAPY_work FROM SCR_DW.SCR.dbo_tblMAIN_TELETHERAPY
		SELECT * INTO Merge_R_Compare.dbo_tblMONITORING_work FROM SCR_DW.SCR.dbo_tblMONITORING
		SELECT * INTO Merge_R_Compare.dbo_tblOTHER_TREATMENT_work FROM SCR_DW.SCR.dbo_tblOTHER_TREATMENT
		SELECT * INTO Merge_R_Compare.dbo_tblPathwayUpdateEvents_work FROM SCR_DW.SCR.dbo_tblPathwayUpdateEvents
		SELECT * INTO Merge_R_Compare.dbo_tblTERTIARY_REFERRALS_work FROM SCR_DW.SCR.dbo_tblTERTIARY_REFERRALS
		SELECT * INTO Merge_R_Compare.dbo_tblTRACKING_COMMENTS_work FROM SCR_DW.SCR.dbo_tblTRACKING_COMMENTS

		-- Take copies of the SCR_ETL tables used for deduplication
		SELECT * INTO Merge_R_Compare.tblDEMOGRAPHICS_tblValidatedData_work FROM SCR_ETL.map.tblDEMOGRAPHICS_tblValidatedData
		SELECT * INTO Merge_R_Compare.tblMAIN_REFERRALS_tblValidatedData_work FROM SCR_ETL.map.tblMAIN_REFERRALS_tblValidatedData
		SELECT * INTO Merge_R_Compare.Treatments_tblValidatedData_work FROM SCR_ETL.map.Treatments_tblValidatedData
		SELECT * INTO Merge_R_Compare.MDT_tblValidatedData_work FROM SCR_ETL.map.MDT_tblValidatedData

/********************************************************************************************************************************************************************************************************************************/
-- Swap out the _work tables for the final persisted tables
/********************************************************************************************************************************************************************************************************************************/

		BEGIN TRY

			BEGIN TRANSACTION

			-- Drop the copies of the SCR_DW tables used for renumbering
			IF OBJECT_ID('Merge_R_Compare.dbo_AspNetUsers') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_AspNetUsers
			IF OBJECT_ID('Merge_R_Compare.dbo_Organisations') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_Organisations
			IF OBJECT_ID('Merge_R_Compare.dbo_OrganisationSites') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_OrganisationSites
			IF OBJECT_ID('Merge_R_Compare.dbo_tblAllTreatmentDeclined') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblAllTreatmentDeclined
			IF OBJECT_ID('Merge_R_Compare.dbo_tblAUDIT') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblAUDIT
			IF OBJECT_ID('Merge_R_Compare.dbo_tblDEFINITIVE_TREATMENT') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblDEFINITIVE_TREATMENT
			IF OBJECT_ID('Merge_R_Compare.dbo_tblDEMOGRAPHICS') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblDEMOGRAPHICS
			IF OBJECT_ID('Merge_R_Compare.dbo_tblMAIN_ASSESSMENT') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMAIN_ASSESSMENT
			IF OBJECT_ID('Merge_R_Compare.dbo_tblMAIN_BRACHYTHERAPY') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMAIN_BRACHYTHERAPY
			IF OBJECT_ID('Merge_R_Compare.dbo_tblMAIN_CHEMOTHERAPY') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMAIN_CHEMOTHERAPY
			IF OBJECT_ID('Merge_R_Compare.dbo_tblMAIN_PALLIATIVE') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMAIN_PALLIATIVE
			IF OBJECT_ID('Merge_R_Compare.dbo_tblMAIN_REFERRALS') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMAIN_REFERRALS
			IF OBJECT_ID('Merge_R_Compare.dbo_tblMAIN_SURGERY') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMAIN_SURGERY
			IF OBJECT_ID('Merge_R_Compare.dbo_tblMAIN_TELETHERAPY') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMAIN_TELETHERAPY
			IF OBJECT_ID('Merge_R_Compare.dbo_tblMONITORING') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblMONITORING
			IF OBJECT_ID('Merge_R_Compare.dbo_tblOTHER_TREATMENT') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblOTHER_TREATMENT
			IF OBJECT_ID('Merge_R_Compare.dbo_tblPathwayUpdateEvents') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblPathwayUpdateEvents
			IF OBJECT_ID('Merge_R_Compare.dbo_tblTERTIARY_REFERRALS') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblTERTIARY_REFERRALS
			IF OBJECT_ID('Merge_R_Compare.dbo_tblTRACKING_COMMENTS') IS NOT NULL DROP TABLE Merge_R_Compare.dbo_tblTRACKING_COMMENTS

			-- Drop the copies of the SCR_ETL tables used for deduplication
			IF OBJECT_ID('Merge_R_Compare.tblDEMOGRAPHICS_tblValidatedData') IS NOT NULL DROP TABLE Merge_R_Compare.tblDEMOGRAPHICS_tblValidatedData
			IF OBJECT_ID('Merge_R_Compare.tblMAIN_REFERRALS_tblValidatedData') IS NOT NULL DROP TABLE Merge_R_Compare.tblMAIN_REFERRALS_tblValidatedData
			IF OBJECT_ID('Merge_R_Compare.Treatments_tblValidatedData') IS NOT NULL DROP TABLE Merge_R_Compare.Treatments_tblValidatedData
			IF OBJECT_ID('Merge_R_Compare.MDT_tblValidatedData') IS NOT NULL DROP TABLE Merge_R_Compare.MDT_tblValidatedData



			-- Drop the copies of the SCR_DW tables used for renumbering
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_AspNetUsers_work', @newname = 'dbo_AspNetUsers'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_Organisations_work', @newname = 'dbo_Organisations'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_OrganisationSites_work', @newname = 'dbo_OrganisationSites'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblAllTreatmentDeclined_work', @newname = 'dbo_tblAllTreatmentDeclined'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblAUDIT_work', @newname = 'dbo_tblAUDIT'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblDEFINITIVE_TREATMENT_work', @newname = 'dbo_tblDEFINITIVE_TREATMENT'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblDEMOGRAPHICS_work', @newname = 'dbo_tblDEMOGRAPHICS'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblMAIN_ASSESSMENT_work', @newname = 'dbo_tblMAIN_ASSESSMENT'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblMAIN_BRACHYTHERAPY_work', @newname = 'dbo_tblMAIN_BRACHYTHERAPY'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblMAIN_CHEMOTHERAPY_work', @newname = 'dbo_tblMAIN_CHEMOTHERAPY'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblMAIN_PALLIATIVE_work', @newname = 'dbo_tblMAIN_PALLIATIVE'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblMAIN_REFERRALS_work', @newname = 'dbo_tblMAIN_REFERRALS'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblMAIN_SURGERY_work', @newname = 'dbo_tblMAIN_SURGERY'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblMAIN_TELETHERAPY_work', @newname = 'dbo_tblMAIN_TELETHERAPY'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblMONITORING_work', @newname = 'dbo_tblMONITORING'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblOTHER_TREATMENT_work', @newname = 'dbo_tblOTHER_TREATMENT'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblPathwayUpdateEvents_work', @newname = 'dbo_tblPathwayUpdateEvents'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblTERTIARY_REFERRALS_work', @newname = 'dbo_tblTERTIARY_REFERRALS'
			EXEC sp_rename @objname = 'Merge_R_Compare.dbo_tblTRACKING_COMMENTS_work', @newname = 'dbo_tblTRACKING_COMMENTS'

			-- Drop the copies of the SCR_ETL tables used for deduplication
			EXEC sp_rename @objname = 'Merge_R_Compare.tblDEMOGRAPHICS_tblValidatedData_work', @newname = 'tblDEMOGRAPHICS_tblValidatedData'
			EXEC sp_rename @objname = 'Merge_R_Compare.tblMAIN_REFERRALS_tblValidatedData_work', @newname = 'tblMAIN_REFERRALS_tblValidatedData'
			EXEC sp_rename @objname = 'Merge_R_Compare.Treatments_tblValidatedData_work', @newname = 'Treatments_tblValidatedData'
			EXEC sp_rename @objname = 'Merge_R_Compare.MDT_tblValidatedData_work', @newname = 'MDT_tblValidatedData'

			COMMIT TRANSACTION

		END TRY

		BEGIN CATCH
 
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

			RAISERROR (@ErrorMessage, -- Message text.  
										15, -- Severity.  
										1 -- State.  
										);
 
		END CATCH
------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------

		-- Creates Merge_R_Compare.ReportingMergeColumns table with list of each column in each view in each schema in CancerReporting_MERGE
		SELECT		IDENTITY(SMALLINT,1,1) AS ColumnIx
					,s.name	AS SchemaName
					,v.name AS TableName
					,c.name AS ColumnName
					,c.column_id AS ColumnOrder
					,CAST(NULL AS DATETIME2) AS ColumnStart
					,CAST(NULL AS DATETIME2) AS ColumnComplete

		INTO		Merge_R_Compare.ReportingMergeColumns_Work
			
		FROM		CancerReporting_MERGE.sys.schemas s
		INNER JOIN	CancerReporting_MERGE.sys.views v
							ON s.schema_id = v.schema_id
		INNER JOIN	CancerReporting_MERGE.sys.columns c
							ON v.object_id = c.object_id
		ORDER BY s.name, v.name, c.name

------------------------------------------------------------------------------------------------------------------------------------------
		
		-- Create Merge_R_Compare.ReportingMergeDifferences table
		CREATE TABLE Merge_R_Compare.ReportingMergeDifferences_Work
					(MerCare_ID INT
					,MerRecordID VARCHAR(255)
					,PreSrcSysID TINYINT
					,PreCare_ID INT
					,PreRecordID VARCHAR(255)
					,ColumnIx SMALLINT
					,DiffType VARCHAR(255)
					,PreValue SQL_VARIANT
					,MerValue SQL_VARIANT
					)  

------------------------------------------------------------------------------------------------------------------------------------------

		-- Declare @ColumnOrder & @SQL variables
		DECLARE @ColumnOrder SMALLINT = 1
		DECLARE @SQL_Ref VARCHAR(MAX) = '' 
		DECLARE @SQL_CWT VARCHAR(MAX) = '' 
		DECLARE @SQL_OpenTargetDates VARCHAR(MAX) = '' 
		DECLARE @SQL_Assessments VARCHAR(MAX) = '' 
		DECLARE @SQL_Comments VARCHAR(MAX) = '' 
		DECLARE @SQL_InterProviderTransfers VARCHAR(MAX) = '' 
		DECLARE @SQL_NextActions VARCHAR(MAX) = '' 
		DECLARE @SQL_WorkFlow VARCHAR(MAX) = ''  
		
		DECLARE @SQL_Ref_CORE VARCHAR(MAX) = '' 
		DECLARE @SQL_CWT_CORE VARCHAR(MAX) = '' 
		DECLARE @SQL_OpenTargetDates_CORE VARCHAR(MAX) = '' 
		DECLARE @SQL_Assessments_CORE VARCHAR(MAX) = '' 
		DECLARE @SQL_Comments_CORE VARCHAR(MAX) = '' 
		DECLARE @SQL_InterProviderTransfers_CORE VARCHAR(MAX) = '' 
		DECLARE @SQL_NextActions_CORE VARCHAR(MAX) = '' 
		DECLARE @SQL_WorkFlow_CORE VARCHAR(MAX) = '' 
		
		DECLARE @SQL_Ref_WHERE1 VARCHAR(MAX) = '' 
		DECLARE @SQL_CWT_WHERE1 VARCHAR(MAX) = '' 
		DECLARE @SQL_OpenTargetDates_WHERE1 VARCHAR(MAX) = '' 
		DECLARE @SQL_Assessments_WHERE1 VARCHAR(MAX) = '' 
		DECLARE @SQL_Comments_WHERE1 VARCHAR(MAX) = '' 
		DECLARE @SQL_InterProviderTransfers_WHERE1 VARCHAR(MAX) = '' 
		DECLARE @SQL_NextActions_WHERE1 VARCHAR(MAX) = '' 
		DECLARE @SQL_WorkFlow_WHERE1 VARCHAR(MAX) = '' 
		
		DECLARE @SQL_Ref_WHERE2 VARCHAR(MAX) = '' 
		DECLARE @SQL_CWT_WHERE2 VARCHAR(MAX) = '' 
		DECLARE @SQL_OpenTargetDates_WHERE2 VARCHAR(MAX) = '' 
		DECLARE @SQL_Assessments_WHERE2 VARCHAR(MAX) = '' 
		DECLARE @SQL_Comments_WHERE2 VARCHAR(MAX) = '' 
		DECLARE @SQL_InterProviderTransfers_WHERE2 VARCHAR(MAX) = '' 
		DECLARE @SQL_NextActions_WHERE2 VARCHAR(MAX) = '' 
		DECLARE @SQL_WorkFlow_WHERE2 VARCHAR(MAX) = '' 
		
		DECLARE @SQL_Ref_WHERE3 VARCHAR(MAX) = '' 
		DECLARE @SQL_CWT_WHERE3 VARCHAR(MAX) = '' 
		DECLARE @SQL_OpenTargetDates_WHERE3 VARCHAR(MAX) = '' 
		DECLARE @SQL_Assessments_WHERE3 VARCHAR(MAX) = '' 
		DECLARE @SQL_Comments_WHERE3 VARCHAR(MAX) = '' 
		DECLARE @SQL_InterProviderTransfers_WHERE3 VARCHAR(MAX) = '' 
		DECLARE @SQL_NextActions_WHERE3 VARCHAR(MAX) = '' 
		DECLARE @SQL_WorkFlow_WHERE3 VARCHAR(MAX) = '' 

/********************************************************************************************************************************************************************************************************************************/

		-- Create temporary table with data from the PRE_MERGE SCR_Referrals view and create an index.
		SELECT * INTO Merge_R_Compare.pre_scr_referrals_Work FROM Merge_R_Compare.VwSCR_Warehouse_SCR_Referrals

		CREATE NONCLUSTERED INDEX ix_care_id ON Merge_R_Compare.pre_scr_referrals_Work(srcsysid ASC, care_id ASC)

------------------------------------------------------------------------------------------------------------------------------------------

		-- Loop around each column in the SCR_Referrals table and execute SQL to find differences between values in pre merge and merge databases and insert into ReportingMergeDifferences_Work table
		WHILE @ColumnOrder <= (SELECT MAX(c.ColumnOrder) FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE C.TableName = 'VwSCR_Warehouse_SCR_Referrals') 
		BEGIN
				IF (SELECT ColumnName FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE c.TableName = 'VwSCR_Warehouse_SCR_Referrals' AND ColumnOrder = @ColumnOrder)
					NOT IN ('ReportDate', 'RefreshMaxActionDate') 
				BEGIN

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnStart = GETDATE() WHERE TableName = 'VwSCR_Warehouse_SCR_Referrals' AND ColumnOrder = @ColumnOrder

						SELECT @SQL_Ref_CORE	=		'INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType , PreValue, MerValue)' + CHAR(13) +
														'SELECT		mer.CARE_ID ' + CHAR(13) +
														'			,mer.CARE_ID ' + CHAR(13) +
														'			,pre.OrigSrcSysID ' + CHAR(13) +
														'			,pre.OrigCARE_ID ' + CHAR(13) +
														'			,pre.OrigCARE_ID ' + CHAR(13) +
														'			,' + CAST(ColumnIx AS VARCHAR(255)) + ' AS ColumnIx ' + CHAR(13) + 
														'			,CASE	WHEN Pre.' + ColumnName + ' != mer.' + ColumnName + ' THEN ''Different'' ' + CHAR(13) + 
														'					WHEN (Pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) THEN ''Gained'' ' + CHAR(13) +
														'					WHEN (Pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) THEN ''Lost'' ' + CHAR(13) + 
														'					END AS DiffType' + CHAR(13) +
														'			,pre.' + ColumnName + ' AS ValueBefore ' + CHAR(13) +
														'			,mer.' + ColumnName + ' AS ValueAfter ' + CHAR(13) +
														'FROM		Merge_R_Compare.pre_scr_referrals_Work pre' + CHAR(13) +
														'INNER JOIN	CancerReporting_MERGE.' + CONCAT(SchemaName, '.', TableName) + ' mer ' + CHAR(13) +
														'													ON	pre.CARE_ID = mer.CARE_ID ' + CHAR(13)
								,@SQL_Ref_WHERE1	=	'WHERE		pre.' + ColumnName + ' != mer.' + ColumnName + ' ' + CHAR(13)
								,@SQL_Ref_WHERE2	=	'WHERE		(pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) ' + CHAR(13)
								,@SQL_Ref_WHERE3	=	'WHERE		(pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) '  + CHAR(13)

						FROM Merge_R_Compare.ReportingMergeColumns_Work WHERE TableName = 'VwSCR_Warehouse_SCR_Referrals' AND ColumnOrder = @ColumnOrder

						-- EXEC the 3 SQL statement variants
						SET @SQL_Ref = @SQL_Ref_CORE + @SQL_Ref_WHERE1; EXEC (@SQL_Ref); PRINT @SQL_Ref
						SET @SQL_Ref = @SQL_Ref_CORE + @SQL_Ref_WHERE2; EXEC (@SQL_Ref); PRINT @SQL_Ref
						SET @SQL_Ref = @SQL_Ref_CORE + @SQL_Ref_WHERE3; EXEC (@SQL_Ref); PRINT @SQL_Ref

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnComplete = GETDATE() WHERE TableName = 'VwSCR_Warehouse_SCR_Referrals' AND ColumnOrder = @ColumnOrder

				END
				SET @ColumnOrder = @ColumnOrder + 1
		END 
		-- end of SCR_Referrals column loop

/********************************************************************************************************************************************************************************************************************************/

		-- Create temporary table with data from the PRE_MERGE SCR_CWT view and create an index.
		SELECT * INTO Merge_R_Compare.pre_scr_cwt_Work FROM Merge_R_Compare.VwSCR_Warehouse_SCR_CWT 

		CREATE NONCLUSTERED INDEX ix_chemo_id ON Merge_R_Compare.pre_scr_cwt_Work(srcsysid ASC, chemo_id ASC)
		CREATE NONCLUSTERED INDEX ix_treatment_id ON Merge_R_Compare.pre_scr_cwt_Work(srcsysid ASC, treatment_id ASC)
		CREATE NONCLUSTERED INDEX ix_treat_id ON Merge_R_Compare.pre_scr_cwt_Work(srcsysid ASC, treat_id ASC)
		CREATE NONCLUSTERED INDEX ix_tele_id ON Merge_R_Compare.pre_scr_cwt_Work(srcsysid ASC, tele_id ASC)
		CREATE NONCLUSTERED INDEX ix_brachy_id ON Merge_R_Compare.pre_scr_cwt_Work(srcsysid ASC, brachy_id ASC)
		CREATE NONCLUSTERED INDEX ix_surgery_id ON Merge_R_Compare.pre_scr_cwt_Work(srcsysid ASC, surgery_id ASC)
		CREATE NONCLUSTERED INDEX ix_other_id ON Merge_R_Compare.pre_scr_cwt_Work(srcsysid ASC, other_id ASC)
		CREATE NONCLUSTERED INDEX ix_pall_id ON Merge_R_Compare.pre_scr_cwt_Work(srcsysid ASC, pall_id ASC)
		CREATE NONCLUSTERED INDEX ix_monitor_id ON Merge_R_Compare.pre_scr_cwt_Work(srcsysid ASC, monitor_id ASC)

		-- Reset @ColumnOrder
		SET @ColumnOrder = 1

------------------------------------------------------------------------------------------------------------------------------------------

		-- Loop around each column in the SCR_CWT table and execute SQL to find differences between values in pre merge and merge databases and insert into ReportingMergeDifferences_Work table
		WHILE @ColumnOrder <= (SELECT MAX(c.ColumnOrder) FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE C.TableName = 'VwSCR_Warehouse_SCR_CWT') 
		BEGIN
				IF (SELECT ColumnName FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE c.TableName = 'VwSCR_Warehouse_SCR_CWT' AND ColumnOrder = @ColumnOrder)
					not in ('ReportDate','CWTInsertIx','OriginalCWTInsertIx') 
				BEGIN

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnStart = GETDATE() WHERE TableName = 'VwSCR_Warehouse_SCR_CWT' AND ColumnOrder = @ColumnOrder

						SELECT @SQL_CWT_CORE		=	'INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType , PreValue, MerValue)' + CHAR(13) +
														'SELECT		mer.CARE_ID ' + CHAR(13) +
														'			,mer.CWT_ID ' + CHAR(13) +
														'			,pre.OrigSrcSysID ' + CHAR(13) +
														'			,pre.OrigCARE_ID ' + CHAR(13) +
														'			,pre.OrigCWT_ID ' + CHAR(13) +
														'			,' + CAST(ColumnIx as varchar(255)) + ' AS ColumnIx ' + CHAR(13) + 
														'			,CASE	WHEN Pre.' + ColumnName + ' != mer.' + ColumnName + ' THEN ''Different'' ' + CHAR(13) + 
														'					WHEN (Pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) THEN ''Gained'' ' + CHAR(13) +
														'					WHEN (Pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) THEN ''Lost'' ' + CHAR(13) + 
														'					END AS DiffType' + CHAR(13) +
														'			,pre.' + ColumnName + ' AS ValueBefore ' + CHAR(13) +
														'			,mer.' + ColumnName + ' AS ValueAfter ' + CHAR(13) +
														'FROM		Merge_R_Compare.pre_scr_cwt_Work pre' + CHAR(13) +
														'INNER JOIN	CancerReporting_MERGE.' + CONCAT(SchemaName, '.', TableName) + ' mer ' + CHAR(13) +
														'													ON	pre.CWT_ID = mer.CWT_ID ' + CHAR(13)
								,@SQL_CWT_WHERE1	=	'WHERE		pre.' + ColumnName + ' != mer.' + ColumnName + ' ' + CHAR(13)
								,@SQL_CWT_WHERE2	=	'WHERE		(pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) ' + CHAR(13)
								,@SQL_CWT_WHERE3	=	'WHERE		(pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) '  + CHAR(13)

						FROM Merge_R_Compare.ReportingMergeColumns_Work WHERE TableName = 'VwSCR_Warehouse_SCR_CWT' AND ColumnOrder = @ColumnOrder

						-- EXEC the 3 SQL statement variants
						SET @SQL_CWT = @SQL_CWT_CORE + @SQL_CWT_WHERE1; EXEC (@SQL_CWT); PRINT @SQL_CWT
						SET @SQL_CWT = @SQL_CWT_CORE + @SQL_CWT_WHERE2; EXEC (@SQL_CWT); PRINT @SQL_CWT
						SET @SQL_CWT = @SQL_CWT_CORE + @SQL_CWT_WHERE3; EXEC (@SQL_CWT); PRINT @SQL_CWT

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnComplete = GETDATE() WHERE TableName = 'VwSCR_Warehouse_SCR_CWT' AND ColumnOrder = @ColumnOrder

				END
				SET @ColumnOrder = @ColumnOrder + 1
		END 
		-- end of SCR_CWT column loop

/********************************************************************************************************************************************************************************************************************************/

		-- Create temporary table with data from the PRE_MERGE SCR_Assessments view and create an index.
		SELECT * INTO Merge_R_Compare.pre_scr_assessments_Work FROM Merge_R_Compare.VwSCR_Warehouse_SCR_Assessments

		CREATE NONCLUSTERED INDEX ix_Assessment_ID ON Merge_R_Compare.pre_scr_assessments_Work (srcsysid ASC, Assessment_ID ASC)

		-- Reset @ColumnOrder
		SET @ColumnOrder = 1

------------------------------------------------------------------------------------------------------------------------------------------

		-- Loop around each column in the SCR_Assessments table and execute SQL to find differences between values in pre merge and merge databases and insert into ReportingMergeDifferences_Work table
		WHILE @ColumnOrder <= (SELECT MAX(c.ColumnOrder) FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE C.TableName = 'VwSCR_Warehouse_SCR_Assessments') 
		BEGIN
				IF (SELECT ColumnName FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE c.TableName = 'VwSCR_Warehouse_SCR_Assessments' AND ColumnOrder = @ColumnOrder)
					not in ('ReportDate') 
				BEGIN

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnStart = GETDATE() WHERE TableName = 'VwSCR_Warehouse_SCR_Assessments' AND ColumnOrder = @ColumnOrder

						SELECT @SQL_Assessments_CORE		 =	'INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType , PreValue, MerValue)' + CHAR(13) +
																'SELECT		mer.CARE_ID ' + CHAR(13) +
																'			,mer.ASSESSMENT_ID ' + CHAR(13) +
																'			,pre.OrigSrcSysID ' + CHAR(13) +
																'			,pre.OrigCARE_ID ' + CHAR(13) +
																'			,pre.OrigASSESSMENT_ID ' + CHAR(13) +
																'			,' + CAST(ColumnIx as varchar(255)) + ' AS ColumnIx ' + CHAR(13) + 
																'			,CASE	WHEN Pre.' + ColumnName + ' != mer.' + ColumnName + ' THEN ''Different'' ' + CHAR(13) + 
																'					WHEN (Pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) THEN ''Gained'' ' + CHAR(13) +
																'					WHEN (Pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) THEN ''Lost'' ' + CHAR(13) + 
																'					END AS DiffType' + CHAR(13) +
																'			,pre.' + ColumnName + ' AS ValueBefore ' + CHAR(13) +
																'			,mer.' + ColumnName + ' AS ValueAfter ' + CHAR(13) +
																'FROM		Merge_R_Compare.pre_scr_assessments_Work pre' + CHAR(13) +
																'INNER JOIN	CancerReporting_MERGE.' + CONCAT(SchemaName, '.', TableName) + ' mer ' + CHAR(13) +
																'													ON	pre.Assessment_ID = mer.Assessment_ID ' + CHAR(13)
								,@SQL_Assessments_WHERE1	=	'WHERE		pre.' + ColumnName + ' != mer.' + ColumnName + ' ' + CHAR(13)
								,@SQL_Assessments_WHERE2	=	'WHERE		(pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) ' + CHAR(13)
								,@SQL_Assessments_WHERE3	=	'WHERE		(pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) '  + CHAR(13)

						FROM Merge_R_Compare.ReportingMergeColumns_Work WHERE TableName = 'VwSCR_Warehouse_SCR_Assessments' AND ColumnOrder = @ColumnOrder

						-- EXEC the 3 SQL statement variants
						SET @SQL_Assessments = @SQL_Assessments_CORE + @SQL_Assessments_WHERE1; EXEC (@SQL_Assessments); PRINT @SQL_Assessments
						SET @SQL_Assessments = @SQL_Assessments_CORE + @SQL_Assessments_WHERE2; EXEC (@SQL_Assessments); PRINT @SQL_Assessments
						SET @SQL_Assessments = @SQL_Assessments_CORE + @SQL_Assessments_WHERE3; EXEC (@SQL_Assessments); PRINT @SQL_Assessments

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnComplete = GETDATE() WHERE TableName = 'VwSCR_Warehouse_SCR_Assessments' AND ColumnOrder = @ColumnOrder
				END
				SET @ColumnOrder = @ColumnOrder + 1
		END 
		-- end of SCR_Assessments column loop

/********************************************************************************************************************************************************************************************************************************/

		-- Create temporary table with data from the PRE_MERGE OpenTargetDates view and create an index.
		SELECT * INTO Merge_R_Compare.pre_OpenTargetDates_Work FROM Merge_R_Compare.VwSCR_Warehouse_OpenTargetDates

		CREATE NONCLUSTERED INDEX ix_OpenTargetDatesId ON Merge_R_Compare.pre_OpenTargetDates_Work(CWT_ID ASC, TargetType ASC)

		-- Reset @ColumnOrder
		SET @ColumnOrder = 1

------------------------------------------------------------------------------------------------------------------------------------------

		-- Loop around each column in the OpentTargetDates table and execute SQL to find differences between values in pre merge and merge databases and insert into ReportingMergeDifferences_Work table
		WHILE @ColumnOrder <= (SELECT MAX(c.ColumnOrder) FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE C.TableName = 'VwSCR_Warehouse_OpenTargetDates') 
		BEGIN
				IF (SELECT ColumnName FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE c.TableName = 'VwSCR_Warehouse_OpenTargetDates' AND ColumnOrder = @ColumnOrder)
					not in ('OpenTargetDatesID','ReportDate') 
				BEGIN

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnStart = GETDATE() WHERE TableName = 'VwSCR_Warehouse_OpenTargetDates' AND ColumnOrder = @ColumnOrder

						SELECT @SQL_OpenTargetDates_CORE		=	'INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType , PreValue, MerValue)' + CHAR(13) +
																	'SELECT		mer.CARE_ID ' + CHAR(13) +
																	'			,mer.OpenTargetDatesId ' + CHAR(13) +
																	'			,pre.OrigSrcSysID ' + CHAR(13) +
																	'			,pre.OrigCARE_ID ' + CHAR(13) +
																	'			,pre.OpenTargetDatesId ' + CHAR(13) +
																	'			,' + CAST(ColumnIx as varchar(255)) + ' AS ColumnIx ' + CHAR(13) + 
																	'			,CASE	WHEN Pre.' + ColumnName + ' != mer.' + ColumnName + ' THEN ''Different'' ' + CHAR(13) + 
																	'					WHEN (Pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) THEN ''Gained'' ' + CHAR(13) +
																	'					WHEN (Pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) THEN ''Lost'' ' + CHAR(13) + 
																	'					END AS DiffType' + CHAR(13) +
																	'			,pre.' + ColumnName + ' AS ValueBefore ' + CHAR(13) +
																	'			,mer.' + ColumnName + ' AS ValueAfter ' + CHAR(13) +
																	'FROM		Merge_R_Compare.pre_OpenTargetDates_Work pre' + CHAR(13) +
																	'INNER JOIN	CancerReporting_MERGE.' + CONCAT(SchemaName, '.', TableName) + ' mer ' + CHAR(13) +
																	'													ON	pre.CWT_ID = mer.CWT_ID ' + CHAR(13) +
																	'													AND	pre.TargetType = mer.TargetType ' + CHAR(13)
								,@SQL_OpenTargetDates_WHERE1	=	'WHERE		pre.' + ColumnName + ' != mer.' + ColumnName + ' ' + CHAR(13)
								,@SQL_OpenTargetDates_WHERE2	=	'WHERE		(pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) ' + CHAR(13)
								,@SQL_OpenTargetDates_WHERE3	=	'WHERE		(pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) '  + CHAR(13)

						FROM Merge_R_Compare.ReportingMergeColumns_Work WHERE TableName = 'VwSCR_Warehouse_OpenTargetDates' AND ColumnOrder = @ColumnOrder

						-- EXEC the 3 SQL statement variants
						SET @SQL_OpenTargetDates = @SQL_OpenTargetDates_CORE + @SQL_OpenTargetDates_WHERE1; EXEC (@SQL_OpenTargetDates); PRINT @SQL_OpenTargetDates
						SET @SQL_OpenTargetDates = @SQL_OpenTargetDates_CORE + @SQL_OpenTargetDates_WHERE2; EXEC (@SQL_OpenTargetDates); PRINT @SQL_OpenTargetDates
						SET @SQL_OpenTargetDates = @SQL_OpenTargetDates_CORE + @SQL_OpenTargetDates_WHERE3; EXEC (@SQL_OpenTargetDates); PRINT @SQL_OpenTargetDates

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnComplete = GETDATE() WHERE TableName = 'VwSCR_Warehouse_OpenTargetDates' AND ColumnOrder = @ColumnOrder

				END
				SET @ColumnOrder = @ColumnOrder + 1
		END 
		-- end of SCR_OpenTargets column loop

/********************************************************************************************************************************************************************************************************************************/

		-- Create temporary table with data from the PRE_MERGE SCR_Comments view and create an index.
		SELECT * INTO Merge_R_Compare.pre_scr_comments_Work FROM Merge_R_Compare.VwSCR_Warehouse_SCR_Comments

		CREATE NONCLUSTERED INDEX ix_comments ON Merge_R_Compare.pre_scr_comments_Work (SourceRecordId ASC, SourceTableName ASC, SourceColumnName ASC)

		-- Reset @ColumnOrder
		SET @ColumnOrder = 1

------------------------------------------------------------------------------------------------------------------------------------------

		-- Loop around each column in the SCR_Comments table and execute SQL to find differences between values in pre merge and merge databases and insert into ReportingMergeDifferences_Work table
		WHILE @ColumnOrder <= (SELECT MAX(c.ColumnOrder) FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE C.TableName = 'VwSCR_Warehouse_SCR_Comments') 
		BEGIN
				IF (SELECT ColumnName FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE c.TableName = 'VwSCR_Warehouse_SCR_Comments' AND ColumnOrder = @ColumnOrder)
					not in ('ReportDate') 
				BEGIN

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnStart = GETDATE() WHERE TableName = 'VwSCR_Warehouse_SCR_Comments' AND ColumnOrder = @ColumnOrder

						SELECT @SQL_Comments_CORE		=	'INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType , PreValue, MerValue)' + CHAR(13) +
															'SELECT		mer.CARE_ID ' + CHAR(13) +
															'			,mer.SourceRecordId ' + CHAR(13) +
															'			,pre.OrigSrcSysID ' + CHAR(13) +
															'			,pre.OrigCARE_ID ' + CHAR(13) +
															'			,pre.OrigSourceRecordId ' + CHAR(13) +
															'			,' + CAST(ColumnIx as varchar(255)) + ' AS ColumnIx ' + CHAR(13) + 
															'			,CASE	WHEN Pre.' + ColumnName + ' != mer.' + ColumnName + ' THEN ''Different'' ' + CHAR(13) + 
															'					WHEN (Pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) THEN ''Gained'' ' + CHAR(13) +
															'					WHEN (Pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) THEN ''Lost'' ' + CHAR(13) + 
															'					END AS DiffType' + CHAR(13) +
															'			,pre.' + ColumnName + ' AS ValueBefore ' + CHAR(13) +
															'			,mer.' + ColumnName + ' AS ValueAfter ' + CHAR(13) +
															'FROM		Merge_R_Compare.pre_scr_comments_Work pre' + CHAR(13) +
															'INNER JOIN	CancerReporting_MERGE.' + CONCAT(SchemaName, '.', TableName) + ' mer ' + CHAR(13) +
															'													ON	pre.SourceRecordId = mer.SourceRecordId ' + CHAR(13) +
															'													AND	pre.SourceTableName = mer.SourceTableName ' + CHAR(13) +
															'													AND	pre.SourceColumnName = mer.SourceColumnName ' + CHAR(13)
								,@SQL_Comments_WHERE1	=	'WHERE		pre.' + ColumnName + ' != mer.' + ColumnName + ' ' + CHAR(13)
								,@SQL_Comments_WHERE2	=	'WHERE		(pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) ' + CHAR(13)
								,@SQL_Comments_WHERE3	=	'WHERE		(pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) '  + CHAR(13)

						FROM Merge_R_Compare.ReportingMergeColumns_Work WHERE TableName = 'VwSCR_Warehouse_SCR_Comments' AND ColumnOrder = @ColumnOrder

						-- EXEC the 3 SQL statement variants
						SET @SQL_Comments = @SQL_Comments_CORE + @SQL_Comments_WHERE1; EXEC (@SQL_Comments); PRINT @SQL_Comments
						SET @SQL_Comments = @SQL_Comments_CORE + @SQL_Comments_WHERE2; EXEC (@SQL_Comments); PRINT @SQL_Comments
						SET @SQL_Comments = @SQL_Comments_CORE + @SQL_Comments_WHERE3; EXEC (@SQL_Comments); PRINT @SQL_Comments

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnComplete = GETDATE() WHERE TableName = 'VwSCR_Warehouse_SCR_Comments' AND ColumnOrder = @ColumnOrder

				END
				SET @ColumnOrder = @ColumnOrder + 1
		END 
		-- end of SCR_Comments column loop

/********************************************************************************************************************************************************************************************************************************/

		-- Create temporary table with data from the PRE_MERGE scr_InterProviderTransfers view and create an index.
		SELECT * INTO Merge_R_Compare.pre_scr_InterProviderTransfers_Work FROM Merge_R_Compare.VwSCR_Warehouse_SCR_InterProviderTransfers

		CREATE NONCLUSTERED INDEX ix_IPT ON Merge_R_Compare.pre_scr_InterProviderTransfers_Work (TertiaryReferralID ASC, SCR_IPTTypeCode ASC)

		-- Reset @ColumnOrder
		SET @ColumnOrder = 1

------------------------------------------------------------------------------------------------------------------------------------------

		-- Loop around each column in the scr_InterProviderTransfers table and execute SQL to find differences between values in pre merge and merge databases and insert into ReportingMergeDifferences_Work table
		WHILE @ColumnOrder <= (SELECT MAX(c.ColumnOrder) FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE C.TableName = 'VwSCR_Warehouse_SCR_InterProviderTransfers') 
		BEGIN
				IF (SELECT ColumnName FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE c.TableName = 'VwSCR_Warehouse_SCR_InterProviderTransfers' AND ColumnOrder = @ColumnOrder)
					not in ('') 
				BEGIN

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnStart = GETDATE() WHERE TableName = 'VwSCR_Warehouse_SCR_InterProviderTransfers' AND ColumnOrder = @ColumnOrder

						SELECT @SQL_InterProviderTransfers_CORE		=	'INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType , PreValue, MerValue)' + CHAR(13) +
																		'SELECT		mer.CareID ' + CHAR(13) +
																		'			,mer.TertiaryReferralID ' + CHAR(13) +
																		'			,pre.OrigSrcSysID ' + CHAR(13) +
																		'			,pre.OrigCARE_ID ' + CHAR(13) +
																		'			,pre.OrigTertiaryReferralID ' + CHAR(13) +
																		'			,' + CAST(ColumnIx as varchar(255)) + ' AS ColumnIx ' + CHAR(13) + 
																		'			,CASE	WHEN Pre.' + ColumnName + ' != mer.' + ColumnName + ' THEN ''Different'' ' + CHAR(13) + 
																		'					WHEN (Pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) THEN ''Gained'' ' + CHAR(13) +
																		'					WHEN (Pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) THEN ''Lost'' ' + CHAR(13) + 
																		'					END AS DiffType' + CHAR(13) +
																		'			,pre.' + ColumnName + ' AS ValueBefore ' + CHAR(13) +
																		'			,mer.' + ColumnName + ' AS ValueAfter ' + CHAR(13) +
																		'FROM		Merge_R_Compare.pre_scr_InterProviderTransfers_Work pre' + CHAR(13) +
																		'INNER JOIN	CancerReporting_MERGE.' + CONCAT(SchemaName, '.', TableName) + ' mer ' + CHAR(13) +
																		'													ON	pre.TertiaryReferralID = mer.TertiaryReferralID ' + CHAR(13) +
																		'													AND	pre.SCR_IPTTypeCode = mer.SCR_IPTTypeCode ' + CHAR(13)
								,@SQL_InterProviderTransfers_WHERE1	=	'WHERE		pre.' + ColumnName + ' != mer.' + ColumnName + ' ' + CHAR(13)
								,@SQL_InterProviderTransfers_WHERE2	=	'WHERE		(pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) ' + CHAR(13)
								,@SQL_InterProviderTransfers_WHERE3	=	'WHERE		(pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) '  + CHAR(13)

						FROM Merge_R_Compare.ReportingMergeColumns_Work WHERE TableName = 'VwSCR_Warehouse_SCR_InterProviderTransfers' AND ColumnOrder = @ColumnOrder

						-- EXEC the 3 SQL statement variants
						SET @SQL_InterProviderTransfers = @SQL_InterProviderTransfers_CORE + @SQL_InterProviderTransfers_WHERE1; EXEC (@SQL_InterProviderTransfers); PRINT @SQL_InterProviderTransfers
						SET @SQL_InterProviderTransfers = @SQL_InterProviderTransfers_CORE + @SQL_InterProviderTransfers_WHERE2; EXEC (@SQL_InterProviderTransfers); PRINT @SQL_InterProviderTransfers
						SET @SQL_InterProviderTransfers = @SQL_InterProviderTransfers_CORE + @SQL_InterProviderTransfers_WHERE3; EXEC (@SQL_InterProviderTransfers); PRINT @SQL_InterProviderTransfers

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnComplete = GETDATE() WHERE TableName = 'VwSCR_Warehouse_SCR_InterProviderTransfers' AND ColumnOrder = @ColumnOrder

				END
				SET @ColumnOrder = @ColumnOrder + 1
		END 
		-- end of SCR_InterProviderTransfers column loop

/********************************************************************************************************************************************************************************************************************************/

		-- Create temporary table with data from the PRE_MERGE scr_Workflow view and create an index.
		SELECT * INTO Merge_R_Compare.pre_Workflow_Work FROM Merge_R_Compare.VwSCR_Warehouse_Workflow

		CREATE NONCLUSTERED INDEX ix_workflow ON Merge_R_Compare.pre_Workflow_Work (IdentityTypeRecordId ASC, IdentityTypeId ASC, WorkflowID ASC)

		-- Reset @ColumnOrder
		SET @ColumnOrder = 1

------------------------------------------------------------------------------------------------------------------------------------------

		-- Loop around each column in the scr_Workflow table and execute SQL to find differences between values in pre merge and merge databases and insert into ReportingMergeDifferences_Work table
		WHILE @ColumnOrder <= (SELECT MAX(c.ColumnOrder) FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE C.TableName = 'VwSCR_Warehouse_SCR_Workflow') 
		BEGIN
				IF (SELECT ColumnName FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE c.TableName = 'VwSCR_Warehouse_SCR_Workflow' AND ColumnOrder = @ColumnOrder)
					not in ('') 
				BEGIN

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnStart = GETDATE() WHERE TableName = 'VwSCR_Warehouse_SCR_Workflow' AND ColumnOrder = @ColumnOrder

						SELECT @SQL_WorkFlow_CORE		=	'INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType , PreValue, MerValue)' + CHAR(13) +
															'SELECT		CAST(NULL AS INT) ' + CHAR(13) +
															'			,CAST(mer.IdentityTypeId AS VARCHAR(255)) + ''|'' + mer.IdentityTypeRecordId + ''|'' + CAST(mer.WorkflowID AS VARCHAR(255)) ' + CHAR(13) +
															'			,pre.OrigSrcSysID ' + CHAR(13) +
															'			,CAST(NULL AS INT) ' + CHAR(13) +
															'			,CAST(Pre.IdentityTypeId AS VARCHAR(255)) + ''|'' + Pre.IdentityTypeRecordId + ''|'' + CAST(Pre.WorkflowID AS VARCHAR(255)) ' + CHAR(13) +
															'			,' + CAST(ColumnIx AS VARCHAR(255)) + ' AS ColumnIx ' + CHAR(13) + 
															'			,CASE	WHEN Pre.' + ColumnName + ' != mer.' + ColumnName + ' THEN ''Different'' ' + CHAR(13) + 
															'					WHEN (Pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) THEN ''Gained'' ' + CHAR(13) +
															'					WHEN (Pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) THEN ''Lost'' ' + CHAR(13) + 
															'					END AS DiffType' + CHAR(13) +
															'			,pre.' + ColumnName + ' AS ValueBefore ' + CHAR(13) +
															'			,mer.' + ColumnName + ' AS ValueAfter ' + CHAR(13) +
															'FROM		Merge_R_Compare.pre_Workflow_Work pre' + CHAR(13) +
															'INNER JOIN	CancerReporting_MERGE.' + CONCAT(SchemaName, '.', TableName) + ' mer ' + CHAR(13) +
															'													ON	pre.IdentityTypeRecordId = mer.IdentityTypeRecordId ' + CHAR(13) +
															'													AND	pre.IdentityTypeId = mer.IdentityTypeId ' + CHAR(13) +
															'													AND	pre.WorkflowID = mer.WorkflowID ' + CHAR(13)
								,@SQL_WorkFlow_WHERE1	=	'WHERE		pre.' + ColumnName + ' != mer.' + ColumnName + ' ' + CHAR(13)
								,@SQL_WorkFlow_WHERE2	=	'WHERE		(pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) ' + CHAR(13)
								,@SQL_WorkFlow_WHERE3	=	'WHERE		(pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) '  + CHAR(13)

						FROM Merge_R_Compare.ReportingMergeColumns_Work WHERE TableName = 'VwSCR_Warehouse_SCR_Workflow' AND ColumnOrder = @ColumnOrder

						-- EXEC the 3 SQL statement variants
						SET @SQL_WorkFlow = @SQL_WorkFlow_CORE + @SQL_WorkFlow_WHERE1; EXEC (@SQL_WorkFlow); PRINT @SQL_WorkFlow
						SET @SQL_WorkFlow = @SQL_WorkFlow_CORE + @SQL_WorkFlow_WHERE2; EXEC (@SQL_WorkFlow); PRINT @SQL_WorkFlow
						SET @SQL_WorkFlow = @SQL_WorkFlow_CORE + @SQL_WorkFlow_WHERE3; EXEC (@SQL_WorkFlow); PRINT @SQL_WorkFlow

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnComplete = GETDATE() WHERE TableName = 'VwSCR_Warehouse_SCR_Workflow' AND ColumnOrder = @ColumnOrder

				END
				SET @ColumnOrder = @ColumnOrder + 1
		END 
		-- end of SCR_Workflow column loop

/********************************************************************************************************************************************************************************************************************************/

		-- Create temporary table with data from the PRE_MERGE scr_NextActions view and create an index.
		SELECT * INTO Merge_R_Compare.pre_scr_NextActions_Work FROM Merge_R_Compare.VwSCR_Warehouse_SCR_NextActions

		CREATE NONCLUSTERED INDEX ix_NextActions ON Merge_R_Compare.pre_scr_NextActions_Work (PathwayUpdateEventID ASC)

		-- Reset @ColumnOrder
		SET @ColumnOrder = 1

------------------------------------------------------------------------------------------------------------------------------------------

		-- Loop around each column in the scr_NextActions table and execute SQL to find differences between values in pre merge and merge databases and insert into ReportingMergeDifferences_Work table
		WHILE @ColumnOrder <= (SELECT MAX(c.ColumnOrder) FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE C.TableName = 'VwSCR_Warehouse_SCR_NextActions') 
		BEGIN
				IF (SELECT ColumnName FROM Merge_R_Compare.ReportingMergeColumns_Work c WHERE c.TableName = 'VwSCR_Warehouse_SCR_NextActions' AND ColumnOrder = @ColumnOrder)
					not in ('ReportDate') 
				BEGIN

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnStart = GETDATE() WHERE TableName = 'VwSCR_Warehouse_SCR_NextActions' AND ColumnOrder = @ColumnOrder

						SELECT @SQL_NextActions_CORE		=	'INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType , PreValue, MerValue)' + CHAR(13) +
																'SELECT		mer.CareID ' + CHAR(13) +
																'			,mer.PathwayUpdateEventID ' + CHAR(13) +
																'			,pre.OrigSrcSysID ' + CHAR(13) +
																'			,pre.OrigCareID ' + CHAR(13) +
																'			,pre.OrigPathwayUpdateEventID ' + CHAR(13) +
																'			,' + CAST(ColumnIx as varchar(255)) + ' AS ColumnIx ' + CHAR(13) + 
																'			,CASE	WHEN Pre.' + ColumnName + ' != mer.' + ColumnName + ' THEN ''Different'' ' + CHAR(13) + 
																'					WHEN (Pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) THEN ''Gained'' ' + CHAR(13) +
																'					WHEN (Pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) THEN ''Lost'' ' + CHAR(13) + 
																'					END AS DiffType' + CHAR(13) +
																'			,pre.' + ColumnName + ' AS ValueBefore ' + CHAR(13) +
																'			,mer.' + ColumnName + ' AS ValueAfter ' + CHAR(13) +
																'FROM		Merge_R_Compare.pre_scr_NextActions_Work pre' + CHAR(13) +
																'INNER JOIN	CancerReporting_MERGE.' + CONCAT(SchemaName, '.', TableName) + ' mer ' + CHAR(13) +
																'													ON	pre.PathwayUpdateEventID = mer.PathwayUpdateEventID ' + CHAR(13)
								,@SQL_NextActions_WHERE1	=	'WHERE		pre.' + ColumnName + ' != mer.' + ColumnName + ' ' + CHAR(13)
								,@SQL_NextActions_WHERE2	=	'WHERE		(pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) ' + CHAR(13)
								,@SQL_NextActions_WHERE3	=	'WHERE		(pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) '  + CHAR(13)

						FROM Merge_R_Compare.ReportingMergeColumns_Work WHERE TableName = 'VwSCR_Warehouse_SCR_NextActions' AND ColumnOrder = @ColumnOrder

						-- EXEC the 3 SQL statement variants
						SET @SQL_NextActions = @SQL_NextActions_CORE + @SQL_NextActions_WHERE1; EXEC (@SQL_NextActions); PRINT @SQL_NextActions
						SET @SQL_NextActions = @SQL_NextActions_CORE + @SQL_NextActions_WHERE2; EXEC (@SQL_NextActions); PRINT @SQL_NextActions
						SET @SQL_NextActions = @SQL_NextActions_CORE + @SQL_NextActions_WHERE3; EXEC (@SQL_NextActions); PRINT @SQL_NextActions

						UPDATE Merge_R_Compare.ReportingMergeColumns_Work SET ColumnComplete = GETDATE() WHERE TableName = 'VwSCR_Warehouse_SCR_NextActions' AND ColumnOrder = @ColumnOrder

				END
				SET @ColumnOrder = @ColumnOrder + 1
		END 
		-- end of SCR_NextActions column loop

/********************************************************************************************************************************************************************************************************************************/
-- Swap out the _work tables for the final persisted tables
/********************************************************************************************************************************************************************************************************************************/

		PRINT CHAR(13) + '-- Swap out the _work tables for the final persisted tables' + CHAR(13)

		BEGIN TRY

			BEGIN TRANSACTION

			-- Drop Column & Differences tables & view temp tables
			IF OBJECT_ID('Merge_R_Compare.ReportingMergeColumns') IS NOT NULL DROP TABLE Merge_R_Compare.ReportingMergeColumns
			IF OBJECT_ID('Merge_R_Compare.ReportingMergeDifferences') IS NOT NULL DROP TABLE Merge_R_Compare.ReportingMergeDifferences

			-- Drop the copies of the renumbered views of the SCR warehouse tables
			IF OBJECT_ID('Merge_R_Compare.pre_scr_referrals') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_referrals
			IF OBJECT_ID('Merge_R_Compare.pre_scr_cwt') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_cwt
			IF OBJECT_ID('Merge_R_Compare.pre_OpenTargetDates') IS NOT NULL DROP TABLE Merge_R_Compare.pre_OpenTargetDates
			IF OBJECT_ID('Merge_R_Compare.pre_scr_assessments') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_assessments
			IF OBJECT_ID('Merge_R_Compare.pre_scr_comments') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_comments
			IF OBJECT_ID('Merge_R_Compare.pre_scr_InterProviderTransfers') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_InterProviderTransfers
			IF OBJECT_ID('Merge_R_Compare.pre_scr_NextActions') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_NextActions
			IF OBJECT_ID('Merge_R_Compare.pre_Workflow') IS NOT NULL DROP TABLE Merge_R_Compare.pre_Workflow



			-- Rename the _work tables to be the new persisted tables (Column & Differences tables)
			EXEC sp_rename @objname = 'Merge_R_Compare.ReportingMergeColumns_Work', @newname = 'ReportingMergeColumns'
			EXEC sp_rename @objname = 'Merge_R_Compare.ReportingMergeDifferences_Work', @newname = 'ReportingMergeDifferences'
			
			-- Rename the _work tables to be the new persisted tables (renumbered views of the SCR warehouse tables)
			EXEC sp_rename @objname = 'Merge_R_Compare.pre_scr_referrals_work', @newname = 'pre_scr_referrals'
			EXEC sp_rename @objname = 'Merge_R_Compare.pre_scr_cwt_work', @newname = 'pre_scr_cwt'
			EXEC sp_rename @objname = 'Merge_R_Compare.pre_OpenTargetDates_work', @newname = 'pre_OpenTargetDates'
			EXEC sp_rename @objname = 'Merge_R_Compare.pre_scr_assessments_work', @newname = 'pre_scr_assessments'
			EXEC sp_rename @objname = 'Merge_R_Compare.pre_scr_comments_work', @newname = 'pre_scr_comments'
			EXEC sp_rename @objname = 'Merge_R_Compare.pre_scr_InterProviderTransfers_work', @newname = 'pre_scr_InterProviderTransfers'
			EXEC sp_rename @objname = 'Merge_R_Compare.pre_scr_NextActions_work', @newname = 'pre_scr_NextActions'
			EXEC sp_rename @objname = 'Merge_R_Compare.pre_Workflow_Work', @newname = 'pre_Workflow'


			COMMIT TRANSACTION

		END TRY

		BEGIN CATCH
 
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

			RAISERROR (@ErrorMessage, -- Message text.  
										15, -- Severity.  
										1 -- State.  
										);
 
		END CATCH


/*

Merge_R_Compare.dbo_AspNetUsers
Merge_R_Compare.dbo_OrganisationSites
Merge_R_Compare.dbo_tblAllTreatmentDeclined
Merge_R_Compare.dbo_tblAUDIT
Merge_R_Compare.dbo_tblDEFINITIVE_TREATMENT
Merge_R_Compare.dbo_tblDEMOGRAPHICS
Merge_R_Compare.dbo_tblMAIN_ASSESSMENT
Merge_R_Compare.dbo_tblMAIN_BRACHYTHERAPY
Merge_R_Compare.dbo_tblMAIN_CHEMOTHERAPY
Merge_R_Compare.dbo_tblMAIN_PALLIATIVE
Merge_R_Compare.dbo_tblMAIN_REFERRALS
Merge_R_Compare.dbo_tblMAIN_SURGERY
Merge_R_Compare.dbo_tblMAIN_TELETHERAPY
Merge_R_Compare.dbo_tblMONITORING
Merge_R_Compare.dbo_tblOTHER_TREATMENT
Merge_R_Compare.dbo_tblPathwayUpdateEvents
Merge_R_Compare.dbo_tblTERTIARY_REFERRALS
Merge_R_Compare.dbo_tblTRACKING_COMMENTS


Merge_R_Compare.tblDEMOGRAPHICS_tblValidatedData
Merge_R_Compare.tblMAIN_REFERRALS_tblValidatedData
Merge_R_Compare.Treatments_tblValidatedData
Merge_R_Compare.MDT_tblValidatedData

*/

GO
