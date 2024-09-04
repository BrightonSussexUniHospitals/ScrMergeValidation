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
	
AS

-- EXEC Merge_R_Compare.CreateReportingMergeDifferences


		SET NOCOUNT ON;
		DECLARE @ErrorMessage_DW VARCHAR(MAX)

/********************************************************************************************************************************************************************************************************************************/
-- Take copies of the SCR_DW and SCR_ETL tables we need for reconciliation
/********************************************************************************************************************************************************************************************************************************/

		PRINT CHAR(13) + '-- Take copies of the SCR_DW and SCR_ETL tables we need for reconciliation' + CHAR(13)
			
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
-- Swap out the _work SCR_DW and SCR_ETL tables for the final persisted tables
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
 
			SELECT @ErrorMessage_DW = ERROR_MESSAGE()
			
			SELECT ERROR_NUMBER() AS ErrorNumber
			SELECT @ErrorMessage_DW AS ErrorMessage
 
			PRINT ERROR_NUMBER()
			PRINT @ErrorMessage_DW

			IF @@TRANCOUNT > 0 -- SELECT @@TRANCOUNT
			BEGIN
				PRINT 'Rolling back because of error in Incremental Transaction'
				ROLLBACK TRANSACTION
			END

			RAISERROR (@ErrorMessage_DW, -- Message text.  
										15, -- Severity.  
										1 -- State.  
										);
 
		END CATCH

/********************************************************************************************************************************************************************************************************************************/
-- Drop any _work tables used in the reconciliation
/********************************************************************************************************************************************************************************************************************************/

		DECLARE @ErrorMessage VARCHAR(MAX)

		PRINT CHAR(13) + '-- Drop any _work tables used in the reconciliation' + CHAR(13)
			
		-- Drop Column & Differences tables & view temp tables
		IF OBJECT_ID('Merge_R_Compare.ReportingMergeColumns_Work') IS NOT NULL DROP TABLE Merge_R_Compare.ReportingMergeColumns_Work
		IF OBJECT_ID('Merge_R_Compare.ReportingMergeDifferences_Work') IS NOT NULL DROP TABLE Merge_R_Compare.ReportingMergeDifferences_Work

		-- Drop the copies of the merge view _work tables
		IF OBJECT_ID('Merge_R_Compare.pre_scr_referrals_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_referrals_Work
		IF OBJECT_ID('Merge_R_Compare.pre_scr_cwt_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_cwt_Work
		IF OBJECT_ID('Merge_R_Compare.pre_OpenTargetDates_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_OpenTargetDates_Work
		IF OBJECT_ID('Merge_R_Compare.pre_scr_assessments_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_assessments_Work
		IF OBJECT_ID('Merge_R_Compare.pre_scr_comments_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_comments_Work
		IF OBJECT_ID('Merge_R_Compare.pre_scr_InterProviderTransfers_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_InterProviderTransfers_Work
		IF OBJECT_ID('Merge_R_Compare.pre_scr_NextActions_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_scr_NextActions_Work
		IF OBJECT_ID('Merge_R_Compare.pre_Workflow_Work') IS NOT NULL DROP TABLE Merge_R_Compare.pre_Workflow_Work

/********************************************************************************************************************************************************************************************************************************/
-- Run the reconciliation
/********************************************************************************************************************************************************************************************************************************/

		PRINT CHAR(13) + '-- Run the reconciliation' + CHAR(13)
			
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

		-- Add in the table names without column names to represent whole records that are lost
		INSERT INTO	Merge_R_Compare.ReportingMergeColumns_Work
					(SchemaName
					,TableName
					,ColumnOrder
					)
		SELECT		s.name	AS SchemaName
					,v.name AS TableName
					,0 AS ColumnOrder
		FROM		CancerReporting_MERGE.sys.schemas s
		INNER JOIN	CancerReporting_MERGE.sys.views v
							ON s.schema_id = v.schema_id
		WHERE		s.name = 'Merge_R_Compare'

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
					,IsDedupeDrop INT
					,HasDedupeChangeDiff INT
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
		
		DECLARE @SQL_Ref_WHERE_All VARCHAR(MAX) = '' 
		DECLARE @SQL_CWT_WHERE_All VARCHAR(MAX) = ''  
		DECLARE @SQL_OpenTargetDates_WHERE_All VARCHAR(MAX) = '' 
		DECLARE @SQL_Assessments_WHERE_All VARCHAR(MAX) = '' 
		DECLARE @SQL_Comments_WHERE_All VARCHAR(MAX) = '' 
		DECLARE @SQL_InterProviderTransfers_WHERE_All VARCHAR(MAX) = '' 
		DECLARE @SQL_NextActions_WHERE_All VARCHAR(MAX) = '' 
		DECLARE @SQL_WorkFlow_WHERE_All VARCHAR(MAX) = '' 

/********************************************************************************************************************************************************************************************************************************/

		-- Create temporary table with data from the PRE_MERGE SCR_Referrals view and create an index.
		SELECT * INTO Merge_R_Compare.pre_scr_referrals_Work FROM Merge_R_Compare.VwSCR_Warehouse_SCR_Referrals

		CREATE NONCLUSTERED INDEX ix_care_id ON Merge_R_Compare.pre_scr_referrals_Work(srcsysid ASC, care_id ASC)

------------------------------------------------------------------------------------------------------------------------------------------

		-- Record the number of gains and losses at record level
		INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType)
		SELECT		mer.CARE_ID
					,mer.CARE_ID
					,pre.OrigSrcSysID
					,pre.OrigCARE_ID
					,pre.OrigCARE_ID
					,mc.ColumnIx
					,CASE	WHEN pre.CARE_ID IS NULL THEN 'Gained'
							WHEN mer.CARE_ID IS NULL THEN 'Lost'
							END AS DiffType
		FROM		Merge_R_Compare.pre_scr_referrals_Work pre
		FULL JOIN	CancerReporting_MERGE.Merge_R_Compare.VwSCR_Warehouse_SCR_Referrals mer
															ON	pre.CARE_ID = mer.CARE_ID
		CROSS JOIN	(SELECT		ColumnIx
					FROM		Merge_R_Compare.ReportingMergeColumns_Work
					WHERE		SchemaName = 'Merge_R_Compare'
					AND			TableName = 'VwSCR_Warehouse_SCR_Referrals'
					AND			ColumnOrder = 0
								) mc
																	
		WHERE		pre.CARE_ID IS NULL
		OR			mer.CARE_ID IS NULL

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

		-- Record the number of gains and losses at record level
		INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType)
		SELECT		mer.CARE_ID
					,mer.CWT_ID
					,pre.OrigSrcSysID
					,pre.OrigCARE_ID
					,pre.OrigCWT_ID
					,mc.ColumnIx
					,CASE	WHEN pre.CARE_ID IS NULL THEN 'Gained'
							WHEN mer.CARE_ID IS NULL THEN 'Lost'
							END AS DiffType
		FROM		Merge_R_Compare.pre_scr_cwt_Work pre
		FULL JOIN	CancerReporting_MERGE.Merge_R_Compare.VwSCR_Warehouse_SCR_CWT mer
															ON	pre.CWT_ID = mer.CWT_ID
		CROSS JOIN	(SELECT		ColumnIx
					FROM		Merge_R_Compare.ReportingMergeColumns_Work
					WHERE		SchemaName = 'Merge_R_Compare'
					AND			TableName = 'VwSCR_Warehouse_SCR_CWT'
					AND			ColumnOrder = 0
								) mc
																	
		WHERE		pre.CWT_ID IS NULL
		OR			mer.CWT_ID IS NULL

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
														'FULL JOIN	CancerReporting_MERGE.' + CONCAT(SchemaName, '.', TableName) + ' mer ' + CHAR(13) +
														'													ON	pre.CWT_ID = mer.CWT_ID ' + CHAR(13)
								,@SQL_CWT_WHERE1	=	'WHERE		pre.' + ColumnName + ' != mer.' + ColumnName + ' ' + CHAR(13)
								,@SQL_CWT_WHERE2	=	'WHERE		(pre.' + ColumnName + ' IS NULL AND mer.' + ColumnName + ' IS NOT NULL) ' + CHAR(13)
								,@SQL_CWT_WHERE3	=	'WHERE		(pre.' + ColumnName + ' IS NOT NULL AND mer.' + ColumnName + ' IS NULL) '  + CHAR(13)
								,@SQL_CWT_WHERE_All	=	CASE WHEN ColumnName IN ('CwtPathwayTypeId2WW','CwtPathwayTypeId28','CwtPathwayTypeId62'
																				,'CwtPathwayTypeIdSurv','UnifyPtlStatusCode','ReportingPathwayLength') THEN '' ELSE		-- Only do a FULL JOIN on these fields
														'AND		pre.CWT_ID IS NOT NULL AND mer.CWT_ID IS NOT NULL ' + CHAR(13) END									-- Treat all other fields like and INNER JOIN

						FROM Merge_R_Compare.ReportingMergeColumns_Work WHERE TableName = 'VwSCR_Warehouse_SCR_CWT' AND ColumnOrder = @ColumnOrder

						-- EXEC the 3 SQL statement variants
						SET @SQL_CWT = @SQL_CWT_CORE + @SQL_CWT_WHERE1 + @SQL_CWT_WHERE_All; EXEC (@SQL_CWT); PRINT @SQL_CWT
						SET @SQL_CWT = @SQL_CWT_CORE + @SQL_CWT_WHERE2 + @SQL_CWT_WHERE_All; EXEC (@SQL_CWT); PRINT @SQL_CWT
						SET @SQL_CWT = @SQL_CWT_CORE + @SQL_CWT_WHERE3 + @SQL_CWT_WHERE_All; EXEC (@SQL_CWT); PRINT @SQL_CWT

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

		-- Record the number of gains and losses at record level
		INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType)
		SELECT		mer.CARE_ID
					,mer.ASSESSMENT_ID
					,pre.OrigSrcSysID
					,pre.OrigCARE_ID
					,pre.OrigASSESSMENT_ID
					,mc.ColumnIx
					,CASE	WHEN pre.CARE_ID IS NULL THEN 'Gained'
							WHEN mer.CARE_ID IS NULL THEN 'Lost'
							END AS DiffType
		FROM		Merge_R_Compare.pre_scr_assessments_Work pre
		FULL JOIN	CancerReporting_MERGE.Merge_R_Compare.VwSCR_Warehouse_SCR_Assessments mer
															ON	pre.ASSESSMENT_ID = mer.ASSESSMENT_ID
		CROSS JOIN	(SELECT		ColumnIx
					FROM		Merge_R_Compare.ReportingMergeColumns_Work
					WHERE		SchemaName = 'Merge_R_Compare'
					AND			TableName = 'VwSCR_Warehouse_SCR_Assessments'
					AND			ColumnOrder = 0
								) mc
																	
		WHERE		pre.ASSESSMENT_ID IS NULL
		OR			mer.ASSESSMENT_ID IS NULL

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

		-- Record the number of gains and losses at record level
		INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType)
		SELECT		mer.CARE_ID
					,mer.OpenTargetDatesId
					,pre.OrigSrcSysID
					,pre.OrigCARE_ID
					,pre.OpenTargetDatesId
					,mc.ColumnIx
					,CASE	WHEN pre.CARE_ID IS NULL THEN 'Gained'
							WHEN mer.CARE_ID IS NULL THEN 'Lost'
							END AS DiffType
		FROM		Merge_R_Compare.pre_OpenTargetDates_Work pre
		FULL JOIN	CancerReporting_MERGE.Merge_R_Compare.VwSCR_Warehouse_OpenTargetDates mer
															ON	pre.CWT_ID = mer.CWT_ID
															AND	pre.TargetType = mer.TargetType
		CROSS JOIN	(SELECT		ColumnIx
					FROM		Merge_R_Compare.ReportingMergeColumns_Work
					WHERE		SchemaName = 'Merge_R_Compare'
					AND			TableName = 'VwSCR_Warehouse_OpenTargetDates'
					AND			ColumnOrder = 0
								) mc
																	
		WHERE		pre.CWT_ID IS NULL
		OR			mer.CWT_ID IS NULL

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

		-- Record the number of gains and losses at record level
		INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType)
		SELECT		mer.CARE_ID
					,mer.SourceRecordId
					,pre.OrigSrcSysID
					,pre.OrigCARE_ID
					,pre.SourceRecordId
					,mc.ColumnIx
					,CASE	WHEN pre.CARE_ID IS NULL THEN 'Gained'
							WHEN mer.CARE_ID IS NULL THEN 'Lost'
							END AS DiffType
		FROM		Merge_R_Compare.pre_scr_comments_Work pre
		FULL JOIN	CancerReporting_MERGE.Merge_R_Compare.VwSCR_Warehouse_SCR_Comments mer
																							ON	pre.SourceRecordId = mer.SourceRecordId
																							AND	pre.SourceTableName = mer.SourceTableName
																							AND	pre.SourceColumnName = mer.SourceColumnName
		CROSS JOIN	(SELECT		ColumnIx
					FROM		Merge_R_Compare.ReportingMergeColumns_Work
					WHERE		SchemaName = 'Merge_R_Compare'
					AND			TableName = 'VwSCR_Warehouse_SCR_Comments'
					AND			ColumnOrder = 0
								) mc
																	
		WHERE		pre.SourceRecordId IS NULL
		OR			mer.SourceRecordId IS NULL

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

		-- Record the number of gains and losses at record level
		INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType)
		SELECT		mer.CareID
					,mer.TertiaryReferralID
					,pre.OrigSrcSysID
					,pre.OrigCARE_ID
					,pre.TertiaryReferralID
					,mc.ColumnIx
					,CASE	WHEN pre.CareID IS NULL THEN 'Gained'
							WHEN mer.CareID IS NULL THEN 'Lost'
							END AS DiffType
		FROM		Merge_R_Compare.pre_scr_InterProviderTransfers_Work pre
		FULL JOIN	CancerReporting_MERGE.Merge_R_Compare.VwSCR_Warehouse_SCR_InterProviderTransfers mer
																							ON	pre.TertiaryReferralID = mer.TertiaryReferralID
																							AND	pre.SCR_IPTTypeCode = mer.SCR_IPTTypeCode
		CROSS JOIN	(SELECT		ColumnIx
					FROM		Merge_R_Compare.ReportingMergeColumns_Work
					WHERE		SchemaName = 'Merge_R_Compare'
					AND			TableName = 'VwSCR_Warehouse_SCR_InterProviderTransfers'
					AND			ColumnOrder = 0
								) mc
																	
		WHERE		pre.TertiaryReferralID IS NULL
		OR			mer.TertiaryReferralID IS NULL

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

		-- Record the number of gains and losses at record level
		INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType)
		SELECT		CAST(NULL AS INT)
					,CAST(mer.IdentityTypeId AS VARCHAR(255)) + '|' + mer.IdentityTypeRecordId + '|' + CAST(mer.WorkflowID AS VARCHAR(255))
					,pre.OrigSrcSysID
					,CAST(NULL AS INT)
					,CAST(Pre.IdentityTypeId AS VARCHAR(255)) + '|' + Pre.IdentityTypeRecordId + '|' + CAST(Pre.WorkflowID AS VARCHAR(255))
					,mc.ColumnIx
					,CASE	WHEN pre.IdentityTypeRecordId IS NULL THEN 'Gained'
							WHEN mer.IdentityTypeRecordId IS NULL THEN 'Lost'
							END AS DiffType
		FROM		Merge_R_Compare.pre_Workflow_Work pre
		FULL JOIN	CancerReporting_MERGE.Merge_R_Compare.VwSCR_Warehouse_Workflow mer
																							ON	pre.IdentityTypeRecordId = mer.IdentityTypeRecordId
																							AND	pre.IdentityTypeId = mer.IdentityTypeId
																							AND	pre.WorkflowID = mer.WorkflowID
		CROSS JOIN	(SELECT		ColumnIx
					FROM		Merge_R_Compare.ReportingMergeColumns_Work
					WHERE		SchemaName = 'Merge_R_Compare'
					AND			TableName = 'VwSCR_Warehouse_SCR_Workflow'
					AND			ColumnOrder = 0
								) mc
																	
		WHERE		pre.IdentityTypeRecordId IS NULL
		OR			mer.IdentityTypeRecordId IS NULL

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

		-- Record the number of gains and losses at record level
		INSERT INTO Merge_R_Compare.ReportingMergeDifferences_Work (MerCare_ID, MerRecordID , PreSrcSysID , PreCare_ID , PreRecordID , ColumnIx , DiffType)
		SELECT		mer.CareID
					,mer.PathwayUpdateEventID
					,pre.OrigSrcSysID
					,pre.OrigCareID
					,pre.OrigPathwayUpdateEventID
					,mc.ColumnIx
					,CASE	WHEN pre.PathwayUpdateEventID IS NULL THEN 'Gained'
							WHEN mer.PathwayUpdateEventID IS NULL THEN 'Lost'
							END AS DiffType
		FROM		Merge_R_Compare.pre_scr_NextActions_Work pre
		FULL JOIN	CancerReporting_MERGE.Merge_R_Compare.VwSCR_Warehouse_SCR_NextActions mer
															ON	pre.PathwayUpdateEventID = mer.PathwayUpdateEventID
		CROSS JOIN	(SELECT		ColumnIx
					FROM		Merge_R_Compare.ReportingMergeColumns_Work
					WHERE		SchemaName = 'Merge_R_Compare'
					AND			TableName = 'VwSCR_Warehouse_SCR_NextActions'
					AND			ColumnOrder = 0
								) mc
																	
		WHERE		pre.PathwayUpdateEventID IS NULL
		OR			mer.PathwayUpdateEventID IS NULL

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
																'FULL JOIN	CancerReporting_MERGE.' + CONCAT(SchemaName, '.', TableName) + ' mer ' + CHAR(13) +
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
-- Drop any _work tables used to flag any columns that have underlying changed resultant values
/********************************************************************************************************************************************************************************************************************************/

		PRINT CHAR(13) + '-- Drop any _work tables used to flag any columns that have underlying changed resultant values' + CHAR(13)
			
		-- Drop dedupe changed values tables
		IF OBJECT_ID('Merge_R_Compare.DedupeChangedDemographics_work') IS NOT NULL DROP TABLE Merge_R_Compare.DedupeChangedDemographics_work
		IF OBJECT_ID('Merge_R_Compare.DedupeChangedRefs_work') IS NOT NULL DROP TABLE Merge_R_Compare.DedupeChangedRefs_work
		IF OBJECT_ID('Merge_R_Compare.DedupeDroppedRefs_work') IS NOT NULL DROP TABLE Merge_R_Compare.DedupeDroppedRefs_work

/********************************************************************************************************************************************************************************************************************************/
-- Find resultant values in the deduplication validation datasets that have changed
/********************************************************************************************************************************************************************************************************************************/

		PRINT CHAR(13) + '-- Find resultant values in the deduplication validation datasets that have changed' + CHAR(13)
			
		-- Find all the minors associated with confirmed major demographics records
		IF OBJECT_ID('tempdb..#tblDEMOGRAPHICS_tblValidatedData') IS NOT NULL DROP TABLE #tblDEMOGRAPHICS_tblValidatedData
		SELECT		vd_minor.SrcSys_MajorExt
					,vd_minor.Src_UID_MajorExt
					,vd_minor.SrcSys_Major
					,vd_minor.Src_UID_Major
					,vd_minor.IsValidatedMajor
					,vd_minor.IsConfirmed
					,vd_minor.LastUpdated
					,vd_minor.SrcSys
					,vd_minor.Src_UID
					,vd_minor.Src_UID AS PATIENT_ID
					,vd_major.N1_1_NHS_NUMBER
					,vd_major.NHS_NUMBER_STATUS
					,vd_major.L_RA3_RID
					,vd_major.L_RA7_RID
					,vd_major.L_RVJ01_RID
					,vd_major.TEMP_ID
					,vd_major.L_NSTS_STATUS
					,vd_major.N1_2_HOSPITAL_NUMBER
					,vd_major.L_TITLE
					,vd_major.N1_5_SURNAME
					,vd_major.N1_6_FORENAME
					,vd_major.N1_7_ADDRESS_1
					,vd_major.N1_7_ADDRESS_2
					,vd_major.N1_7_ADDRESS_3
					,vd_major.N1_7_ADDRESS_4
					,vd_major.N1_7_ADDRESS_5
					,vd_major.N1_8_POSTCODE
					,vd_major.N1_9_SEX
					,vd_major.N1_10_DATE_BIRTH
					,vd_major.N1_11_GP_CODE
					,vd_major.N1_12_GP_PRACTICE_CODE
					,vd_major.N1_13_PCT
					,vd_major.N1_14_SURNAME_BIRTH
					,vd_major.N1_15_ETHNICITY
					,vd_major.PAT_PREF_NAME
					,vd_major.PAT_OCCUPATION
					,vd_major.PAT_SOCIAL_CLASS
					,vd_major.PAT_LIVES_ALONE
					,vd_major.MARITAL_STATUS
					,vd_major.PAT_PREF_LANGUAGE
					,vd_major.PAT_PREF_CONTACT
					,vd_major.L_DEATH_STATUS
					,vd_major.N15_1_DATE_DEATH
					,vd_major.N15_2_DEATH_LOCATION
					,vd_major.N15_3_DEATH_CAUSE
					,vd_major.N15_4_DEATH_CANCER
					,vd_major.N15_5_DEATH_CODE_1
					,vd_major.N15_6_DEATH_CODE_2
					,vd_major.N15_7_DEATH_CODE_3
					,vd_major.N15_8_DEATH_CODE_4
					,vd_major.N15_9_DEATH_DISCREPANCY
					,vd_major.N_CC4_TOWN
					,vd_major.N_CC5_COUNTRY
					,vd_major.N_CC6_M_SURNAME
					,vd_major.N_CC7_M_CLASS
					,vd_major.N_CC8_M_FORENAME
					,vd_major.N_CC9_M_DOB
					,vd_major.N_CC10_M_TOWN
					,vd_major.N_CC11_M_COUNTRY
					,vd_major.N_CC12_M_OCC
					,vd_major.N_CC13_M_OCC_DIAG
					,vd_major.N_CC6_F_SURNAME
					,vd_major.N_CC7_F_CLASS
					,vd_major.N_CC8_F_FORENAME
					,vd_major.N_CC9_F_DOB
					,vd_major.N_CC10_F_TOWN
					,vd_major.N_CC11_F_COUNTRY
					,vd_major.N_CC12_F_OCC
					,vd_major.N_CC13_F_OCC_DIAG
					,vd_major.N_CC14_MULTI_BIRTH
					,vd_major.R_POST_MORTEM
					,vd_major.R_DAY_PHONE
					,vd_major.DAY_PHONE_EXT
					,vd_major.R_EVE_PHONE
					,vd_major.EVE_PHONE_EXT
					,vd_major.R_DEATH_TREATMENT
					,vd_major.R_PM_DETAILS
					,vd_major.L_IATROGENIC_DEATH
					,vd_major.L_INFECTION_DEATH
					,vd_major.L_DEATH_COMMENTS
					,vd_major.RELIGION
					,vd_major.CONTACT_DETAILS
					,vd_major.NOK_NAME
					,vd_major.NOK_ADDRESS_1
					,vd_major.NOK_ADDRESS_2
					,vd_major.NOK_ADDRESS_3
					,vd_major.NOK_ADDRESS_4
					,vd_major.NOK_ADDRESS_5
					,vd_major.NOK_POSTCODE
					,vd_major.NOK_CONTACT
					,vd_major.NOK_RELATIONSHIP
					,vd_major.PAT_DEPENDANTS
					,vd_major.CARER_NAME
					,vd_major.CARER_ADDRESS_1
					,vd_major.CARER_ADDRESS_2
					,vd_major.CARER_ADDRESS_3
					,vd_major.CARER_ADDRESS_4
					,vd_major.CARER_ADDRESS_5
					,vd_major.CARER_POSTCODE
					,vd_major.CARER_CONTACT
					,vd_major.CARER_RELATIONSHIP
					,vd_major.CARER1_TYPE
					,vd_major.CARER2_NAME
					,vd_major.CARER2_ADDRESS_1
					,vd_major.CARER2_ADDRESS_2
					,vd_major.CARER2_ADDRESS_3
					,vd_major.CARER2_ADDRESS_4
					,vd_major.CARER2_ADDRESS_5
					,vd_major.CARER2_POSTCODE
					,vd_major.CARER2_CONTACT
					,vd_major.CARER2_RELATIONSHIP
					,vd_major.CARER2_TYPE
					,vd_major.PT_AT_RISK
					,vd_major.REASON_RISK
					,vd_major.GESTATION
					,vd_major.CAUSE_OF_DEATH_UROLOGY
					,vd_major.AVOIDABLE_DEATH
					,vd_major.AVOIDABLE_DETAILS
					,vd_major.OTHER_DEATH_CAUSE_UROLOGY
					,vd_major.ACTION_ID
					,vd_major.STATED_GENDER_CODE
					,vd_major.CAUSE_OF_DEATH_UROLOGY_FUP
					,vd_major.DEATH_WITHIN_30_DAYS_OF_TREAT
					,vd_major.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT
					,vd_major.DEATH_CAUSE_LATER_DATE
					,vd_major.RegisteredPractice
					,vd_major.RegisteredGP
					,vd_major.PersonSexualOrientation
					,vd_major.ValidatedRecordCreatedDttm
		INTO		#tblDEMOGRAPHICS_tblValidatedData
		FROM		Merge_R_Compare.tblDEMOGRAPHICS_tblValidatedData vd_major
		INNER JOIN	Merge_R_Compare.tblDEMOGRAPHICS_tblValidatedData vd_minor
																			ON	vd_major.SrcSys_MajorExt = vd_minor.SrcSys_MajorExt
																			AND	vd_major.Src_UID_MajorExt = vd_minor.Src_UID_MajorExt
		WHERE		vd_major.IsConfirmed = 1
		AND			vd_major.IsValidatedMajor = 1


		-- Find the deduplicated demographics that are different from the original demographics
		SELECT		dem.SrcSysID
					,dem.PATIENT_ID
					,N1_1_NHS_NUMBER_Diff						= CASE WHEN dem.N1_1_NHS_NUMBER != vd.N1_1_NHS_NUMBER OR (dem.N1_1_NHS_NUMBER IS NULL AND vd.N1_1_NHS_NUMBER IS NOT NULL) OR (dem.N1_1_NHS_NUMBER IS NOT NULL AND vd.N1_1_NHS_NUMBER IS NULL) THEN 1 ELSE 0 END
					,NHS_NUMBER_STATUS_Diff						= CASE WHEN dem.NHS_NUMBER_STATUS != vd.NHS_NUMBER_STATUS OR (dem.NHS_NUMBER_STATUS IS NULL AND vd.NHS_NUMBER_STATUS IS NOT NULL) OR (dem.NHS_NUMBER_STATUS IS NOT NULL AND vd.NHS_NUMBER_STATUS IS NULL) THEN 1 ELSE 0 END
					,L_RA3_RID_Diff								= CASE WHEN dem.L_RA3_RID != vd.L_RA3_RID OR (dem.L_RA3_RID IS NULL AND vd.L_RA3_RID IS NOT NULL) OR (dem.L_RA3_RID IS NOT NULL AND vd.L_RA3_RID IS NULL) THEN 1 ELSE 0 END
					,L_RA7_RID_Diff								= CASE WHEN dem.L_RA7_RID != vd.L_RA7_RID OR (dem.L_RA7_RID IS NULL AND vd.L_RA7_RID IS NOT NULL) OR (dem.L_RA7_RID IS NOT NULL AND vd.L_RA7_RID IS NULL) THEN 1 ELSE 0 END
					,L_RVJ01_RID_Diff							= CASE WHEN dem.L_RVJ01_RID != vd.L_RVJ01_RID OR (dem.L_RVJ01_RID IS NULL AND vd.L_RVJ01_RID IS NOT NULL) OR (dem.L_RVJ01_RID IS NOT NULL AND vd.L_RVJ01_RID IS NULL) THEN 1 ELSE 0 END
					,TEMP_ID_Diff								= CASE WHEN dem.TEMP_ID != vd.TEMP_ID OR (dem.TEMP_ID IS NULL AND vd.TEMP_ID IS NOT NULL) OR (dem.TEMP_ID IS NOT NULL AND vd.TEMP_ID IS NULL) THEN 1 ELSE 0 END
					,L_NSTS_STATUS_Diff							= CASE WHEN dem.L_NSTS_STATUS != vd.L_NSTS_STATUS OR (dem.L_NSTS_STATUS IS NULL AND vd.L_NSTS_STATUS IS NOT NULL) OR (dem.L_NSTS_STATUS IS NOT NULL AND vd.L_NSTS_STATUS IS NULL) THEN 1 ELSE 0 END
					,N1_2_HOSPITAL_NUMBER_Diff					= CASE WHEN dem.N1_2_HOSPITAL_NUMBER != vd.N1_2_HOSPITAL_NUMBER OR (dem.N1_2_HOSPITAL_NUMBER IS NULL AND vd.N1_2_HOSPITAL_NUMBER IS NOT NULL) OR (dem.N1_2_HOSPITAL_NUMBER IS NOT NULL AND vd.N1_2_HOSPITAL_NUMBER IS NULL) THEN 1 ELSE 0 END
					,L_TITLE_Diff								= CASE WHEN dem.L_TITLE != vd.L_TITLE OR (dem.L_TITLE IS NULL AND vd.L_TITLE IS NOT NULL) OR (dem.L_TITLE IS NOT NULL AND vd.L_TITLE IS NULL) THEN 1 ELSE 0 END
					,N1_5_SURNAME_Diff							= CASE WHEN dem.N1_5_SURNAME != vd.N1_5_SURNAME OR (dem.N1_5_SURNAME IS NULL AND vd.N1_5_SURNAME IS NOT NULL) OR (dem.N1_5_SURNAME IS NOT NULL AND vd.N1_5_SURNAME IS NULL) THEN 1 ELSE 0 END
					,N1_6_FORENAME_Diff							= CASE WHEN dem.N1_6_FORENAME != vd.N1_6_FORENAME OR (dem.N1_6_FORENAME IS NULL AND vd.N1_6_FORENAME IS NOT NULL) OR (dem.N1_6_FORENAME IS NOT NULL AND vd.N1_6_FORENAME IS NULL) THEN 1 ELSE 0 END
					,N1_7_ADDRESS_1_Diff						= CASE WHEN dem.N1_7_ADDRESS_1 != vd.N1_7_ADDRESS_1 OR (dem.N1_7_ADDRESS_1 IS NULL AND vd.N1_7_ADDRESS_1 IS NOT NULL) OR (dem.N1_7_ADDRESS_1 IS NOT NULL AND vd.N1_7_ADDRESS_1 IS NULL) THEN 1 ELSE 0 END
					,N1_7_ADDRESS_2_Diff						= CASE WHEN dem.N1_7_ADDRESS_2 != vd.N1_7_ADDRESS_2 OR (dem.N1_7_ADDRESS_2 IS NULL AND vd.N1_7_ADDRESS_2 IS NOT NULL) OR (dem.N1_7_ADDRESS_2 IS NOT NULL AND vd.N1_7_ADDRESS_2 IS NULL) THEN 1 ELSE 0 END
					,N1_7_ADDRESS_3_Diff						= CASE WHEN dem.N1_7_ADDRESS_3 != vd.N1_7_ADDRESS_3 OR (dem.N1_7_ADDRESS_3 IS NULL AND vd.N1_7_ADDRESS_3 IS NOT NULL) OR (dem.N1_7_ADDRESS_3 IS NOT NULL AND vd.N1_7_ADDRESS_3 IS NULL) THEN 1 ELSE 0 END
					,N1_7_ADDRESS_4_Diff						= CASE WHEN dem.N1_7_ADDRESS_4 != vd.N1_7_ADDRESS_4 OR (dem.N1_7_ADDRESS_4 IS NULL AND vd.N1_7_ADDRESS_4 IS NOT NULL) OR (dem.N1_7_ADDRESS_4 IS NOT NULL AND vd.N1_7_ADDRESS_4 IS NULL) THEN 1 ELSE 0 END
					,N1_7_ADDRESS_5_Diff						= CASE WHEN dem.N1_7_ADDRESS_5 != vd.N1_7_ADDRESS_5 OR (dem.N1_7_ADDRESS_5 IS NULL AND vd.N1_7_ADDRESS_5 IS NOT NULL) OR (dem.N1_7_ADDRESS_5 IS NOT NULL AND vd.N1_7_ADDRESS_5 IS NULL) THEN 1 ELSE 0 END
					,N1_8_POSTCODE_Diff							= CASE WHEN dem.N1_8_POSTCODE != vd.N1_8_POSTCODE OR (dem.N1_8_POSTCODE IS NULL AND vd.N1_8_POSTCODE IS NOT NULL) OR (dem.N1_8_POSTCODE IS NOT NULL AND vd.N1_8_POSTCODE IS NULL) THEN 1 ELSE 0 END
					,N1_9_SEX_Diff								= CASE WHEN dem.N1_9_SEX != vd.N1_9_SEX OR (dem.N1_9_SEX IS NULL AND vd.N1_9_SEX IS NOT NULL) OR (dem.N1_9_SEX IS NOT NULL AND vd.N1_9_SEX IS NULL) THEN 1 ELSE 0 END
					,N1_10_DATE_BIRTH_Diff						= CASE WHEN dem.N1_10_DATE_BIRTH != vd.N1_10_DATE_BIRTH OR (dem.N1_10_DATE_BIRTH IS NULL AND vd.N1_10_DATE_BIRTH IS NOT NULL) OR (dem.N1_10_DATE_BIRTH IS NOT NULL AND vd.N1_10_DATE_BIRTH IS NULL) THEN 1 ELSE 0 END
					,N1_11_GP_CODE_Diff							= CASE WHEN dem.N1_11_GP_CODE != vd.N1_11_GP_CODE OR (dem.N1_11_GP_CODE IS NULL AND vd.N1_11_GP_CODE IS NOT NULL) OR (dem.N1_11_GP_CODE IS NOT NULL AND vd.N1_11_GP_CODE IS NULL) THEN 1 ELSE 0 END
					,N1_12_GP_PRACTICE_CODE_Diff				= CASE WHEN dem.N1_12_GP_PRACTICE_CODE != vd.N1_12_GP_PRACTICE_CODE OR (dem.N1_12_GP_PRACTICE_CODE IS NULL AND vd.N1_12_GP_PRACTICE_CODE IS NOT NULL) OR (dem.N1_12_GP_PRACTICE_CODE IS NOT NULL AND vd.N1_12_GP_PRACTICE_CODE IS NULL) THEN 1 ELSE 0 END
					,N1_13_PCT_Diff								= CASE WHEN dem.N1_13_PCT != vd.N1_13_PCT OR (dem.N1_13_PCT IS NULL AND vd.N1_13_PCT IS NOT NULL) OR (dem.N1_13_PCT IS NOT NULL AND vd.N1_13_PCT IS NULL) THEN 1 ELSE 0 END
					,N1_14_SURNAME_BIRTH_Diff					= CASE WHEN dem.N1_14_SURNAME_BIRTH != vd.N1_14_SURNAME_BIRTH OR (dem.N1_14_SURNAME_BIRTH IS NULL AND vd.N1_14_SURNAME_BIRTH IS NOT NULL) OR (dem.N1_14_SURNAME_BIRTH IS NOT NULL AND vd.N1_14_SURNAME_BIRTH IS NULL) THEN 1 ELSE 0 END
					,N1_15_ETHNICITY_Diff						= CASE WHEN dem.N1_15_ETHNICITY != vd.N1_15_ETHNICITY OR (dem.N1_15_ETHNICITY IS NULL AND vd.N1_15_ETHNICITY IS NOT NULL) OR (dem.N1_15_ETHNICITY IS NOT NULL AND vd.N1_15_ETHNICITY IS NULL) THEN 1 ELSE 0 END
					,PAT_PREF_NAME_Diff							= CASE WHEN dem.PAT_PREF_NAME != vd.PAT_PREF_NAME OR (dem.PAT_PREF_NAME IS NULL AND vd.PAT_PREF_NAME IS NOT NULL) OR (dem.PAT_PREF_NAME IS NOT NULL AND vd.PAT_PREF_NAME IS NULL) THEN 1 ELSE 0 END
					,PAT_OCCUPATION_Diff						= CASE WHEN dem.PAT_OCCUPATION != vd.PAT_OCCUPATION OR (dem.PAT_OCCUPATION IS NULL AND vd.PAT_OCCUPATION IS NOT NULL) OR (dem.PAT_OCCUPATION IS NOT NULL AND vd.PAT_OCCUPATION IS NULL) THEN 1 ELSE 0 END
					,PAT_SOCIAL_CLASS_Diff						= CASE WHEN dem.PAT_SOCIAL_CLASS != vd.PAT_SOCIAL_CLASS OR (dem.PAT_SOCIAL_CLASS IS NULL AND vd.PAT_SOCIAL_CLASS IS NOT NULL) OR (dem.PAT_SOCIAL_CLASS IS NOT NULL AND vd.PAT_SOCIAL_CLASS IS NULL) THEN 1 ELSE 0 END
					,PAT_LIVES_ALONE_Diff						= CASE WHEN dem.PAT_LIVES_ALONE != vd.PAT_LIVES_ALONE OR (dem.PAT_LIVES_ALONE IS NULL AND vd.PAT_LIVES_ALONE IS NOT NULL) OR (dem.PAT_LIVES_ALONE IS NOT NULL AND vd.PAT_LIVES_ALONE IS NULL) THEN 1 ELSE 0 END
					,MARITAL_STATUS_Diff						= CASE WHEN dem.MARITAL_STATUS != vd.MARITAL_STATUS OR (dem.MARITAL_STATUS IS NULL AND vd.MARITAL_STATUS IS NOT NULL) OR (dem.MARITAL_STATUS IS NOT NULL AND vd.MARITAL_STATUS IS NULL) THEN 1 ELSE 0 END
					,PAT_PREF_LANGUAGE_Diff						= CASE WHEN dem.PAT_PREF_LANGUAGE != vd.PAT_PREF_LANGUAGE OR (dem.PAT_PREF_LANGUAGE IS NULL AND vd.PAT_PREF_LANGUAGE IS NOT NULL) OR (dem.PAT_PREF_LANGUAGE IS NOT NULL AND vd.PAT_PREF_LANGUAGE IS NULL) THEN 1 ELSE 0 END
					,PAT_PREF_CONTACT_Diff						= CASE WHEN dem.PAT_PREF_CONTACT != vd.PAT_PREF_CONTACT OR (dem.PAT_PREF_CONTACT IS NULL AND vd.PAT_PREF_CONTACT IS NOT NULL) OR (dem.PAT_PREF_CONTACT IS NOT NULL AND vd.PAT_PREF_CONTACT IS NULL) THEN 1 ELSE 0 END
					,L_DEATH_STATUS_Diff						= CASE WHEN dem.L_DEATH_STATUS != vd.L_DEATH_STATUS OR (dem.L_DEATH_STATUS IS NULL AND vd.L_DEATH_STATUS IS NOT NULL) OR (dem.L_DEATH_STATUS IS NOT NULL AND vd.L_DEATH_STATUS IS NULL) THEN 1 ELSE 0 END
					,N15_1_DATE_DEATH_Diff						= CASE WHEN dem.N15_1_DATE_DEATH != vd.N15_1_DATE_DEATH OR (dem.N15_1_DATE_DEATH IS NULL AND vd.N15_1_DATE_DEATH IS NOT NULL) OR (dem.N15_1_DATE_DEATH IS NOT NULL AND vd.N15_1_DATE_DEATH IS NULL) THEN 1 ELSE 0 END
					,N15_2_DEATH_LOCATION_Diff					= CASE WHEN dem.N15_2_DEATH_LOCATION != vd.N15_2_DEATH_LOCATION OR (dem.N15_2_DEATH_LOCATION IS NULL AND vd.N15_2_DEATH_LOCATION IS NOT NULL) OR (dem.N15_2_DEATH_LOCATION IS NOT NULL AND vd.N15_2_DEATH_LOCATION IS NULL) THEN 1 ELSE 0 END
					,N15_3_DEATH_CAUSE_Diff						= CASE WHEN dem.N15_3_DEATH_CAUSE != vd.N15_3_DEATH_CAUSE OR (dem.N15_3_DEATH_CAUSE IS NULL AND vd.N15_3_DEATH_CAUSE IS NOT NULL) OR (dem.N15_3_DEATH_CAUSE IS NOT NULL AND vd.N15_3_DEATH_CAUSE IS NULL) THEN 1 ELSE 0 END
					,N15_4_DEATH_CANCER_Diff					= CASE WHEN dem.N15_4_DEATH_CANCER != vd.N15_4_DEATH_CANCER OR (dem.N15_4_DEATH_CANCER IS NULL AND vd.N15_4_DEATH_CANCER IS NOT NULL) OR (dem.N15_4_DEATH_CANCER IS NOT NULL AND vd.N15_4_DEATH_CANCER IS NULL) THEN 1 ELSE 0 END
					,N15_5_DEATH_CODE_1_Diff					= CASE WHEN dem.N15_5_DEATH_CODE_1 != vd.N15_5_DEATH_CODE_1 OR (dem.N15_5_DEATH_CODE_1 IS NULL AND vd.N15_5_DEATH_CODE_1 IS NOT NULL) OR (dem.N15_5_DEATH_CODE_1 IS NOT NULL AND vd.N15_5_DEATH_CODE_1 IS NULL) THEN 1 ELSE 0 END
					,N15_6_DEATH_CODE_2_Diff					= CASE WHEN dem.N15_6_DEATH_CODE_2 != vd.N15_6_DEATH_CODE_2 OR (dem.N15_6_DEATH_CODE_2 IS NULL AND vd.N15_6_DEATH_CODE_2 IS NOT NULL) OR (dem.N15_6_DEATH_CODE_2 IS NOT NULL AND vd.N15_6_DEATH_CODE_2 IS NULL) THEN 1 ELSE 0 END
					,N15_7_DEATH_CODE_3_Diff					= CASE WHEN dem.N15_7_DEATH_CODE_3 != vd.N15_7_DEATH_CODE_3 OR (dem.N15_7_DEATH_CODE_3 IS NULL AND vd.N15_7_DEATH_CODE_3 IS NOT NULL) OR (dem.N15_7_DEATH_CODE_3 IS NOT NULL AND vd.N15_7_DEATH_CODE_3 IS NULL) THEN 1 ELSE 0 END
					,N15_8_DEATH_CODE_4_Diff					= CASE WHEN dem.N15_8_DEATH_CODE_4 != vd.N15_8_DEATH_CODE_4 OR (dem.N15_8_DEATH_CODE_4 IS NULL AND vd.N15_8_DEATH_CODE_4 IS NOT NULL) OR (dem.N15_8_DEATH_CODE_4 IS NOT NULL AND vd.N15_8_DEATH_CODE_4 IS NULL) THEN 1 ELSE 0 END
					,N15_9_DEATH_DISCREPANCY_Diff				= CASE WHEN dem.N15_9_DEATH_DISCREPANCY != vd.N15_9_DEATH_DISCREPANCY OR (dem.N15_9_DEATH_DISCREPANCY IS NULL AND vd.N15_9_DEATH_DISCREPANCY IS NOT NULL) OR (dem.N15_9_DEATH_DISCREPANCY IS NOT NULL AND vd.N15_9_DEATH_DISCREPANCY IS NULL) THEN 1 ELSE 0 END
					,N_CC4_TOWN_Diff							= CASE WHEN dem.N_CC4_TOWN != vd.N_CC4_TOWN OR (dem.N_CC4_TOWN IS NULL AND vd.N_CC4_TOWN IS NOT NULL) OR (dem.N_CC4_TOWN IS NOT NULL AND vd.N_CC4_TOWN IS NULL) THEN 1 ELSE 0 END
					,N_CC5_COUNTRY_Diff							= CASE WHEN dem.N_CC5_COUNTRY != vd.N_CC5_COUNTRY OR (dem.N_CC5_COUNTRY IS NULL AND vd.N_CC5_COUNTRY IS NOT NULL) OR (dem.N_CC5_COUNTRY IS NOT NULL AND vd.N_CC5_COUNTRY IS NULL) THEN 1 ELSE 0 END
					,N_CC6_M_SURNAME_Diff						= CASE WHEN dem.N_CC6_M_SURNAME != vd.N_CC6_M_SURNAME OR (dem.N_CC6_M_SURNAME IS NULL AND vd.N_CC6_M_SURNAME IS NOT NULL) OR (dem.N_CC6_M_SURNAME IS NOT NULL AND vd.N_CC6_M_SURNAME IS NULL) THEN 1 ELSE 0 END
					,N_CC7_M_CLASS_Diff							= CASE WHEN dem.N_CC7_M_CLASS != vd.N_CC7_M_CLASS OR (dem.N_CC7_M_CLASS IS NULL AND vd.N_CC7_M_CLASS IS NOT NULL) OR (dem.N_CC7_M_CLASS IS NOT NULL AND vd.N_CC7_M_CLASS IS NULL) THEN 1 ELSE 0 END
					,N_CC8_M_FORENAME_Diff						= CASE WHEN dem.N_CC8_M_FORENAME != vd.N_CC8_M_FORENAME OR (dem.N_CC8_M_FORENAME IS NULL AND vd.N_CC8_M_FORENAME IS NOT NULL) OR (dem.N_CC8_M_FORENAME IS NOT NULL AND vd.N_CC8_M_FORENAME IS NULL) THEN 1 ELSE 0 END
					,N_CC9_M_DOB_Diff							= CASE WHEN dem.N_CC9_M_DOB != vd.N_CC9_M_DOB OR (dem.N_CC9_M_DOB IS NULL AND vd.N_CC9_M_DOB IS NOT NULL) OR (dem.N_CC9_M_DOB IS NOT NULL AND vd.N_CC9_M_DOB IS NULL) THEN 1 ELSE 0 END
					,N_CC10_M_TOWN_Diff							= CASE WHEN dem.N_CC10_M_TOWN != vd.N_CC10_M_TOWN OR (dem.N_CC10_M_TOWN IS NULL AND vd.N_CC10_M_TOWN IS NOT NULL) OR (dem.N_CC10_M_TOWN IS NOT NULL AND vd.N_CC10_M_TOWN IS NULL) THEN 1 ELSE 0 END
					,N_CC11_M_COUNTRY_Diff						= CASE WHEN dem.N_CC11_M_COUNTRY != vd.N_CC11_M_COUNTRY OR (dem.N_CC11_M_COUNTRY IS NULL AND vd.N_CC11_M_COUNTRY IS NOT NULL) OR (dem.N_CC11_M_COUNTRY IS NOT NULL AND vd.N_CC11_M_COUNTRY IS NULL) THEN 1 ELSE 0 END
					,N_CC12_M_OCC_Diff							= CASE WHEN dem.N_CC12_M_OCC != vd.N_CC12_M_OCC OR (dem.N_CC12_M_OCC IS NULL AND vd.N_CC12_M_OCC IS NOT NULL) OR (dem.N_CC12_M_OCC IS NOT NULL AND vd.N_CC12_M_OCC IS NULL) THEN 1 ELSE 0 END
					,N_CC13_M_OCC_DIAG_Diff						= CASE WHEN dem.N_CC13_M_OCC_DIAG != vd.N_CC13_M_OCC_DIAG OR (dem.N_CC13_M_OCC_DIAG IS NULL AND vd.N_CC13_M_OCC_DIAG IS NOT NULL) OR (dem.N_CC13_M_OCC_DIAG IS NOT NULL AND vd.N_CC13_M_OCC_DIAG IS NULL) THEN 1 ELSE 0 END
					,N_CC6_F_SURNAME_Diff						= CASE WHEN dem.N_CC6_F_SURNAME != vd.N_CC6_F_SURNAME OR (dem.N_CC6_F_SURNAME IS NULL AND vd.N_CC6_F_SURNAME IS NOT NULL) OR (dem.N_CC6_F_SURNAME IS NOT NULL AND vd.N_CC6_F_SURNAME IS NULL) THEN 1 ELSE 0 END
					,N_CC7_F_CLASS_Diff							= CASE WHEN dem.N_CC7_F_CLASS != vd.N_CC7_F_CLASS OR (dem.N_CC7_F_CLASS IS NULL AND vd.N_CC7_F_CLASS IS NOT NULL) OR (dem.N_CC7_F_CLASS IS NOT NULL AND vd.N_CC7_F_CLASS IS NULL) THEN 1 ELSE 0 END
					,N_CC8_F_FORENAME_Diff						= CASE WHEN dem.N_CC8_F_FORENAME != vd.N_CC8_F_FORENAME OR (dem.N_CC8_F_FORENAME IS NULL AND vd.N_CC8_F_FORENAME IS NOT NULL) OR (dem.N_CC8_F_FORENAME IS NOT NULL AND vd.N_CC8_F_FORENAME IS NULL) THEN 1 ELSE 0 END
					,N_CC9_F_DOB_Diff							= CASE WHEN dem.N_CC9_F_DOB != vd.N_CC9_F_DOB OR (dem.N_CC9_F_DOB IS NULL AND vd.N_CC9_F_DOB IS NOT NULL) OR (dem.N_CC9_F_DOB IS NOT NULL AND vd.N_CC9_F_DOB IS NULL) THEN 1 ELSE 0 END
					,N_CC10_F_TOWN_Diff							= CASE WHEN dem.N_CC10_F_TOWN != vd.N_CC10_F_TOWN OR (dem.N_CC10_F_TOWN IS NULL AND vd.N_CC10_F_TOWN IS NOT NULL) OR (dem.N_CC10_F_TOWN IS NOT NULL AND vd.N_CC10_F_TOWN IS NULL) THEN 1 ELSE 0 END
					,N_CC11_F_COUNTRY_Diff						= CASE WHEN dem.N_CC11_F_COUNTRY != vd.N_CC11_F_COUNTRY OR (dem.N_CC11_F_COUNTRY IS NULL AND vd.N_CC11_F_COUNTRY IS NOT NULL) OR (dem.N_CC11_F_COUNTRY IS NOT NULL AND vd.N_CC11_F_COUNTRY IS NULL) THEN 1 ELSE 0 END
					,N_CC12_F_OCC_Diff							= CASE WHEN dem.N_CC12_F_OCC != vd.N_CC12_F_OCC OR (dem.N_CC12_F_OCC IS NULL AND vd.N_CC12_F_OCC IS NOT NULL) OR (dem.N_CC12_F_OCC IS NOT NULL AND vd.N_CC12_F_OCC IS NULL) THEN 1 ELSE 0 END
					,N_CC13_F_OCC_DIAG_Diff						= CASE WHEN dem.N_CC13_F_OCC_DIAG != vd.N_CC13_F_OCC_DIAG OR (dem.N_CC13_F_OCC_DIAG IS NULL AND vd.N_CC13_F_OCC_DIAG IS NOT NULL) OR (dem.N_CC13_F_OCC_DIAG IS NOT NULL AND vd.N_CC13_F_OCC_DIAG IS NULL) THEN 1 ELSE 0 END
					,N_CC14_MULTI_BIRTH_Diff					= CASE WHEN dem.N_CC14_MULTI_BIRTH != vd.N_CC14_MULTI_BIRTH OR (dem.N_CC14_MULTI_BIRTH IS NULL AND vd.N_CC14_MULTI_BIRTH IS NOT NULL) OR (dem.N_CC14_MULTI_BIRTH IS NOT NULL AND vd.N_CC14_MULTI_BIRTH IS NULL) THEN 1 ELSE 0 END
					,R_POST_MORTEM_Diff							= CASE WHEN dem.R_POST_MORTEM != vd.R_POST_MORTEM OR (dem.R_POST_MORTEM IS NULL AND vd.R_POST_MORTEM IS NOT NULL) OR (dem.R_POST_MORTEM IS NOT NULL AND vd.R_POST_MORTEM IS NULL) THEN 1 ELSE 0 END
					,R_DAY_PHONE_Diff							= CASE WHEN dem.R_DAY_PHONE != vd.R_DAY_PHONE OR (dem.R_DAY_PHONE IS NULL AND vd.R_DAY_PHONE IS NOT NULL) OR (dem.R_DAY_PHONE IS NOT NULL AND vd.R_DAY_PHONE IS NULL) THEN 1 ELSE 0 END
					,DAY_PHONE_EXT_Diff							= CASE WHEN dem.DAY_PHONE_EXT != vd.DAY_PHONE_EXT OR (dem.DAY_PHONE_EXT IS NULL AND vd.DAY_PHONE_EXT IS NOT NULL) OR (dem.DAY_PHONE_EXT IS NOT NULL AND vd.DAY_PHONE_EXT IS NULL) THEN 1 ELSE 0 END
					,R_EVE_PHONE_Diff							= CASE WHEN dem.R_EVE_PHONE != vd.R_EVE_PHONE OR (dem.R_EVE_PHONE IS NULL AND vd.R_EVE_PHONE IS NOT NULL) OR (dem.R_EVE_PHONE IS NOT NULL AND vd.R_EVE_PHONE IS NULL) THEN 1 ELSE 0 END
					,EVE_PHONE_EXT_Diff							= CASE WHEN dem.EVE_PHONE_EXT != vd.EVE_PHONE_EXT OR (dem.EVE_PHONE_EXT IS NULL AND vd.EVE_PHONE_EXT IS NOT NULL) OR (dem.EVE_PHONE_EXT IS NOT NULL AND vd.EVE_PHONE_EXT IS NULL) THEN 1 ELSE 0 END
					,R_DEATH_TREATMENT_Diff						= CASE WHEN dem.R_DEATH_TREATMENT != vd.R_DEATH_TREATMENT OR (dem.R_DEATH_TREATMENT IS NULL AND vd.R_DEATH_TREATMENT IS NOT NULL) OR (dem.R_DEATH_TREATMENT IS NOT NULL AND vd.R_DEATH_TREATMENT IS NULL) THEN 1 ELSE 0 END
					,R_PM_DETAILS_Diff							= CASE WHEN dem.R_PM_DETAILS != vd.R_PM_DETAILS OR (dem.R_PM_DETAILS IS NULL AND vd.R_PM_DETAILS IS NOT NULL) OR (dem.R_PM_DETAILS IS NOT NULL AND vd.R_PM_DETAILS IS NULL) THEN 1 ELSE 0 END
					,L_IATROGENIC_DEATH_Diff					= CASE WHEN dem.L_IATROGENIC_DEATH != vd.L_IATROGENIC_DEATH OR (dem.L_IATROGENIC_DEATH IS NULL AND vd.L_IATROGENIC_DEATH IS NOT NULL) OR (dem.L_IATROGENIC_DEATH IS NOT NULL AND vd.L_IATROGENIC_DEATH IS NULL) THEN 1 ELSE 0 END
					,L_INFECTION_DEATH_Diff						= CASE WHEN dem.L_INFECTION_DEATH != vd.L_INFECTION_DEATH OR (dem.L_INFECTION_DEATH IS NULL AND vd.L_INFECTION_DEATH IS NOT NULL) OR (dem.L_INFECTION_DEATH IS NOT NULL AND vd.L_INFECTION_DEATH IS NULL) THEN 1 ELSE 0 END
					,L_DEATH_COMMENTS_Diff						= CASE WHEN dem.L_DEATH_COMMENTS != vd.L_DEATH_COMMENTS OR (dem.L_DEATH_COMMENTS IS NULL AND vd.L_DEATH_COMMENTS IS NOT NULL) OR (dem.L_DEATH_COMMENTS IS NOT NULL AND vd.L_DEATH_COMMENTS IS NULL) THEN 1 ELSE 0 END
					,RELIGION_Diff								= CASE WHEN dem.RELIGION != vd.RELIGION OR (dem.RELIGION IS NULL AND vd.RELIGION IS NOT NULL) OR (dem.RELIGION IS NOT NULL AND vd.RELIGION IS NULL) THEN 1 ELSE 0 END
					,CONTACT_DETAILS_Diff						= CASE WHEN dem.CONTACT_DETAILS != vd.CONTACT_DETAILS OR (dem.CONTACT_DETAILS IS NULL AND vd.CONTACT_DETAILS IS NOT NULL) OR (dem.CONTACT_DETAILS IS NOT NULL AND vd.CONTACT_DETAILS IS NULL) THEN 1 ELSE 0 END
					,NOK_NAME_Diff								= CASE WHEN dem.NOK_NAME != vd.NOK_NAME OR (dem.NOK_NAME IS NULL AND vd.NOK_NAME IS NOT NULL) OR (dem.NOK_NAME IS NOT NULL AND vd.NOK_NAME IS NULL) THEN 1 ELSE 0 END
					,NOK_ADDRESS_1_Diff							= CASE WHEN dem.NOK_ADDRESS_1 != vd.NOK_ADDRESS_1 OR (dem.NOK_ADDRESS_1 IS NULL AND vd.NOK_ADDRESS_1 IS NOT NULL) OR (dem.NOK_ADDRESS_1 IS NOT NULL AND vd.NOK_ADDRESS_1 IS NULL) THEN 1 ELSE 0 END
					,NOK_ADDRESS_2_Diff							= CASE WHEN dem.NOK_ADDRESS_2 != vd.NOK_ADDRESS_2 OR (dem.NOK_ADDRESS_2 IS NULL AND vd.NOK_ADDRESS_2 IS NOT NULL) OR (dem.NOK_ADDRESS_2 IS NOT NULL AND vd.NOK_ADDRESS_2 IS NULL) THEN 1 ELSE 0 END
					,NOK_ADDRESS_3_Diff							= CASE WHEN dem.NOK_ADDRESS_3 != vd.NOK_ADDRESS_3 OR (dem.NOK_ADDRESS_3 IS NULL AND vd.NOK_ADDRESS_3 IS NOT NULL) OR (dem.NOK_ADDRESS_3 IS NOT NULL AND vd.NOK_ADDRESS_3 IS NULL) THEN 1 ELSE 0 END
					,NOK_ADDRESS_4_Diff							= CASE WHEN dem.NOK_ADDRESS_4 != vd.NOK_ADDRESS_4 OR (dem.NOK_ADDRESS_4 IS NULL AND vd.NOK_ADDRESS_4 IS NOT NULL) OR (dem.NOK_ADDRESS_4 IS NOT NULL AND vd.NOK_ADDRESS_4 IS NULL) THEN 1 ELSE 0 END
					,NOK_ADDRESS_5_Diff							= CASE WHEN dem.NOK_ADDRESS_5 != vd.NOK_ADDRESS_5 OR (dem.NOK_ADDRESS_5 IS NULL AND vd.NOK_ADDRESS_5 IS NOT NULL) OR (dem.NOK_ADDRESS_5 IS NOT NULL AND vd.NOK_ADDRESS_5 IS NULL) THEN 1 ELSE 0 END
					,NOK_POSTCODE_Diff							= CASE WHEN dem.NOK_POSTCODE != vd.NOK_POSTCODE OR (dem.NOK_POSTCODE IS NULL AND vd.NOK_POSTCODE IS NOT NULL) OR (dem.NOK_POSTCODE IS NOT NULL AND vd.NOK_POSTCODE IS NULL) THEN 1 ELSE 0 END
					,NOK_CONTACT_Diff							= CASE WHEN dem.NOK_CONTACT != vd.NOK_CONTACT OR (dem.NOK_CONTACT IS NULL AND vd.NOK_CONTACT IS NOT NULL) OR (dem.NOK_CONTACT IS NOT NULL AND vd.NOK_CONTACT IS NULL) THEN 1 ELSE 0 END
					,NOK_RELATIONSHIP_Diff						= CASE WHEN dem.NOK_RELATIONSHIP != vd.NOK_RELATIONSHIP OR (dem.NOK_RELATIONSHIP IS NULL AND vd.NOK_RELATIONSHIP IS NOT NULL) OR (dem.NOK_RELATIONSHIP IS NOT NULL AND vd.NOK_RELATIONSHIP IS NULL) THEN 1 ELSE 0 END
					,PAT_DEPENDANTS_Diff						= CASE WHEN dem.PAT_DEPENDANTS != vd.PAT_DEPENDANTS OR (dem.PAT_DEPENDANTS IS NULL AND vd.PAT_DEPENDANTS IS NOT NULL) OR (dem.PAT_DEPENDANTS IS NOT NULL AND vd.PAT_DEPENDANTS IS NULL) THEN 1 ELSE 0 END
					,CARER_NAME_Diff							= CASE WHEN dem.CARER_NAME != vd.CARER_NAME OR (dem.CARER_NAME IS NULL AND vd.CARER_NAME IS NOT NULL) OR (dem.CARER_NAME IS NOT NULL AND vd.CARER_NAME IS NULL) THEN 1 ELSE 0 END
					,CARER_ADDRESS_1_Diff						= CASE WHEN dem.CARER_ADDRESS_1 != vd.CARER_ADDRESS_1 OR (dem.CARER_ADDRESS_1 IS NULL AND vd.CARER_ADDRESS_1 IS NOT NULL) OR (dem.CARER_ADDRESS_1 IS NOT NULL AND vd.CARER_ADDRESS_1 IS NULL) THEN 1 ELSE 0 END
					,CARER_ADDRESS_2_Diff						= CASE WHEN dem.CARER_ADDRESS_2 != vd.CARER_ADDRESS_2 OR (dem.CARER_ADDRESS_2 IS NULL AND vd.CARER_ADDRESS_2 IS NOT NULL) OR (dem.CARER_ADDRESS_2 IS NOT NULL AND vd.CARER_ADDRESS_2 IS NULL) THEN 1 ELSE 0 END
					,CARER_ADDRESS_3_Diff						= CASE WHEN dem.CARER_ADDRESS_3 != vd.CARER_ADDRESS_3 OR (dem.CARER_ADDRESS_3 IS NULL AND vd.CARER_ADDRESS_3 IS NOT NULL) OR (dem.CARER_ADDRESS_3 IS NOT NULL AND vd.CARER_ADDRESS_3 IS NULL) THEN 1 ELSE 0 END
					,CARER_ADDRESS_4_Diff						= CASE WHEN dem.CARER_ADDRESS_4 != vd.CARER_ADDRESS_4 OR (dem.CARER_ADDRESS_4 IS NULL AND vd.CARER_ADDRESS_4 IS NOT NULL) OR (dem.CARER_ADDRESS_4 IS NOT NULL AND vd.CARER_ADDRESS_4 IS NULL) THEN 1 ELSE 0 END
					,CARER_ADDRESS_5_Diff						= CASE WHEN dem.CARER_ADDRESS_5 != vd.CARER_ADDRESS_5 OR (dem.CARER_ADDRESS_5 IS NULL AND vd.CARER_ADDRESS_5 IS NOT NULL) OR (dem.CARER_ADDRESS_5 IS NOT NULL AND vd.CARER_ADDRESS_5 IS NULL) THEN 1 ELSE 0 END
					,CARER_POSTCODE_Diff						= CASE WHEN dem.CARER_POSTCODE != vd.CARER_POSTCODE OR (dem.CARER_POSTCODE IS NULL AND vd.CARER_POSTCODE IS NOT NULL) OR (dem.CARER_POSTCODE IS NOT NULL AND vd.CARER_POSTCODE IS NULL) THEN 1 ELSE 0 END
					,CARER_CONTACT_Diff							= CASE WHEN dem.CARER_CONTACT != vd.CARER_CONTACT OR (dem.CARER_CONTACT IS NULL AND vd.CARER_CONTACT IS NOT NULL) OR (dem.CARER_CONTACT IS NOT NULL AND vd.CARER_CONTACT IS NULL) THEN 1 ELSE 0 END
					,CARER_RELATIONSHIP_Diff					= CASE WHEN dem.CARER_RELATIONSHIP != vd.CARER_RELATIONSHIP OR (dem.CARER_RELATIONSHIP IS NULL AND vd.CARER_RELATIONSHIP IS NOT NULL) OR (dem.CARER_RELATIONSHIP IS NOT NULL AND vd.CARER_RELATIONSHIP IS NULL) THEN 1 ELSE 0 END
					,CARER1_TYPE_Diff							= CASE WHEN dem.CARER1_TYPE != vd.CARER1_TYPE OR (dem.CARER1_TYPE IS NULL AND vd.CARER1_TYPE IS NOT NULL) OR (dem.CARER1_TYPE IS NOT NULL AND vd.CARER1_TYPE IS NULL) THEN 1 ELSE 0 END
					,CARER2_NAME_Diff							= CASE WHEN dem.CARER2_NAME != vd.CARER2_NAME OR (dem.CARER2_NAME IS NULL AND vd.CARER2_NAME IS NOT NULL) OR (dem.CARER2_NAME IS NOT NULL AND vd.CARER2_NAME IS NULL) THEN 1 ELSE 0 END
					,CARER2_ADDRESS_1_Diff						= CASE WHEN dem.CARER2_ADDRESS_1 != vd.CARER2_ADDRESS_1 OR (dem.CARER2_ADDRESS_1 IS NULL AND vd.CARER2_ADDRESS_1 IS NOT NULL) OR (dem.CARER2_ADDRESS_1 IS NOT NULL AND vd.CARER2_ADDRESS_1 IS NULL) THEN 1 ELSE 0 END
					,CARER2_ADDRESS_2_Diff						= CASE WHEN dem.CARER2_ADDRESS_2 != vd.CARER2_ADDRESS_2 OR (dem.CARER2_ADDRESS_2 IS NULL AND vd.CARER2_ADDRESS_2 IS NOT NULL) OR (dem.CARER2_ADDRESS_2 IS NOT NULL AND vd.CARER2_ADDRESS_2 IS NULL) THEN 1 ELSE 0 END
					,CARER2_ADDRESS_3_Diff						= CASE WHEN dem.CARER2_ADDRESS_3 != vd.CARER2_ADDRESS_3 OR (dem.CARER2_ADDRESS_3 IS NULL AND vd.CARER2_ADDRESS_3 IS NOT NULL) OR (dem.CARER2_ADDRESS_3 IS NOT NULL AND vd.CARER2_ADDRESS_3 IS NULL) THEN 1 ELSE 0 END
					,CARER2_ADDRESS_4_Diff						= CASE WHEN dem.CARER2_ADDRESS_4 != vd.CARER2_ADDRESS_4 OR (dem.CARER2_ADDRESS_4 IS NULL AND vd.CARER2_ADDRESS_4 IS NOT NULL) OR (dem.CARER2_ADDRESS_4 IS NOT NULL AND vd.CARER2_ADDRESS_4 IS NULL) THEN 1 ELSE 0 END
					,CARER2_ADDRESS_5_Diff						= CASE WHEN dem.CARER2_ADDRESS_5 != vd.CARER2_ADDRESS_5 OR (dem.CARER2_ADDRESS_5 IS NULL AND vd.CARER2_ADDRESS_5 IS NOT NULL) OR (dem.CARER2_ADDRESS_5 IS NOT NULL AND vd.CARER2_ADDRESS_5 IS NULL) THEN 1 ELSE 0 END
					,CARER2_POSTCODE_Diff						= CASE WHEN dem.CARER2_POSTCODE != vd.CARER2_POSTCODE OR (dem.CARER2_POSTCODE IS NULL AND vd.CARER2_POSTCODE IS NOT NULL) OR (dem.CARER2_POSTCODE IS NOT NULL AND vd.CARER2_POSTCODE IS NULL) THEN 1 ELSE 0 END
					,CARER2_CONTACT_Diff						= CASE WHEN dem.CARER2_CONTACT != vd.CARER2_CONTACT OR (dem.CARER2_CONTACT IS NULL AND vd.CARER2_CONTACT IS NOT NULL) OR (dem.CARER2_CONTACT IS NOT NULL AND vd.CARER2_CONTACT IS NULL) THEN 1 ELSE 0 END
					,CARER2_RELATIONSHIP_Diff					= CASE WHEN dem.CARER2_RELATIONSHIP != vd.CARER2_RELATIONSHIP OR (dem.CARER2_RELATIONSHIP IS NULL AND vd.CARER2_RELATIONSHIP IS NOT NULL) OR (dem.CARER2_RELATIONSHIP IS NOT NULL AND vd.CARER2_RELATIONSHIP IS NULL) THEN 1 ELSE 0 END
					,CARER2_TYPE_Diff							= CASE WHEN dem.CARER2_TYPE != vd.CARER2_TYPE OR (dem.CARER2_TYPE IS NULL AND vd.CARER2_TYPE IS NOT NULL) OR (dem.CARER2_TYPE IS NOT NULL AND vd.CARER2_TYPE IS NULL) THEN 1 ELSE 0 END
					,PT_AT_RISK_Diff							= CASE WHEN dem.PT_AT_RISK != vd.PT_AT_RISK OR (dem.PT_AT_RISK IS NULL AND vd.PT_AT_RISK IS NOT NULL) OR (dem.PT_AT_RISK IS NOT NULL AND vd.PT_AT_RISK IS NULL) THEN 1 ELSE 0 END
					,REASON_RISK_Diff							= CASE WHEN dem.REASON_RISK != vd.REASON_RISK OR (dem.REASON_RISK IS NULL AND vd.REASON_RISK IS NOT NULL) OR (dem.REASON_RISK IS NOT NULL AND vd.REASON_RISK IS NULL) THEN 1 ELSE 0 END
					,GESTATION_Diff								= CASE WHEN dem.GESTATION != vd.GESTATION OR (dem.GESTATION IS NULL AND vd.GESTATION IS NOT NULL) OR (dem.GESTATION IS NOT NULL AND vd.GESTATION IS NULL) THEN 1 ELSE 0 END
					,CAUSE_OF_DEATH_UROLOGY_Diff				= CASE WHEN dem.CAUSE_OF_DEATH_UROLOGY != vd.CAUSE_OF_DEATH_UROLOGY OR (dem.CAUSE_OF_DEATH_UROLOGY IS NULL AND vd.CAUSE_OF_DEATH_UROLOGY IS NOT NULL) OR (dem.CAUSE_OF_DEATH_UROLOGY IS NOT NULL AND vd.CAUSE_OF_DEATH_UROLOGY IS NULL) THEN 1 ELSE 0 END
					,AVOIDABLE_DEATH_Diff						= CASE WHEN dem.AVOIDABLE_DEATH != vd.AVOIDABLE_DEATH OR (dem.AVOIDABLE_DEATH IS NULL AND vd.AVOIDABLE_DEATH IS NOT NULL) OR (dem.AVOIDABLE_DEATH IS NOT NULL AND vd.AVOIDABLE_DEATH IS NULL) THEN 1 ELSE 0 END
					,AVOIDABLE_DETAILS_Diff						= CASE WHEN dem.AVOIDABLE_DETAILS != vd.AVOIDABLE_DETAILS OR (dem.AVOIDABLE_DETAILS IS NULL AND vd.AVOIDABLE_DETAILS IS NOT NULL) OR (dem.AVOIDABLE_DETAILS IS NOT NULL AND vd.AVOIDABLE_DETAILS IS NULL) THEN 1 ELSE 0 END
					,OTHER_DEATH_CAUSE_UROLOGY_Diff				= CASE WHEN dem.OTHER_DEATH_CAUSE_UROLOGY != vd.OTHER_DEATH_CAUSE_UROLOGY OR (dem.OTHER_DEATH_CAUSE_UROLOGY IS NULL AND vd.OTHER_DEATH_CAUSE_UROLOGY IS NOT NULL) OR (dem.OTHER_DEATH_CAUSE_UROLOGY IS NOT NULL AND vd.OTHER_DEATH_CAUSE_UROLOGY IS NULL) THEN 1 ELSE 0 END
					,ACTION_ID_Diff								= CASE WHEN dem.ACTION_ID != vd.ACTION_ID OR (dem.ACTION_ID IS NULL AND vd.ACTION_ID IS NOT NULL) OR (dem.ACTION_ID IS NOT NULL AND vd.ACTION_ID IS NULL) THEN 1 ELSE 0 END
					,STATED_GENDER_CODE_Diff					= CASE WHEN dem.STATED_GENDER_CODE != vd.STATED_GENDER_CODE OR (dem.STATED_GENDER_CODE IS NULL AND vd.STATED_GENDER_CODE IS NOT NULL) OR (dem.STATED_GENDER_CODE IS NOT NULL AND vd.STATED_GENDER_CODE IS NULL) THEN 1 ELSE 0 END
					,CAUSE_OF_DEATH_UROLOGY_FUP_Diff			= CASE WHEN dem.CAUSE_OF_DEATH_UROLOGY_FUP != vd.CAUSE_OF_DEATH_UROLOGY_FUP OR (dem.CAUSE_OF_DEATH_UROLOGY_FUP IS NULL AND vd.CAUSE_OF_DEATH_UROLOGY_FUP IS NOT NULL) OR (dem.CAUSE_OF_DEATH_UROLOGY_FUP IS NOT NULL AND vd.CAUSE_OF_DEATH_UROLOGY_FUP IS NULL) THEN 1 ELSE 0 END
					,DEATH_WITHIN_30_DAYS_OF_TREAT_Diff			= CASE WHEN dem.DEATH_WITHIN_30_DAYS_OF_TREAT != vd.DEATH_WITHIN_30_DAYS_OF_TREAT OR (dem.DEATH_WITHIN_30_DAYS_OF_TREAT IS NULL AND vd.DEATH_WITHIN_30_DAYS_OF_TREAT IS NOT NULL) OR (dem.DEATH_WITHIN_30_DAYS_OF_TREAT IS NOT NULL AND vd.DEATH_WITHIN_30_DAYS_OF_TREAT IS NULL) THEN 1 ELSE 0 END
					,DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT_Diff	= CASE WHEN dem.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT != vd.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT OR (dem.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT IS NULL AND vd.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT IS NOT NULL) OR (dem.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT IS NOT NULL AND vd.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT IS NULL) THEN 1 ELSE 0 END
					,DEATH_CAUSE_LATER_DATE_Diff				= CASE WHEN dem.DEATH_CAUSE_LATER_DATE != vd.DEATH_CAUSE_LATER_DATE OR (dem.DEATH_CAUSE_LATER_DATE IS NULL AND vd.DEATH_CAUSE_LATER_DATE IS NOT NULL) OR (dem.DEATH_CAUSE_LATER_DATE IS NOT NULL AND vd.DEATH_CAUSE_LATER_DATE IS NULL) THEN 1 ELSE 0 END
					,RegisteredPractice_Diff					= CASE WHEN dem.RegisteredPractice != vd.RegisteredPractice OR (dem.RegisteredPractice IS NULL AND vd.RegisteredPractice IS NOT NULL) OR (dem.RegisteredPractice IS NOT NULL AND vd.RegisteredPractice IS NULL) THEN 1 ELSE 0 END
					,RegisteredGP_Diff							= CASE WHEN dem.RegisteredGP != vd.RegisteredGP OR (dem.RegisteredGP IS NULL AND vd.RegisteredGP IS NOT NULL) OR (dem.RegisteredGP IS NOT NULL AND vd.RegisteredGP IS NULL) THEN 1 ELSE 0 END
					,PersonSexualOrientation_Diff				= CASE WHEN dem.PersonSexualOrientation != vd.PersonSexualOrientation OR (dem.PersonSexualOrientation IS NULL AND vd.PersonSexualOrientation IS NOT NULL) OR (dem.PersonSexualOrientation IS NOT NULL AND vd.PersonSexualOrientation IS NULL) THEN 1 ELSE 0 END
		INTO		Merge_R_Compare.DedupeChangedDemographics_work
		FROM		LocalConfig.tblDEMOGRAPHICS dem
		INNER JOIN	#tblDEMOGRAPHICS_tblValidatedData vd
														ON	dem.SrcSysID = vd.SrcSys
														AND	dem.PATIENT_ID = vd.PATIENT_ID
		WHERE		dem.N1_1_NHS_NUMBER != vd.N1_1_NHS_NUMBER OR (dem.N1_1_NHS_NUMBER IS NULL AND vd.N1_1_NHS_NUMBER IS NOT NULL) OR (dem.N1_1_NHS_NUMBER IS NOT NULL AND vd.N1_1_NHS_NUMBER IS NULL)
		OR			dem.NHS_NUMBER_STATUS != vd.NHS_NUMBER_STATUS OR (dem.NHS_NUMBER_STATUS IS NULL AND vd.NHS_NUMBER_STATUS IS NOT NULL) OR (dem.NHS_NUMBER_STATUS IS NOT NULL AND vd.NHS_NUMBER_STATUS IS NULL)
		OR			dem.L_RA3_RID != vd.L_RA3_RID OR (dem.L_RA3_RID IS NULL AND vd.L_RA3_RID IS NOT NULL) OR (dem.L_RA3_RID IS NOT NULL AND vd.L_RA3_RID IS NULL)
		OR			dem.L_RA7_RID != vd.L_RA7_RID OR (dem.L_RA7_RID IS NULL AND vd.L_RA7_RID IS NOT NULL) OR (dem.L_RA7_RID IS NOT NULL AND vd.L_RA7_RID IS NULL)
		OR			dem.L_RVJ01_RID != vd.L_RVJ01_RID OR (dem.L_RVJ01_RID IS NULL AND vd.L_RVJ01_RID IS NOT NULL) OR (dem.L_RVJ01_RID IS NOT NULL AND vd.L_RVJ01_RID IS NULL)
		OR			dem.TEMP_ID != vd.TEMP_ID OR (dem.TEMP_ID IS NULL AND vd.TEMP_ID IS NOT NULL) OR (dem.TEMP_ID IS NOT NULL AND vd.TEMP_ID IS NULL)
		OR			dem.L_NSTS_STATUS != vd.L_NSTS_STATUS OR (dem.L_NSTS_STATUS IS NULL AND vd.L_NSTS_STATUS IS NOT NULL) OR (dem.L_NSTS_STATUS IS NOT NULL AND vd.L_NSTS_STATUS IS NULL)
		OR			dem.N1_2_HOSPITAL_NUMBER != vd.N1_2_HOSPITAL_NUMBER OR (dem.N1_2_HOSPITAL_NUMBER IS NULL AND vd.N1_2_HOSPITAL_NUMBER IS NOT NULL) OR (dem.N1_2_HOSPITAL_NUMBER IS NOT NULL AND vd.N1_2_HOSPITAL_NUMBER IS NULL)
		OR			dem.L_TITLE != vd.L_TITLE OR (dem.L_TITLE IS NULL AND vd.L_TITLE IS NOT NULL) OR (dem.L_TITLE IS NOT NULL AND vd.L_TITLE IS NULL)
		OR			dem.N1_5_SURNAME != vd.N1_5_SURNAME OR (dem.N1_5_SURNAME IS NULL AND vd.N1_5_SURNAME IS NOT NULL) OR (dem.N1_5_SURNAME IS NOT NULL AND vd.N1_5_SURNAME IS NULL)
		OR			dem.N1_6_FORENAME != vd.N1_6_FORENAME OR (dem.N1_6_FORENAME IS NULL AND vd.N1_6_FORENAME IS NOT NULL) OR (dem.N1_6_FORENAME IS NOT NULL AND vd.N1_6_FORENAME IS NULL)
		OR			dem.N1_7_ADDRESS_1 != vd.N1_7_ADDRESS_1 OR (dem.N1_7_ADDRESS_1 IS NULL AND vd.N1_7_ADDRESS_1 IS NOT NULL) OR (dem.N1_7_ADDRESS_1 IS NOT NULL AND vd.N1_7_ADDRESS_1 IS NULL)
		OR			dem.N1_7_ADDRESS_2 != vd.N1_7_ADDRESS_2 OR (dem.N1_7_ADDRESS_2 IS NULL AND vd.N1_7_ADDRESS_2 IS NOT NULL) OR (dem.N1_7_ADDRESS_2 IS NOT NULL AND vd.N1_7_ADDRESS_2 IS NULL)
		OR			dem.N1_7_ADDRESS_3 != vd.N1_7_ADDRESS_3 OR (dem.N1_7_ADDRESS_3 IS NULL AND vd.N1_7_ADDRESS_3 IS NOT NULL) OR (dem.N1_7_ADDRESS_3 IS NOT NULL AND vd.N1_7_ADDRESS_3 IS NULL)
		OR			dem.N1_7_ADDRESS_4 != vd.N1_7_ADDRESS_4 OR (dem.N1_7_ADDRESS_4 IS NULL AND vd.N1_7_ADDRESS_4 IS NOT NULL) OR (dem.N1_7_ADDRESS_4 IS NOT NULL AND vd.N1_7_ADDRESS_4 IS NULL)
		OR			dem.N1_7_ADDRESS_5 != vd.N1_7_ADDRESS_5 OR (dem.N1_7_ADDRESS_5 IS NULL AND vd.N1_7_ADDRESS_5 IS NOT NULL) OR (dem.N1_7_ADDRESS_5 IS NOT NULL AND vd.N1_7_ADDRESS_5 IS NULL)
		OR			dem.N1_8_POSTCODE != vd.N1_8_POSTCODE OR (dem.N1_8_POSTCODE IS NULL AND vd.N1_8_POSTCODE IS NOT NULL) OR (dem.N1_8_POSTCODE IS NOT NULL AND vd.N1_8_POSTCODE IS NULL)
		OR			dem.N1_9_SEX != vd.N1_9_SEX OR (dem.N1_9_SEX IS NULL AND vd.N1_9_SEX IS NOT NULL) OR (dem.N1_9_SEX IS NOT NULL AND vd.N1_9_SEX IS NULL)
		OR			dem.N1_10_DATE_BIRTH != vd.N1_10_DATE_BIRTH OR (dem.N1_10_DATE_BIRTH IS NULL AND vd.N1_10_DATE_BIRTH IS NOT NULL) OR (dem.N1_10_DATE_BIRTH IS NOT NULL AND vd.N1_10_DATE_BIRTH IS NULL)
		OR			dem.N1_11_GP_CODE != vd.N1_11_GP_CODE OR (dem.N1_11_GP_CODE IS NULL AND vd.N1_11_GP_CODE IS NOT NULL) OR (dem.N1_11_GP_CODE IS NOT NULL AND vd.N1_11_GP_CODE IS NULL)
		OR			dem.N1_12_GP_PRACTICE_CODE != vd.N1_12_GP_PRACTICE_CODE OR (dem.N1_12_GP_PRACTICE_CODE IS NULL AND vd.N1_12_GP_PRACTICE_CODE IS NOT NULL) OR (dem.N1_12_GP_PRACTICE_CODE IS NOT NULL AND vd.N1_12_GP_PRACTICE_CODE IS NULL)
		OR			dem.N1_13_PCT != vd.N1_13_PCT OR (dem.N1_13_PCT IS NULL AND vd.N1_13_PCT IS NOT NULL) OR (dem.N1_13_PCT IS NOT NULL AND vd.N1_13_PCT IS NULL)
		OR			dem.N1_14_SURNAME_BIRTH != vd.N1_14_SURNAME_BIRTH OR (dem.N1_14_SURNAME_BIRTH IS NULL AND vd.N1_14_SURNAME_BIRTH IS NOT NULL) OR (dem.N1_14_SURNAME_BIRTH IS NOT NULL AND vd.N1_14_SURNAME_BIRTH IS NULL)
		OR			dem.N1_15_ETHNICITY != vd.N1_15_ETHNICITY OR (dem.N1_15_ETHNICITY IS NULL AND vd.N1_15_ETHNICITY IS NOT NULL) OR (dem.N1_15_ETHNICITY IS NOT NULL AND vd.N1_15_ETHNICITY IS NULL)
		OR			dem.PAT_PREF_NAME != vd.PAT_PREF_NAME OR (dem.PAT_PREF_NAME IS NULL AND vd.PAT_PREF_NAME IS NOT NULL) OR (dem.PAT_PREF_NAME IS NOT NULL AND vd.PAT_PREF_NAME IS NULL)
		OR			dem.PAT_OCCUPATION != vd.PAT_OCCUPATION OR (dem.PAT_OCCUPATION IS NULL AND vd.PAT_OCCUPATION IS NOT NULL) OR (dem.PAT_OCCUPATION IS NOT NULL AND vd.PAT_OCCUPATION IS NULL)
		OR			dem.PAT_SOCIAL_CLASS != vd.PAT_SOCIAL_CLASS OR (dem.PAT_SOCIAL_CLASS IS NULL AND vd.PAT_SOCIAL_CLASS IS NOT NULL) OR (dem.PAT_SOCIAL_CLASS IS NOT NULL AND vd.PAT_SOCIAL_CLASS IS NULL)
		OR			dem.PAT_LIVES_ALONE != vd.PAT_LIVES_ALONE OR (dem.PAT_LIVES_ALONE IS NULL AND vd.PAT_LIVES_ALONE IS NOT NULL) OR (dem.PAT_LIVES_ALONE IS NOT NULL AND vd.PAT_LIVES_ALONE IS NULL)
		OR			dem.MARITAL_STATUS != vd.MARITAL_STATUS OR (dem.MARITAL_STATUS IS NULL AND vd.MARITAL_STATUS IS NOT NULL) OR (dem.MARITAL_STATUS IS NOT NULL AND vd.MARITAL_STATUS IS NULL)
		OR			dem.PAT_PREF_LANGUAGE != vd.PAT_PREF_LANGUAGE OR (dem.PAT_PREF_LANGUAGE IS NULL AND vd.PAT_PREF_LANGUAGE IS NOT NULL) OR (dem.PAT_PREF_LANGUAGE IS NOT NULL AND vd.PAT_PREF_LANGUAGE IS NULL)
		OR			dem.PAT_PREF_CONTACT != vd.PAT_PREF_CONTACT OR (dem.PAT_PREF_CONTACT IS NULL AND vd.PAT_PREF_CONTACT IS NOT NULL) OR (dem.PAT_PREF_CONTACT IS NOT NULL AND vd.PAT_PREF_CONTACT IS NULL)
		OR			dem.L_DEATH_STATUS != vd.L_DEATH_STATUS OR (dem.L_DEATH_STATUS IS NULL AND vd.L_DEATH_STATUS IS NOT NULL) OR (dem.L_DEATH_STATUS IS NOT NULL AND vd.L_DEATH_STATUS IS NULL)
		OR			dem.N15_1_DATE_DEATH != vd.N15_1_DATE_DEATH OR (dem.N15_1_DATE_DEATH IS NULL AND vd.N15_1_DATE_DEATH IS NOT NULL) OR (dem.N15_1_DATE_DEATH IS NOT NULL AND vd.N15_1_DATE_DEATH IS NULL)
		OR			dem.N15_2_DEATH_LOCATION != vd.N15_2_DEATH_LOCATION OR (dem.N15_2_DEATH_LOCATION IS NULL AND vd.N15_2_DEATH_LOCATION IS NOT NULL) OR (dem.N15_2_DEATH_LOCATION IS NOT NULL AND vd.N15_2_DEATH_LOCATION IS NULL)
		OR			dem.N15_3_DEATH_CAUSE != vd.N15_3_DEATH_CAUSE OR (dem.N15_3_DEATH_CAUSE IS NULL AND vd.N15_3_DEATH_CAUSE IS NOT NULL) OR (dem.N15_3_DEATH_CAUSE IS NOT NULL AND vd.N15_3_DEATH_CAUSE IS NULL)
		OR			dem.N15_4_DEATH_CANCER != vd.N15_4_DEATH_CANCER OR (dem.N15_4_DEATH_CANCER IS NULL AND vd.N15_4_DEATH_CANCER IS NOT NULL) OR (dem.N15_4_DEATH_CANCER IS NOT NULL AND vd.N15_4_DEATH_CANCER IS NULL)
		OR			dem.N15_5_DEATH_CODE_1 != vd.N15_5_DEATH_CODE_1 OR (dem.N15_5_DEATH_CODE_1 IS NULL AND vd.N15_5_DEATH_CODE_1 IS NOT NULL) OR (dem.N15_5_DEATH_CODE_1 IS NOT NULL AND vd.N15_5_DEATH_CODE_1 IS NULL)
		OR			dem.N15_6_DEATH_CODE_2 != vd.N15_6_DEATH_CODE_2 OR (dem.N15_6_DEATH_CODE_2 IS NULL AND vd.N15_6_DEATH_CODE_2 IS NOT NULL) OR (dem.N15_6_DEATH_CODE_2 IS NOT NULL AND vd.N15_6_DEATH_CODE_2 IS NULL)
		OR			dem.N15_7_DEATH_CODE_3 != vd.N15_7_DEATH_CODE_3 OR (dem.N15_7_DEATH_CODE_3 IS NULL AND vd.N15_7_DEATH_CODE_3 IS NOT NULL) OR (dem.N15_7_DEATH_CODE_3 IS NOT NULL AND vd.N15_7_DEATH_CODE_3 IS NULL)
		OR			dem.N15_8_DEATH_CODE_4 != vd.N15_8_DEATH_CODE_4 OR (dem.N15_8_DEATH_CODE_4 IS NULL AND vd.N15_8_DEATH_CODE_4 IS NOT NULL) OR (dem.N15_8_DEATH_CODE_4 IS NOT NULL AND vd.N15_8_DEATH_CODE_4 IS NULL)
		OR			dem.N15_9_DEATH_DISCREPANCY != vd.N15_9_DEATH_DISCREPANCY OR (dem.N15_9_DEATH_DISCREPANCY IS NULL AND vd.N15_9_DEATH_DISCREPANCY IS NOT NULL) OR (dem.N15_9_DEATH_DISCREPANCY IS NOT NULL AND vd.N15_9_DEATH_DISCREPANCY IS NULL)
		OR			dem.N_CC4_TOWN != vd.N_CC4_TOWN OR (dem.N_CC4_TOWN IS NULL AND vd.N_CC4_TOWN IS NOT NULL) OR (dem.N_CC4_TOWN IS NOT NULL AND vd.N_CC4_TOWN IS NULL)
		OR			dem.N_CC5_COUNTRY != vd.N_CC5_COUNTRY OR (dem.N_CC5_COUNTRY IS NULL AND vd.N_CC5_COUNTRY IS NOT NULL) OR (dem.N_CC5_COUNTRY IS NOT NULL AND vd.N_CC5_COUNTRY IS NULL)
		OR			dem.N_CC6_M_SURNAME != vd.N_CC6_M_SURNAME OR (dem.N_CC6_M_SURNAME IS NULL AND vd.N_CC6_M_SURNAME IS NOT NULL) OR (dem.N_CC6_M_SURNAME IS NOT NULL AND vd.N_CC6_M_SURNAME IS NULL)
		OR			dem.N_CC7_M_CLASS != vd.N_CC7_M_CLASS OR (dem.N_CC7_M_CLASS IS NULL AND vd.N_CC7_M_CLASS IS NOT NULL) OR (dem.N_CC7_M_CLASS IS NOT NULL AND vd.N_CC7_M_CLASS IS NULL)
		OR			dem.N_CC8_M_FORENAME != vd.N_CC8_M_FORENAME OR (dem.N_CC8_M_FORENAME IS NULL AND vd.N_CC8_M_FORENAME IS NOT NULL) OR (dem.N_CC8_M_FORENAME IS NOT NULL AND vd.N_CC8_M_FORENAME IS NULL)
		OR			dem.N_CC9_M_DOB != vd.N_CC9_M_DOB OR (dem.N_CC9_M_DOB IS NULL AND vd.N_CC9_M_DOB IS NOT NULL) OR (dem.N_CC9_M_DOB IS NOT NULL AND vd.N_CC9_M_DOB IS NULL)
		OR			dem.N_CC10_M_TOWN != vd.N_CC10_M_TOWN OR (dem.N_CC10_M_TOWN IS NULL AND vd.N_CC10_M_TOWN IS NOT NULL) OR (dem.N_CC10_M_TOWN IS NOT NULL AND vd.N_CC10_M_TOWN IS NULL)
		OR			dem.N_CC11_M_COUNTRY != vd.N_CC11_M_COUNTRY OR (dem.N_CC11_M_COUNTRY IS NULL AND vd.N_CC11_M_COUNTRY IS NOT NULL) OR (dem.N_CC11_M_COUNTRY IS NOT NULL AND vd.N_CC11_M_COUNTRY IS NULL)
		OR			dem.N_CC12_M_OCC != vd.N_CC12_M_OCC OR (dem.N_CC12_M_OCC IS NULL AND vd.N_CC12_M_OCC IS NOT NULL) OR (dem.N_CC12_M_OCC IS NOT NULL AND vd.N_CC12_M_OCC IS NULL)
		OR			dem.N_CC13_M_OCC_DIAG != vd.N_CC13_M_OCC_DIAG OR (dem.N_CC13_M_OCC_DIAG IS NULL AND vd.N_CC13_M_OCC_DIAG IS NOT NULL) OR (dem.N_CC13_M_OCC_DIAG IS NOT NULL AND vd.N_CC13_M_OCC_DIAG IS NULL)
		OR			dem.N_CC6_F_SURNAME != vd.N_CC6_F_SURNAME OR (dem.N_CC6_F_SURNAME IS NULL AND vd.N_CC6_F_SURNAME IS NOT NULL) OR (dem.N_CC6_F_SURNAME IS NOT NULL AND vd.N_CC6_F_SURNAME IS NULL)
		OR			dem.N_CC7_F_CLASS != vd.N_CC7_F_CLASS OR (dem.N_CC7_F_CLASS IS NULL AND vd.N_CC7_F_CLASS IS NOT NULL) OR (dem.N_CC7_F_CLASS IS NOT NULL AND vd.N_CC7_F_CLASS IS NULL)
		OR			dem.N_CC8_F_FORENAME != vd.N_CC8_F_FORENAME OR (dem.N_CC8_F_FORENAME IS NULL AND vd.N_CC8_F_FORENAME IS NOT NULL) OR (dem.N_CC8_F_FORENAME IS NOT NULL AND vd.N_CC8_F_FORENAME IS NULL)
		OR			dem.N_CC9_F_DOB != vd.N_CC9_F_DOB OR (dem.N_CC9_F_DOB IS NULL AND vd.N_CC9_F_DOB IS NOT NULL) OR (dem.N_CC9_F_DOB IS NOT NULL AND vd.N_CC9_F_DOB IS NULL)
		OR			dem.N_CC10_F_TOWN != vd.N_CC10_F_TOWN OR (dem.N_CC10_F_TOWN IS NULL AND vd.N_CC10_F_TOWN IS NOT NULL) OR (dem.N_CC10_F_TOWN IS NOT NULL AND vd.N_CC10_F_TOWN IS NULL)
		OR			dem.N_CC11_F_COUNTRY != vd.N_CC11_F_COUNTRY OR (dem.N_CC11_F_COUNTRY IS NULL AND vd.N_CC11_F_COUNTRY IS NOT NULL) OR (dem.N_CC11_F_COUNTRY IS NOT NULL AND vd.N_CC11_F_COUNTRY IS NULL)
		OR			dem.N_CC12_F_OCC != vd.N_CC12_F_OCC OR (dem.N_CC12_F_OCC IS NULL AND vd.N_CC12_F_OCC IS NOT NULL) OR (dem.N_CC12_F_OCC IS NOT NULL AND vd.N_CC12_F_OCC IS NULL)
		OR			dem.N_CC13_F_OCC_DIAG != vd.N_CC13_F_OCC_DIAG OR (dem.N_CC13_F_OCC_DIAG IS NULL AND vd.N_CC13_F_OCC_DIAG IS NOT NULL) OR (dem.N_CC13_F_OCC_DIAG IS NOT NULL AND vd.N_CC13_F_OCC_DIAG IS NULL)
		OR			dem.N_CC14_MULTI_BIRTH != vd.N_CC14_MULTI_BIRTH OR (dem.N_CC14_MULTI_BIRTH IS NULL AND vd.N_CC14_MULTI_BIRTH IS NOT NULL) OR (dem.N_CC14_MULTI_BIRTH IS NOT NULL AND vd.N_CC14_MULTI_BIRTH IS NULL)
		OR			dem.R_POST_MORTEM != vd.R_POST_MORTEM OR (dem.R_POST_MORTEM IS NULL AND vd.R_POST_MORTEM IS NOT NULL) OR (dem.R_POST_MORTEM IS NOT NULL AND vd.R_POST_MORTEM IS NULL)
		OR			dem.R_DAY_PHONE != vd.R_DAY_PHONE OR (dem.R_DAY_PHONE IS NULL AND vd.R_DAY_PHONE IS NOT NULL) OR (dem.R_DAY_PHONE IS NOT NULL AND vd.R_DAY_PHONE IS NULL)
		OR			dem.DAY_PHONE_EXT != vd.DAY_PHONE_EXT OR (dem.DAY_PHONE_EXT IS NULL AND vd.DAY_PHONE_EXT IS NOT NULL) OR (dem.DAY_PHONE_EXT IS NOT NULL AND vd.DAY_PHONE_EXT IS NULL)
		OR			dem.R_EVE_PHONE != vd.R_EVE_PHONE OR (dem.R_EVE_PHONE IS NULL AND vd.R_EVE_PHONE IS NOT NULL) OR (dem.R_EVE_PHONE IS NOT NULL AND vd.R_EVE_PHONE IS NULL)
		OR			dem.EVE_PHONE_EXT != vd.EVE_PHONE_EXT OR (dem.EVE_PHONE_EXT IS NULL AND vd.EVE_PHONE_EXT IS NOT NULL) OR (dem.EVE_PHONE_EXT IS NOT NULL AND vd.EVE_PHONE_EXT IS NULL)
		OR			dem.R_DEATH_TREATMENT != vd.R_DEATH_TREATMENT OR (dem.R_DEATH_TREATMENT IS NULL AND vd.R_DEATH_TREATMENT IS NOT NULL) OR (dem.R_DEATH_TREATMENT IS NOT NULL AND vd.R_DEATH_TREATMENT IS NULL)
		OR			dem.R_PM_DETAILS != vd.R_PM_DETAILS OR (dem.R_PM_DETAILS IS NULL AND vd.R_PM_DETAILS IS NOT NULL) OR (dem.R_PM_DETAILS IS NOT NULL AND vd.R_PM_DETAILS IS NULL)
		OR			dem.L_IATROGENIC_DEATH != vd.L_IATROGENIC_DEATH OR (dem.L_IATROGENIC_DEATH IS NULL AND vd.L_IATROGENIC_DEATH IS NOT NULL) OR (dem.L_IATROGENIC_DEATH IS NOT NULL AND vd.L_IATROGENIC_DEATH IS NULL)
		OR			dem.L_INFECTION_DEATH != vd.L_INFECTION_DEATH OR (dem.L_INFECTION_DEATH IS NULL AND vd.L_INFECTION_DEATH IS NOT NULL) OR (dem.L_INFECTION_DEATH IS NOT NULL AND vd.L_INFECTION_DEATH IS NULL)
		OR			dem.L_DEATH_COMMENTS != vd.L_DEATH_COMMENTS OR (dem.L_DEATH_COMMENTS IS NULL AND vd.L_DEATH_COMMENTS IS NOT NULL) OR (dem.L_DEATH_COMMENTS IS NOT NULL AND vd.L_DEATH_COMMENTS IS NULL)
		OR			dem.RELIGION != vd.RELIGION OR (dem.RELIGION IS NULL AND vd.RELIGION IS NOT NULL) OR (dem.RELIGION IS NOT NULL AND vd.RELIGION IS NULL)
		OR			dem.CONTACT_DETAILS != vd.CONTACT_DETAILS OR (dem.CONTACT_DETAILS IS NULL AND vd.CONTACT_DETAILS IS NOT NULL) OR (dem.CONTACT_DETAILS IS NOT NULL AND vd.CONTACT_DETAILS IS NULL)
		OR			dem.NOK_NAME != vd.NOK_NAME OR (dem.NOK_NAME IS NULL AND vd.NOK_NAME IS NOT NULL) OR (dem.NOK_NAME IS NOT NULL AND vd.NOK_NAME IS NULL)
		OR			dem.NOK_ADDRESS_1 != vd.NOK_ADDRESS_1 OR (dem.NOK_ADDRESS_1 IS NULL AND vd.NOK_ADDRESS_1 IS NOT NULL) OR (dem.NOK_ADDRESS_1 IS NOT NULL AND vd.NOK_ADDRESS_1 IS NULL)
		OR			dem.NOK_ADDRESS_2 != vd.NOK_ADDRESS_2 OR (dem.NOK_ADDRESS_2 IS NULL AND vd.NOK_ADDRESS_2 IS NOT NULL) OR (dem.NOK_ADDRESS_2 IS NOT NULL AND vd.NOK_ADDRESS_2 IS NULL)
		OR			dem.NOK_ADDRESS_3 != vd.NOK_ADDRESS_3 OR (dem.NOK_ADDRESS_3 IS NULL AND vd.NOK_ADDRESS_3 IS NOT NULL) OR (dem.NOK_ADDRESS_3 IS NOT NULL AND vd.NOK_ADDRESS_3 IS NULL)
		OR			dem.NOK_ADDRESS_4 != vd.NOK_ADDRESS_4 OR (dem.NOK_ADDRESS_4 IS NULL AND vd.NOK_ADDRESS_4 IS NOT NULL) OR (dem.NOK_ADDRESS_4 IS NOT NULL AND vd.NOK_ADDRESS_4 IS NULL)
		OR			dem.NOK_ADDRESS_5 != vd.NOK_ADDRESS_5 OR (dem.NOK_ADDRESS_5 IS NULL AND vd.NOK_ADDRESS_5 IS NOT NULL) OR (dem.NOK_ADDRESS_5 IS NOT NULL AND vd.NOK_ADDRESS_5 IS NULL)
		OR			dem.NOK_POSTCODE != vd.NOK_POSTCODE OR (dem.NOK_POSTCODE IS NULL AND vd.NOK_POSTCODE IS NOT NULL) OR (dem.NOK_POSTCODE IS NOT NULL AND vd.NOK_POSTCODE IS NULL)
		OR			dem.NOK_CONTACT != vd.NOK_CONTACT OR (dem.NOK_CONTACT IS NULL AND vd.NOK_CONTACT IS NOT NULL) OR (dem.NOK_CONTACT IS NOT NULL AND vd.NOK_CONTACT IS NULL)
		OR			dem.NOK_RELATIONSHIP != vd.NOK_RELATIONSHIP OR (dem.NOK_RELATIONSHIP IS NULL AND vd.NOK_RELATIONSHIP IS NOT NULL) OR (dem.NOK_RELATIONSHIP IS NOT NULL AND vd.NOK_RELATIONSHIP IS NULL)
		OR			dem.PAT_DEPENDANTS != vd.PAT_DEPENDANTS OR (dem.PAT_DEPENDANTS IS NULL AND vd.PAT_DEPENDANTS IS NOT NULL) OR (dem.PAT_DEPENDANTS IS NOT NULL AND vd.PAT_DEPENDANTS IS NULL)
		OR			dem.CARER_NAME != vd.CARER_NAME OR (dem.CARER_NAME IS NULL AND vd.CARER_NAME IS NOT NULL) OR (dem.CARER_NAME IS NOT NULL AND vd.CARER_NAME IS NULL)
		OR			dem.CARER_ADDRESS_1 != vd.CARER_ADDRESS_1 OR (dem.CARER_ADDRESS_1 IS NULL AND vd.CARER_ADDRESS_1 IS NOT NULL) OR (dem.CARER_ADDRESS_1 IS NOT NULL AND vd.CARER_ADDRESS_1 IS NULL)
		OR			dem.CARER_ADDRESS_2 != vd.CARER_ADDRESS_2 OR (dem.CARER_ADDRESS_2 IS NULL AND vd.CARER_ADDRESS_2 IS NOT NULL) OR (dem.CARER_ADDRESS_2 IS NOT NULL AND vd.CARER_ADDRESS_2 IS NULL)
		OR			dem.CARER_ADDRESS_3 != vd.CARER_ADDRESS_3 OR (dem.CARER_ADDRESS_3 IS NULL AND vd.CARER_ADDRESS_3 IS NOT NULL) OR (dem.CARER_ADDRESS_3 IS NOT NULL AND vd.CARER_ADDRESS_3 IS NULL)
		OR			dem.CARER_ADDRESS_4 != vd.CARER_ADDRESS_4 OR (dem.CARER_ADDRESS_4 IS NULL AND vd.CARER_ADDRESS_4 IS NOT NULL) OR (dem.CARER_ADDRESS_4 IS NOT NULL AND vd.CARER_ADDRESS_4 IS NULL)
		OR			dem.CARER_ADDRESS_5 != vd.CARER_ADDRESS_5 OR (dem.CARER_ADDRESS_5 IS NULL AND vd.CARER_ADDRESS_5 IS NOT NULL) OR (dem.CARER_ADDRESS_5 IS NOT NULL AND vd.CARER_ADDRESS_5 IS NULL)
		OR			dem.CARER_POSTCODE != vd.CARER_POSTCODE OR (dem.CARER_POSTCODE IS NULL AND vd.CARER_POSTCODE IS NOT NULL) OR (dem.CARER_POSTCODE IS NOT NULL AND vd.CARER_POSTCODE IS NULL)
		OR			dem.CARER_CONTACT != vd.CARER_CONTACT OR (dem.CARER_CONTACT IS NULL AND vd.CARER_CONTACT IS NOT NULL) OR (dem.CARER_CONTACT IS NOT NULL AND vd.CARER_CONTACT IS NULL)
		OR			dem.CARER_RELATIONSHIP != vd.CARER_RELATIONSHIP OR (dem.CARER_RELATIONSHIP IS NULL AND vd.CARER_RELATIONSHIP IS NOT NULL) OR (dem.CARER_RELATIONSHIP IS NOT NULL AND vd.CARER_RELATIONSHIP IS NULL)
		OR			dem.CARER1_TYPE != vd.CARER1_TYPE OR (dem.CARER1_TYPE IS NULL AND vd.CARER1_TYPE IS NOT NULL) OR (dem.CARER1_TYPE IS NOT NULL AND vd.CARER1_TYPE IS NULL)
		OR			dem.CARER2_NAME != vd.CARER2_NAME OR (dem.CARER2_NAME IS NULL AND vd.CARER2_NAME IS NOT NULL) OR (dem.CARER2_NAME IS NOT NULL AND vd.CARER2_NAME IS NULL)
		OR			dem.CARER2_ADDRESS_1 != vd.CARER2_ADDRESS_1 OR (dem.CARER2_ADDRESS_1 IS NULL AND vd.CARER2_ADDRESS_1 IS NOT NULL) OR (dem.CARER2_ADDRESS_1 IS NOT NULL AND vd.CARER2_ADDRESS_1 IS NULL)
		OR			dem.CARER2_ADDRESS_2 != vd.CARER2_ADDRESS_2 OR (dem.CARER2_ADDRESS_2 IS NULL AND vd.CARER2_ADDRESS_2 IS NOT NULL) OR (dem.CARER2_ADDRESS_2 IS NOT NULL AND vd.CARER2_ADDRESS_2 IS NULL)
		OR			dem.CARER2_ADDRESS_3 != vd.CARER2_ADDRESS_3 OR (dem.CARER2_ADDRESS_3 IS NULL AND vd.CARER2_ADDRESS_3 IS NOT NULL) OR (dem.CARER2_ADDRESS_3 IS NOT NULL AND vd.CARER2_ADDRESS_3 IS NULL)
		OR			dem.CARER2_ADDRESS_4 != vd.CARER2_ADDRESS_4 OR (dem.CARER2_ADDRESS_4 IS NULL AND vd.CARER2_ADDRESS_4 IS NOT NULL) OR (dem.CARER2_ADDRESS_4 IS NOT NULL AND vd.CARER2_ADDRESS_4 IS NULL)
		OR			dem.CARER2_ADDRESS_5 != vd.CARER2_ADDRESS_5 OR (dem.CARER2_ADDRESS_5 IS NULL AND vd.CARER2_ADDRESS_5 IS NOT NULL) OR (dem.CARER2_ADDRESS_5 IS NOT NULL AND vd.CARER2_ADDRESS_5 IS NULL)
		OR			dem.CARER2_POSTCODE != vd.CARER2_POSTCODE OR (dem.CARER2_POSTCODE IS NULL AND vd.CARER2_POSTCODE IS NOT NULL) OR (dem.CARER2_POSTCODE IS NOT NULL AND vd.CARER2_POSTCODE IS NULL)
		OR			dem.CARER2_CONTACT != vd.CARER2_CONTACT OR (dem.CARER2_CONTACT IS NULL AND vd.CARER2_CONTACT IS NOT NULL) OR (dem.CARER2_CONTACT IS NOT NULL AND vd.CARER2_CONTACT IS NULL)
		OR			dem.CARER2_RELATIONSHIP != vd.CARER2_RELATIONSHIP OR (dem.CARER2_RELATIONSHIP IS NULL AND vd.CARER2_RELATIONSHIP IS NOT NULL) OR (dem.CARER2_RELATIONSHIP IS NOT NULL AND vd.CARER2_RELATIONSHIP IS NULL)
		OR			dem.CARER2_TYPE != vd.CARER2_TYPE OR (dem.CARER2_TYPE IS NULL AND vd.CARER2_TYPE IS NOT NULL) OR (dem.CARER2_TYPE IS NOT NULL AND vd.CARER2_TYPE IS NULL)
		OR			dem.PT_AT_RISK != vd.PT_AT_RISK OR (dem.PT_AT_RISK IS NULL AND vd.PT_AT_RISK IS NOT NULL) OR (dem.PT_AT_RISK IS NOT NULL AND vd.PT_AT_RISK IS NULL)
		OR			dem.REASON_RISK != vd.REASON_RISK OR (dem.REASON_RISK IS NULL AND vd.REASON_RISK IS NOT NULL) OR (dem.REASON_RISK IS NOT NULL AND vd.REASON_RISK IS NULL)
		OR			dem.GESTATION != vd.GESTATION OR (dem.GESTATION IS NULL AND vd.GESTATION IS NOT NULL) OR (dem.GESTATION IS NOT NULL AND vd.GESTATION IS NULL)
		OR			dem.CAUSE_OF_DEATH_UROLOGY != vd.CAUSE_OF_DEATH_UROLOGY OR (dem.CAUSE_OF_DEATH_UROLOGY IS NULL AND vd.CAUSE_OF_DEATH_UROLOGY IS NOT NULL) OR (dem.CAUSE_OF_DEATH_UROLOGY IS NOT NULL AND vd.CAUSE_OF_DEATH_UROLOGY IS NULL)
		OR			dem.AVOIDABLE_DEATH != vd.AVOIDABLE_DEATH OR (dem.AVOIDABLE_DEATH IS NULL AND vd.AVOIDABLE_DEATH IS NOT NULL) OR (dem.AVOIDABLE_DEATH IS NOT NULL AND vd.AVOIDABLE_DEATH IS NULL)
		OR			dem.AVOIDABLE_DETAILS != vd.AVOIDABLE_DETAILS OR (dem.AVOIDABLE_DETAILS IS NULL AND vd.AVOIDABLE_DETAILS IS NOT NULL) OR (dem.AVOIDABLE_DETAILS IS NOT NULL AND vd.AVOIDABLE_DETAILS IS NULL)
		OR			dem.OTHER_DEATH_CAUSE_UROLOGY != vd.OTHER_DEATH_CAUSE_UROLOGY OR (dem.OTHER_DEATH_CAUSE_UROLOGY IS NULL AND vd.OTHER_DEATH_CAUSE_UROLOGY IS NOT NULL) OR (dem.OTHER_DEATH_CAUSE_UROLOGY IS NOT NULL AND vd.OTHER_DEATH_CAUSE_UROLOGY IS NULL)
		OR			dem.ACTION_ID != vd.ACTION_ID OR (dem.ACTION_ID IS NULL AND vd.ACTION_ID IS NOT NULL) OR (dem.ACTION_ID IS NOT NULL AND vd.ACTION_ID IS NULL)
		OR			dem.STATED_GENDER_CODE != vd.STATED_GENDER_CODE OR (dem.STATED_GENDER_CODE IS NULL AND vd.STATED_GENDER_CODE IS NOT NULL) OR (dem.STATED_GENDER_CODE IS NOT NULL AND vd.STATED_GENDER_CODE IS NULL)
		OR			dem.CAUSE_OF_DEATH_UROLOGY_FUP != vd.CAUSE_OF_DEATH_UROLOGY_FUP OR (dem.CAUSE_OF_DEATH_UROLOGY_FUP IS NULL AND vd.CAUSE_OF_DEATH_UROLOGY_FUP IS NOT NULL) OR (dem.CAUSE_OF_DEATH_UROLOGY_FUP IS NOT NULL AND vd.CAUSE_OF_DEATH_UROLOGY_FUP IS NULL)
		OR			dem.DEATH_WITHIN_30_DAYS_OF_TREAT != vd.DEATH_WITHIN_30_DAYS_OF_TREAT OR (dem.DEATH_WITHIN_30_DAYS_OF_TREAT IS NULL AND vd.DEATH_WITHIN_30_DAYS_OF_TREAT IS NOT NULL) OR (dem.DEATH_WITHIN_30_DAYS_OF_TREAT IS NOT NULL AND vd.DEATH_WITHIN_30_DAYS_OF_TREAT IS NULL)
		OR			dem.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT != vd.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT OR (dem.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT IS NULL AND vd.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT IS NOT NULL) OR (dem.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT IS NOT NULL AND vd.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT IS NULL)
		OR			dem.DEATH_CAUSE_LATER_DATE != vd.DEATH_CAUSE_LATER_DATE OR (dem.DEATH_CAUSE_LATER_DATE IS NULL AND vd.DEATH_CAUSE_LATER_DATE IS NOT NULL) OR (dem.DEATH_CAUSE_LATER_DATE IS NOT NULL AND vd.DEATH_CAUSE_LATER_DATE IS NULL)
		OR			dem.RegisteredPractice != vd.RegisteredPractice OR (dem.RegisteredPractice IS NULL AND vd.RegisteredPractice IS NOT NULL) OR (dem.RegisteredPractice IS NOT NULL AND vd.RegisteredPractice IS NULL)
		OR			dem.RegisteredGP != vd.RegisteredGP OR (dem.RegisteredGP IS NULL AND vd.RegisteredGP IS NOT NULL) OR (dem.RegisteredGP IS NOT NULL AND vd.RegisteredGP IS NULL)
		OR			dem.PersonSexualOrientation != vd.PersonSexualOrientation OR (dem.PersonSexualOrientation IS NULL AND vd.PersonSexualOrientation IS NOT NULL) OR (dem.PersonSexualOrientation IS NOT NULL AND vd.PersonSexualOrientation IS NULL)

		-- Find all the confirmed major referrals
		IF OBJECT_ID('tempdb..#tblMAIN_REFERRALS_tblValidatedData') IS NOT NULL DROP TABLE #tblMAIN_REFERRALS_tblValidatedData
		SELECT		vd_minor.SrcSys_MajorExt
					,vd_minor.Src_UID_MajorExt
					,vd_minor.SrcSys_Major
					,vd_minor.Src_UID_Major
					,vd_minor.IsValidatedMajor
					,vd_minor.IsConfirmed
					,vd_minor.LastUpdated
					,vd_minor.SrcSys
					,vd_minor.Src_UID
					,vd_major.CARE_ID
					,vd_major.PATIENT_ID
					,vd_major.TEMP_ID
					,vd_major.L_CANCER_SITE
					,vd_major.N2_1_REFERRAL_SOURCE
					,vd_major.N2_2_ORG_CODE_REF
					,vd_major.N2_3_REFERRER_CODE
					,vd_major.N2_4_PRIORITY_TYPE
					,vd_major.N2_5_DECISION_DATE
					,vd_major.N2_6_RECEIPT_DATE
					,vd_major.N2_7_CONSULTANT
					,vd_major.N2_8_SPECIALTY
					,vd_major.N2_9_FIRST_SEEN_DATE
					,vd_major.N1_3_ORG_CODE_SEEN
					,vd_major.N2_10_FIRST_SEEN_DELAY
					,vd_major.N2_12_CANCER_TYPE
					,vd_major.N2_13_CANCER_STATUS
					,vd_major.L_FIRST_APPOINTMENT
					,vd_major.L_CANCELLED_DATE
					,vd_major.N2_14_ADJ_TIME
					,vd_major.N2_15_ADJ_REASON
					,vd_major.L_REFERRAL_METHOD
					,vd_major.N2_16_OP_REFERRAL
					,vd_major.L_SPECIALIST_DATE
					,vd_major.L_ORG_CODE_SPECIALIST
					,vd_major.L_SPECIALIST_SEEN_DATE
					,vd_major.N1_3_ORG_CODE_SPEC_SEEN
					,vd_major.N_UPGRADE_DATE
					,vd_major.N_UPGRADE_ORG_CODE
					,vd_major.L_UPGRADE_WHEN
					,vd_major.L_UPGRADE_WHO
					,vd_major.N4_1_DIAGNOSIS_DATE
					,vd_major.L_DIAGNOSIS
					,vd_major.N4_2_DIAGNOSIS_CODE
					,vd_major.L_ORG_CODE_DIAGNOSIS
					,vd_major.L_PT_INFORMED_DATE
					,vd_major.L_OTHER_DIAG_DATE
					,vd_major.N4_3_LATERALITY
					,vd_major.N4_4_BASIS_DIAGNOSIS
					,vd_major.L_TOPOGRAPHY
					,vd_major.L_HISTOLOGY_GROUP
					,vd_major.N4_5_HISTOLOGY
					,vd_major.N4_6_DIFFERENTIATION
					,vd_major.ClinicalTStage
					,vd_major.ClinicalTCertainty
					,vd_major.ClinicalNStage
					,vd_major.ClinicalNCertainty
					,vd_major.ClinicalMStage
					,vd_major.ClinicalMCertainty
					,vd_major.ClinicalOverallCertainty
					,vd_major.N6_9_SITE_CLASSIFICATION
					,vd_major.PathologicalOverallCertainty
					,vd_major.PathologicalTCertainty
					,vd_major.PathologicalTStage
					,vd_major.PathologicalNCertainty
					,vd_major.PathologicalNStage
					,vd_major.PathologicalMCertainty
					,vd_major.PathologicalMStage
					,vd_major.L_GP_INFORMED
					,vd_major.L_GP_INFORMED_DATE
					,vd_major.L_GP_NOT
					,vd_major.L_REL_INFORMED
					,vd_major.L_NURSE_PRESENT
					,vd_major.L_SPEC_NURSE_DATE
					,vd_major.L_SEEN_NURSE_DATE
					,vd_major.N16_1_ADJ_DAYS
					,vd_major.N16_2_ADJ_DAYS
					,vd_major.N16_3_ADJ_DECISION_CODE
					,vd_major.N16_4_ADJ_TREAT_CODE
					,vd_major.N16_5_DECISION_REASON_CODE
					,vd_major.N16_6_TREATMENT_REASON_CODE
					,vd_major.PathologicalTNMDate
					,vd_major.ClinicalTNMDate
					,vd_major.L_FIRST_CONSULTANT
					,vd_major.L_APPROPRIATE
					,vd_major.L_TERTIARY_DATE
					,vd_major.L_TERTIARY_TRUST
					,vd_major.L_TERTIARY_REASON
					,vd_major.L_INAP_REF
					,vd_major.L_NEW_CA_SITE
					,vd_major.L_AUTO_REF
					,vd_major.L_SEC_DIAGNOSIS_G
					,vd_major.L_SEC_DIAGNOSIS
					,vd_major.L_WRONG_REF
					,vd_major.L_WRONG_REASON
					,vd_major.L_TUMOUR_STATUS
					,vd_major.L_NON_CANCER
					,vd_major.L_FIRST_APP
					,vd_major.L_NO_APP
					,vd_major.L_DIAG_WHO
					,vd_major.L_RECURRENCE
					,vd_major.L_OTHER_SYMPS
					,vd_major.L_COMMENTS
					,vd_major.N2_11_FIRST_SEEN_REASON
					,vd_major.N16_7_DECISION_REASON
					,vd_major.N16_8_TREATMENT_REASON
					,vd_major.L_DIAGNOSIS_COMMENTS
					,vd_major.GP_PRACTICE_CODE
					,vd_major.ClinicalTNMGroup
					,vd_major.PathologicalTNMGroup
					,vd_major.L_KEY_WORKER_SEEN
					,vd_major.L_PALLIATIVE_SPECIALIST_SEEN
					,vd_major.GERM_CELL_NON_CNS_ID
					,vd_major.RECURRENCE_CANCER_SITE_ID
					,vd_major.ICD03_GROUP
					,vd_major.ICD03
					,vd_major.L_DATE_DIAGNOSIS_DAHNO_LUCADA
					,vd_major.L_INDICATOR_CODE
					,vd_major.PRIMARY_DIAGNOSIS_SUB_COMMENT
					,vd_major.CONSULTANT_CODE_AT_DIAGNOSIS
					,vd_major.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS
					,vd_major.FETOPROTEIN
					,vd_major.GONADOTROPIN
					,vd_major.GONADOTROPIN_SERUM
					,vd_major.FETOPROTEIN_SERUM
					,vd_major.SARCOMA_TUMOUR_SITE_BONE
					,vd_major.SARCOMA_TUMOUR_SITE_SOFT_TISSUE
					,vd_major.SARCOMA_TUMOUR_SUBSITE_BONE
					,vd_major.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE
					,vd_major.ROOT_DECISION_DATE_COMMENTS
					,vd_major.ROOT_RECEIPT_DATE_COMMENTS
					,vd_major.ROOT_FIRST_SEEN_DATE_COMMENTS
					,vd_major.ROOT_DIAGNOSIS_DATE_COMMENTS
					,vd_major.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS
					,vd_major.ROOT_UPGRADE_COMMENTS
					,vd_major.FIRST_APPT_TIME
					,vd_major.TRANSFER_REASON
					,vd_major.DATE_NEW_REFERRAL
					,vd_major.TUMOUR_SITE_NEW
					,vd_major.DATE_TRANSFER_ACTIONED
					,vd_major.SOURCE_CARE_ID
					,vd_major.ADT_REF_ID
					,vd_major.ACTION_ID
					,vd_major.DIAGNOSIS_ACTION_ID
					,vd_major.ORIGINAL_SOURCE_CARE_ID
					,vd_major.TRANSFER_DATE_COMMENTS
					,vd_major.SPECIALIST_REFERRAL_COMMENTS
					,vd_major.NON_CANCER_DIAGNOSIS_CHAPTER
					,vd_major.NON_CANCER_DIAGNOSIS_GROUP
					,vd_major.NON_CANCER_DIAGNOSIS_CODE
					,vd_major.TNM_UNKNOWN
					,vd_major.ReferringPractice
					,vd_major.ReferringGP
					,vd_major.ReferringBranch
					,vd_major.BankedTissue
					,vd_major.BankedTissueTumour
					,vd_major.BankedTissueBlood
					,vd_major.BankedTissueCSF
					,vd_major.BankedTissueBoneMarrow
					,vd_major.SNOMed_CT
					,vd_major.ADT_PLACER_ID
					,vd_major.SNOMEDCTDiagnosisID
					,vd_major.FasterDiagnosisOrganisationID
					,vd_major.FasterDiagnosisCancerSiteOverrideID
					,vd_major.FasterDiagnosisExclusionDate
					,vd_major.FasterDiagnosisExclusionReasonID
					,vd_major.FasterDiagnosisDelayReasonID
					,vd_major.FasterDiagnosisDelayReasonComments
					,vd_major.FasterDiagnosisCommunicationMethodID
					,vd_major.FasterDiagnosisInformingCareProfessionalID
					,vd_major.FasterDiagnosisOtherCareProfessional
					,vd_major.FasterDiagnosisOtherCommunicationMethod
					,vd_major.NonPrimaryPathwayOptionsID
					,vd_major.DiagnosisUncertainty
					,vd_major.TNMOrganisation
					,vd_major.FasterDiagnosisTargetRCComments
					,vd_major.FasterDiagnosisEndRCComments
					,vd_major.TNMOrganisation_Integrated
					,vd_major.LDHValue
					,vd_major.BankedTissueUrine
					,vd_major.SubsiteID
					,vd_major.PredictedBreachStatus
					,vd_major.RMRefID
					,vd_major.TertiaryReferralKey
					,vd_major.ClinicalTLetter
					,vd_major.ClinicalNLetter
					,vd_major.ClinicalMLetter
					,vd_major.PathologicalTLetter
					,vd_major.PathologicalNLetter
					,vd_major.PathologicalMLetter
					,vd_major.FDPlannedInterval
					,vd_major.LabReportDate
					,vd_major.LabReportOrgID
					,vd_major.ReferralRoute
					,vd_major.ReferralOtherRoute
					,vd_major.RelapseMorphology
					,vd_major.RelapseFlow
					,vd_major.RelapseMolecular
					,vd_major.RelapseClinicalExamination
					,vd_major.RelapseOther
					,vd_major.RapidDiagnostic
					,vd_major.PrimaryReferralFlag
					,vd_major.OtherAssessedBy
					,vd_major.SharedBreach
					,vd_major.PredictedBreachYear
					,vd_major.PredictedBreachMonth
					,vd_major.ValidatedRecordCreatedDttm
		INTO		#tblMAIN_REFERRALS_tblValidatedData
		FROM		Merge_R_Compare.tblMAIN_REFERRALS_tblValidatedData vd_major
		INNER JOIN	Merge_R_Compare.tblMAIN_REFERRALS_tblValidatedData vd_minor
																			ON	vd_major.SrcSys_MajorExt = vd_minor.SrcSys_MajorExt
																			AND	vd_major.Src_UID_MajorExt = vd_minor.Src_UID_MajorExt
		WHERE		vd_major.IsConfirmed = 1
		AND			vd_major.IsValidatedMajor = 1

		-- Find the confirmed major refs that are different from the original ref
		SELECT		vd.SrcSys_MajorExt
					,vd.Src_UID_MajorExt
					,vd.SrcSys_Major
					,vd.Src_UID_Major
					,vd.IsValidatedMajor
					,vd.IsConfirmed
					,vd.LastUpdated
					,vd.SrcSys
					,vd.Src_UID
					,vd.CARE_ID
					,vd.PATIENT_ID
					,mainref.PATIENT_ID AS OrigPATIENT_ID
					,PATIENT_ID_Diff										= CASE WHEN mainref.PATIENT_ID != vd.PATIENT_ID OR (mainref.PATIENT_ID IS NULL AND vd.PATIENT_ID IS NOT NULL) OR (mainref.PATIENT_ID IS NOT NULL AND vd.PATIENT_ID IS NULL) THEN 1 ELSE 0 END
					,TEMP_ID_Diff											= CASE WHEN mainref.TEMP_ID != vd.TEMP_ID OR (mainref.TEMP_ID IS NULL AND vd.TEMP_ID IS NOT NULL) OR (mainref.TEMP_ID IS NOT NULL AND vd.TEMP_ID IS NULL) THEN 1 ELSE 0 END
					,L_CANCER_SITE_Diff										= CASE WHEN mainref.L_CANCER_SITE != vd.L_CANCER_SITE OR (mainref.L_CANCER_SITE IS NULL AND vd.L_CANCER_SITE IS NOT NULL) OR (mainref.L_CANCER_SITE IS NOT NULL AND vd.L_CANCER_SITE IS NULL) THEN 1 ELSE 0 END
					,N2_1_REFERRAL_SOURCE_Diff								= CASE WHEN mainref.N2_1_REFERRAL_SOURCE != vd.N2_1_REFERRAL_SOURCE OR (mainref.N2_1_REFERRAL_SOURCE IS NULL AND vd.N2_1_REFERRAL_SOURCE IS NOT NULL) OR (mainref.N2_1_REFERRAL_SOURCE IS NOT NULL AND vd.N2_1_REFERRAL_SOURCE IS NULL) THEN 1 ELSE 0 END
					,N2_2_ORG_CODE_REF_Diff									= CASE WHEN mainref.N2_2_ORG_CODE_REF != vd.N2_2_ORG_CODE_REF OR (mainref.N2_2_ORG_CODE_REF IS NULL AND vd.N2_2_ORG_CODE_REF IS NOT NULL) OR (mainref.N2_2_ORG_CODE_REF IS NOT NULL AND vd.N2_2_ORG_CODE_REF IS NULL) THEN 1 ELSE 0 END
					,N2_3_REFERRER_CODE_Diff								= CASE WHEN mainref.N2_3_REFERRER_CODE != vd.N2_3_REFERRER_CODE OR (mainref.N2_3_REFERRER_CODE IS NULL AND vd.N2_3_REFERRER_CODE IS NOT NULL) OR (mainref.N2_3_REFERRER_CODE IS NOT NULL AND vd.N2_3_REFERRER_CODE IS NULL) THEN 1 ELSE 0 END
					,N2_4_PRIORITY_TYPE_Diff								= CASE WHEN mainref.N2_4_PRIORITY_TYPE != vd.N2_4_PRIORITY_TYPE OR (mainref.N2_4_PRIORITY_TYPE IS NULL AND vd.N2_4_PRIORITY_TYPE IS NOT NULL) OR (mainref.N2_4_PRIORITY_TYPE IS NOT NULL AND vd.N2_4_PRIORITY_TYPE IS NULL) THEN 1 ELSE 0 END
					,N2_5_DECISION_DATE_Diff								= CASE WHEN mainref.N2_5_DECISION_DATE != vd.N2_5_DECISION_DATE OR (mainref.N2_5_DECISION_DATE IS NULL AND vd.N2_5_DECISION_DATE IS NOT NULL) OR (mainref.N2_5_DECISION_DATE IS NOT NULL AND vd.N2_5_DECISION_DATE IS NULL) THEN 1 ELSE 0 END
					,N2_6_RECEIPT_DATE_Diff									= CASE WHEN mainref.N2_6_RECEIPT_DATE != vd.N2_6_RECEIPT_DATE OR (mainref.N2_6_RECEIPT_DATE IS NULL AND vd.N2_6_RECEIPT_DATE IS NOT NULL) OR (mainref.N2_6_RECEIPT_DATE IS NOT NULL AND vd.N2_6_RECEIPT_DATE IS NULL) THEN 1 ELSE 0 END
					,N2_7_CONSULTANT_Diff									= CASE WHEN mainref.N2_7_CONSULTANT != vd.N2_7_CONSULTANT OR (mainref.N2_7_CONSULTANT IS NULL AND vd.N2_7_CONSULTANT IS NOT NULL) OR (mainref.N2_7_CONSULTANT IS NOT NULL AND vd.N2_7_CONSULTANT IS NULL) THEN 1 ELSE 0 END
					,N2_8_SPECIALTY_Diff									= CASE WHEN mainref.N2_8_SPECIALTY != vd.N2_8_SPECIALTY OR (mainref.N2_8_SPECIALTY IS NULL AND vd.N2_8_SPECIALTY IS NOT NULL) OR (mainref.N2_8_SPECIALTY IS NOT NULL AND vd.N2_8_SPECIALTY IS NULL) THEN 1 ELSE 0 END
					,N2_9_FIRST_SEEN_DATE_Diff								= CASE WHEN mainref.N2_9_FIRST_SEEN_DATE != vd.N2_9_FIRST_SEEN_DATE OR (mainref.N2_9_FIRST_SEEN_DATE IS NULL AND vd.N2_9_FIRST_SEEN_DATE IS NOT NULL) OR (mainref.N2_9_FIRST_SEEN_DATE IS NOT NULL AND vd.N2_9_FIRST_SEEN_DATE IS NULL) THEN 1 ELSE 0 END
					,N1_3_ORG_CODE_SEEN_Diff								= CASE WHEN mainref.N1_3_ORG_CODE_SEEN != vd.N1_3_ORG_CODE_SEEN OR (mainref.N1_3_ORG_CODE_SEEN IS NULL AND vd.N1_3_ORG_CODE_SEEN IS NOT NULL) OR (mainref.N1_3_ORG_CODE_SEEN IS NOT NULL AND vd.N1_3_ORG_CODE_SEEN IS NULL) THEN 1 ELSE 0 END
					,N2_10_FIRST_SEEN_DELAY_Diff							= CASE WHEN mainref.N2_10_FIRST_SEEN_DELAY != vd.N2_10_FIRST_SEEN_DELAY OR (mainref.N2_10_FIRST_SEEN_DELAY IS NULL AND vd.N2_10_FIRST_SEEN_DELAY IS NOT NULL) OR (mainref.N2_10_FIRST_SEEN_DELAY IS NOT NULL AND vd.N2_10_FIRST_SEEN_DELAY IS NULL) THEN 1 ELSE 0 END
					,N2_12_CANCER_TYPE_Diff									= CASE WHEN mainref.N2_12_CANCER_TYPE != vd.N2_12_CANCER_TYPE OR (mainref.N2_12_CANCER_TYPE IS NULL AND vd.N2_12_CANCER_TYPE IS NOT NULL) OR (mainref.N2_12_CANCER_TYPE IS NOT NULL AND vd.N2_12_CANCER_TYPE IS NULL) THEN 1 ELSE 0 END
					,N2_13_CANCER_STATUS_Diff								= CASE WHEN mainref.N2_13_CANCER_STATUS != vd.N2_13_CANCER_STATUS OR (mainref.N2_13_CANCER_STATUS IS NULL AND vd.N2_13_CANCER_STATUS IS NOT NULL) OR (mainref.N2_13_CANCER_STATUS IS NOT NULL AND vd.N2_13_CANCER_STATUS IS NULL) THEN 1 ELSE 0 END
					,L_FIRST_APPOINTMENT_Diff								= CASE WHEN mainref.L_FIRST_APPOINTMENT != vd.L_FIRST_APPOINTMENT OR (mainref.L_FIRST_APPOINTMENT IS NULL AND vd.L_FIRST_APPOINTMENT IS NOT NULL) OR (mainref.L_FIRST_APPOINTMENT IS NOT NULL AND vd.L_FIRST_APPOINTMENT IS NULL) THEN 1 ELSE 0 END
					,L_CANCELLED_DATE_Diff									= CASE WHEN mainref.L_CANCELLED_DATE != vd.L_CANCELLED_DATE OR (mainref.L_CANCELLED_DATE IS NULL AND vd.L_CANCELLED_DATE IS NOT NULL) OR (mainref.L_CANCELLED_DATE IS NOT NULL AND vd.L_CANCELLED_DATE IS NULL) THEN 1 ELSE 0 END
					,N2_14_ADJ_TIME_Diff									= CASE WHEN mainref.N2_14_ADJ_TIME != vd.N2_14_ADJ_TIME OR (mainref.N2_14_ADJ_TIME IS NULL AND vd.N2_14_ADJ_TIME IS NOT NULL) OR (mainref.N2_14_ADJ_TIME IS NOT NULL AND vd.N2_14_ADJ_TIME IS NULL) THEN 1 ELSE 0 END
					,N2_15_ADJ_REASON_Diff									= CASE WHEN mainref.N2_15_ADJ_REASON != vd.N2_15_ADJ_REASON OR (mainref.N2_15_ADJ_REASON IS NULL AND vd.N2_15_ADJ_REASON IS NOT NULL) OR (mainref.N2_15_ADJ_REASON IS NOT NULL AND vd.N2_15_ADJ_REASON IS NULL) THEN 1 ELSE 0 END
					,L_REFERRAL_METHOD_Diff									= CASE WHEN mainref.L_REFERRAL_METHOD != vd.L_REFERRAL_METHOD OR (mainref.L_REFERRAL_METHOD IS NULL AND vd.L_REFERRAL_METHOD IS NOT NULL) OR (mainref.L_REFERRAL_METHOD IS NOT NULL AND vd.L_REFERRAL_METHOD IS NULL) THEN 1 ELSE 0 END
					,N2_16_OP_REFERRAL_Diff									= CASE WHEN mainref.N2_16_OP_REFERRAL != vd.N2_16_OP_REFERRAL OR (mainref.N2_16_OP_REFERRAL IS NULL AND vd.N2_16_OP_REFERRAL IS NOT NULL) OR (mainref.N2_16_OP_REFERRAL IS NOT NULL AND vd.N2_16_OP_REFERRAL IS NULL) THEN 1 ELSE 0 END
					,L_SPECIALIST_DATE_Diff									= CASE WHEN mainref.L_SPECIALIST_DATE != vd.L_SPECIALIST_DATE OR (mainref.L_SPECIALIST_DATE IS NULL AND vd.L_SPECIALIST_DATE IS NOT NULL) OR (mainref.L_SPECIALIST_DATE IS NOT NULL AND vd.L_SPECIALIST_DATE IS NULL) THEN 1 ELSE 0 END
					,L_ORG_CODE_SPECIALIST_Diff								= CASE WHEN mainref.L_ORG_CODE_SPECIALIST != vd.L_ORG_CODE_SPECIALIST OR (mainref.L_ORG_CODE_SPECIALIST IS NULL AND vd.L_ORG_CODE_SPECIALIST IS NOT NULL) OR (mainref.L_ORG_CODE_SPECIALIST IS NOT NULL AND vd.L_ORG_CODE_SPECIALIST IS NULL) THEN 1 ELSE 0 END
					,L_SPECIALIST_SEEN_DATE_Diff							= CASE WHEN mainref.L_SPECIALIST_SEEN_DATE != vd.L_SPECIALIST_SEEN_DATE OR (mainref.L_SPECIALIST_SEEN_DATE IS NULL AND vd.L_SPECIALIST_SEEN_DATE IS NOT NULL) OR (mainref.L_SPECIALIST_SEEN_DATE IS NOT NULL AND vd.L_SPECIALIST_SEEN_DATE IS NULL) THEN 1 ELSE 0 END
					,N1_3_ORG_CODE_SPEC_SEEN_Diff							= CASE WHEN mainref.N1_3_ORG_CODE_SPEC_SEEN != vd.N1_3_ORG_CODE_SPEC_SEEN OR (mainref.N1_3_ORG_CODE_SPEC_SEEN IS NULL AND vd.N1_3_ORG_CODE_SPEC_SEEN IS NOT NULL) OR (mainref.N1_3_ORG_CODE_SPEC_SEEN IS NOT NULL AND vd.N1_3_ORG_CODE_SPEC_SEEN IS NULL) THEN 1 ELSE 0 END
					,N_UPGRADE_DATE_Diff									= CASE WHEN mainref.N_UPGRADE_DATE != vd.N_UPGRADE_DATE OR (mainref.N_UPGRADE_DATE IS NULL AND vd.N_UPGRADE_DATE IS NOT NULL) OR (mainref.N_UPGRADE_DATE IS NOT NULL AND vd.N_UPGRADE_DATE IS NULL) THEN 1 ELSE 0 END
					,N_UPGRADE_ORG_CODE_Diff								= CASE WHEN mainref.N_UPGRADE_ORG_CODE != vd.N_UPGRADE_ORG_CODE OR (mainref.N_UPGRADE_ORG_CODE IS NULL AND vd.N_UPGRADE_ORG_CODE IS NOT NULL) OR (mainref.N_UPGRADE_ORG_CODE IS NOT NULL AND vd.N_UPGRADE_ORG_CODE IS NULL) THEN 1 ELSE 0 END
					,L_UPGRADE_WHEN_Diff									= CASE WHEN mainref.L_UPGRADE_WHEN != vd.L_UPGRADE_WHEN OR (mainref.L_UPGRADE_WHEN IS NULL AND vd.L_UPGRADE_WHEN IS NOT NULL) OR (mainref.L_UPGRADE_WHEN IS NOT NULL AND vd.L_UPGRADE_WHEN IS NULL) THEN 1 ELSE 0 END
					,L_UPGRADE_WHO_Diff										= CASE WHEN mainref.L_UPGRADE_WHO != vd.L_UPGRADE_WHO OR (mainref.L_UPGRADE_WHO IS NULL AND vd.L_UPGRADE_WHO IS NOT NULL) OR (mainref.L_UPGRADE_WHO IS NOT NULL AND vd.L_UPGRADE_WHO IS NULL) THEN 1 ELSE 0 END
					,N4_1_DIAGNOSIS_DATE_Diff								= CASE WHEN mainref.N4_1_DIAGNOSIS_DATE != vd.N4_1_DIAGNOSIS_DATE OR (mainref.N4_1_DIAGNOSIS_DATE IS NULL AND vd.N4_1_DIAGNOSIS_DATE IS NOT NULL) OR (mainref.N4_1_DIAGNOSIS_DATE IS NOT NULL AND vd.N4_1_DIAGNOSIS_DATE IS NULL) THEN 1 ELSE 0 END
					,L_DIAGNOSIS_Diff										= CASE WHEN mainref.L_DIAGNOSIS != vd.L_DIAGNOSIS OR (mainref.L_DIAGNOSIS IS NULL AND vd.L_DIAGNOSIS IS NOT NULL) OR (mainref.L_DIAGNOSIS IS NOT NULL AND vd.L_DIAGNOSIS IS NULL) THEN 1 ELSE 0 END
					,N4_2_DIAGNOSIS_CODE_Diff								= CASE WHEN mainref.N4_2_DIAGNOSIS_CODE != vd.N4_2_DIAGNOSIS_CODE OR (mainref.N4_2_DIAGNOSIS_CODE IS NULL AND vd.N4_2_DIAGNOSIS_CODE IS NOT NULL) OR (mainref.N4_2_DIAGNOSIS_CODE IS NOT NULL AND vd.N4_2_DIAGNOSIS_CODE IS NULL) THEN 1 ELSE 0 END
					,L_ORG_CODE_DIAGNOSIS_Diff								= CASE WHEN mainref.L_ORG_CODE_DIAGNOSIS != vd.L_ORG_CODE_DIAGNOSIS OR (mainref.L_ORG_CODE_DIAGNOSIS IS NULL AND vd.L_ORG_CODE_DIAGNOSIS IS NOT NULL) OR (mainref.L_ORG_CODE_DIAGNOSIS IS NOT NULL AND vd.L_ORG_CODE_DIAGNOSIS IS NULL) THEN 1 ELSE 0 END
					,L_PT_INFORMED_DATE_Diff								= CASE WHEN mainref.L_PT_INFORMED_DATE != vd.L_PT_INFORMED_DATE OR (mainref.L_PT_INFORMED_DATE IS NULL AND vd.L_PT_INFORMED_DATE IS NOT NULL) OR (mainref.L_PT_INFORMED_DATE IS NOT NULL AND vd.L_PT_INFORMED_DATE IS NULL) THEN 1 ELSE 0 END
					,L_OTHER_DIAG_DATE_Diff									= CASE WHEN mainref.L_OTHER_DIAG_DATE != vd.L_OTHER_DIAG_DATE OR (mainref.L_OTHER_DIAG_DATE IS NULL AND vd.L_OTHER_DIAG_DATE IS NOT NULL) OR (mainref.L_OTHER_DIAG_DATE IS NOT NULL AND vd.L_OTHER_DIAG_DATE IS NULL) THEN 1 ELSE 0 END
					,N4_3_LATERALITY_Diff									= CASE WHEN mainref.N4_3_LATERALITY != vd.N4_3_LATERALITY OR (mainref.N4_3_LATERALITY IS NULL AND vd.N4_3_LATERALITY IS NOT NULL) OR (mainref.N4_3_LATERALITY IS NOT NULL AND vd.N4_3_LATERALITY IS NULL) THEN 1 ELSE 0 END
					,N4_4_BASIS_DIAGNOSIS_Diff								= CASE WHEN mainref.N4_4_BASIS_DIAGNOSIS != vd.N4_4_BASIS_DIAGNOSIS OR (mainref.N4_4_BASIS_DIAGNOSIS IS NULL AND vd.N4_4_BASIS_DIAGNOSIS IS NOT NULL) OR (mainref.N4_4_BASIS_DIAGNOSIS IS NOT NULL AND vd.N4_4_BASIS_DIAGNOSIS IS NULL) THEN 1 ELSE 0 END
					,L_TOPOGRAPHY_Diff										= CASE WHEN mainref.L_TOPOGRAPHY != vd.L_TOPOGRAPHY OR (mainref.L_TOPOGRAPHY IS NULL AND vd.L_TOPOGRAPHY IS NOT NULL) OR (mainref.L_TOPOGRAPHY IS NOT NULL AND vd.L_TOPOGRAPHY IS NULL) THEN 1 ELSE 0 END
					,L_HISTOLOGY_GROUP_Diff									= CASE WHEN mainref.L_HISTOLOGY_GROUP != vd.L_HISTOLOGY_GROUP OR (mainref.L_HISTOLOGY_GROUP IS NULL AND vd.L_HISTOLOGY_GROUP IS NOT NULL) OR (mainref.L_HISTOLOGY_GROUP IS NOT NULL AND vd.L_HISTOLOGY_GROUP IS NULL) THEN 1 ELSE 0 END
					,N4_5_HISTOLOGY_Diff									= CASE WHEN mainref.N4_5_HISTOLOGY != vd.N4_5_HISTOLOGY OR (mainref.N4_5_HISTOLOGY IS NULL AND vd.N4_5_HISTOLOGY IS NOT NULL) OR (mainref.N4_5_HISTOLOGY IS NOT NULL AND vd.N4_5_HISTOLOGY IS NULL) THEN 1 ELSE 0 END
					,N4_6_DIFFERENTIATION_Diff								= CASE WHEN mainref.N4_6_DIFFERENTIATION != vd.N4_6_DIFFERENTIATION OR (mainref.N4_6_DIFFERENTIATION IS NULL AND vd.N4_6_DIFFERENTIATION IS NOT NULL) OR (mainref.N4_6_DIFFERENTIATION IS NOT NULL AND vd.N4_6_DIFFERENTIATION IS NULL) THEN 1 ELSE 0 END
					,ClinicalTStage_Diff									= CASE WHEN mainref.ClinicalTStage != vd.ClinicalTStage OR (mainref.ClinicalTStage IS NULL AND vd.ClinicalTStage IS NOT NULL) OR (mainref.ClinicalTStage IS NOT NULL AND vd.ClinicalTStage IS NULL) THEN 1 ELSE 0 END
					,ClinicalTCertainty_Diff								= CASE WHEN mainref.ClinicalTCertainty != vd.ClinicalTCertainty OR (mainref.ClinicalTCertainty IS NULL AND vd.ClinicalTCertainty IS NOT NULL) OR (mainref.ClinicalTCertainty IS NOT NULL AND vd.ClinicalTCertainty IS NULL) THEN 1 ELSE 0 END
					,ClinicalNStage_Diff									= CASE WHEN mainref.ClinicalNStage != vd.ClinicalNStage OR (mainref.ClinicalNStage IS NULL AND vd.ClinicalNStage IS NOT NULL) OR (mainref.ClinicalNStage IS NOT NULL AND vd.ClinicalNStage IS NULL) THEN 1 ELSE 0 END
					,ClinicalNCertainty_Diff								= CASE WHEN mainref.ClinicalNCertainty != vd.ClinicalNCertainty OR (mainref.ClinicalNCertainty IS NULL AND vd.ClinicalNCertainty IS NOT NULL) OR (mainref.ClinicalNCertainty IS NOT NULL AND vd.ClinicalNCertainty IS NULL) THEN 1 ELSE 0 END
					,ClinicalMStage_Diff									= CASE WHEN mainref.ClinicalMStage != vd.ClinicalMStage OR (mainref.ClinicalMStage IS NULL AND vd.ClinicalMStage IS NOT NULL) OR (mainref.ClinicalMStage IS NOT NULL AND vd.ClinicalMStage IS NULL) THEN 1 ELSE 0 END
					,ClinicalMCertainty_Diff								= CASE WHEN mainref.ClinicalMCertainty != vd.ClinicalMCertainty OR (mainref.ClinicalMCertainty IS NULL AND vd.ClinicalMCertainty IS NOT NULL) OR (mainref.ClinicalMCertainty IS NOT NULL AND vd.ClinicalMCertainty IS NULL) THEN 1 ELSE 0 END
					,ClinicalOverallCertainty_Diff							= CASE WHEN mainref.ClinicalOverallCertainty != vd.ClinicalOverallCertainty OR (mainref.ClinicalOverallCertainty IS NULL AND vd.ClinicalOverallCertainty IS NOT NULL) OR (mainref.ClinicalOverallCertainty IS NOT NULL AND vd.ClinicalOverallCertainty IS NULL) THEN 1 ELSE 0 END
					,N6_9_SITE_CLASSIFICATION_Diff							= CASE WHEN mainref.N6_9_SITE_CLASSIFICATION != vd.N6_9_SITE_CLASSIFICATION OR (mainref.N6_9_SITE_CLASSIFICATION IS NULL AND vd.N6_9_SITE_CLASSIFICATION IS NOT NULL) OR (mainref.N6_9_SITE_CLASSIFICATION IS NOT NULL AND vd.N6_9_SITE_CLASSIFICATION IS NULL) THEN 1 ELSE 0 END
					,PathologicalOverallCertainty_Diff						= CASE WHEN mainref.PathologicalOverallCertainty != vd.PathologicalOverallCertainty OR (mainref.PathologicalOverallCertainty IS NULL AND vd.PathologicalOverallCertainty IS NOT NULL) OR (mainref.PathologicalOverallCertainty IS NOT NULL AND vd.PathologicalOverallCertainty IS NULL) THEN 1 ELSE 0 END
					,PathologicalTCertainty_Diff							= CASE WHEN mainref.PathologicalTCertainty != vd.PathologicalTCertainty OR (mainref.PathologicalTCertainty IS NULL AND vd.PathologicalTCertainty IS NOT NULL) OR (mainref.PathologicalTCertainty IS NOT NULL AND vd.PathologicalTCertainty IS NULL) THEN 1 ELSE 0 END
					,PathologicalTStage_Diff								= CASE WHEN mainref.PathologicalTStage != vd.PathologicalTStage OR (mainref.PathologicalTStage IS NULL AND vd.PathologicalTStage IS NOT NULL) OR (mainref.PathologicalTStage IS NOT NULL AND vd.PathologicalTStage IS NULL) THEN 1 ELSE 0 END
					,PathologicalNCertainty_Diff							= CASE WHEN mainref.PathologicalNCertainty != vd.PathologicalNCertainty OR (mainref.PathologicalNCertainty IS NULL AND vd.PathologicalNCertainty IS NOT NULL) OR (mainref.PathologicalNCertainty IS NOT NULL AND vd.PathologicalNCertainty IS NULL) THEN 1 ELSE 0 END
					,PathologicalNStage_Diff								= CASE WHEN mainref.PathologicalNStage != vd.PathologicalNStage OR (mainref.PathologicalNStage IS NULL AND vd.PathologicalNStage IS NOT NULL) OR (mainref.PathologicalNStage IS NOT NULL AND vd.PathologicalNStage IS NULL) THEN 1 ELSE 0 END
					,PathologicalMCertainty_Diff							= CASE WHEN mainref.PathologicalMCertainty != vd.PathologicalMCertainty OR (mainref.PathologicalMCertainty IS NULL AND vd.PathologicalMCertainty IS NOT NULL) OR (mainref.PathologicalMCertainty IS NOT NULL AND vd.PathologicalMCertainty IS NULL) THEN 1 ELSE 0 END
					,PathologicalMStage_Diff								= CASE WHEN mainref.PathologicalMStage != vd.PathologicalMStage OR (mainref.PathologicalMStage IS NULL AND vd.PathologicalMStage IS NOT NULL) OR (mainref.PathologicalMStage IS NOT NULL AND vd.PathologicalMStage IS NULL) THEN 1 ELSE 0 END
					,L_GP_INFORMED_Diff										= CASE WHEN mainref.L_GP_INFORMED != vd.L_GP_INFORMED OR (mainref.L_GP_INFORMED IS NULL AND vd.L_GP_INFORMED IS NOT NULL) OR (mainref.L_GP_INFORMED IS NOT NULL AND vd.L_GP_INFORMED IS NULL) THEN 1 ELSE 0 END
					,L_GP_INFORMED_DATE_Diff								= CASE WHEN mainref.L_GP_INFORMED_DATE != vd.L_GP_INFORMED_DATE OR (mainref.L_GP_INFORMED_DATE IS NULL AND vd.L_GP_INFORMED_DATE IS NOT NULL) OR (mainref.L_GP_INFORMED_DATE IS NOT NULL AND vd.L_GP_INFORMED_DATE IS NULL) THEN 1 ELSE 0 END
					,L_GP_NOT_Diff											= CASE WHEN mainref.L_GP_NOT != vd.L_GP_NOT OR (mainref.L_GP_NOT IS NULL AND vd.L_GP_NOT IS NOT NULL) OR (mainref.L_GP_NOT IS NOT NULL AND vd.L_GP_NOT IS NULL) THEN 1 ELSE 0 END
					,L_REL_INFORMED_Diff									= CASE WHEN mainref.L_REL_INFORMED != vd.L_REL_INFORMED OR (mainref.L_REL_INFORMED IS NULL AND vd.L_REL_INFORMED IS NOT NULL) OR (mainref.L_REL_INFORMED IS NOT NULL AND vd.L_REL_INFORMED IS NULL) THEN 1 ELSE 0 END
					,L_NURSE_PRESENT_Diff									= CASE WHEN mainref.L_NURSE_PRESENT != vd.L_NURSE_PRESENT OR (mainref.L_NURSE_PRESENT IS NULL AND vd.L_NURSE_PRESENT IS NOT NULL) OR (mainref.L_NURSE_PRESENT IS NOT NULL AND vd.L_NURSE_PRESENT IS NULL) THEN 1 ELSE 0 END
					,L_SPEC_NURSE_DATE_Diff									= CASE WHEN mainref.L_SPEC_NURSE_DATE != vd.L_SPEC_NURSE_DATE OR (mainref.L_SPEC_NURSE_DATE IS NULL AND vd.L_SPEC_NURSE_DATE IS NOT NULL) OR (mainref.L_SPEC_NURSE_DATE IS NOT NULL AND vd.L_SPEC_NURSE_DATE IS NULL) THEN 1 ELSE 0 END
					,L_SEEN_NURSE_DATE_Diff									= CASE WHEN mainref.L_SEEN_NURSE_DATE != vd.L_SEEN_NURSE_DATE OR (mainref.L_SEEN_NURSE_DATE IS NULL AND vd.L_SEEN_NURSE_DATE IS NOT NULL) OR (mainref.L_SEEN_NURSE_DATE IS NOT NULL AND vd.L_SEEN_NURSE_DATE IS NULL) THEN 1 ELSE 0 END
					,N16_1_ADJ_DAYS_Diff									= CASE WHEN mainref.N16_1_ADJ_DAYS != vd.N16_1_ADJ_DAYS OR (mainref.N16_1_ADJ_DAYS IS NULL AND vd.N16_1_ADJ_DAYS IS NOT NULL) OR (mainref.N16_1_ADJ_DAYS IS NOT NULL AND vd.N16_1_ADJ_DAYS IS NULL) THEN 1 ELSE 0 END
					,N16_2_ADJ_DAYS_Diff									= CASE WHEN mainref.N16_2_ADJ_DAYS != vd.N16_2_ADJ_DAYS OR (mainref.N16_2_ADJ_DAYS IS NULL AND vd.N16_2_ADJ_DAYS IS NOT NULL) OR (mainref.N16_2_ADJ_DAYS IS NOT NULL AND vd.N16_2_ADJ_DAYS IS NULL) THEN 1 ELSE 0 END
					,N16_3_ADJ_DECISION_CODE_Diff							= CASE WHEN mainref.N16_3_ADJ_DECISION_CODE != vd.N16_3_ADJ_DECISION_CODE OR (mainref.N16_3_ADJ_DECISION_CODE IS NULL AND vd.N16_3_ADJ_DECISION_CODE IS NOT NULL) OR (mainref.N16_3_ADJ_DECISION_CODE IS NOT NULL AND vd.N16_3_ADJ_DECISION_CODE IS NULL) THEN 1 ELSE 0 END
					,N16_4_ADJ_TREAT_CODE_Diff								= CASE WHEN mainref.N16_4_ADJ_TREAT_CODE != vd.N16_4_ADJ_TREAT_CODE OR (mainref.N16_4_ADJ_TREAT_CODE IS NULL AND vd.N16_4_ADJ_TREAT_CODE IS NOT NULL) OR (mainref.N16_4_ADJ_TREAT_CODE IS NOT NULL AND vd.N16_4_ADJ_TREAT_CODE IS NULL) THEN 1 ELSE 0 END
					,N16_5_DECISION_REASON_CODE_Diff						= CASE WHEN mainref.N16_5_DECISION_REASON_CODE != vd.N16_5_DECISION_REASON_CODE OR (mainref.N16_5_DECISION_REASON_CODE IS NULL AND vd.N16_5_DECISION_REASON_CODE IS NOT NULL) OR (mainref.N16_5_DECISION_REASON_CODE IS NOT NULL AND vd.N16_5_DECISION_REASON_CODE IS NULL) THEN 1 ELSE 0 END
					,N16_6_TREATMENT_REASON_CODE_Diff						= CASE WHEN mainref.N16_6_TREATMENT_REASON_CODE != vd.N16_6_TREATMENT_REASON_CODE OR (mainref.N16_6_TREATMENT_REASON_CODE IS NULL AND vd.N16_6_TREATMENT_REASON_CODE IS NOT NULL) OR (mainref.N16_6_TREATMENT_REASON_CODE IS NOT NULL AND vd.N16_6_TREATMENT_REASON_CODE IS NULL) THEN 1 ELSE 0 END
					,PathologicalTNMDate_Diff								= CASE WHEN mainref.PathologicalTNMDate != vd.PathologicalTNMDate OR (mainref.PathologicalTNMDate IS NULL AND vd.PathologicalTNMDate IS NOT NULL) OR (mainref.PathologicalTNMDate IS NOT NULL AND vd.PathologicalTNMDate IS NULL) THEN 1 ELSE 0 END
					,ClinicalTNMDate_Diff									= CASE WHEN mainref.ClinicalTNMDate != vd.ClinicalTNMDate OR (mainref.ClinicalTNMDate IS NULL AND vd.ClinicalTNMDate IS NOT NULL) OR (mainref.ClinicalTNMDate IS NOT NULL AND vd.ClinicalTNMDate IS NULL) THEN 1 ELSE 0 END
					,L_FIRST_CONSULTANT_Diff								= CASE WHEN mainref.L_FIRST_CONSULTANT != vd.L_FIRST_CONSULTANT OR (mainref.L_FIRST_CONSULTANT IS NULL AND vd.L_FIRST_CONSULTANT IS NOT NULL) OR (mainref.L_FIRST_CONSULTANT IS NOT NULL AND vd.L_FIRST_CONSULTANT IS NULL) THEN 1 ELSE 0 END
					,L_APPROPRIATE_Diff										= CASE WHEN mainref.L_APPROPRIATE != vd.L_APPROPRIATE OR (mainref.L_APPROPRIATE IS NULL AND vd.L_APPROPRIATE IS NOT NULL) OR (mainref.L_APPROPRIATE IS NOT NULL AND vd.L_APPROPRIATE IS NULL) THEN 1 ELSE 0 END
					,L_TERTIARY_DATE_Diff									= CASE WHEN mainref.L_TERTIARY_DATE != vd.L_TERTIARY_DATE OR (mainref.L_TERTIARY_DATE IS NULL AND vd.L_TERTIARY_DATE IS NOT NULL) OR (mainref.L_TERTIARY_DATE IS NOT NULL AND vd.L_TERTIARY_DATE IS NULL) THEN 1 ELSE 0 END
					,L_TERTIARY_TRUST_Diff									= CASE WHEN mainref.L_TERTIARY_TRUST != vd.L_TERTIARY_TRUST OR (mainref.L_TERTIARY_TRUST IS NULL AND vd.L_TERTIARY_TRUST IS NOT NULL) OR (mainref.L_TERTIARY_TRUST IS NOT NULL AND vd.L_TERTIARY_TRUST IS NULL) THEN 1 ELSE 0 END
					,L_TERTIARY_REASON_Diff									= CASE WHEN mainref.L_TERTIARY_REASON != vd.L_TERTIARY_REASON OR (mainref.L_TERTIARY_REASON IS NULL AND vd.L_TERTIARY_REASON IS NOT NULL) OR (mainref.L_TERTIARY_REASON IS NOT NULL AND vd.L_TERTIARY_REASON IS NULL) THEN 1 ELSE 0 END
					,L_INAP_REF_Diff										= CASE WHEN mainref.L_INAP_REF != vd.L_INAP_REF OR (mainref.L_INAP_REF IS NULL AND vd.L_INAP_REF IS NOT NULL) OR (mainref.L_INAP_REF IS NOT NULL AND vd.L_INAP_REF IS NULL) THEN 1 ELSE 0 END
					,L_NEW_CA_SITE_Diff										= CASE WHEN mainref.L_NEW_CA_SITE != vd.L_NEW_CA_SITE OR (mainref.L_NEW_CA_SITE IS NULL AND vd.L_NEW_CA_SITE IS NOT NULL) OR (mainref.L_NEW_CA_SITE IS NOT NULL AND vd.L_NEW_CA_SITE IS NULL) THEN 1 ELSE 0 END
					,L_AUTO_REF_Diff										= CASE WHEN mainref.L_AUTO_REF != vd.L_AUTO_REF OR (mainref.L_AUTO_REF IS NULL AND vd.L_AUTO_REF IS NOT NULL) OR (mainref.L_AUTO_REF IS NOT NULL AND vd.L_AUTO_REF IS NULL) THEN 1 ELSE 0 END
					,L_SEC_DIAGNOSIS_G_Diff									= CASE WHEN mainref.L_SEC_DIAGNOSIS_G != vd.L_SEC_DIAGNOSIS_G OR (mainref.L_SEC_DIAGNOSIS_G IS NULL AND vd.L_SEC_DIAGNOSIS_G IS NOT NULL) OR (mainref.L_SEC_DIAGNOSIS_G IS NOT NULL AND vd.L_SEC_DIAGNOSIS_G IS NULL) THEN 1 ELSE 0 END
					,L_SEC_DIAGNOSIS_Diff									= CASE WHEN mainref.L_SEC_DIAGNOSIS != vd.L_SEC_DIAGNOSIS OR (mainref.L_SEC_DIAGNOSIS IS NULL AND vd.L_SEC_DIAGNOSIS IS NOT NULL) OR (mainref.L_SEC_DIAGNOSIS IS NOT NULL AND vd.L_SEC_DIAGNOSIS IS NULL) THEN 1 ELSE 0 END
					,L_WRONG_REF_Diff										= CASE WHEN mainref.L_WRONG_REF != vd.L_WRONG_REF OR (mainref.L_WRONG_REF IS NULL AND vd.L_WRONG_REF IS NOT NULL) OR (mainref.L_WRONG_REF IS NOT NULL AND vd.L_WRONG_REF IS NULL) THEN 1 ELSE 0 END
					,L_WRONG_REASON_Diff									= CASE WHEN mainref.L_WRONG_REASON != vd.L_WRONG_REASON OR (mainref.L_WRONG_REASON IS NULL AND vd.L_WRONG_REASON IS NOT NULL) OR (mainref.L_WRONG_REASON IS NOT NULL AND vd.L_WRONG_REASON IS NULL) THEN 1 ELSE 0 END
					,L_TUMOUR_STATUS_Diff									= CASE WHEN mainref.L_TUMOUR_STATUS != vd.L_TUMOUR_STATUS OR (mainref.L_TUMOUR_STATUS IS NULL AND vd.L_TUMOUR_STATUS IS NOT NULL) OR (mainref.L_TUMOUR_STATUS IS NOT NULL AND vd.L_TUMOUR_STATUS IS NULL) THEN 1 ELSE 0 END
					,L_NON_CANCER_Diff										= CASE WHEN mainref.L_NON_CANCER != vd.L_NON_CANCER OR (mainref.L_NON_CANCER IS NULL AND vd.L_NON_CANCER IS NOT NULL) OR (mainref.L_NON_CANCER IS NOT NULL AND vd.L_NON_CANCER IS NULL) THEN 1 ELSE 0 END
					,L_FIRST_APP_Diff										= CASE WHEN mainref.L_FIRST_APP != vd.L_FIRST_APP OR (mainref.L_FIRST_APP IS NULL AND vd.L_FIRST_APP IS NOT NULL) OR (mainref.L_FIRST_APP IS NOT NULL AND vd.L_FIRST_APP IS NULL) THEN 1 ELSE 0 END
					,L_NO_APP_Diff											= CASE WHEN mainref.L_NO_APP != vd.L_NO_APP OR (mainref.L_NO_APP IS NULL AND vd.L_NO_APP IS NOT NULL) OR (mainref.L_NO_APP IS NOT NULL AND vd.L_NO_APP IS NULL) THEN 1 ELSE 0 END
					,L_DIAG_WHO_Diff										= CASE WHEN mainref.L_DIAG_WHO != vd.L_DIAG_WHO OR (mainref.L_DIAG_WHO IS NULL AND vd.L_DIAG_WHO IS NOT NULL) OR (mainref.L_DIAG_WHO IS NOT NULL AND vd.L_DIAG_WHO IS NULL) THEN 1 ELSE 0 END
					,L_RECURRENCE_Diff										= CASE WHEN mainref.L_RECURRENCE != vd.L_RECURRENCE OR (mainref.L_RECURRENCE IS NULL AND vd.L_RECURRENCE IS NOT NULL) OR (mainref.L_RECURRENCE IS NOT NULL AND vd.L_RECURRENCE IS NULL) THEN 1 ELSE 0 END
					,GP_PRACTICE_CODE_Diff									= CASE WHEN mainref.GP_PRACTICE_CODE != vd.GP_PRACTICE_CODE OR (mainref.GP_PRACTICE_CODE IS NULL AND vd.GP_PRACTICE_CODE IS NOT NULL) OR (mainref.GP_PRACTICE_CODE IS NOT NULL AND vd.GP_PRACTICE_CODE IS NULL) THEN 1 ELSE 0 END
					,ClinicalTNMGroup_Diff									= CASE WHEN mainref.ClinicalTNMGroup != vd.ClinicalTNMGroup OR (mainref.ClinicalTNMGroup IS NULL AND vd.ClinicalTNMGroup IS NOT NULL) OR (mainref.ClinicalTNMGroup IS NOT NULL AND vd.ClinicalTNMGroup IS NULL) THEN 1 ELSE 0 END
					,PathologicalTNMGroup_Diff								= CASE WHEN mainref.PathologicalTNMGroup != vd.PathologicalTNMGroup OR (mainref.PathologicalTNMGroup IS NULL AND vd.PathologicalTNMGroup IS NOT NULL) OR (mainref.PathologicalTNMGroup IS NOT NULL AND vd.PathologicalTNMGroup IS NULL) THEN 1 ELSE 0 END
					,L_KEY_WORKER_SEEN_Diff									= CASE WHEN mainref.L_KEY_WORKER_SEEN != vd.L_KEY_WORKER_SEEN OR (mainref.L_KEY_WORKER_SEEN IS NULL AND vd.L_KEY_WORKER_SEEN IS NOT NULL) OR (mainref.L_KEY_WORKER_SEEN IS NOT NULL AND vd.L_KEY_WORKER_SEEN IS NULL) THEN 1 ELSE 0 END
					,L_PALLIATIVE_SPECIALIST_SEEN_Diff						= CASE WHEN mainref.L_PALLIATIVE_SPECIALIST_SEEN != vd.L_PALLIATIVE_SPECIALIST_SEEN OR (mainref.L_PALLIATIVE_SPECIALIST_SEEN IS NULL AND vd.L_PALLIATIVE_SPECIALIST_SEEN IS NOT NULL) OR (mainref.L_PALLIATIVE_SPECIALIST_SEEN IS NOT NULL AND vd.L_PALLIATIVE_SPECIALIST_SEEN IS NULL) THEN 1 ELSE 0 END
					,GERM_CELL_NON_CNS_ID_Diff								= CASE WHEN mainref.GERM_CELL_NON_CNS_ID != vd.GERM_CELL_NON_CNS_ID OR (mainref.GERM_CELL_NON_CNS_ID IS NULL AND vd.GERM_CELL_NON_CNS_ID IS NOT NULL) OR (mainref.GERM_CELL_NON_CNS_ID IS NOT NULL AND vd.GERM_CELL_NON_CNS_ID IS NULL) THEN 1 ELSE 0 END
					,RECURRENCE_CANCER_SITE_ID_Diff							= CASE WHEN mainref.RECURRENCE_CANCER_SITE_ID != vd.RECURRENCE_CANCER_SITE_ID OR (mainref.RECURRENCE_CANCER_SITE_ID IS NULL AND vd.RECURRENCE_CANCER_SITE_ID IS NOT NULL) OR (mainref.RECURRENCE_CANCER_SITE_ID IS NOT NULL AND vd.RECURRENCE_CANCER_SITE_ID IS NULL) THEN 1 ELSE 0 END
					,ICD03_GROUP_Diff										= CASE WHEN mainref.ICD03_GROUP != vd.ICD03_GROUP OR (mainref.ICD03_GROUP IS NULL AND vd.ICD03_GROUP IS NOT NULL) OR (mainref.ICD03_GROUP IS NOT NULL AND vd.ICD03_GROUP IS NULL) THEN 1 ELSE 0 END
					,ICD03_Diff												= CASE WHEN mainref.ICD03 != vd.ICD03 OR (mainref.ICD03 IS NULL AND vd.ICD03 IS NOT NULL) OR (mainref.ICD03 IS NOT NULL AND vd.ICD03 IS NULL) THEN 1 ELSE 0 END
					,L_DATE_DIAGNOSIS_DAHNO_LUCADA_Diff						= CASE WHEN mainref.L_DATE_DIAGNOSIS_DAHNO_LUCADA != vd.L_DATE_DIAGNOSIS_DAHNO_LUCADA OR (mainref.L_DATE_DIAGNOSIS_DAHNO_LUCADA IS NULL AND vd.L_DATE_DIAGNOSIS_DAHNO_LUCADA IS NOT NULL) OR (mainref.L_DATE_DIAGNOSIS_DAHNO_LUCADA IS NOT NULL AND vd.L_DATE_DIAGNOSIS_DAHNO_LUCADA IS NULL) THEN 1 ELSE 0 END
					,L_INDICATOR_CODE_Diff									= CASE WHEN mainref.L_INDICATOR_CODE != vd.L_INDICATOR_CODE OR (mainref.L_INDICATOR_CODE IS NULL AND vd.L_INDICATOR_CODE IS NOT NULL) OR (mainref.L_INDICATOR_CODE IS NOT NULL AND vd.L_INDICATOR_CODE IS NULL) THEN 1 ELSE 0 END
					,PRIMARY_DIAGNOSIS_SUB_COMMENT_Diff						= CASE WHEN mainref.PRIMARY_DIAGNOSIS_SUB_COMMENT != vd.PRIMARY_DIAGNOSIS_SUB_COMMENT OR (mainref.PRIMARY_DIAGNOSIS_SUB_COMMENT IS NULL AND vd.PRIMARY_DIAGNOSIS_SUB_COMMENT IS NOT NULL) OR (mainref.PRIMARY_DIAGNOSIS_SUB_COMMENT IS NOT NULL AND vd.PRIMARY_DIAGNOSIS_SUB_COMMENT IS NULL) THEN 1 ELSE 0 END
					,CONSULTANT_CODE_AT_DIAGNOSIS_Diff						= CASE WHEN mainref.CONSULTANT_CODE_AT_DIAGNOSIS != vd.CONSULTANT_CODE_AT_DIAGNOSIS OR (mainref.CONSULTANT_CODE_AT_DIAGNOSIS IS NULL AND vd.CONSULTANT_CODE_AT_DIAGNOSIS IS NOT NULL) OR (mainref.CONSULTANT_CODE_AT_DIAGNOSIS IS NOT NULL AND vd.CONSULTANT_CODE_AT_DIAGNOSIS IS NULL) THEN 1 ELSE 0 END
					,CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS_Diff				= CASE WHEN mainref.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS != vd.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS OR (mainref.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS IS NULL AND vd.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS IS NOT NULL) OR (mainref.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS IS NOT NULL AND vd.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS IS NULL) THEN 1 ELSE 0 END
					,FETOPROTEIN_Diff										= CASE WHEN mainref.FETOPROTEIN != vd.FETOPROTEIN OR (mainref.FETOPROTEIN IS NULL AND vd.FETOPROTEIN IS NOT NULL) OR (mainref.FETOPROTEIN IS NOT NULL AND vd.FETOPROTEIN IS NULL) THEN 1 ELSE 0 END
					,GONADOTROPIN_Diff										= CASE WHEN mainref.GONADOTROPIN != vd.GONADOTROPIN OR (mainref.GONADOTROPIN IS NULL AND vd.GONADOTROPIN IS NOT NULL) OR (mainref.GONADOTROPIN IS NOT NULL AND vd.GONADOTROPIN IS NULL) THEN 1 ELSE 0 END
					,GONADOTROPIN_SERUM_Diff								= CASE WHEN mainref.GONADOTROPIN_SERUM != vd.GONADOTROPIN_SERUM OR (mainref.GONADOTROPIN_SERUM IS NULL AND vd.GONADOTROPIN_SERUM IS NOT NULL) OR (mainref.GONADOTROPIN_SERUM IS NOT NULL AND vd.GONADOTROPIN_SERUM IS NULL) THEN 1 ELSE 0 END
					,FETOPROTEIN_SERUM_Diff									= CASE WHEN mainref.FETOPROTEIN_SERUM != vd.FETOPROTEIN_SERUM OR (mainref.FETOPROTEIN_SERUM IS NULL AND vd.FETOPROTEIN_SERUM IS NOT NULL) OR (mainref.FETOPROTEIN_SERUM IS NOT NULL AND vd.FETOPROTEIN_SERUM IS NULL) THEN 1 ELSE 0 END
					,SARCOMA_TUMOUR_SITE_BONE_Diff							= CASE WHEN mainref.SARCOMA_TUMOUR_SITE_BONE != vd.SARCOMA_TUMOUR_SITE_BONE OR (mainref.SARCOMA_TUMOUR_SITE_BONE IS NULL AND vd.SARCOMA_TUMOUR_SITE_BONE IS NOT NULL) OR (mainref.SARCOMA_TUMOUR_SITE_BONE IS NOT NULL AND vd.SARCOMA_TUMOUR_SITE_BONE IS NULL) THEN 1 ELSE 0 END
					,SARCOMA_TUMOUR_SITE_SOFT_TISSUE_Diff					= CASE WHEN mainref.SARCOMA_TUMOUR_SITE_SOFT_TISSUE != vd.SARCOMA_TUMOUR_SITE_SOFT_TISSUE OR (mainref.SARCOMA_TUMOUR_SITE_SOFT_TISSUE IS NULL AND vd.SARCOMA_TUMOUR_SITE_SOFT_TISSUE IS NOT NULL) OR (mainref.SARCOMA_TUMOUR_SITE_SOFT_TISSUE IS NOT NULL AND vd.SARCOMA_TUMOUR_SITE_SOFT_TISSUE IS NULL) THEN 1 ELSE 0 END
					,SARCOMA_TUMOUR_SUBSITE_BONE_Diff						= CASE WHEN mainref.SARCOMA_TUMOUR_SUBSITE_BONE != vd.SARCOMA_TUMOUR_SUBSITE_BONE OR (mainref.SARCOMA_TUMOUR_SUBSITE_BONE IS NULL AND vd.SARCOMA_TUMOUR_SUBSITE_BONE IS NOT NULL) OR (mainref.SARCOMA_TUMOUR_SUBSITE_BONE IS NOT NULL AND vd.SARCOMA_TUMOUR_SUBSITE_BONE IS NULL) THEN 1 ELSE 0 END
					,SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE_Diff				= CASE WHEN mainref.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE != vd.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE OR (mainref.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE IS NULL AND vd.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE IS NOT NULL) OR (mainref.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE IS NOT NULL AND vd.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE IS NULL) THEN 1 ELSE 0 END
					,FIRST_APPT_TIME_Diff									= CASE WHEN mainref.FIRST_APPT_TIME != vd.FIRST_APPT_TIME OR (mainref.FIRST_APPT_TIME IS NULL AND vd.FIRST_APPT_TIME IS NOT NULL) OR (mainref.FIRST_APPT_TIME IS NOT NULL AND vd.FIRST_APPT_TIME IS NULL) THEN 1 ELSE 0 END
					,TRANSFER_REASON_Diff									= CASE WHEN mainref.TRANSFER_REASON != vd.TRANSFER_REASON OR (mainref.TRANSFER_REASON IS NULL AND vd.TRANSFER_REASON IS NOT NULL) OR (mainref.TRANSFER_REASON IS NOT NULL AND vd.TRANSFER_REASON IS NULL) THEN 1 ELSE 0 END
					,DATE_NEW_REFERRAL_Diff									= CASE WHEN mainref.DATE_NEW_REFERRAL != vd.DATE_NEW_REFERRAL OR (mainref.DATE_NEW_REFERRAL IS NULL AND vd.DATE_NEW_REFERRAL IS NOT NULL) OR (mainref.DATE_NEW_REFERRAL IS NOT NULL AND vd.DATE_NEW_REFERRAL IS NULL) THEN 1 ELSE 0 END
					,TUMOUR_SITE_NEW_Diff									= CASE WHEN mainref.TUMOUR_SITE_NEW != vd.TUMOUR_SITE_NEW OR (mainref.TUMOUR_SITE_NEW IS NULL AND vd.TUMOUR_SITE_NEW IS NOT NULL) OR (mainref.TUMOUR_SITE_NEW IS NOT NULL AND vd.TUMOUR_SITE_NEW IS NULL) THEN 1 ELSE 0 END
					,DATE_TRANSFER_ACTIONED_Diff							= CASE WHEN mainref.DATE_TRANSFER_ACTIONED != vd.DATE_TRANSFER_ACTIONED OR (mainref.DATE_TRANSFER_ACTIONED IS NULL AND vd.DATE_TRANSFER_ACTIONED IS NOT NULL) OR (mainref.DATE_TRANSFER_ACTIONED IS NOT NULL AND vd.DATE_TRANSFER_ACTIONED IS NULL) THEN 1 ELSE 0 END
					,SOURCE_CARE_ID_Diff									= CASE WHEN mainref.SOURCE_CARE_ID != vd.SOURCE_CARE_ID OR (mainref.SOURCE_CARE_ID IS NULL AND vd.SOURCE_CARE_ID IS NOT NULL) OR (mainref.SOURCE_CARE_ID IS NOT NULL AND vd.SOURCE_CARE_ID IS NULL) THEN 1 ELSE 0 END
					,ADT_REF_ID_Diff										= CASE WHEN mainref.ADT_REF_ID != vd.ADT_REF_ID OR (mainref.ADT_REF_ID IS NULL AND vd.ADT_REF_ID IS NOT NULL) OR (mainref.ADT_REF_ID IS NOT NULL AND vd.ADT_REF_ID IS NULL) THEN 1 ELSE 0 END
					,ACTION_ID_Diff											= CASE WHEN mainref.ACTION_ID != vd.ACTION_ID OR (mainref.ACTION_ID IS NULL AND vd.ACTION_ID IS NOT NULL) OR (mainref.ACTION_ID IS NOT NULL AND vd.ACTION_ID IS NULL) THEN 1 ELSE 0 END
					,DIAGNOSIS_ACTION_ID_Diff								= CASE WHEN mainref.DIAGNOSIS_ACTION_ID != vd.DIAGNOSIS_ACTION_ID OR (mainref.DIAGNOSIS_ACTION_ID IS NULL AND vd.DIAGNOSIS_ACTION_ID IS NOT NULL) OR (mainref.DIAGNOSIS_ACTION_ID IS NOT NULL AND vd.DIAGNOSIS_ACTION_ID IS NULL) THEN 1 ELSE 0 END
					,ORIGINAL_SOURCE_CARE_ID_Diff							= CASE WHEN mainref.ORIGINAL_SOURCE_CARE_ID != vd.ORIGINAL_SOURCE_CARE_ID OR (mainref.ORIGINAL_SOURCE_CARE_ID IS NULL AND vd.ORIGINAL_SOURCE_CARE_ID IS NOT NULL) OR (mainref.ORIGINAL_SOURCE_CARE_ID IS NOT NULL AND vd.ORIGINAL_SOURCE_CARE_ID IS NULL) THEN 1 ELSE 0 END
					,NON_CANCER_DIAGNOSIS_CHAPTER_Diff						= CASE WHEN mainref.NON_CANCER_DIAGNOSIS_CHAPTER != vd.NON_CANCER_DIAGNOSIS_CHAPTER OR (mainref.NON_CANCER_DIAGNOSIS_CHAPTER IS NULL AND vd.NON_CANCER_DIAGNOSIS_CHAPTER IS NOT NULL) OR (mainref.NON_CANCER_DIAGNOSIS_CHAPTER IS NOT NULL AND vd.NON_CANCER_DIAGNOSIS_CHAPTER IS NULL) THEN 1 ELSE 0 END
					,NON_CANCER_DIAGNOSIS_GROUP_Diff						= CASE WHEN mainref.NON_CANCER_DIAGNOSIS_GROUP != vd.NON_CANCER_DIAGNOSIS_GROUP OR (mainref.NON_CANCER_DIAGNOSIS_GROUP IS NULL AND vd.NON_CANCER_DIAGNOSIS_GROUP IS NOT NULL) OR (mainref.NON_CANCER_DIAGNOSIS_GROUP IS NOT NULL AND vd.NON_CANCER_DIAGNOSIS_GROUP IS NULL) THEN 1 ELSE 0 END
					,NON_CANCER_DIAGNOSIS_CODE_Diff							= CASE WHEN mainref.NON_CANCER_DIAGNOSIS_CODE != vd.NON_CANCER_DIAGNOSIS_CODE OR (mainref.NON_CANCER_DIAGNOSIS_CODE IS NULL AND vd.NON_CANCER_DIAGNOSIS_CODE IS NOT NULL) OR (mainref.NON_CANCER_DIAGNOSIS_CODE IS NOT NULL AND vd.NON_CANCER_DIAGNOSIS_CODE IS NULL) THEN 1 ELSE 0 END
					,TNM_UNKNOWN_Diff										= CASE WHEN mainref.TNM_UNKNOWN != vd.TNM_UNKNOWN OR (mainref.TNM_UNKNOWN IS NULL AND vd.TNM_UNKNOWN IS NOT NULL) OR (mainref.TNM_UNKNOWN IS NOT NULL AND vd.TNM_UNKNOWN IS NULL) THEN 1 ELSE 0 END
					,ReferringPractice_Diff									= CASE WHEN mainref.ReferringPractice != vd.ReferringPractice OR (mainref.ReferringPractice IS NULL AND vd.ReferringPractice IS NOT NULL) OR (mainref.ReferringPractice IS NOT NULL AND vd.ReferringPractice IS NULL) THEN 1 ELSE 0 END
					,ReferringGP_Diff										= CASE WHEN mainref.ReferringGP != vd.ReferringGP OR (mainref.ReferringGP IS NULL AND vd.ReferringGP IS NOT NULL) OR (mainref.ReferringGP IS NOT NULL AND vd.ReferringGP IS NULL) THEN 1 ELSE 0 END
					,ReferringBranch_Diff									= CASE WHEN mainref.ReferringBranch != vd.ReferringBranch OR (mainref.ReferringBranch IS NULL AND vd.ReferringBranch IS NOT NULL) OR (mainref.ReferringBranch IS NOT NULL AND vd.ReferringBranch IS NULL) THEN 1 ELSE 0 END
					,BankedTissue_Diff										= CASE WHEN mainref.BankedTissue != vd.BankedTissue OR (mainref.BankedTissue IS NULL AND vd.BankedTissue IS NOT NULL) OR (mainref.BankedTissue IS NOT NULL AND vd.BankedTissue IS NULL) THEN 1 ELSE 0 END
					,BankedTissueTumour_Diff								= CASE WHEN mainref.BankedTissueTumour != vd.BankedTissueTumour OR (mainref.BankedTissueTumour IS NULL AND vd.BankedTissueTumour IS NOT NULL) OR (mainref.BankedTissueTumour IS NOT NULL AND vd.BankedTissueTumour IS NULL) THEN 1 ELSE 0 END
					,BankedTissueBlood_Diff									= CASE WHEN mainref.BankedTissueBlood != vd.BankedTissueBlood OR (mainref.BankedTissueBlood IS NULL AND vd.BankedTissueBlood IS NOT NULL) OR (mainref.BankedTissueBlood IS NOT NULL AND vd.BankedTissueBlood IS NULL) THEN 1 ELSE 0 END
					,BankedTissueCSF_Diff									= CASE WHEN mainref.BankedTissueCSF != vd.BankedTissueCSF OR (mainref.BankedTissueCSF IS NULL AND vd.BankedTissueCSF IS NOT NULL) OR (mainref.BankedTissueCSF IS NOT NULL AND vd.BankedTissueCSF IS NULL) THEN 1 ELSE 0 END
					,BankedTissueBoneMarrow_Diff							= CASE WHEN mainref.BankedTissueBoneMarrow != vd.BankedTissueBoneMarrow OR (mainref.BankedTissueBoneMarrow IS NULL AND vd.BankedTissueBoneMarrow IS NOT NULL) OR (mainref.BankedTissueBoneMarrow IS NOT NULL AND vd.BankedTissueBoneMarrow IS NULL) THEN 1 ELSE 0 END
					,SNOMed_CT_Diff											= CASE WHEN mainref.SNOMed_CT != vd.SNOMed_CT OR (mainref.SNOMed_CT IS NULL AND vd.SNOMed_CT IS NOT NULL) OR (mainref.SNOMed_CT IS NOT NULL AND vd.SNOMed_CT IS NULL) THEN 1 ELSE 0 END
					,ADT_PLACER_ID_Diff										= CASE WHEN mainref.ADT_PLACER_ID != vd.ADT_PLACER_ID OR (mainref.ADT_PLACER_ID IS NULL AND vd.ADT_PLACER_ID IS NOT NULL) OR (mainref.ADT_PLACER_ID IS NOT NULL AND vd.ADT_PLACER_ID IS NULL) THEN 1 ELSE 0 END
					,SNOMEDCTDiagnosisID_Diff								= CASE WHEN mainref.SNOMEDCTDiagnosisID != vd.SNOMEDCTDiagnosisID OR (mainref.SNOMEDCTDiagnosisID IS NULL AND vd.SNOMEDCTDiagnosisID IS NOT NULL) OR (mainref.SNOMEDCTDiagnosisID IS NOT NULL AND vd.SNOMEDCTDiagnosisID IS NULL) THEN 1 ELSE 0 END
					,FasterDiagnosisOrganisationID_Diff						= CASE WHEN mainref.FasterDiagnosisOrganisationID != vd.FasterDiagnosisOrganisationID OR (mainref.FasterDiagnosisOrganisationID IS NULL AND vd.FasterDiagnosisOrganisationID IS NOT NULL) OR (mainref.FasterDiagnosisOrganisationID IS NOT NULL AND vd.FasterDiagnosisOrganisationID IS NULL) THEN 1 ELSE 0 END
					,FasterDiagnosisCancerSiteOverrideID_Diff				= CASE WHEN mainref.FasterDiagnosisCancerSiteOverrideID != vd.FasterDiagnosisCancerSiteOverrideID OR (mainref.FasterDiagnosisCancerSiteOverrideID IS NULL AND vd.FasterDiagnosisCancerSiteOverrideID IS NOT NULL) OR (mainref.FasterDiagnosisCancerSiteOverrideID IS NOT NULL AND vd.FasterDiagnosisCancerSiteOverrideID IS NULL) THEN 1 ELSE 0 END
					,FasterDiagnosisExclusionDate_Diff						= CASE WHEN mainref.FasterDiagnosisExclusionDate != vd.FasterDiagnosisExclusionDate OR (mainref.FasterDiagnosisExclusionDate IS NULL AND vd.FasterDiagnosisExclusionDate IS NOT NULL) OR (mainref.FasterDiagnosisExclusionDate IS NOT NULL AND vd.FasterDiagnosisExclusionDate IS NULL) THEN 1 ELSE 0 END
					,FasterDiagnosisExclusionReasonID_Diff					= CASE WHEN mainref.FasterDiagnosisExclusionReasonID != vd.FasterDiagnosisExclusionReasonID OR (mainref.FasterDiagnosisExclusionReasonID IS NULL AND vd.FasterDiagnosisExclusionReasonID IS NOT NULL) OR (mainref.FasterDiagnosisExclusionReasonID IS NOT NULL AND vd.FasterDiagnosisExclusionReasonID IS NULL) THEN 1 ELSE 0 END
					,FasterDiagnosisDelayReasonID_Diff						= CASE WHEN mainref.FasterDiagnosisDelayReasonID != vd.FasterDiagnosisDelayReasonID OR (mainref.FasterDiagnosisDelayReasonID IS NULL AND vd.FasterDiagnosisDelayReasonID IS NOT NULL) OR (mainref.FasterDiagnosisDelayReasonID IS NOT NULL AND vd.FasterDiagnosisDelayReasonID IS NULL) THEN 1 ELSE 0 END
					,FasterDiagnosisDelayReasonComments_Diff				= CASE WHEN mainref.FasterDiagnosisDelayReasonComments != vd.FasterDiagnosisDelayReasonComments OR (mainref.FasterDiagnosisDelayReasonComments IS NULL AND vd.FasterDiagnosisDelayReasonComments IS NOT NULL) OR (mainref.FasterDiagnosisDelayReasonComments IS NOT NULL AND vd.FasterDiagnosisDelayReasonComments IS NULL) THEN 1 ELSE 0 END
					,FasterDiagnosisCommunicationMethodID_Diff				= CASE WHEN mainref.FasterDiagnosisCommunicationMethodID != vd.FasterDiagnosisCommunicationMethodID OR (mainref.FasterDiagnosisCommunicationMethodID IS NULL AND vd.FasterDiagnosisCommunicationMethodID IS NOT NULL) OR (mainref.FasterDiagnosisCommunicationMethodID IS NOT NULL AND vd.FasterDiagnosisCommunicationMethodID IS NULL) THEN 1 ELSE 0 END
					,FasterDiagnosisInformingCareProfessionalID_Diff		= CASE WHEN mainref.FasterDiagnosisInformingCareProfessionalID != vd.FasterDiagnosisInformingCareProfessionalID OR (mainref.FasterDiagnosisInformingCareProfessionalID IS NULL AND vd.FasterDiagnosisInformingCareProfessionalID IS NOT NULL) OR (mainref.FasterDiagnosisInformingCareProfessionalID IS NOT NULL AND vd.FasterDiagnosisInformingCareProfessionalID IS NULL) THEN 1 ELSE 0 END
					,FasterDiagnosisOtherCareProfessional_Diff				= CASE WHEN mainref.FasterDiagnosisOtherCareProfessional != vd.FasterDiagnosisOtherCareProfessional OR (mainref.FasterDiagnosisOtherCareProfessional IS NULL AND vd.FasterDiagnosisOtherCareProfessional IS NOT NULL) OR (mainref.FasterDiagnosisOtherCareProfessional IS NOT NULL AND vd.FasterDiagnosisOtherCareProfessional IS NULL) THEN 1 ELSE 0 END
					,FasterDiagnosisOtherCommunicationMethod_Diff			= CASE WHEN mainref.FasterDiagnosisOtherCommunicationMethod != vd.FasterDiagnosisOtherCommunicationMethod OR (mainref.FasterDiagnosisOtherCommunicationMethod IS NULL AND vd.FasterDiagnosisOtherCommunicationMethod IS NOT NULL) OR (mainref.FasterDiagnosisOtherCommunicationMethod IS NOT NULL AND vd.FasterDiagnosisOtherCommunicationMethod IS NULL) THEN 1 ELSE 0 END
					,NonPrimaryPathwayOptionsID_Diff						= CASE WHEN mainref.NonPrimaryPathwayOptionsID != vd.NonPrimaryPathwayOptionsID OR (mainref.NonPrimaryPathwayOptionsID IS NULL AND vd.NonPrimaryPathwayOptionsID IS NOT NULL) OR (mainref.NonPrimaryPathwayOptionsID IS NOT NULL AND vd.NonPrimaryPathwayOptionsID IS NULL) THEN 1 ELSE 0 END
					,DiagnosisUncertainty_Diff								= CASE WHEN mainref.DiagnosisUncertainty != vd.DiagnosisUncertainty OR (mainref.DiagnosisUncertainty IS NULL AND vd.DiagnosisUncertainty IS NOT NULL) OR (mainref.DiagnosisUncertainty IS NOT NULL AND vd.DiagnosisUncertainty IS NULL) THEN 1 ELSE 0 END
					,TNMOrganisation_Diff									= CASE WHEN mainref.TNMOrganisation != vd.TNMOrganisation OR (mainref.TNMOrganisation IS NULL AND vd.TNMOrganisation IS NOT NULL) OR (mainref.TNMOrganisation IS NOT NULL AND vd.TNMOrganisation IS NULL) THEN 1 ELSE 0 END
					,FasterDiagnosisTargetRCComments_Diff					= CASE WHEN mainref.FasterDiagnosisTargetRCComments != vd.FasterDiagnosisTargetRCComments OR (mainref.FasterDiagnosisTargetRCComments IS NULL AND vd.FasterDiagnosisTargetRCComments IS NOT NULL) OR (mainref.FasterDiagnosisTargetRCComments IS NOT NULL AND vd.FasterDiagnosisTargetRCComments IS NULL) THEN 1 ELSE 0 END
					,FasterDiagnosisEndRCComments_Diff						= CASE WHEN mainref.FasterDiagnosisEndRCComments != vd.FasterDiagnosisEndRCComments OR (mainref.FasterDiagnosisEndRCComments IS NULL AND vd.FasterDiagnosisEndRCComments IS NOT NULL) OR (mainref.FasterDiagnosisEndRCComments IS NOT NULL AND vd.FasterDiagnosisEndRCComments IS NULL) THEN 1 ELSE 0 END
					,TNMOrganisation_Integrated_Diff						= CASE WHEN mainref.TNMOrganisation_Integrated != vd.TNMOrganisation_Integrated OR (mainref.TNMOrganisation_Integrated IS NULL AND vd.TNMOrganisation_Integrated IS NOT NULL) OR (mainref.TNMOrganisation_Integrated IS NOT NULL AND vd.TNMOrganisation_Integrated IS NULL) THEN 1 ELSE 0 END
					,LDHValue_Diff											= CASE WHEN mainref.LDHValue != vd.LDHValue OR (mainref.LDHValue IS NULL AND vd.LDHValue IS NOT NULL) OR (mainref.LDHValue IS NOT NULL AND vd.LDHValue IS NULL) THEN 1 ELSE 0 END
					,BankedTissueUrine_Diff									= CASE WHEN mainref.BankedTissueUrine != vd.BankedTissueUrine OR (mainref.BankedTissueUrine IS NULL AND vd.BankedTissueUrine IS NOT NULL) OR (mainref.BankedTissueUrine IS NOT NULL AND vd.BankedTissueUrine IS NULL) THEN 1 ELSE 0 END
					,SubsiteID_Diff											= CASE WHEN mainref.SubsiteID != vd.SubsiteID OR (mainref.SubsiteID IS NULL AND vd.SubsiteID IS NOT NULL) OR (mainref.SubsiteID IS NOT NULL AND vd.SubsiteID IS NULL) THEN 1 ELSE 0 END
					,PredictedBreachStatus_Diff								= CASE WHEN mainref.PredictedBreachStatus != vd.PredictedBreachStatus OR (mainref.PredictedBreachStatus IS NULL AND vd.PredictedBreachStatus IS NOT NULL) OR (mainref.PredictedBreachStatus IS NOT NULL AND vd.PredictedBreachStatus IS NULL) THEN 1 ELSE 0 END
					,RMRefID_Diff											= CASE WHEN mainref.RMRefID != vd.RMRefID OR (mainref.RMRefID IS NULL AND vd.RMRefID IS NOT NULL) OR (mainref.RMRefID IS NOT NULL AND vd.RMRefID IS NULL) THEN 1 ELSE 0 END
					,TertiaryReferralKey_Diff								= CASE WHEN mainref.TertiaryReferralKey != vd.TertiaryReferralKey OR (mainref.TertiaryReferralKey IS NULL AND vd.TertiaryReferralKey IS NOT NULL) OR (mainref.TertiaryReferralKey IS NOT NULL AND vd.TertiaryReferralKey IS NULL) THEN 1 ELSE 0 END
					,ClinicalTLetter_Diff									= CASE WHEN mainref.ClinicalTLetter != vd.ClinicalTLetter OR (mainref.ClinicalTLetter IS NULL AND vd.ClinicalTLetter IS NOT NULL) OR (mainref.ClinicalTLetter IS NOT NULL AND vd.ClinicalTLetter IS NULL) THEN 1 ELSE 0 END
					,ClinicalNLetter_Diff									= CASE WHEN mainref.ClinicalNLetter != vd.ClinicalNLetter OR (mainref.ClinicalNLetter IS NULL AND vd.ClinicalNLetter IS NOT NULL) OR (mainref.ClinicalNLetter IS NOT NULL AND vd.ClinicalNLetter IS NULL) THEN 1 ELSE 0 END
					,ClinicalMLetter_Diff									= CASE WHEN mainref.ClinicalMLetter != vd.ClinicalMLetter OR (mainref.ClinicalMLetter IS NULL AND vd.ClinicalMLetter IS NOT NULL) OR (mainref.ClinicalMLetter IS NOT NULL AND vd.ClinicalMLetter IS NULL) THEN 1 ELSE 0 END
					,PathologicalTLetter_Diff								= CASE WHEN mainref.PathologicalTLetter != vd.PathologicalTLetter OR (mainref.PathologicalTLetter IS NULL AND vd.PathologicalTLetter IS NOT NULL) OR (mainref.PathologicalTLetter IS NOT NULL AND vd.PathologicalTLetter IS NULL) THEN 1 ELSE 0 END
					,PathologicalNLetter_Diff								= CASE WHEN mainref.PathologicalNLetter != vd.PathologicalNLetter OR (mainref.PathologicalNLetter IS NULL AND vd.PathologicalNLetter IS NOT NULL) OR (mainref.PathologicalNLetter IS NOT NULL AND vd.PathologicalNLetter IS NULL) THEN 1 ELSE 0 END
					,PathologicalMLetter_Diff								= CASE WHEN mainref.PathologicalMLetter != vd.PathologicalMLetter OR (mainref.PathologicalMLetter IS NULL AND vd.PathologicalMLetter IS NOT NULL) OR (mainref.PathologicalMLetter IS NOT NULL AND vd.PathologicalMLetter IS NULL) THEN 1 ELSE 0 END
					,FDPlannedInterval_Diff									= CASE WHEN mainref.FDPlannedInterval != vd.FDPlannedInterval OR (mainref.FDPlannedInterval IS NULL AND vd.FDPlannedInterval IS NOT NULL) OR (mainref.FDPlannedInterval IS NOT NULL AND vd.FDPlannedInterval IS NULL) THEN 1 ELSE 0 END
					,LabReportDate_Diff										= CASE WHEN mainref.LabReportDate != vd.LabReportDate OR (mainref.LabReportDate IS NULL AND vd.LabReportDate IS NOT NULL) OR (mainref.LabReportDate IS NOT NULL AND vd.LabReportDate IS NULL) THEN 1 ELSE 0 END
					,LabReportOrgID_Diff									= CASE WHEN mainref.LabReportOrgID != vd.LabReportOrgID OR (mainref.LabReportOrgID IS NULL AND vd.LabReportOrgID IS NOT NULL) OR (mainref.LabReportOrgID IS NOT NULL AND vd.LabReportOrgID IS NULL) THEN 1 ELSE 0 END
					,ReferralRoute_Diff										= CASE WHEN mainref.ReferralRoute != vd.ReferralRoute OR (mainref.ReferralRoute IS NULL AND vd.ReferralRoute IS NOT NULL) OR (mainref.ReferralRoute IS NOT NULL AND vd.ReferralRoute IS NULL) THEN 1 ELSE 0 END
					,ReferralOtherRoute_Diff								= CASE WHEN mainref.ReferralOtherRoute != vd.ReferralOtherRoute OR (mainref.ReferralOtherRoute IS NULL AND vd.ReferralOtherRoute IS NOT NULL) OR (mainref.ReferralOtherRoute IS NOT NULL AND vd.ReferralOtherRoute IS NULL) THEN 1 ELSE 0 END
					,RelapseMorphology_Diff									= CASE WHEN mainref.RelapseMorphology != vd.RelapseMorphology OR (mainref.RelapseMorphology IS NULL AND vd.RelapseMorphology IS NOT NULL) OR (mainref.RelapseMorphology IS NOT NULL AND vd.RelapseMorphology IS NULL) THEN 1 ELSE 0 END
					,RelapseFlow_Diff										= CASE WHEN mainref.RelapseFlow != vd.RelapseFlow OR (mainref.RelapseFlow IS NULL AND vd.RelapseFlow IS NOT NULL) OR (mainref.RelapseFlow IS NOT NULL AND vd.RelapseFlow IS NULL) THEN 1 ELSE 0 END
					,RelapseMolecular_Diff									= CASE WHEN mainref.RelapseMolecular != vd.RelapseMolecular OR (mainref.RelapseMolecular IS NULL AND vd.RelapseMolecular IS NOT NULL) OR (mainref.RelapseMolecular IS NOT NULL AND vd.RelapseMolecular IS NULL) THEN 1 ELSE 0 END
					,RelapseClinicalExamination_Diff						= CASE WHEN mainref.RelapseClinicalExamination != vd.RelapseClinicalExamination OR (mainref.RelapseClinicalExamination IS NULL AND vd.RelapseClinicalExamination IS NOT NULL) OR (mainref.RelapseClinicalExamination IS NOT NULL AND vd.RelapseClinicalExamination IS NULL) THEN 1 ELSE 0 END
					,RelapseOther_Diff										= CASE WHEN mainref.RelapseOther != vd.RelapseOther OR (mainref.RelapseOther IS NULL AND vd.RelapseOther IS NOT NULL) OR (mainref.RelapseOther IS NOT NULL AND vd.RelapseOther IS NULL) THEN 1 ELSE 0 END
					,RapidDiagnostic_Diff									= CASE WHEN mainref.RapidDiagnostic != vd.RapidDiagnostic OR (mainref.RapidDiagnostic IS NULL AND vd.RapidDiagnostic IS NOT NULL) OR (mainref.RapidDiagnostic IS NOT NULL AND vd.RapidDiagnostic IS NULL) THEN 1 ELSE 0 END
					,PrimaryReferralFlag_Diff								= CASE WHEN mainref.PrimaryReferralFlag != vd.PrimaryReferralFlag OR (mainref.PrimaryReferralFlag IS NULL AND vd.PrimaryReferralFlag IS NOT NULL) OR (mainref.PrimaryReferralFlag IS NOT NULL AND vd.PrimaryReferralFlag IS NULL) THEN 1 ELSE 0 END
					,OtherAssessedBy_Diff									= CASE WHEN mainref.OtherAssessedBy != vd.OtherAssessedBy OR (mainref.OtherAssessedBy IS NULL AND vd.OtherAssessedBy IS NOT NULL) OR (mainref.OtherAssessedBy IS NOT NULL AND vd.OtherAssessedBy IS NULL) THEN 1 ELSE 0 END
					,SharedBreach_Diff										= CASE WHEN mainref.SharedBreach != vd.SharedBreach OR (mainref.SharedBreach IS NULL AND vd.SharedBreach IS NOT NULL) OR (mainref.SharedBreach IS NOT NULL AND vd.SharedBreach IS NULL) THEN 1 ELSE 0 END
					,PredictedBreachYear_Diff								= CASE WHEN mainref.PredictedBreachYear != vd.PredictedBreachYear OR (mainref.PredictedBreachYear IS NULL AND vd.PredictedBreachYear IS NOT NULL) OR (mainref.PredictedBreachYear IS NOT NULL AND vd.PredictedBreachYear IS NULL) THEN 1 ELSE 0 END
					,PredictedBreachMonth_Diff								= CASE WHEN mainref.PredictedBreachMonth != vd.PredictedBreachMonth OR (mainref.PredictedBreachMonth IS NULL AND vd.PredictedBreachMonth IS NOT NULL) OR (mainref.PredictedBreachMonth IS NOT NULL AND vd.PredictedBreachMonth IS NULL) THEN 1 ELSE 0 END

		INTO		Merge_R_Compare.DedupeChangedRefs_work
		FROM		#tblMAIN_REFERRALS_tblValidatedData vd
		INNER JOIN	LocalConfig.tblMAIN_REFERRALS mainref
														ON	vd.SrcSys = mainref.SrcSysID
														AND	vd.Src_UID = mainref.CARE_ID
		WHERE		mainref.PATIENT_ID != vd.PATIENT_ID OR (mainref.PATIENT_ID IS NULL AND vd.PATIENT_ID IS NOT NULL) OR (mainref.PATIENT_ID IS NOT NULL AND vd.PATIENT_ID IS NULL)
		OR			mainref.TEMP_ID != vd.TEMP_ID OR (mainref.TEMP_ID IS NULL AND vd.TEMP_ID IS NOT NULL) OR (mainref.TEMP_ID IS NOT NULL AND vd.TEMP_ID IS NULL)
		OR			mainref.L_CANCER_SITE != vd.L_CANCER_SITE OR (mainref.L_CANCER_SITE IS NULL AND vd.L_CANCER_SITE IS NOT NULL) OR (mainref.L_CANCER_SITE IS NOT NULL AND vd.L_CANCER_SITE IS NULL)
		OR			mainref.N2_1_REFERRAL_SOURCE != vd.N2_1_REFERRAL_SOURCE OR (mainref.N2_1_REFERRAL_SOURCE IS NULL AND vd.N2_1_REFERRAL_SOURCE IS NOT NULL) OR (mainref.N2_1_REFERRAL_SOURCE IS NOT NULL AND vd.N2_1_REFERRAL_SOURCE IS NULL)
		OR			mainref.N2_2_ORG_CODE_REF != vd.N2_2_ORG_CODE_REF OR (mainref.N2_2_ORG_CODE_REF IS NULL AND vd.N2_2_ORG_CODE_REF IS NOT NULL) OR (mainref.N2_2_ORG_CODE_REF IS NOT NULL AND vd.N2_2_ORG_CODE_REF IS NULL)
		OR			mainref.N2_3_REFERRER_CODE != vd.N2_3_REFERRER_CODE OR (mainref.N2_3_REFERRER_CODE IS NULL AND vd.N2_3_REFERRER_CODE IS NOT NULL) OR (mainref.N2_3_REFERRER_CODE IS NOT NULL AND vd.N2_3_REFERRER_CODE IS NULL)
		OR			mainref.N2_4_PRIORITY_TYPE != vd.N2_4_PRIORITY_TYPE OR (mainref.N2_4_PRIORITY_TYPE IS NULL AND vd.N2_4_PRIORITY_TYPE IS NOT NULL) OR (mainref.N2_4_PRIORITY_TYPE IS NOT NULL AND vd.N2_4_PRIORITY_TYPE IS NULL)
		OR			mainref.N2_5_DECISION_DATE != vd.N2_5_DECISION_DATE OR (mainref.N2_5_DECISION_DATE IS NULL AND vd.N2_5_DECISION_DATE IS NOT NULL) OR (mainref.N2_5_DECISION_DATE IS NOT NULL AND vd.N2_5_DECISION_DATE IS NULL)
		OR			mainref.N2_6_RECEIPT_DATE != vd.N2_6_RECEIPT_DATE OR (mainref.N2_6_RECEIPT_DATE IS NULL AND vd.N2_6_RECEIPT_DATE IS NOT NULL) OR (mainref.N2_6_RECEIPT_DATE IS NOT NULL AND vd.N2_6_RECEIPT_DATE IS NULL)
		OR			mainref.N2_7_CONSULTANT != vd.N2_7_CONSULTANT OR (mainref.N2_7_CONSULTANT IS NULL AND vd.N2_7_CONSULTANT IS NOT NULL) OR (mainref.N2_7_CONSULTANT IS NOT NULL AND vd.N2_7_CONSULTANT IS NULL)
		OR			mainref.N2_8_SPECIALTY != vd.N2_8_SPECIALTY OR (mainref.N2_8_SPECIALTY IS NULL AND vd.N2_8_SPECIALTY IS NOT NULL) OR (mainref.N2_8_SPECIALTY IS NOT NULL AND vd.N2_8_SPECIALTY IS NULL)
		OR			mainref.N2_9_FIRST_SEEN_DATE != vd.N2_9_FIRST_SEEN_DATE OR (mainref.N2_9_FIRST_SEEN_DATE IS NULL AND vd.N2_9_FIRST_SEEN_DATE IS NOT NULL) OR (mainref.N2_9_FIRST_SEEN_DATE IS NOT NULL AND vd.N2_9_FIRST_SEEN_DATE IS NULL)
		OR			mainref.N1_3_ORG_CODE_SEEN != vd.N1_3_ORG_CODE_SEEN OR (mainref.N1_3_ORG_CODE_SEEN IS NULL AND vd.N1_3_ORG_CODE_SEEN IS NOT NULL) OR (mainref.N1_3_ORG_CODE_SEEN IS NOT NULL AND vd.N1_3_ORG_CODE_SEEN IS NULL)
		OR			mainref.N2_10_FIRST_SEEN_DELAY != vd.N2_10_FIRST_SEEN_DELAY OR (mainref.N2_10_FIRST_SEEN_DELAY IS NULL AND vd.N2_10_FIRST_SEEN_DELAY IS NOT NULL) OR (mainref.N2_10_FIRST_SEEN_DELAY IS NOT NULL AND vd.N2_10_FIRST_SEEN_DELAY IS NULL)
		OR			mainref.N2_12_CANCER_TYPE != vd.N2_12_CANCER_TYPE OR (mainref.N2_12_CANCER_TYPE IS NULL AND vd.N2_12_CANCER_TYPE IS NOT NULL) OR (mainref.N2_12_CANCER_TYPE IS NOT NULL AND vd.N2_12_CANCER_TYPE IS NULL)
		OR			mainref.N2_13_CANCER_STATUS != vd.N2_13_CANCER_STATUS OR (mainref.N2_13_CANCER_STATUS IS NULL AND vd.N2_13_CANCER_STATUS IS NOT NULL) OR (mainref.N2_13_CANCER_STATUS IS NOT NULL AND vd.N2_13_CANCER_STATUS IS NULL)
		OR			mainref.L_FIRST_APPOINTMENT != vd.L_FIRST_APPOINTMENT OR (mainref.L_FIRST_APPOINTMENT IS NULL AND vd.L_FIRST_APPOINTMENT IS NOT NULL) OR (mainref.L_FIRST_APPOINTMENT IS NOT NULL AND vd.L_FIRST_APPOINTMENT IS NULL)
		OR			mainref.L_CANCELLED_DATE != vd.L_CANCELLED_DATE OR (mainref.L_CANCELLED_DATE IS NULL AND vd.L_CANCELLED_DATE IS NOT NULL) OR (mainref.L_CANCELLED_DATE IS NOT NULL AND vd.L_CANCELLED_DATE IS NULL)
		OR			mainref.N2_14_ADJ_TIME != vd.N2_14_ADJ_TIME OR (mainref.N2_14_ADJ_TIME IS NULL AND vd.N2_14_ADJ_TIME IS NOT NULL) OR (mainref.N2_14_ADJ_TIME IS NOT NULL AND vd.N2_14_ADJ_TIME IS NULL)
		OR			mainref.N2_15_ADJ_REASON != vd.N2_15_ADJ_REASON OR (mainref.N2_15_ADJ_REASON IS NULL AND vd.N2_15_ADJ_REASON IS NOT NULL) OR (mainref.N2_15_ADJ_REASON IS NOT NULL AND vd.N2_15_ADJ_REASON IS NULL)
		OR			mainref.L_REFERRAL_METHOD != vd.L_REFERRAL_METHOD OR (mainref.L_REFERRAL_METHOD IS NULL AND vd.L_REFERRAL_METHOD IS NOT NULL) OR (mainref.L_REFERRAL_METHOD IS NOT NULL AND vd.L_REFERRAL_METHOD IS NULL)
		OR			mainref.N2_16_OP_REFERRAL != vd.N2_16_OP_REFERRAL OR (mainref.N2_16_OP_REFERRAL IS NULL AND vd.N2_16_OP_REFERRAL IS NOT NULL) OR (mainref.N2_16_OP_REFERRAL IS NOT NULL AND vd.N2_16_OP_REFERRAL IS NULL)
		OR			mainref.L_SPECIALIST_DATE != vd.L_SPECIALIST_DATE OR (mainref.L_SPECIALIST_DATE IS NULL AND vd.L_SPECIALIST_DATE IS NOT NULL) OR (mainref.L_SPECIALIST_DATE IS NOT NULL AND vd.L_SPECIALIST_DATE IS NULL)
		OR			mainref.L_ORG_CODE_SPECIALIST != vd.L_ORG_CODE_SPECIALIST OR (mainref.L_ORG_CODE_SPECIALIST IS NULL AND vd.L_ORG_CODE_SPECIALIST IS NOT NULL) OR (mainref.L_ORG_CODE_SPECIALIST IS NOT NULL AND vd.L_ORG_CODE_SPECIALIST IS NULL)
		OR			mainref.L_SPECIALIST_SEEN_DATE != vd.L_SPECIALIST_SEEN_DATE OR (mainref.L_SPECIALIST_SEEN_DATE IS NULL AND vd.L_SPECIALIST_SEEN_DATE IS NOT NULL) OR (mainref.L_SPECIALIST_SEEN_DATE IS NOT NULL AND vd.L_SPECIALIST_SEEN_DATE IS NULL)
		OR			mainref.N1_3_ORG_CODE_SPEC_SEEN != vd.N1_3_ORG_CODE_SPEC_SEEN OR (mainref.N1_3_ORG_CODE_SPEC_SEEN IS NULL AND vd.N1_3_ORG_CODE_SPEC_SEEN IS NOT NULL) OR (mainref.N1_3_ORG_CODE_SPEC_SEEN IS NOT NULL AND vd.N1_3_ORG_CODE_SPEC_SEEN IS NULL)
		OR			mainref.N_UPGRADE_DATE != vd.N_UPGRADE_DATE OR (mainref.N_UPGRADE_DATE IS NULL AND vd.N_UPGRADE_DATE IS NOT NULL) OR (mainref.N_UPGRADE_DATE IS NOT NULL AND vd.N_UPGRADE_DATE IS NULL)
		OR			mainref.N_UPGRADE_ORG_CODE != vd.N_UPGRADE_ORG_CODE OR (mainref.N_UPGRADE_ORG_CODE IS NULL AND vd.N_UPGRADE_ORG_CODE IS NOT NULL) OR (mainref.N_UPGRADE_ORG_CODE IS NOT NULL AND vd.N_UPGRADE_ORG_CODE IS NULL)
		OR			mainref.L_UPGRADE_WHEN != vd.L_UPGRADE_WHEN OR (mainref.L_UPGRADE_WHEN IS NULL AND vd.L_UPGRADE_WHEN IS NOT NULL) OR (mainref.L_UPGRADE_WHEN IS NOT NULL AND vd.L_UPGRADE_WHEN IS NULL)
		OR			mainref.L_UPGRADE_WHO != vd.L_UPGRADE_WHO OR (mainref.L_UPGRADE_WHO IS NULL AND vd.L_UPGRADE_WHO IS NOT NULL) OR (mainref.L_UPGRADE_WHO IS NOT NULL AND vd.L_UPGRADE_WHO IS NULL)
		OR			mainref.N4_1_DIAGNOSIS_DATE != vd.N4_1_DIAGNOSIS_DATE OR (mainref.N4_1_DIAGNOSIS_DATE IS NULL AND vd.N4_1_DIAGNOSIS_DATE IS NOT NULL) OR (mainref.N4_1_DIAGNOSIS_DATE IS NOT NULL AND vd.N4_1_DIAGNOSIS_DATE IS NULL)
		OR			mainref.L_DIAGNOSIS != vd.L_DIAGNOSIS OR (mainref.L_DIAGNOSIS IS NULL AND vd.L_DIAGNOSIS IS NOT NULL) OR (mainref.L_DIAGNOSIS IS NOT NULL AND vd.L_DIAGNOSIS IS NULL)
		OR			mainref.N4_2_DIAGNOSIS_CODE != vd.N4_2_DIAGNOSIS_CODE OR (mainref.N4_2_DIAGNOSIS_CODE IS NULL AND vd.N4_2_DIAGNOSIS_CODE IS NOT NULL) OR (mainref.N4_2_DIAGNOSIS_CODE IS NOT NULL AND vd.N4_2_DIAGNOSIS_CODE IS NULL)
		OR			mainref.L_ORG_CODE_DIAGNOSIS != vd.L_ORG_CODE_DIAGNOSIS OR (mainref.L_ORG_CODE_DIAGNOSIS IS NULL AND vd.L_ORG_CODE_DIAGNOSIS IS NOT NULL) OR (mainref.L_ORG_CODE_DIAGNOSIS IS NOT NULL AND vd.L_ORG_CODE_DIAGNOSIS IS NULL)
		OR			mainref.L_PT_INFORMED_DATE != vd.L_PT_INFORMED_DATE OR (mainref.L_PT_INFORMED_DATE IS NULL AND vd.L_PT_INFORMED_DATE IS NOT NULL) OR (mainref.L_PT_INFORMED_DATE IS NOT NULL AND vd.L_PT_INFORMED_DATE IS NULL)
		OR			mainref.L_OTHER_DIAG_DATE != vd.L_OTHER_DIAG_DATE OR (mainref.L_OTHER_DIAG_DATE IS NULL AND vd.L_OTHER_DIAG_DATE IS NOT NULL) OR (mainref.L_OTHER_DIAG_DATE IS NOT NULL AND vd.L_OTHER_DIAG_DATE IS NULL)
		OR			mainref.N4_3_LATERALITY != vd.N4_3_LATERALITY OR (mainref.N4_3_LATERALITY IS NULL AND vd.N4_3_LATERALITY IS NOT NULL) OR (mainref.N4_3_LATERALITY IS NOT NULL AND vd.N4_3_LATERALITY IS NULL)
		OR			mainref.N4_4_BASIS_DIAGNOSIS != vd.N4_4_BASIS_DIAGNOSIS OR (mainref.N4_4_BASIS_DIAGNOSIS IS NULL AND vd.N4_4_BASIS_DIAGNOSIS IS NOT NULL) OR (mainref.N4_4_BASIS_DIAGNOSIS IS NOT NULL AND vd.N4_4_BASIS_DIAGNOSIS IS NULL)
		OR			mainref.L_TOPOGRAPHY != vd.L_TOPOGRAPHY OR (mainref.L_TOPOGRAPHY IS NULL AND vd.L_TOPOGRAPHY IS NOT NULL) OR (mainref.L_TOPOGRAPHY IS NOT NULL AND vd.L_TOPOGRAPHY IS NULL)
		OR			mainref.L_HISTOLOGY_GROUP != vd.L_HISTOLOGY_GROUP OR (mainref.L_HISTOLOGY_GROUP IS NULL AND vd.L_HISTOLOGY_GROUP IS NOT NULL) OR (mainref.L_HISTOLOGY_GROUP IS NOT NULL AND vd.L_HISTOLOGY_GROUP IS NULL)
		OR			mainref.N4_5_HISTOLOGY != vd.N4_5_HISTOLOGY OR (mainref.N4_5_HISTOLOGY IS NULL AND vd.N4_5_HISTOLOGY IS NOT NULL) OR (mainref.N4_5_HISTOLOGY IS NOT NULL AND vd.N4_5_HISTOLOGY IS NULL)
		OR			mainref.N4_6_DIFFERENTIATION != vd.N4_6_DIFFERENTIATION OR (mainref.N4_6_DIFFERENTIATION IS NULL AND vd.N4_6_DIFFERENTIATION IS NOT NULL) OR (mainref.N4_6_DIFFERENTIATION IS NOT NULL AND vd.N4_6_DIFFERENTIATION IS NULL)
		OR			mainref.ClinicalTStage != vd.ClinicalTStage OR (mainref.ClinicalTStage IS NULL AND vd.ClinicalTStage IS NOT NULL) OR (mainref.ClinicalTStage IS NOT NULL AND vd.ClinicalTStage IS NULL)
		OR			mainref.ClinicalTCertainty != vd.ClinicalTCertainty OR (mainref.ClinicalTCertainty IS NULL AND vd.ClinicalTCertainty IS NOT NULL) OR (mainref.ClinicalTCertainty IS NOT NULL AND vd.ClinicalTCertainty IS NULL)
		OR			mainref.ClinicalNStage != vd.ClinicalNStage OR (mainref.ClinicalNStage IS NULL AND vd.ClinicalNStage IS NOT NULL) OR (mainref.ClinicalNStage IS NOT NULL AND vd.ClinicalNStage IS NULL)
		OR			mainref.ClinicalNCertainty != vd.ClinicalNCertainty OR (mainref.ClinicalNCertainty IS NULL AND vd.ClinicalNCertainty IS NOT NULL) OR (mainref.ClinicalNCertainty IS NOT NULL AND vd.ClinicalNCertainty IS NULL)
		OR			mainref.ClinicalMStage != vd.ClinicalMStage OR (mainref.ClinicalMStage IS NULL AND vd.ClinicalMStage IS NOT NULL) OR (mainref.ClinicalMStage IS NOT NULL AND vd.ClinicalMStage IS NULL)
		OR			mainref.ClinicalMCertainty != vd.ClinicalMCertainty OR (mainref.ClinicalMCertainty IS NULL AND vd.ClinicalMCertainty IS NOT NULL) OR (mainref.ClinicalMCertainty IS NOT NULL AND vd.ClinicalMCertainty IS NULL)
		OR			mainref.ClinicalOverallCertainty != vd.ClinicalOverallCertainty OR (mainref.ClinicalOverallCertainty IS NULL AND vd.ClinicalOverallCertainty IS NOT NULL) OR (mainref.ClinicalOverallCertainty IS NOT NULL AND vd.ClinicalOverallCertainty IS NULL)
		OR			mainref.N6_9_SITE_CLASSIFICATION != vd.N6_9_SITE_CLASSIFICATION OR (mainref.N6_9_SITE_CLASSIFICATION IS NULL AND vd.N6_9_SITE_CLASSIFICATION IS NOT NULL) OR (mainref.N6_9_SITE_CLASSIFICATION IS NOT NULL AND vd.N6_9_SITE_CLASSIFICATION IS NULL)
		OR			mainref.PathologicalOverallCertainty != vd.PathologicalOverallCertainty OR (mainref.PathologicalOverallCertainty IS NULL AND vd.PathologicalOverallCertainty IS NOT NULL) OR (mainref.PathologicalOverallCertainty IS NOT NULL AND vd.PathologicalOverallCertainty IS NULL)
		OR			mainref.PathologicalTCertainty != vd.PathologicalTCertainty OR (mainref.PathologicalTCertainty IS NULL AND vd.PathologicalTCertainty IS NOT NULL) OR (mainref.PathologicalTCertainty IS NOT NULL AND vd.PathologicalTCertainty IS NULL)
		OR			mainref.PathologicalTStage != vd.PathologicalTStage OR (mainref.PathologicalTStage IS NULL AND vd.PathologicalTStage IS NOT NULL) OR (mainref.PathologicalTStage IS NOT NULL AND vd.PathologicalTStage IS NULL)
		OR			mainref.PathologicalNCertainty != vd.PathologicalNCertainty OR (mainref.PathologicalNCertainty IS NULL AND vd.PathologicalNCertainty IS NOT NULL) OR (mainref.PathologicalNCertainty IS NOT NULL AND vd.PathologicalNCertainty IS NULL)
		OR			mainref.PathologicalNStage != vd.PathologicalNStage OR (mainref.PathologicalNStage IS NULL AND vd.PathologicalNStage IS NOT NULL) OR (mainref.PathologicalNStage IS NOT NULL AND vd.PathologicalNStage IS NULL)
		OR			mainref.PathologicalMCertainty != vd.PathologicalMCertainty OR (mainref.PathologicalMCertainty IS NULL AND vd.PathologicalMCertainty IS NOT NULL) OR (mainref.PathologicalMCertainty IS NOT NULL AND vd.PathologicalMCertainty IS NULL)
		OR			mainref.PathologicalMStage != vd.PathologicalMStage OR (mainref.PathologicalMStage IS NULL AND vd.PathologicalMStage IS NOT NULL) OR (mainref.PathologicalMStage IS NOT NULL AND vd.PathologicalMStage IS NULL)
		OR			mainref.L_GP_INFORMED != vd.L_GP_INFORMED OR (mainref.L_GP_INFORMED IS NULL AND vd.L_GP_INFORMED IS NOT NULL) OR (mainref.L_GP_INFORMED IS NOT NULL AND vd.L_GP_INFORMED IS NULL)
		OR			mainref.L_GP_INFORMED_DATE != vd.L_GP_INFORMED_DATE OR (mainref.L_GP_INFORMED_DATE IS NULL AND vd.L_GP_INFORMED_DATE IS NOT NULL) OR (mainref.L_GP_INFORMED_DATE IS NOT NULL AND vd.L_GP_INFORMED_DATE IS NULL)
		OR			mainref.L_GP_NOT != vd.L_GP_NOT OR (mainref.L_GP_NOT IS NULL AND vd.L_GP_NOT IS NOT NULL) OR (mainref.L_GP_NOT IS NOT NULL AND vd.L_GP_NOT IS NULL)
		OR			mainref.L_REL_INFORMED != vd.L_REL_INFORMED OR (mainref.L_REL_INFORMED IS NULL AND vd.L_REL_INFORMED IS NOT NULL) OR (mainref.L_REL_INFORMED IS NOT NULL AND vd.L_REL_INFORMED IS NULL)
		OR			mainref.L_NURSE_PRESENT != vd.L_NURSE_PRESENT OR (mainref.L_NURSE_PRESENT IS NULL AND vd.L_NURSE_PRESENT IS NOT NULL) OR (mainref.L_NURSE_PRESENT IS NOT NULL AND vd.L_NURSE_PRESENT IS NULL)
		OR			mainref.L_SPEC_NURSE_DATE != vd.L_SPEC_NURSE_DATE OR (mainref.L_SPEC_NURSE_DATE IS NULL AND vd.L_SPEC_NURSE_DATE IS NOT NULL) OR (mainref.L_SPEC_NURSE_DATE IS NOT NULL AND vd.L_SPEC_NURSE_DATE IS NULL)
		OR			mainref.L_SEEN_NURSE_DATE != vd.L_SEEN_NURSE_DATE OR (mainref.L_SEEN_NURSE_DATE IS NULL AND vd.L_SEEN_NURSE_DATE IS NOT NULL) OR (mainref.L_SEEN_NURSE_DATE IS NOT NULL AND vd.L_SEEN_NURSE_DATE IS NULL)
		OR			mainref.N16_1_ADJ_DAYS != vd.N16_1_ADJ_DAYS OR (mainref.N16_1_ADJ_DAYS IS NULL AND vd.N16_1_ADJ_DAYS IS NOT NULL) OR (mainref.N16_1_ADJ_DAYS IS NOT NULL AND vd.N16_1_ADJ_DAYS IS NULL)
		OR			mainref.N16_2_ADJ_DAYS != vd.N16_2_ADJ_DAYS OR (mainref.N16_2_ADJ_DAYS IS NULL AND vd.N16_2_ADJ_DAYS IS NOT NULL) OR (mainref.N16_2_ADJ_DAYS IS NOT NULL AND vd.N16_2_ADJ_DAYS IS NULL)
		OR			mainref.N16_3_ADJ_DECISION_CODE != vd.N16_3_ADJ_DECISION_CODE OR (mainref.N16_3_ADJ_DECISION_CODE IS NULL AND vd.N16_3_ADJ_DECISION_CODE IS NOT NULL) OR (mainref.N16_3_ADJ_DECISION_CODE IS NOT NULL AND vd.N16_3_ADJ_DECISION_CODE IS NULL)
		OR			mainref.N16_4_ADJ_TREAT_CODE != vd.N16_4_ADJ_TREAT_CODE OR (mainref.N16_4_ADJ_TREAT_CODE IS NULL AND vd.N16_4_ADJ_TREAT_CODE IS NOT NULL) OR (mainref.N16_4_ADJ_TREAT_CODE IS NOT NULL AND vd.N16_4_ADJ_TREAT_CODE IS NULL)
		OR			mainref.N16_5_DECISION_REASON_CODE != vd.N16_5_DECISION_REASON_CODE OR (mainref.N16_5_DECISION_REASON_CODE IS NULL AND vd.N16_5_DECISION_REASON_CODE IS NOT NULL) OR (mainref.N16_5_DECISION_REASON_CODE IS NOT NULL AND vd.N16_5_DECISION_REASON_CODE IS NULL)
		OR			mainref.N16_6_TREATMENT_REASON_CODE != vd.N16_6_TREATMENT_REASON_CODE OR (mainref.N16_6_TREATMENT_REASON_CODE IS NULL AND vd.N16_6_TREATMENT_REASON_CODE IS NOT NULL) OR (mainref.N16_6_TREATMENT_REASON_CODE IS NOT NULL AND vd.N16_6_TREATMENT_REASON_CODE IS NULL)
		OR			mainref.PathologicalTNMDate != vd.PathologicalTNMDate OR (mainref.PathologicalTNMDate IS NULL AND vd.PathologicalTNMDate IS NOT NULL) OR (mainref.PathologicalTNMDate IS NOT NULL AND vd.PathologicalTNMDate IS NULL)
		OR			mainref.ClinicalTNMDate != vd.ClinicalTNMDate OR (mainref.ClinicalTNMDate IS NULL AND vd.ClinicalTNMDate IS NOT NULL) OR (mainref.ClinicalTNMDate IS NOT NULL AND vd.ClinicalTNMDate IS NULL)
		OR			mainref.L_FIRST_CONSULTANT != vd.L_FIRST_CONSULTANT OR (mainref.L_FIRST_CONSULTANT IS NULL AND vd.L_FIRST_CONSULTANT IS NOT NULL) OR (mainref.L_FIRST_CONSULTANT IS NOT NULL AND vd.L_FIRST_CONSULTANT IS NULL)
		OR			mainref.L_APPROPRIATE != vd.L_APPROPRIATE OR (mainref.L_APPROPRIATE IS NULL AND vd.L_APPROPRIATE IS NOT NULL) OR (mainref.L_APPROPRIATE IS NOT NULL AND vd.L_APPROPRIATE IS NULL)
		OR			mainref.L_TERTIARY_DATE != vd.L_TERTIARY_DATE OR (mainref.L_TERTIARY_DATE IS NULL AND vd.L_TERTIARY_DATE IS NOT NULL) OR (mainref.L_TERTIARY_DATE IS NOT NULL AND vd.L_TERTIARY_DATE IS NULL)
		OR			mainref.L_TERTIARY_TRUST != vd.L_TERTIARY_TRUST OR (mainref.L_TERTIARY_TRUST IS NULL AND vd.L_TERTIARY_TRUST IS NOT NULL) OR (mainref.L_TERTIARY_TRUST IS NOT NULL AND vd.L_TERTIARY_TRUST IS NULL)
		OR			mainref.L_TERTIARY_REASON != vd.L_TERTIARY_REASON OR (mainref.L_TERTIARY_REASON IS NULL AND vd.L_TERTIARY_REASON IS NOT NULL) OR (mainref.L_TERTIARY_REASON IS NOT NULL AND vd.L_TERTIARY_REASON IS NULL)
		OR			mainref.L_INAP_REF != vd.L_INAP_REF OR (mainref.L_INAP_REF IS NULL AND vd.L_INAP_REF IS NOT NULL) OR (mainref.L_INAP_REF IS NOT NULL AND vd.L_INAP_REF IS NULL)
		OR			mainref.L_NEW_CA_SITE != vd.L_NEW_CA_SITE OR (mainref.L_NEW_CA_SITE IS NULL AND vd.L_NEW_CA_SITE IS NOT NULL) OR (mainref.L_NEW_CA_SITE IS NOT NULL AND vd.L_NEW_CA_SITE IS NULL)
		OR			mainref.L_AUTO_REF != vd.L_AUTO_REF OR (mainref.L_AUTO_REF IS NULL AND vd.L_AUTO_REF IS NOT NULL) OR (mainref.L_AUTO_REF IS NOT NULL AND vd.L_AUTO_REF IS NULL)
		OR			mainref.L_SEC_DIAGNOSIS_G != vd.L_SEC_DIAGNOSIS_G OR (mainref.L_SEC_DIAGNOSIS_G IS NULL AND vd.L_SEC_DIAGNOSIS_G IS NOT NULL) OR (mainref.L_SEC_DIAGNOSIS_G IS NOT NULL AND vd.L_SEC_DIAGNOSIS_G IS NULL)
		OR			mainref.L_SEC_DIAGNOSIS != vd.L_SEC_DIAGNOSIS OR (mainref.L_SEC_DIAGNOSIS IS NULL AND vd.L_SEC_DIAGNOSIS IS NOT NULL) OR (mainref.L_SEC_DIAGNOSIS IS NOT NULL AND vd.L_SEC_DIAGNOSIS IS NULL)
		OR			mainref.L_WRONG_REF != vd.L_WRONG_REF OR (mainref.L_WRONG_REF IS NULL AND vd.L_WRONG_REF IS NOT NULL) OR (mainref.L_WRONG_REF IS NOT NULL AND vd.L_WRONG_REF IS NULL)
		OR			mainref.L_WRONG_REASON != vd.L_WRONG_REASON OR (mainref.L_WRONG_REASON IS NULL AND vd.L_WRONG_REASON IS NOT NULL) OR (mainref.L_WRONG_REASON IS NOT NULL AND vd.L_WRONG_REASON IS NULL)
		OR			mainref.L_TUMOUR_STATUS != vd.L_TUMOUR_STATUS OR (mainref.L_TUMOUR_STATUS IS NULL AND vd.L_TUMOUR_STATUS IS NOT NULL) OR (mainref.L_TUMOUR_STATUS IS NOT NULL AND vd.L_TUMOUR_STATUS IS NULL)
		OR			mainref.L_NON_CANCER != vd.L_NON_CANCER OR (mainref.L_NON_CANCER IS NULL AND vd.L_NON_CANCER IS NOT NULL) OR (mainref.L_NON_CANCER IS NOT NULL AND vd.L_NON_CANCER IS NULL)
		OR			mainref.L_FIRST_APP != vd.L_FIRST_APP OR (mainref.L_FIRST_APP IS NULL AND vd.L_FIRST_APP IS NOT NULL) OR (mainref.L_FIRST_APP IS NOT NULL AND vd.L_FIRST_APP IS NULL)
		OR			mainref.L_NO_APP != vd.L_NO_APP OR (mainref.L_NO_APP IS NULL AND vd.L_NO_APP IS NOT NULL) OR (mainref.L_NO_APP IS NOT NULL AND vd.L_NO_APP IS NULL)
		OR			mainref.L_DIAG_WHO != vd.L_DIAG_WHO OR (mainref.L_DIAG_WHO IS NULL AND vd.L_DIAG_WHO IS NOT NULL) OR (mainref.L_DIAG_WHO IS NOT NULL AND vd.L_DIAG_WHO IS NULL)
		OR			mainref.L_RECURRENCE != vd.L_RECURRENCE OR (mainref.L_RECURRENCE IS NULL AND vd.L_RECURRENCE IS NOT NULL) OR (mainref.L_RECURRENCE IS NOT NULL AND vd.L_RECURRENCE IS NULL)
		--OR			mainref.L_OTHER_SYMPS != vd.L_OTHER_SYMPS OR (mainref.L_OTHER_SYMPS IS NULL AND vd.L_OTHER_SYMPS IS NOT NULL) OR (mainref.L_OTHER_SYMPS IS NOT NULL AND vd.L_OTHER_SYMPS IS NULL)
		--OR			mainref.L_COMMENTS != vd.L_COMMENTS OR (mainref.L_COMMENTS IS NULL AND vd.L_COMMENTS IS NOT NULL) OR (mainref.L_COMMENTS IS NOT NULL AND vd.L_COMMENTS IS NULL)
		--OR			mainref.N2_11_FIRST_SEEN_REASON != vd.N2_11_FIRST_SEEN_REASON OR (mainref.N2_11_FIRST_SEEN_REASON IS NULL AND vd.N2_11_FIRST_SEEN_REASON IS NOT NULL) OR (mainref.N2_11_FIRST_SEEN_REASON IS NOT NULL AND vd.N2_11_FIRST_SEEN_REASON IS NULL)
		--OR			mainref.N16_7_DECISION_REASON != vd.N16_7_DECISION_REASON OR (mainref.N16_7_DECISION_REASON IS NULL AND vd.N16_7_DECISION_REASON IS NOT NULL) OR (mainref.N16_7_DECISION_REASON IS NOT NULL AND vd.N16_7_DECISION_REASON IS NULL)
		--OR			mainref.N16_8_TREATMENT_REASON != vd.N16_8_TREATMENT_REASON OR (mainref.N16_8_TREATMENT_REASON IS NULL AND vd.N16_8_TREATMENT_REASON IS NOT NULL) OR (mainref.N16_8_TREATMENT_REASON IS NOT NULL AND vd.N16_8_TREATMENT_REASON IS NULL)
		--OR			mainref.L_DIAGNOSIS_COMMENTS != vd.L_DIAGNOSIS_COMMENTS OR (mainref.L_DIAGNOSIS_COMMENTS IS NULL AND vd.L_DIAGNOSIS_COMMENTS IS NOT NULL) OR (mainref.L_DIAGNOSIS_COMMENTS IS NOT NULL AND vd.L_DIAGNOSIS_COMMENTS IS NULL)
		OR			mainref.GP_PRACTICE_CODE != vd.GP_PRACTICE_CODE OR (mainref.GP_PRACTICE_CODE IS NULL AND vd.GP_PRACTICE_CODE IS NOT NULL) OR (mainref.GP_PRACTICE_CODE IS NOT NULL AND vd.GP_PRACTICE_CODE IS NULL)
		OR			mainref.ClinicalTNMGroup != vd.ClinicalTNMGroup OR (mainref.ClinicalTNMGroup IS NULL AND vd.ClinicalTNMGroup IS NOT NULL) OR (mainref.ClinicalTNMGroup IS NOT NULL AND vd.ClinicalTNMGroup IS NULL)
		OR			mainref.PathologicalTNMGroup != vd.PathologicalTNMGroup OR (mainref.PathologicalTNMGroup IS NULL AND vd.PathologicalTNMGroup IS NOT NULL) OR (mainref.PathologicalTNMGroup IS NOT NULL AND vd.PathologicalTNMGroup IS NULL)
		OR			mainref.L_KEY_WORKER_SEEN != vd.L_KEY_WORKER_SEEN OR (mainref.L_KEY_WORKER_SEEN IS NULL AND vd.L_KEY_WORKER_SEEN IS NOT NULL) OR (mainref.L_KEY_WORKER_SEEN IS NOT NULL AND vd.L_KEY_WORKER_SEEN IS NULL)
		OR			mainref.L_PALLIATIVE_SPECIALIST_SEEN != vd.L_PALLIATIVE_SPECIALIST_SEEN OR (mainref.L_PALLIATIVE_SPECIALIST_SEEN IS NULL AND vd.L_PALLIATIVE_SPECIALIST_SEEN IS NOT NULL) OR (mainref.L_PALLIATIVE_SPECIALIST_SEEN IS NOT NULL AND vd.L_PALLIATIVE_SPECIALIST_SEEN IS NULL)
		OR			mainref.GERM_CELL_NON_CNS_ID != vd.GERM_CELL_NON_CNS_ID OR (mainref.GERM_CELL_NON_CNS_ID IS NULL AND vd.GERM_CELL_NON_CNS_ID IS NOT NULL) OR (mainref.GERM_CELL_NON_CNS_ID IS NOT NULL AND vd.GERM_CELL_NON_CNS_ID IS NULL)
		OR			mainref.RECURRENCE_CANCER_SITE_ID != vd.RECURRENCE_CANCER_SITE_ID OR (mainref.RECURRENCE_CANCER_SITE_ID IS NULL AND vd.RECURRENCE_CANCER_SITE_ID IS NOT NULL) OR (mainref.RECURRENCE_CANCER_SITE_ID IS NOT NULL AND vd.RECURRENCE_CANCER_SITE_ID IS NULL)
		OR			mainref.ICD03_GROUP != vd.ICD03_GROUP OR (mainref.ICD03_GROUP IS NULL AND vd.ICD03_GROUP IS NOT NULL) OR (mainref.ICD03_GROUP IS NOT NULL AND vd.ICD03_GROUP IS NULL)
		OR			mainref.ICD03 != vd.ICD03 OR (mainref.ICD03 IS NULL AND vd.ICD03 IS NOT NULL) OR (mainref.ICD03 IS NOT NULL AND vd.ICD03 IS NULL)
		OR			mainref.L_DATE_DIAGNOSIS_DAHNO_LUCADA != vd.L_DATE_DIAGNOSIS_DAHNO_LUCADA OR (mainref.L_DATE_DIAGNOSIS_DAHNO_LUCADA IS NULL AND vd.L_DATE_DIAGNOSIS_DAHNO_LUCADA IS NOT NULL) OR (mainref.L_DATE_DIAGNOSIS_DAHNO_LUCADA IS NOT NULL AND vd.L_DATE_DIAGNOSIS_DAHNO_LUCADA IS NULL)
		OR			mainref.L_INDICATOR_CODE != vd.L_INDICATOR_CODE OR (mainref.L_INDICATOR_CODE IS NULL AND vd.L_INDICATOR_CODE IS NOT NULL) OR (mainref.L_INDICATOR_CODE IS NOT NULL AND vd.L_INDICATOR_CODE IS NULL)
		OR			mainref.PRIMARY_DIAGNOSIS_SUB_COMMENT != vd.PRIMARY_DIAGNOSIS_SUB_COMMENT OR (mainref.PRIMARY_DIAGNOSIS_SUB_COMMENT IS NULL AND vd.PRIMARY_DIAGNOSIS_SUB_COMMENT IS NOT NULL) OR (mainref.PRIMARY_DIAGNOSIS_SUB_COMMENT IS NOT NULL AND vd.PRIMARY_DIAGNOSIS_SUB_COMMENT IS NULL)
		OR			mainref.CONSULTANT_CODE_AT_DIAGNOSIS != vd.CONSULTANT_CODE_AT_DIAGNOSIS OR (mainref.CONSULTANT_CODE_AT_DIAGNOSIS IS NULL AND vd.CONSULTANT_CODE_AT_DIAGNOSIS IS NOT NULL) OR (mainref.CONSULTANT_CODE_AT_DIAGNOSIS IS NOT NULL AND vd.CONSULTANT_CODE_AT_DIAGNOSIS IS NULL)
		OR			mainref.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS != vd.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS OR (mainref.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS IS NULL AND vd.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS IS NOT NULL) OR (mainref.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS IS NOT NULL AND vd.CONSULTANT_AGE_SPECIALTY_AT_DIAGNOSIS IS NULL)
		OR			mainref.FETOPROTEIN != vd.FETOPROTEIN OR (mainref.FETOPROTEIN IS NULL AND vd.FETOPROTEIN IS NOT NULL) OR (mainref.FETOPROTEIN IS NOT NULL AND vd.FETOPROTEIN IS NULL)
		OR			mainref.GONADOTROPIN != vd.GONADOTROPIN OR (mainref.GONADOTROPIN IS NULL AND vd.GONADOTROPIN IS NOT NULL) OR (mainref.GONADOTROPIN IS NOT NULL AND vd.GONADOTROPIN IS NULL)
		OR			mainref.GONADOTROPIN_SERUM != vd.GONADOTROPIN_SERUM OR (mainref.GONADOTROPIN_SERUM IS NULL AND vd.GONADOTROPIN_SERUM IS NOT NULL) OR (mainref.GONADOTROPIN_SERUM IS NOT NULL AND vd.GONADOTROPIN_SERUM IS NULL)
		OR			mainref.FETOPROTEIN_SERUM != vd.FETOPROTEIN_SERUM OR (mainref.FETOPROTEIN_SERUM IS NULL AND vd.FETOPROTEIN_SERUM IS NOT NULL) OR (mainref.FETOPROTEIN_SERUM IS NOT NULL AND vd.FETOPROTEIN_SERUM IS NULL)
		OR			mainref.SARCOMA_TUMOUR_SITE_BONE != vd.SARCOMA_TUMOUR_SITE_BONE OR (mainref.SARCOMA_TUMOUR_SITE_BONE IS NULL AND vd.SARCOMA_TUMOUR_SITE_BONE IS NOT NULL) OR (mainref.SARCOMA_TUMOUR_SITE_BONE IS NOT NULL AND vd.SARCOMA_TUMOUR_SITE_BONE IS NULL)
		OR			mainref.SARCOMA_TUMOUR_SITE_SOFT_TISSUE != vd.SARCOMA_TUMOUR_SITE_SOFT_TISSUE OR (mainref.SARCOMA_TUMOUR_SITE_SOFT_TISSUE IS NULL AND vd.SARCOMA_TUMOUR_SITE_SOFT_TISSUE IS NOT NULL) OR (mainref.SARCOMA_TUMOUR_SITE_SOFT_TISSUE IS NOT NULL AND vd.SARCOMA_TUMOUR_SITE_SOFT_TISSUE IS NULL)
		OR			mainref.SARCOMA_TUMOUR_SUBSITE_BONE != vd.SARCOMA_TUMOUR_SUBSITE_BONE OR (mainref.SARCOMA_TUMOUR_SUBSITE_BONE IS NULL AND vd.SARCOMA_TUMOUR_SUBSITE_BONE IS NOT NULL) OR (mainref.SARCOMA_TUMOUR_SUBSITE_BONE IS NOT NULL AND vd.SARCOMA_TUMOUR_SUBSITE_BONE IS NULL)
		OR			mainref.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE != vd.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE OR (mainref.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE IS NULL AND vd.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE IS NOT NULL) OR (mainref.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE IS NOT NULL AND vd.SARCOMA_TUMOUR_SUBSITE_SOFT_TISSUE IS NULL)
		--OR			mainref.ROOT_DECISION_DATE_COMMENTS != vd.ROOT_DECISION_DATE_COMMENTS OR (mainref.ROOT_DECISION_DATE_COMMENTS IS NULL AND vd.ROOT_DECISION_DATE_COMMENTS IS NOT NULL) OR (mainref.ROOT_DECISION_DATE_COMMENTS IS NOT NULL AND vd.ROOT_DECISION_DATE_COMMENTS IS NULL)
		--OR			mainref.ROOT_RECEIPT_DATE_COMMENTS != vd.ROOT_RECEIPT_DATE_COMMENTS OR (mainref.ROOT_RECEIPT_DATE_COMMENTS IS NULL AND vd.ROOT_RECEIPT_DATE_COMMENTS IS NOT NULL) OR (mainref.ROOT_RECEIPT_DATE_COMMENTS IS NOT NULL AND vd.ROOT_RECEIPT_DATE_COMMENTS IS NULL)
		--OR			mainref.ROOT_FIRST_SEEN_DATE_COMMENTS != vd.ROOT_FIRST_SEEN_DATE_COMMENTS OR (mainref.ROOT_FIRST_SEEN_DATE_COMMENTS IS NULL AND vd.ROOT_FIRST_SEEN_DATE_COMMENTS IS NOT NULL) OR (mainref.ROOT_FIRST_SEEN_DATE_COMMENTS IS NOT NULL AND vd.ROOT_FIRST_SEEN_DATE_COMMENTS IS NULL)
		--OR			mainref.ROOT_DIAGNOSIS_DATE_COMMENTS != vd.ROOT_DIAGNOSIS_DATE_COMMENTS OR (mainref.ROOT_DIAGNOSIS_DATE_COMMENTS IS NULL AND vd.ROOT_DIAGNOSIS_DATE_COMMENTS IS NOT NULL) OR (mainref.ROOT_DIAGNOSIS_DATE_COMMENTS IS NOT NULL AND vd.ROOT_DIAGNOSIS_DATE_COMMENTS IS NULL)
		--OR			mainref.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS != vd.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS OR (mainref.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS IS NULL AND vd.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS IS NOT NULL) OR (mainref.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS IS NOT NULL AND vd.ROOT_DNA_APPT_REBOOKED_DATE_COMMENTS IS NULL)
		--OR			mainref.ROOT_UPGRADE_COMMENTS != vd.ROOT_UPGRADE_COMMENTS OR (mainref.ROOT_UPGRADE_COMMENTS IS NULL AND vd.ROOT_UPGRADE_COMMENTS IS NOT NULL) OR (mainref.ROOT_UPGRADE_COMMENTS IS NOT NULL AND vd.ROOT_UPGRADE_COMMENTS IS NULL)
		OR			mainref.FIRST_APPT_TIME != vd.FIRST_APPT_TIME OR (mainref.FIRST_APPT_TIME IS NULL AND vd.FIRST_APPT_TIME IS NOT NULL) OR (mainref.FIRST_APPT_TIME IS NOT NULL AND vd.FIRST_APPT_TIME IS NULL)
		OR			mainref.TRANSFER_REASON != vd.TRANSFER_REASON OR (mainref.TRANSFER_REASON IS NULL AND vd.TRANSFER_REASON IS NOT NULL) OR (mainref.TRANSFER_REASON IS NOT NULL AND vd.TRANSFER_REASON IS NULL)
		OR			mainref.DATE_NEW_REFERRAL != vd.DATE_NEW_REFERRAL OR (mainref.DATE_NEW_REFERRAL IS NULL AND vd.DATE_NEW_REFERRAL IS NOT NULL) OR (mainref.DATE_NEW_REFERRAL IS NOT NULL AND vd.DATE_NEW_REFERRAL IS NULL)
		OR			mainref.TUMOUR_SITE_NEW != vd.TUMOUR_SITE_NEW OR (mainref.TUMOUR_SITE_NEW IS NULL AND vd.TUMOUR_SITE_NEW IS NOT NULL) OR (mainref.TUMOUR_SITE_NEW IS NOT NULL AND vd.TUMOUR_SITE_NEW IS NULL)
		OR			mainref.DATE_TRANSFER_ACTIONED != vd.DATE_TRANSFER_ACTIONED OR (mainref.DATE_TRANSFER_ACTIONED IS NULL AND vd.DATE_TRANSFER_ACTIONED IS NOT NULL) OR (mainref.DATE_TRANSFER_ACTIONED IS NOT NULL AND vd.DATE_TRANSFER_ACTIONED IS NULL)
		OR			mainref.SOURCE_CARE_ID != vd.SOURCE_CARE_ID OR (mainref.SOURCE_CARE_ID IS NULL AND vd.SOURCE_CARE_ID IS NOT NULL) OR (mainref.SOURCE_CARE_ID IS NOT NULL AND vd.SOURCE_CARE_ID IS NULL)
		OR			mainref.ADT_REF_ID != vd.ADT_REF_ID OR (mainref.ADT_REF_ID IS NULL AND vd.ADT_REF_ID IS NOT NULL) OR (mainref.ADT_REF_ID IS NOT NULL AND vd.ADT_REF_ID IS NULL)
		OR			mainref.ACTION_ID != vd.ACTION_ID OR (mainref.ACTION_ID IS NULL AND vd.ACTION_ID IS NOT NULL) OR (mainref.ACTION_ID IS NOT NULL AND vd.ACTION_ID IS NULL)
		OR			mainref.DIAGNOSIS_ACTION_ID != vd.DIAGNOSIS_ACTION_ID OR (mainref.DIAGNOSIS_ACTION_ID IS NULL AND vd.DIAGNOSIS_ACTION_ID IS NOT NULL) OR (mainref.DIAGNOSIS_ACTION_ID IS NOT NULL AND vd.DIAGNOSIS_ACTION_ID IS NULL)
		OR			mainref.ORIGINAL_SOURCE_CARE_ID != vd.ORIGINAL_SOURCE_CARE_ID OR (mainref.ORIGINAL_SOURCE_CARE_ID IS NULL AND vd.ORIGINAL_SOURCE_CARE_ID IS NOT NULL) OR (mainref.ORIGINAL_SOURCE_CARE_ID IS NOT NULL AND vd.ORIGINAL_SOURCE_CARE_ID IS NULL)
		--OR			mainref.TRANSFER_DATE_COMMENTS != vd.TRANSFER_DATE_COMMENTS OR (mainref.TRANSFER_DATE_COMMENTS IS NULL AND vd.TRANSFER_DATE_COMMENTS IS NOT NULL) OR (mainref.TRANSFER_DATE_COMMENTS IS NOT NULL AND vd.TRANSFER_DATE_COMMENTS IS NULL)
		--OR			mainref.SPECIALIST_REFERRAL_COMMENTS != vd.SPECIALIST_REFERRAL_COMMENTS OR (mainref.SPECIALIST_REFERRAL_COMMENTS IS NULL AND vd.SPECIALIST_REFERRAL_COMMENTS IS NOT NULL) OR (mainref.SPECIALIST_REFERRAL_COMMENTS IS NOT NULL AND vd.SPECIALIST_REFERRAL_COMMENTS IS NULL)
		OR			mainref.NON_CANCER_DIAGNOSIS_CHAPTER != vd.NON_CANCER_DIAGNOSIS_CHAPTER OR (mainref.NON_CANCER_DIAGNOSIS_CHAPTER IS NULL AND vd.NON_CANCER_DIAGNOSIS_CHAPTER IS NOT NULL) OR (mainref.NON_CANCER_DIAGNOSIS_CHAPTER IS NOT NULL AND vd.NON_CANCER_DIAGNOSIS_CHAPTER IS NULL)
		OR			mainref.NON_CANCER_DIAGNOSIS_GROUP != vd.NON_CANCER_DIAGNOSIS_GROUP OR (mainref.NON_CANCER_DIAGNOSIS_GROUP IS NULL AND vd.NON_CANCER_DIAGNOSIS_GROUP IS NOT NULL) OR (mainref.NON_CANCER_DIAGNOSIS_GROUP IS NOT NULL AND vd.NON_CANCER_DIAGNOSIS_GROUP IS NULL)
		OR			mainref.NON_CANCER_DIAGNOSIS_CODE != vd.NON_CANCER_DIAGNOSIS_CODE OR (mainref.NON_CANCER_DIAGNOSIS_CODE IS NULL AND vd.NON_CANCER_DIAGNOSIS_CODE IS NOT NULL) OR (mainref.NON_CANCER_DIAGNOSIS_CODE IS NOT NULL AND vd.NON_CANCER_DIAGNOSIS_CODE IS NULL)
		OR			mainref.TNM_UNKNOWN != vd.TNM_UNKNOWN OR (mainref.TNM_UNKNOWN IS NULL AND vd.TNM_UNKNOWN IS NOT NULL) OR (mainref.TNM_UNKNOWN IS NOT NULL AND vd.TNM_UNKNOWN IS NULL)
		OR			mainref.ReferringPractice != vd.ReferringPractice OR (mainref.ReferringPractice IS NULL AND vd.ReferringPractice IS NOT NULL) OR (mainref.ReferringPractice IS NOT NULL AND vd.ReferringPractice IS NULL)
		OR			mainref.ReferringGP != vd.ReferringGP OR (mainref.ReferringGP IS NULL AND vd.ReferringGP IS NOT NULL) OR (mainref.ReferringGP IS NOT NULL AND vd.ReferringGP IS NULL)
		OR			mainref.ReferringBranch != vd.ReferringBranch OR (mainref.ReferringBranch IS NULL AND vd.ReferringBranch IS NOT NULL) OR (mainref.ReferringBranch IS NOT NULL AND vd.ReferringBranch IS NULL)
		OR			mainref.BankedTissue != vd.BankedTissue OR (mainref.BankedTissue IS NULL AND vd.BankedTissue IS NOT NULL) OR (mainref.BankedTissue IS NOT NULL AND vd.BankedTissue IS NULL)
		OR			mainref.BankedTissueTumour != vd.BankedTissueTumour OR (mainref.BankedTissueTumour IS NULL AND vd.BankedTissueTumour IS NOT NULL) OR (mainref.BankedTissueTumour IS NOT NULL AND vd.BankedTissueTumour IS NULL)
		OR			mainref.BankedTissueBlood != vd.BankedTissueBlood OR (mainref.BankedTissueBlood IS NULL AND vd.BankedTissueBlood IS NOT NULL) OR (mainref.BankedTissueBlood IS NOT NULL AND vd.BankedTissueBlood IS NULL)
		OR			mainref.BankedTissueCSF != vd.BankedTissueCSF OR (mainref.BankedTissueCSF IS NULL AND vd.BankedTissueCSF IS NOT NULL) OR (mainref.BankedTissueCSF IS NOT NULL AND vd.BankedTissueCSF IS NULL)
		OR			mainref.BankedTissueBoneMarrow != vd.BankedTissueBoneMarrow OR (mainref.BankedTissueBoneMarrow IS NULL AND vd.BankedTissueBoneMarrow IS NOT NULL) OR (mainref.BankedTissueBoneMarrow IS NOT NULL AND vd.BankedTissueBoneMarrow IS NULL)
		OR			mainref.SNOMed_CT != vd.SNOMed_CT OR (mainref.SNOMed_CT IS NULL AND vd.SNOMed_CT IS NOT NULL) OR (mainref.SNOMed_CT IS NOT NULL AND vd.SNOMed_CT IS NULL)
		OR			mainref.ADT_PLACER_ID != vd.ADT_PLACER_ID OR (mainref.ADT_PLACER_ID IS NULL AND vd.ADT_PLACER_ID IS NOT NULL) OR (mainref.ADT_PLACER_ID IS NOT NULL AND vd.ADT_PLACER_ID IS NULL)
		OR			mainref.SNOMEDCTDiagnosisID != vd.SNOMEDCTDiagnosisID OR (mainref.SNOMEDCTDiagnosisID IS NULL AND vd.SNOMEDCTDiagnosisID IS NOT NULL) OR (mainref.SNOMEDCTDiagnosisID IS NOT NULL AND vd.SNOMEDCTDiagnosisID IS NULL)
		OR			mainref.FasterDiagnosisOrganisationID != vd.FasterDiagnosisOrganisationID OR (mainref.FasterDiagnosisOrganisationID IS NULL AND vd.FasterDiagnosisOrganisationID IS NOT NULL) OR (mainref.FasterDiagnosisOrganisationID IS NOT NULL AND vd.FasterDiagnosisOrganisationID IS NULL)
		OR			mainref.FasterDiagnosisCancerSiteOverrideID != vd.FasterDiagnosisCancerSiteOverrideID OR (mainref.FasterDiagnosisCancerSiteOverrideID IS NULL AND vd.FasterDiagnosisCancerSiteOverrideID IS NOT NULL) OR (mainref.FasterDiagnosisCancerSiteOverrideID IS NOT NULL AND vd.FasterDiagnosisCancerSiteOverrideID IS NULL)
		OR			mainref.FasterDiagnosisExclusionDate != vd.FasterDiagnosisExclusionDate OR (mainref.FasterDiagnosisExclusionDate IS NULL AND vd.FasterDiagnosisExclusionDate IS NOT NULL) OR (mainref.FasterDiagnosisExclusionDate IS NOT NULL AND vd.FasterDiagnosisExclusionDate IS NULL)
		OR			mainref.FasterDiagnosisExclusionReasonID != vd.FasterDiagnosisExclusionReasonID OR (mainref.FasterDiagnosisExclusionReasonID IS NULL AND vd.FasterDiagnosisExclusionReasonID IS NOT NULL) OR (mainref.FasterDiagnosisExclusionReasonID IS NOT NULL AND vd.FasterDiagnosisExclusionReasonID IS NULL)
		OR			mainref.FasterDiagnosisDelayReasonID != vd.FasterDiagnosisDelayReasonID OR (mainref.FasterDiagnosisDelayReasonID IS NULL AND vd.FasterDiagnosisDelayReasonID IS NOT NULL) OR (mainref.FasterDiagnosisDelayReasonID IS NOT NULL AND vd.FasterDiagnosisDelayReasonID IS NULL)
		OR			mainref.FasterDiagnosisDelayReasonComments != vd.FasterDiagnosisDelayReasonComments OR (mainref.FasterDiagnosisDelayReasonComments IS NULL AND vd.FasterDiagnosisDelayReasonComments IS NOT NULL) OR (mainref.FasterDiagnosisDelayReasonComments IS NOT NULL AND vd.FasterDiagnosisDelayReasonComments IS NULL)
		OR			mainref.FasterDiagnosisCommunicationMethodID != vd.FasterDiagnosisCommunicationMethodID OR (mainref.FasterDiagnosisCommunicationMethodID IS NULL AND vd.FasterDiagnosisCommunicationMethodID IS NOT NULL) OR (mainref.FasterDiagnosisCommunicationMethodID IS NOT NULL AND vd.FasterDiagnosisCommunicationMethodID IS NULL)
		OR			mainref.FasterDiagnosisInformingCareProfessionalID != vd.FasterDiagnosisInformingCareProfessionalID OR (mainref.FasterDiagnosisInformingCareProfessionalID IS NULL AND vd.FasterDiagnosisInformingCareProfessionalID IS NOT NULL) OR (mainref.FasterDiagnosisInformingCareProfessionalID IS NOT NULL AND vd.FasterDiagnosisInformingCareProfessionalID IS NULL)
		OR			mainref.FasterDiagnosisOtherCareProfessional != vd.FasterDiagnosisOtherCareProfessional OR (mainref.FasterDiagnosisOtherCareProfessional IS NULL AND vd.FasterDiagnosisOtherCareProfessional IS NOT NULL) OR (mainref.FasterDiagnosisOtherCareProfessional IS NOT NULL AND vd.FasterDiagnosisOtherCareProfessional IS NULL)
		OR			mainref.FasterDiagnosisOtherCommunicationMethod != vd.FasterDiagnosisOtherCommunicationMethod OR (mainref.FasterDiagnosisOtherCommunicationMethod IS NULL AND vd.FasterDiagnosisOtherCommunicationMethod IS NOT NULL) OR (mainref.FasterDiagnosisOtherCommunicationMethod IS NOT NULL AND vd.FasterDiagnosisOtherCommunicationMethod IS NULL)
		OR			mainref.NonPrimaryPathwayOptionsID != vd.NonPrimaryPathwayOptionsID OR (mainref.NonPrimaryPathwayOptionsID IS NULL AND vd.NonPrimaryPathwayOptionsID IS NOT NULL) OR (mainref.NonPrimaryPathwayOptionsID IS NOT NULL AND vd.NonPrimaryPathwayOptionsID IS NULL)
		OR			mainref.DiagnosisUncertainty != vd.DiagnosisUncertainty OR (mainref.DiagnosisUncertainty IS NULL AND vd.DiagnosisUncertainty IS NOT NULL) OR (mainref.DiagnosisUncertainty IS NOT NULL AND vd.DiagnosisUncertainty IS NULL)
		OR			mainref.TNMOrganisation != vd.TNMOrganisation OR (mainref.TNMOrganisation IS NULL AND vd.TNMOrganisation IS NOT NULL) OR (mainref.TNMOrganisation IS NOT NULL AND vd.TNMOrganisation IS NULL)
		OR			mainref.FasterDiagnosisTargetRCComments != vd.FasterDiagnosisTargetRCComments OR (mainref.FasterDiagnosisTargetRCComments IS NULL AND vd.FasterDiagnosisTargetRCComments IS NOT NULL) OR (mainref.FasterDiagnosisTargetRCComments IS NOT NULL AND vd.FasterDiagnosisTargetRCComments IS NULL)
		OR			mainref.FasterDiagnosisEndRCComments != vd.FasterDiagnosisEndRCComments OR (mainref.FasterDiagnosisEndRCComments IS NULL AND vd.FasterDiagnosisEndRCComments IS NOT NULL) OR (mainref.FasterDiagnosisEndRCComments IS NOT NULL AND vd.FasterDiagnosisEndRCComments IS NULL)
		OR			mainref.TNMOrganisation_Integrated != vd.TNMOrganisation_Integrated OR (mainref.TNMOrganisation_Integrated IS NULL AND vd.TNMOrganisation_Integrated IS NOT NULL) OR (mainref.TNMOrganisation_Integrated IS NOT NULL AND vd.TNMOrganisation_Integrated IS NULL)
		OR			mainref.LDHValue != vd.LDHValue OR (mainref.LDHValue IS NULL AND vd.LDHValue IS NOT NULL) OR (mainref.LDHValue IS NOT NULL AND vd.LDHValue IS NULL)
		OR			mainref.BankedTissueUrine != vd.BankedTissueUrine OR (mainref.BankedTissueUrine IS NULL AND vd.BankedTissueUrine IS NOT NULL) OR (mainref.BankedTissueUrine IS NOT NULL AND vd.BankedTissueUrine IS NULL)
		OR			mainref.SubsiteID != vd.SubsiteID OR (mainref.SubsiteID IS NULL AND vd.SubsiteID IS NOT NULL) OR (mainref.SubsiteID IS NOT NULL AND vd.SubsiteID IS NULL)
		OR			mainref.PredictedBreachStatus != vd.PredictedBreachStatus OR (mainref.PredictedBreachStatus IS NULL AND vd.PredictedBreachStatus IS NOT NULL) OR (mainref.PredictedBreachStatus IS NOT NULL AND vd.PredictedBreachStatus IS NULL)
		OR			mainref.RMRefID != vd.RMRefID OR (mainref.RMRefID IS NULL AND vd.RMRefID IS NOT NULL) OR (mainref.RMRefID IS NOT NULL AND vd.RMRefID IS NULL)
		OR			mainref.TertiaryReferralKey != vd.TertiaryReferralKey OR (mainref.TertiaryReferralKey IS NULL AND vd.TertiaryReferralKey IS NOT NULL) OR (mainref.TertiaryReferralKey IS NOT NULL AND vd.TertiaryReferralKey IS NULL)
		OR			mainref.ClinicalTLetter != vd.ClinicalTLetter OR (mainref.ClinicalTLetter IS NULL AND vd.ClinicalTLetter IS NOT NULL) OR (mainref.ClinicalTLetter IS NOT NULL AND vd.ClinicalTLetter IS NULL)
		OR			mainref.ClinicalNLetter != vd.ClinicalNLetter OR (mainref.ClinicalNLetter IS NULL AND vd.ClinicalNLetter IS NOT NULL) OR (mainref.ClinicalNLetter IS NOT NULL AND vd.ClinicalNLetter IS NULL)
		OR			mainref.ClinicalMLetter != vd.ClinicalMLetter OR (mainref.ClinicalMLetter IS NULL AND vd.ClinicalMLetter IS NOT NULL) OR (mainref.ClinicalMLetter IS NOT NULL AND vd.ClinicalMLetter IS NULL)
		OR			mainref.PathologicalTLetter != vd.PathologicalTLetter OR (mainref.PathologicalTLetter IS NULL AND vd.PathologicalTLetter IS NOT NULL) OR (mainref.PathologicalTLetter IS NOT NULL AND vd.PathologicalTLetter IS NULL)
		OR			mainref.PathologicalNLetter != vd.PathologicalNLetter OR (mainref.PathologicalNLetter IS NULL AND vd.PathologicalNLetter IS NOT NULL) OR (mainref.PathologicalNLetter IS NOT NULL AND vd.PathologicalNLetter IS NULL)
		OR			mainref.PathologicalMLetter != vd.PathologicalMLetter OR (mainref.PathologicalMLetter IS NULL AND vd.PathologicalMLetter IS NOT NULL) OR (mainref.PathologicalMLetter IS NOT NULL AND vd.PathologicalMLetter IS NULL)
		OR			mainref.FDPlannedInterval != vd.FDPlannedInterval OR (mainref.FDPlannedInterval IS NULL AND vd.FDPlannedInterval IS NOT NULL) OR (mainref.FDPlannedInterval IS NOT NULL AND vd.FDPlannedInterval IS NULL)
		OR			mainref.LabReportDate != vd.LabReportDate OR (mainref.LabReportDate IS NULL AND vd.LabReportDate IS NOT NULL) OR (mainref.LabReportDate IS NOT NULL AND vd.LabReportDate IS NULL)
		OR			mainref.LabReportOrgID != vd.LabReportOrgID OR (mainref.LabReportOrgID IS NULL AND vd.LabReportOrgID IS NOT NULL) OR (mainref.LabReportOrgID IS NOT NULL AND vd.LabReportOrgID IS NULL)
		OR			mainref.ReferralRoute != vd.ReferralRoute OR (mainref.ReferralRoute IS NULL AND vd.ReferralRoute IS NOT NULL) OR (mainref.ReferralRoute IS NOT NULL AND vd.ReferralRoute IS NULL)
		OR			mainref.ReferralOtherRoute != vd.ReferralOtherRoute OR (mainref.ReferralOtherRoute IS NULL AND vd.ReferralOtherRoute IS NOT NULL) OR (mainref.ReferralOtherRoute IS NOT NULL AND vd.ReferralOtherRoute IS NULL)
		OR			mainref.RelapseMorphology != vd.RelapseMorphology OR (mainref.RelapseMorphology IS NULL AND vd.RelapseMorphology IS NOT NULL) OR (mainref.RelapseMorphology IS NOT NULL AND vd.RelapseMorphology IS NULL)
		OR			mainref.RelapseFlow != vd.RelapseFlow OR (mainref.RelapseFlow IS NULL AND vd.RelapseFlow IS NOT NULL) OR (mainref.RelapseFlow IS NOT NULL AND vd.RelapseFlow IS NULL)
		OR			mainref.RelapseMolecular != vd.RelapseMolecular OR (mainref.RelapseMolecular IS NULL AND vd.RelapseMolecular IS NOT NULL) OR (mainref.RelapseMolecular IS NOT NULL AND vd.RelapseMolecular IS NULL)
		OR			mainref.RelapseClinicalExamination != vd.RelapseClinicalExamination OR (mainref.RelapseClinicalExamination IS NULL AND vd.RelapseClinicalExamination IS NOT NULL) OR (mainref.RelapseClinicalExamination IS NOT NULL AND vd.RelapseClinicalExamination IS NULL)
		OR			mainref.RelapseOther != vd.RelapseOther OR (mainref.RelapseOther IS NULL AND vd.RelapseOther IS NOT NULL) OR (mainref.RelapseOther IS NOT NULL AND vd.RelapseOther IS NULL)
		OR			mainref.RapidDiagnostic != vd.RapidDiagnostic OR (mainref.RapidDiagnostic IS NULL AND vd.RapidDiagnostic IS NOT NULL) OR (mainref.RapidDiagnostic IS NOT NULL AND vd.RapidDiagnostic IS NULL)
		OR			mainref.PrimaryReferralFlag != vd.PrimaryReferralFlag OR (mainref.PrimaryReferralFlag IS NULL AND vd.PrimaryReferralFlag IS NOT NULL) OR (mainref.PrimaryReferralFlag IS NOT NULL AND vd.PrimaryReferralFlag IS NULL)
		OR			mainref.OtherAssessedBy != vd.OtherAssessedBy OR (mainref.OtherAssessedBy IS NULL AND vd.OtherAssessedBy IS NOT NULL) OR (mainref.OtherAssessedBy IS NOT NULL AND vd.OtherAssessedBy IS NULL)
		OR			mainref.SharedBreach != vd.SharedBreach OR (mainref.SharedBreach IS NULL AND vd.SharedBreach IS NOT NULL) OR (mainref.SharedBreach IS NOT NULL AND vd.SharedBreach IS NULL)
		OR			mainref.PredictedBreachYear != vd.PredictedBreachYear OR (mainref.PredictedBreachYear IS NULL AND vd.PredictedBreachYear IS NOT NULL) OR (mainref.PredictedBreachYear IS NOT NULL AND vd.PredictedBreachYear IS NULL)
		OR			mainref.PredictedBreachMonth != vd.PredictedBreachMonth OR (mainref.PredictedBreachMonth IS NULL AND vd.PredictedBreachMonth IS NOT NULL) OR (mainref.PredictedBreachMonth IS NOT NULL AND vd.PredictedBreachMonth IS NULL)

		-- SELECT * FROM Merge_R_Compare.DedupeChangedRefs_work

		-- Find all the dropped minor referrals
		SELECT		SrcSys
					,Src_UID AS CARE_ID
					,SrcSys_MajorExt
					,Src_UID_MajorExt
					,renum_mainref.CARE_ID AS renum_CARE_ID
		INTO		Merge_R_Compare.DedupeDroppedRefs_work
		FROM		Merge_R_Compare.tblMAIN_REFERRALS_tblValidatedData vd_minor
		INNER JOIN	Merge_R_Compare.dbo_tblMAIN_REFERRALS renum_mainref
																		ON	vd_minor.Src_UID_MajorExt = renum_mainref.DW_SOURCE_ID
																		AND vd_minor.SrcSys_MajorExt = renum_mainref.DW_SOURCE_SYSTEM_ID
		WHERE		IsConfirmed = 1
		AND			IsValidatedMajor = 0


/********************************************************************************************************************************************************************************************************************************/
-- Flag any columns that have changed resultant values in the deduplication validation dataset that could alter the merged value
/********************************************************************************************************************************************************************************************************************************/

		PRINT CHAR(13) + '-- Flag any columns that have changed resultant values in the deduplication validation dataset that could alter the merged value' + CHAR(13)
			
		-- Update any SCR referral table values that will have been "lost" because the record is a minor and has been deleted
		UPDATE		rmd
		SET			rmd.IsDedupeDrop = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.DedupeDroppedRefs_work dropped_ref
																		ON	rmd.PreSrcSysID = dropped_ref.SrcSys
																		AND	rmd.PreCare_ID = dropped_ref.CARE_ID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_Referrals'

		-- Update any SCR CWT definitive treatment (TREAT_NO) values that should have been changed because the referral is a minor and has been deleted
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.DedupeDroppedRefs_Work dropped_ref
																		ON	rmd.PreSrcSysID = dropped_ref.SrcSys
																		AND	rmd.PreCare_ID = dropped_ref.CARE_ID
		LEFT JOIN	Merge_R_Compare.pre_scr_cwt pre_scr_cwt
															ON	rmd.PreSrcSysID = pre_scr_cwt.OrigSrcSysID
															AND	rmd.PreRecordID = pre_scr_cwt.OrigCWT_ID
															AND	pre_scr_cwt.TREAT_ID IS NULL
															AND	pre_scr_cwt.DeftTreatmentCode IS NULL
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('DeftDefinitiveTreatment')
		AND			(rmd.DiffType = 'Lost'			-- Lost because the referral was deleted
		OR			(pre_scr_cwt.OrigCWT_ID IS NULL	-- Changed from a 1 (FDT) to a 2 (Sub) because there was a treatment on the minor referral
		AND			rmd.PreValue = 1
		AND			rmd.MerValue = 2)
					)

		-- Ignore any FDT-based CWT status code changes where we are expecting to drop the "2nd" FDT for referrals that have been merged
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	(
					SELECT		rmd_inner.PreSrcSysID
								,rmd_inner.PreRecordID
					FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc_inner
					INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd_inner
																				ON	rmc_inner.ColumnIx = rmd_inner.ColumnIx
					INNER JOIN	Merge_R_Compare.pre_scr_cwt pre_scr_cwt 
																		ON	rmd_inner.PreSrcSysID = pre_scr_cwt.OrigSrcSysID
																		AND	rmd_inner.PreRecordID = pre_scr_cwt.OrigCWT_ID
																		AND	pre_scr_cwt.DeftDefinitiveTreatment = 1
					INNER JOIN	CancerReporting_MERGE.SCR_Warehouse.SCR_CWT post_scr_cwt
																		ON	rmd_inner.MerCare_ID = post_scr_cwt.CARE_ID
																		AND	post_scr_cwt.DeftDefinitiveTreatment = 1
																		AND	post_scr_cwt.TREAT_ID IS NOT NULL
																		AND	post_scr_cwt.DeftTreatmentCode IS NOT NULL
					WHERE		rmc_inner.TableName = 'VwSCR_Warehouse_SCR_CWT'
					AND			rmc_inner.ColumnName IN ('DeftDefinitiveTreatment')	-- with a DEFT TREAT_NO
					AND			rmd_inner.PreValue = 1								-- that Kevin has renumbered from a 1 to a 2
					AND			rmd_inner.MerValue = 2								-- that Kevin has renumbered from a 1 to a 2
					AND			((pre_scr_cwt.TREAT_ID IS NULL							-- has been demoted to TREAT_NO=2 because there was no treatment on their original FDT (TREAT_NO=1) record
					AND			pre_scr_cwt.DeftTreatmentCode IS NULL)					-- has been demoted to TREAT_NO=2 because there was no treatment on their original FDT (TREAT_NO=1) record
					OR			(post_scr_cwt.CARE_ID IS NOT NULL))						-- has been demoted to TREAT_NO=2 because there was another higher priority treatment on another merged definitive treatment (TREAT_NO=1) record
					GROUP BY	rmd_inner.PreSrcSysID
								,rmd_inner.PreRecordID
								) ToBeDroppedFDTs
												ON	rmd.PreSrcSysID = ToBeDroppedFDTs.PreSrcSysID
												AND	rmd.PreRecordID = ToBeDroppedFDTs.PreRecordID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('CWTStatusCode2WW','CWTStatusCode28','CWTStatusCode62')
		AND			rmd.PreValue != 38
		AND			rmd.MerValue = 38

		-- Update any cwtFlag62 / cwtReason62 values that may have been changed because an underlying component of the calculation has changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		LEFT JOIN	Merge_R_Compare.DedupeChangedRefs_work changed_ref
																		ON	rmd.PreSrcSysID = changed_ref.SrcSys
																		AND	rmd.PreCare_ID = changed_ref.CARE_ID
																			
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('cwtFlag62','cwtReason62')
		AND			(changed_ref.TRANSFER_REASON_Diff = 1
		OR			changed_ref.L_INAP_REF_Diff = 1
		OR			changed_ref.L_FIRST_APP_Diff = 1
		OR			changed_ref.L_NO_APP_Diff = 1
		OR			changed_ref.N2_13_CANCER_STATUS_Diff = 1
		OR			changed_ref.L_DIAGNOSIS_Diff = 1
		OR			changed_ref.SNOMed_CT_Diff = 1
		OR			changed_ref.N4_5_HISTOLOGY_Diff = 1
		OR			changed_ref.L_TUMOUR_STATUS_Diff = 1
		OR			changed_ref.N2_4_PRIORITY_TYPE_Diff = 1
		OR			changed_ref.N2_16_OP_REFERRAL_Diff = 1
		OR			changed_ref.N_UPGRADE_DATE_Diff = 1)

		-- Update any cwtType62 values that may have been changed because an underlying component of the calculation has changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		LEFT JOIN	Merge_R_Compare.DedupeChangedRefs_work changed_ref
																		ON	rmd.PreSrcSysID = changed_ref.SrcSys
																		AND	rmd.PreCare_ID = changed_ref.Src_UID
		LEFT JOIN	LocalConfig.tblMAIN_REFERRALS mainref
														ON	rmd.PreSrcSysID = mainref.SrcSysID
														AND	rmd.PreCare_ID = mainref.CARE_ID
		LEFT JOIN	Merge_R_Compare.DedupeChangedDemographics_work changed_dem
																			ON	mainref.SrcSysID = changed_dem.SrcSysID
																			AND	mainref.PATIENT_ID = changed_dem.PATIENT_ID
		LEFT JOIN	Merge_R_Compare.DedupeDroppedRefs_work dropped_ref
																		ON	rmd.PreSrcSysID = dropped_ref.SrcSys
																		AND	rmd.PreCare_ID = dropped_ref.CARE_ID
																			
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('cwtType62','Pathway')
		AND			(changed_ref.N2_16_OP_REFERRAL_Diff = 1
		OR			changed_ref.N_UPGRADE_DATE_Diff = 1
		OR			changed_ref.N2_12_CANCER_TYPE_Diff = 1
		OR			changed_dem.N1_10_DATE_BIRTH_Diff = 1
		OR			changed_ref.N2_6_RECEIPT_DATE_Diff = 1
		OR			changed_ref.N4_2_DIAGNOSIS_CODE_Diff = 1
		OR			changed_ref.N2_4_PRIORITY_TYPE_Diff = 1
		OR			dropped_ref.SrcSys IS NOT NULL)

		-- Update any cwtStatusCode28 values that may have been changed because an underlying component of the calculation has changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		LEFT JOIN	Merge_R_Compare.DedupeChangedRefs_work changed_ref
																		ON	rmd.PreSrcSysID = changed_ref.SrcSys
																		AND	rmd.PreCare_ID = changed_ref.Src_UID
		LEFT JOIN	(SELECT		OrigSrcSysID
								,OrigCARE_ID
								,MIN(pre_scr_cwt.DeftDateDecisionTreat) AS MinDeftDateDecisionTreat
					FROM		Merge_R_Compare.pre_scr_cwt 
					GROUP BY	OrigSrcSysID
								,OrigCARE_ID
								) pre_scr_cwt_minor
												ON	rmd.PreSrcSysID = pre_scr_cwt_minor.OrigSrcSysID
												AND	rmd.PreCare_ID = pre_scr_cwt_minor.OrigCARE_ID
		LEFT JOIN	(SELECT		SrcSysID
								,CARE_ID
								,MIN(pre_scr_cwt.DeftDateDecisionTreat) AS MinDeftDateDecisionTreat
					FROM		Merge_R_Compare.pre_scr_cwt 
					GROUP BY	SrcSysID
								,CARE_ID
								) pre_scr_cwt_major
												ON	rmd.MerCare_ID = pre_scr_cwt_major.CARE_ID
		WHERE		((rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('cwtStatusCode28'))
		OR			(rmc.TableName = 'VwSCR_Warehouse_SCR_Referrals'
		AND			rmc.ColumnName IN ('FastDiagEndReasonID')))
		AND			(changed_ref.FasterDiagnosisExclusionDate_Diff = 1
		OR			changed_ref.L_PT_INFORMED_DATE_Diff = 1
		OR			changed_ref.L_Diagnosis_Diff = 1
		OR			changed_ref.SNOMed_CT_Diff = 1
		OR			changed_ref.N4_5_HISTOLOGY_Diff = 1
		OR			changed_ref.N2_13_CANCER_STATUS_Diff = 1
		OR			changed_ref.FDPlannedInterval_Diff = 1
		OR			changed_ref.L_TUMOUR_STATUS_Diff = 1
		OR			changed_ref.N4_2_DIAGNOSIS_CODE_Diff = 1
		OR			pre_scr_cwt_minor.MinDeftDateDecisionTreat != pre_scr_cwt_major.MinDeftDateDecisionTreat
		OR			(pre_scr_cwt_minor.MinDeftDateDecisionTreat IS NULL AND pre_scr_cwt_major.MinDeftDateDecisionTreat IS NOT NULL)
		OR			(pre_scr_cwt_minor.MinDeftDateDecisionTreat IS NOT NULL AND pre_scr_cwt_major.MinDeftDateDecisionTreat IS NULL))


		-- Update any cwtStatusCode62 values that may have been changed because an underlying component of the calculation has changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		LEFT JOIN	Merge_R_Compare.DedupeChangedRefs_Work changed_ref
																		ON	rmd.PreSrcSysID = changed_ref.SrcSys
																		AND	rmd.PreCare_ID = changed_ref.Src_UID
		LEFT JOIN	CancerReporting_PREMERGE.SCR_Warehouse.SCR_Referrals pre_scr_ref
																ON	rmd.PreSrcSysID = pre_scr_ref.SrcSysID
																AND	rmd.PreCare_ID = pre_scr_ref.CARE_ID
		LEFT JOIN	CancerReporting_MERGE.SCR_Warehouse.SCR_Referrals post_scr_ref
																				ON rmd.MerCare_ID = post_scr_ref.CARE_ID
		LEFT JOIN	(SELECT		rmd_inner.PreSrcSysID, rmd_inner.PreRecordID
					FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc_inner INNER JOIN Merge_R_Compare.ReportingMergeDifferences_Work rmd_inner ON rmc_inner.ColumnIx = rmd_inner.ColumnIx 
					WHERE		rmc_inner.TableName = 'VwSCR_Warehouse_SCR_CWT'
					AND			rmc_inner.ColumnName IN ('DeftOrgCodeTreatment','DeftDateTreatment','cwtFlag2WW','cwtFlag62','TargetDate62','ReportDate','cwtFlag28','cwtType62','Pathway','ReportingPathwayLength')
					GROUP BY	rmd_inner.PreSrcSysID, rmd_inner.PreRecordID
								) changed_wh_cwt
											ON	rmd.PreSrcSysID = changed_wh_cwt.PreSrcSysID
											AND	rmd.PreRecordID = changed_wh_cwt.PreRecordID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('cwtStatusCode62')
		AND			(changed_ref.N2_13_CANCER_STATUS_Diff = 1
		OR			changed_ref.N4_1_DIAGNOSIS_DATE_Diff = 1
		OR			changed_ref.N2_9_FIRST_SEEN_DATE_Diff = 1
		OR			changed_ref.L_Diagnosis_Diff = 1
		OR			changed_ref.SNOMed_CT_Diff = 1
		OR			changed_ref.N4_5_HISTOLOGY_Diff = 1
		OR			changed_ref.L_FIRST_APP_Diff = 1
		OR			changed_ref.N2_6_RECEIPT_DATE_Diff = 1
		OR			changed_ref.L_CANCER_SITE_Diff = 1
		OR			changed_ref.N2_12_CANCER_TYPE_Diff = 1
		OR			changed_ref.N2_7_CONSULTANT_Diff = 1
		OR			changed_ref.N_UPGRADE_DATE_Diff = 1
		OR			changed_ref.N2_16_OP_REFERRAL_Diff = 1
		OR			changed_ref.N2_4_PRIORITY_TYPE_Diff = 1
		OR			changed_ref.L_NO_APP_Diff = 1
		OR			changed_ref.FasterDiagnosisOrganisationID_Diff = 1
		OR			changed_ref.N1_3_ORG_CODE_SEEN_Diff = 1
		OR			(pre_scr_ref.DateDeath != post_scr_ref.DateDeath)
		OR			(pre_scr_ref.DateDeath IS NULL AND post_scr_ref.DateDeath IS NOT NULL)
		OR			(pre_scr_ref.DateDeath IS NOT NULL AND post_scr_ref.DateDeath IS NULL)
		OR			changed_wh_cwt.PreSrcSysID IS NOT NULL)


		-- Update any UnifyPtlStatusCode values that may have been changed because an underlying component of the calculation has changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		LEFT JOIN	Merge_R_Compare.DedupeChangedRefs_Work changed_ref
																		ON	rmd.PreSrcSysID = changed_ref.SrcSys
																		AND	rmd.PreCare_ID = changed_ref.Src_UID
		--LEFT JOIN	CancerReporting_PREMERGE.SCR_Warehouse.SCR_Referrals pre_scr_ref
		--														ON	rmd.PreSrcSysID = pre_scr_ref.SrcSysID
		--														AND	rmd.PreCare_ID = pre_scr_ref.CARE_ID
		--LEFT JOIN	CancerReporting_MERGE.SCR_Warehouse.SCR_Referrals post_scr_ref
		--																		ON rmd.MerCare_ID = post_scr_ref.CARE_ID
		LEFT JOIN	(SELECT		rmd_inner.PreSrcSysID, rmd_inner.PreRecordID
					FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc_inner INNER JOIN Merge_R_Compare.ReportingMergeDifferences_Work rmd_inner ON rmc_inner.ColumnIx = rmd_inner.ColumnIx 
					WHERE		rmc_inner.TableName = 'VwSCR_Warehouse_SCR_CWT'
					AND			rmc_inner.ColumnName IN ('DeftDateTreatment','CwtPathwayTypeDesc62','cwtType62','Pathway','CWTStatusCode62','DeftDateDecisionTreat')
					AND			rmd_inner.DiffType = 'Different'
					GROUP BY	rmd_inner.PreSrcSysID, rmd_inner.PreRecordID
								) changed_wh_cwt
											ON	rmd.PreSrcSysID = changed_wh_cwt.PreSrcSysID
											AND	rmd.PreRecordID = changed_wh_cwt.PreRecordID
		LEFT JOIN	(SELECT		rmd_inner2.PreSrcSysID, rmd_inner2.MerCare_ID
					FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc_inner2 INNER JOIN Merge_R_Compare.ReportingMergeDifferences_Work rmd_inner2 ON rmc_inner2.ColumnIx = rmd_inner2.ColumnIx 
					WHERE		rmc_inner2.TableName = 'VwSCR_Warehouse_SCR_InterProviderTransfers'
					AND			rmc_inner2.ColumnName IN ('CareID')
					AND			rmd_inner2.DiffType = 'Different'
					GROUP BY	rmd_inner2.PreSrcSysID, rmd_inner2.MerCare_ID
								) changed_wh_ipt
											ON	rmd.MerCare_ID = changed_wh_ipt.MerCare_ID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('UnifyPtlStatusCode')
		AND			(changed_ref.N2_10_FIRST_SEEN_DELAY_Diff = 1
		OR			changed_ref.L_CANCELLED_DATE_Diff = 1
		OR			changed_ref.N_UPGRADE_DATE_Diff = 1
		OR			changed_ref.N2_6_RECEIPT_DATE_Diff = 1
		OR			changed_ref.L_CANCER_SITE_Diff = 1
		OR			changed_ref.N2_12_CANCER_TYPE_Diff = 1
		OR			changed_wh_cwt.PreSrcSysID IS NOT NULL/*
		OR			changed_wh_ipt.PreSrcSysID IS NOT NULL*/)


		-- Update any cwtFlagSurv values that may have been changed because a later treatment was added
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
--		SELECT		cwt_minor.DeftDefinitiveTreatment
--					,cwt_minor.DeftDateTreatment
--					,cwt_major.DeftDefinitiveTreatment
--					,cwt_major.DeftDateTreatment
--					,*
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.tblMAIN_REFERRALS_tblValidatedData vd_minor
																				ON	rmd.PreSrcSysID = vd_minor.SrcSys
																				AND	rmd.PreCare_ID = vd_minor.Src_UID
																				AND	vd_minor.IsConfirmed = 1
		INNER JOIN	Merge_R_Compare.pre_scr_cwt cwt_minor
														ON	rmd.PreSrcSysID = cwt_minor.OrigSrcSysID
														AND	rmd.PreCare_ID = cwt_minor.OrigCARE_ID
		INNER JOIN	(SELECT		*
								,COUNT(*) OVER (PARTITION BY SrcSys_MajorExt, Src_UID_MajorExt) AS MajorCount
					FROM		Merge_R_Compare.tblMAIN_REFERRALS_tblValidatedData
					WHERE		IsConfirmed = 1
								) vd_major
																				ON	vd_minor.SrcSys_MajorExt = vd_major.SrcSys_MajorExt
																				AND	vd_minor.Src_UID_MajorExt = vd_major.Src_UID_MajorExt
		INNER JOIN	Merge_R_Compare.pre_scr_cwt cwt_major
														ON	vd_major.SrcSys = cwt_major.OrigSrcSysID
														AND	vd_major.Src_UID = cwt_major.OrigCARE_ID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('cwtFlagSurv','ClockStartDateSurv','WaitingtimeSurv','CWTStatusCodeSurv','CWTStatusDescSurv','CwtPathwayTypeIdSurv','CwtPathwayTypeDescSurv','DefaultShowSurv')
		AND			(cwt_major.DeftDefinitiveTreatment != cwt_minor.DeftDefinitiveTreatment
		OR			cwt_major.DeftDateTreatment != cwt_minor.DeftDateTreatment
		OR			(cwt_major.DeftDateTreatment IS NOT NULL AND cwt_minor.DeftDateTreatment IS NULL)
		OR			(cwt_major.DeftDateTreatment IS NULL AND cwt_minor.DeftDateTreatment IS NOT NULL)
		OR			vd_major.MajorCount > 1
					)

		-- Update any SCR CWT table values that will have been changed because the deft record has been designated as a subsequent treatment
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.DedupeDroppedRefs_Work dropped_ref
																ON	rmd.PreSrcSysID = dropped_ref.SrcSys
																AND	rmd.PreCare_ID = dropped_ref.CARE_ID
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd_fdt_to_sub
																					ON	rmd.PreSrcSysID = rmd_fdt_to_sub.PreSrcSysID
																					AND	rmd.PreRecordID = rmd_fdt_to_sub.PreRecordID
																					AND	rmd_fdt_to_sub.PreValue = 1
																					AND	rmd_fdt_to_sub.MerValue = 2
		INNER JOIN	Merge_R_Compare.ReportingMergeColumns_Work rmc_fdt_to_sub
																				ON	rmd_fdt_to_sub.ColumnIx = rmc_fdt_to_sub.ColumnIx
																				AND	rmc_fdt_to_sub.TableName = 'VwSCR_Warehouse_SCR_CWT'
																				AND	rmc_fdt_to_sub.ColumnName IN ('DeftDefinitiveTreatment')
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('cwtFlag2WW','cwtFlag28','cwtFlag62','ReportingPathwayLength')
		AND			rmd.PreValue != 4
		AND			rmd.MerValue = 4

		-- Update any SCR CWT table values that will have been changed because the referral record has been re-assigned to a 2WW
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		--INNER JOIN	Merge_R_Compare.DedupeDroppedRefs_Work dropped_ref
		--														ON	rmd.PreSrcSysID = dropped_ref.SrcSys
		--														AND	rmd.PreCare_ID = dropped_ref.CARE_ID
		INNER JOIN	Merge_R_Compare.DedupeChangedRefs_Work changed_ref
																ON	rmd.PreSrcSysID = changed_ref.SrcSys
																AND	rmd.PreCare_ID = changed_ref.Src_UID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('cwtFlag2WW','ReportingPathwayLength')
		AND			rmd.PreValue = 4
		AND			rmd.MerValue != 4
		AND			changed_ref.N2_4_PRIORITY_TYPE_Diff = 1

		-- Update any SCR CWT table values that will have been changed because the deft record has been designated as a subsequent treatment
		UPDATE		rmd
		SET			rmd.IsDedupeDrop = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.DedupeDroppedRefs_Work dropped_ref
																ON	rmd.PreSrcSysID = dropped_ref.SrcSys
																AND	rmd.PreCare_ID = dropped_ref.CARE_ID
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd_fdt_to_sub
																					ON	rmd.PreSrcSysID = rmd_fdt_to_sub.PreSrcSysID
																					AND	rmd.PreRecordID = rmd_fdt_to_sub.PreRecordID
																					AND	rmd_fdt_to_sub.PreValue = 1
																					AND	rmd_fdt_to_sub.MerValue = 2
		INNER JOIN	Merge_R_Compare.ReportingMergeColumns_Work rmc_fdt_to_sub
																				ON	rmd_fdt_to_sub.ColumnIx = rmc_fdt_to_sub.ColumnIx
																				AND	rmc_fdt_to_sub.TableName = 'VwSCR_Warehouse_SCR_CWT'
																				AND	rmc_fdt_to_sub.ColumnName IN ('DeftDefinitiveTreatment')
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('cwtReason2WW','cwtReason28','cwtReason62')
		AND			rmd.PreValue IS NOT NULL
		AND			rmd.MerValue IS NULL

		-- Update any SCR CWT table values that will have been changed because the referral record has been re-assigned to a 2WW
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		--INNER JOIN	Merge_R_Compare.DedupeDroppedRefs_Work dropped_ref
		--														ON	rmd.PreSrcSysID = dropped_ref.SrcSys
		--														AND	rmd.PreCare_ID = dropped_ref.CARE_ID
		INNER JOIN	Merge_R_Compare.DedupeChangedRefs_Work changed_ref
																ON	rmd.PreSrcSysID = changed_ref.SrcSys
																AND	rmd.PreCare_ID = changed_ref.Src_UID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('cwtReason2WW')
		AND			(changed_ref.N2_4_PRIORITY_TYPE_Diff = 1
		OR			changed_ref.TRANSFER_REASON_Diff = 1
		OR			changed_ref.L_INAP_REF_Diff = 1
		OR			changed_ref.N2_9_FIRST_SEEN_DATE_Diff = 1
		OR			changed_ref.N2_13_CANCER_STATUS_Diff = 1
		OR			changed_ref.L_FIRST_APP_Diff = 1
		OR			changed_ref.L_TUMOUR_STATUS_Diff = 1
					)

		-- Update any SCR CWT table values that will have been changed because the referral record has been re-assigned to a 2WW
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		LEFT JOIN	Merge_R_Compare.DedupeDroppedRefs_Work dropped_ref
																ON	rmd.PreSrcSysID = dropped_ref.SrcSys
																AND	rmd.PreCare_ID = dropped_ref.CARE_ID
		INNER JOIN	Merge_R_Compare.DedupeChangedRefs_Work changed_ref
																ON	rmd.PreSrcSysID = changed_ref.SrcSys
																AND	rmd.PreCare_ID = changed_ref.Src_UID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('cwtType2WW','cwtReason2WW','Pathway')
		AND			(changed_ref.N2_4_PRIORITY_TYPE_Diff = 1
		OR			changed_ref.N2_12_CANCER_TYPE_Diff = 1
		OR			dropped_ref.SrcSys IS NOT NULL
					)

		-- Update any SCR CWT table values that will have been changed because the referral record has changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.DedupeChangedRefs_Work changed_ref
																ON	rmd.PreSrcSysID = changed_ref.SrcSys
																AND	rmd.PreCare_ID = changed_ref.Src_UID
		LEFT JOIN	Merge_R_Compare.DedupeDroppedRefs_Work dropped_ref
																ON	rmd.PreSrcSysID = dropped_ref.SrcSys
																AND	rmd.PreCare_ID = dropped_ref.CARE_ID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('cwtType28','cwtFlag28','cwtReason28')
		AND			(changed_ref.N2_4_PRIORITY_TYPE_Diff = 1
		OR			changed_ref.N2_12_CANCER_TYPE_Diff = 1
		OR			changed_ref.N2_1_REFERRAL_SOURCE_Diff = 1
		OR			changed_ref.N_UPGRADE_DATE_Diff = 1
		OR			changed_ref.N2_6_RECEIPT_DATE_Diff = 1
		OR			dropped_ref.SrcSys IS NOT NULL
					)

		-- Update any SCR CWT table values that will have been changed because the referral record has changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.DedupeChangedRefs_Work changed_ref
																ON	rmd.PreSrcSysID = changed_ref.SrcSys
																AND	rmd.PreCare_ID = changed_ref.Src_UID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('cwtFlag28','cwtReason28')
		AND			(changed_ref.N2_4_PRIORITY_TYPE_Diff = 1
		OR			changed_ref.N2_12_CANCER_TYPE_Diff = 1
		OR			changed_ref.N2_1_REFERRAL_SOURCE_Diff = 1
		OR			changed_ref.N_UPGRADE_DATE_Diff = 1
		OR			changed_ref.N2_6_RECEIPT_DATE_Diff = 1
		OR			changed_ref.TRANSFER_REASON_Diff = 1
		OR			changed_ref.L_INAP_REF_Diff = 1
		OR			changed_ref.N2_13_CANCER_STATUS_Diff = 1
		OR			changed_ref.L_FIRST_APP_Diff = 1
		OR			changed_ref.L_TUMOUR_STATUS_Diff = 1
		OR			changed_ref.FasterDiagnosisExclusionDate_Diff = 1
		OR			changed_ref.FasterDiagnosisExclusionReasonID_Diff = 1
		OR			changed_ref.L_PT_INFORMED_DATE_Diff = 1
		OR			changed_ref.FDPlannedInterval_Diff = 1
		OR			changed_ref.SNOMed_CT_Diff = 1
		OR			changed_ref.N4_2_DIAGNOSIS_CODE_Diff = 1
					)

		-- Update any SCR CWT table values that will have been changed because the referral record has changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.DedupeChangedRefs_Work changed_ref
																ON	rmd.PreSrcSysID = changed_ref.SrcSys
																AND	rmd.PreCare_ID = changed_ref.Src_UID
		LEFT JOIN	Merge_R_Compare.DedupeDroppedRefs_Work dropped_ref
																ON	rmd.PreSrcSysID = dropped_ref.SrcSys
																AND	rmd.PreCare_ID = dropped_ref.CARE_ID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('ClockStartDate2WW','ClockStartDate28','ClockStartDate62'
										,'TargetDate2WW','TargetDate28','TargetDate62'
										,'DaysTo2WWBreach','DaysTo28DayBreach','DaysTo62DayBreach'
										,'Breach2WW','Breach28','Breach62'
										,'WillBeBreach2WW','WillBeBreach28','WillBeBreach62')
		AND			(changed_ref.N2_6_RECEIPT_DATE_Diff = 1
		OR			changed_ref.N_UPGRADE_DATE_Diff = 1
		OR			dropped_ref.SrcSys IS NOT NULL
					)

		-- Update any SCR CWT table values that will have been changed because the referral record has changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.DedupeChangedRefs_Work changed_ref
																ON	rmd.PreSrcSysID = changed_ref.SrcSys
																AND	rmd.PreCare_ID = changed_ref.Src_UID
		LEFT JOIN	Merge_R_Compare.DedupeDroppedRefs_Work dropped_ref
																ON	rmd.PreSrcSysID = dropped_ref.SrcSys
																AND	rmd.PreCare_ID = dropped_ref.CARE_ID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('DaysTo2WWBreach','DaysTo28DayBreach','DaysTo62DayBreach'
										,'WillBeBreach2WW','WillBeBreach28','WillBeBreach62')
		AND			(changed_ref.N2_4_PRIORITY_TYPE_Diff = 1
		OR			dropped_ref.SrcSys IS NOT NULL
					)

		-- Update any SCR CWT table values that will have been changed because the referral record has changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		--INNER JOIN	Merge_R_Compare.DedupeDroppedRefs_Work dropped_ref
		--														ON	rmd.PreSrcSysID = dropped_ref.SrcSys
		--														AND	rmd.PreCare_ID = dropped_ref.CARE_ID
		INNER JOIN	Merge_R_Compare.DedupeChangedRefs_Work changed_ref
																ON	rmd.PreSrcSysID = changed_ref.SrcSys
																AND	rmd.PreCare_ID = changed_ref.Src_UID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('WillBeClockStopDate2WW','ClockStopDate2WW','DaysTo2WWBreach'
										,'Breach2WW'
										,'WillBeBreach2WW')

		-- Update any SCR CWT table values that will have been changed because the referral record has changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		--INNER JOIN	Merge_R_Compare.DedupeDroppedRefs_Work dropped_ref
		--														ON	rmd.PreSrcSysID = dropped_ref.SrcSys
		--														AND	rmd.PreCare_ID = dropped_ref.CARE_ID
		INNER JOIN	Merge_R_Compare.DedupeChangedRefs_Work changed_ref
																ON	rmd.PreSrcSysID = changed_ref.SrcSys
																AND	rmd.PreCare_ID = changed_ref.Src_UID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('Waitingtime2WW','WaitingTime28','WaitingTime62'
										,'WillBeWaitingtime2WW','WillBeWaitingTime28','WillBeWaitingTime62'
										,'ReportingPathwayLength')
		AND			(changed_ref.N2_9_FIRST_SEEN_DATE_Diff = 1
		OR			changed_ref.N2_6_RECEIPT_DATE_Diff = 1
		OR			changed_ref.N_UPGRADE_DATE_Diff = 1
					)

		-- Update any SCR CWT table values that will have been changed because the deft record has been designated as a subsequent treatment
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd_fdt_to_sub
																					ON	rmd.MerCare_ID = rmd_fdt_to_sub.MerCare_ID
																					AND	rmd_fdt_to_sub.PreValue = 1
																					AND	rmd_fdt_to_sub.MerValue = 2
		INNER JOIN	Merge_R_Compare.ReportingMergeColumns_Work rmc_fdt_to_sub
																				ON	rmd_fdt_to_sub.ColumnIx = rmc_fdt_to_sub.ColumnIx
																				AND	rmc_fdt_to_sub.TableName = 'VwSCR_Warehouse_SCR_CWT'
																				AND	rmc_fdt_to_sub.ColumnName IN ('DeftDefinitiveTreatment')
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('Waitingtime2WW','WaitingTime28','WaitingTime62'
										,'WillBeWaitingtime2WW','WillBeWaitingTime28','WillBeWaitingTime62'
										,'ReportingPathwayLength')

		-- Update any SCR CWT table values that will have been changed because the deft record has been re-designated as an eligible 2WW
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd_fdt_to_sub
																					ON	rmd.MerCare_ID = rmd_fdt_to_sub.MerCare_ID
																					AND	rmd_fdt_to_sub.PreValue = 4
																					AND	rmd_fdt_to_sub.MerValue != 4
		INNER JOIN	Merge_R_Compare.ReportingMergeColumns_Work rmc_fdt_to_sub
																				ON	rmd_fdt_to_sub.ColumnIx = rmc_fdt_to_sub.ColumnIx
																				AND	rmc_fdt_to_sub.TableName = 'VwSCR_Warehouse_SCR_CWT'
																				AND	rmc_fdt_to_sub.ColumnName IN ('cwtFlag2WW')
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('TargetDate2WW')

		-- Update any SCR CWT table values that will have been changed because the deft record has been re-designated as an eligible FDS
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd_fdt_to_sub
																					ON	rmd.MerCare_ID = rmd_fdt_to_sub.MerCare_ID
																					AND	rmd_fdt_to_sub.PreValue = 4
																					AND	rmd_fdt_to_sub.MerValue != 4
		INNER JOIN	Merge_R_Compare.ReportingMergeColumns_Work rmc_fdt_to_sub
																				ON	rmd_fdt_to_sub.ColumnIx = rmc_fdt_to_sub.ColumnIx
																				AND	rmc_fdt_to_sub.TableName = 'VwSCR_Warehouse_SCR_CWT'
																				AND	rmc_fdt_to_sub.ColumnName IN ('cwtFlag28')
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('TargetDate28')

		-- Update any SCR CWT table values that will have been changed because the deft record has been re-designated as an eligible 62D treatment
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd_fdt_to_sub
																					ON	rmd.MerCare_ID = rmd_fdt_to_sub.MerCare_ID
																					AND	rmd_fdt_to_sub.PreValue = 4
																					AND	rmd_fdt_to_sub.MerValue != 4
		INNER JOIN	Merge_R_Compare.ReportingMergeColumns_Work rmc_fdt_to_sub
																				ON	rmd_fdt_to_sub.ColumnIx = rmc_fdt_to_sub.ColumnIx
																				AND	rmc_fdt_to_sub.TableName = 'VwSCR_Warehouse_SCR_CWT'
																				AND	rmc_fdt_to_sub.ColumnName IN ('cwtFlag62')
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('TargetDate62')

		-- Update any SCR CWT table values that will have been changed because the referral record has been dropped
		UPDATE		rmd
		SET			rmd.IsDedupeDrop = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		LEFT JOIN	Merge_R_Compare.DedupeDroppedRefs_Work dropped_ref
																ON	rmd.PreSrcSysID = dropped_ref.SrcSys
																AND	rmd.PreCare_ID = dropped_ref.CARE_ID
		LEFT JOIN	Merge_R_Compare.DedupeChangedRefs_Work changed_ref
																ON	rmd.PreSrcSysID = changed_ref.SrcSys
																AND	rmd.PreCare_ID = changed_ref.Src_UID
		LEFT JOIN	(SELECT		OrigSrcSysID
								,OrigCARE_ID
								,MIN(pre_scr_cwt.DeftDateDecisionTreat) AS MinDeftDateDecisionTreat
					FROM		Merge_R_Compare.pre_scr_cwt 
					GROUP BY	OrigSrcSysID
								,OrigCARE_ID
								) pre_scr_cwt_minor
												ON	rmd.PreSrcSysID = pre_scr_cwt_minor.OrigSrcSysID
												AND	rmd.PreCare_ID = pre_scr_cwt_minor.OrigCARE_ID
		LEFT JOIN	(SELECT		SrcSysID
								,CARE_ID
								,MIN(pre_scr_cwt.DeftDateDecisionTreat) AS MinDeftDateDecisionTreat
					FROM		Merge_R_Compare.pre_scr_cwt 
					GROUP BY	SrcSysID
								,CARE_ID
								) pre_scr_cwt_major
												ON	rmd.MerCare_ID = pre_scr_cwt_major.CARE_ID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('WillBeClockStopDate28','ClockStopDate28','DaysTo28DayBreach'
										,'Breach28'
										,'WillBeBreach28')
		AND			(dropped_ref.SrcSys IS NOT NULL
		OR			changed_ref.FasterDiagnosisExclusionDate_Diff = 1
		OR			changed_ref.FasterDiagnosisExclusionReasonID_Diff = 1
		OR			changed_ref.L_PT_INFORMED_DATE_Diff = 1
		OR			changed_ref.FDPlannedInterval_Diff = 1
		OR			changed_ref.SNOMed_CT_Diff = 1
		OR			changed_ref.N4_2_DIAGNOSIS_CODE_Diff = 1
		OR			pre_scr_cwt_minor.MinDeftDateDecisionTreat != pre_scr_cwt_major.MinDeftDateDecisionTreat
		OR			(pre_scr_cwt_minor.MinDeftDateDecisionTreat IS NULL AND pre_scr_cwt_major.MinDeftDateDecisionTreat IS NOT NULL)
		OR			(pre_scr_cwt_minor.MinDeftDateDecisionTreat IS NOT NULL AND pre_scr_cwt_major.MinDeftDateDecisionTreat IS NULL))

		-- Update any SCR CWT table values that will have been changed because the referral record has been dropped
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.DedupeDroppedRefs_Work dropped_ref
																ON	rmd.PreSrcSysID = dropped_ref.SrcSys
																AND	rmd.PreCare_ID = dropped_ref.CARE_ID
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('WillBeClockStopDate31','ClockStopDate31'
										,'WillBeClockStopDate62','ClockStopDate62','DaysTo62DayBreach'
										,'Breach31','Breach62'
										,'WillBeBreach31','WillBeBreach62')

		-- Update any cwtFlag62 / cwtReason62 values that may have been changed because an underlying component of the calculation has changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		LEFT JOIN	Merge_R_Compare.DedupeChangedRefs_work changed_ref
																		ON	rmd.PreSrcSysID = changed_ref.SrcSys
																		AND	rmd.PreCare_ID = changed_ref.Src_UID
																			
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('AdjTime2WW','AdjTime28'
										,'TargetDate2WW','TargetDate28'
										,'Waitingtime2WW','WaitingTime28'
										,'WillBeWaitingtime2WW','WillBeWaitingTime28'
										,'Breach2WW','Breach28'
										,'WillBeBreach2WW','WillBeBreach28'
										,'ReportingPathwayLength')
		AND			(changed_ref.N2_15_ADJ_REASON_Diff = 1
		OR			changed_ref.L_CANCELLED_DATE_Diff = 1)

		-- Update any cwtFlag62 / cwtReason62 values that may have been changed because an underlying component of the calculation has changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		LEFT JOIN	Merge_R_Compare.DedupeDroppedRefs_Work dropped_ref
																ON	rmd.PreSrcSysID = dropped_ref.SrcSys
																AND	rmd.PreCare_ID = dropped_ref.CARE_ID
		LEFT JOIN	Merge_R_Compare.DedupeChangedRefs_work changed_ref
																		ON	rmd.PreSrcSysID = changed_ref.SrcSys
																		AND	rmd.PreCare_ID = changed_ref.Src_UID
																			
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('AdjTime62','TargetDate62','WaitingTime62','Breach62','WillBeBreach62','ReportingPathwayLength')
		AND			(dropped_ref.SrcSys IS NOT NULL
		OR			changed_ref.N16_4_ADJ_TREAT_CODE_Diff = 1)

		-- Update any cwtFlag62 / cwtReason62 values that may have been changed because an underlying component of the calculation has changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.DedupeDroppedRefs_Work dropped_ref
																ON	rmd.PreSrcSysID = dropped_ref.SrcSys
																AND	rmd.PreCare_ID = dropped_ref.CARE_ID
																			
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_CWT'
		AND			rmc.ColumnName IN ('AdjTime31','TargetDate31','Breach31','WillBeBreach31')


		-- Update any PatientPathwayID values that may have been changed because an underlying component of the calculation has changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	Merge_R_Compare.tblMAIN_REFERRALS_tblValidatedData merged_ref
																		ON	rmd.PreSrcSysID = merged_ref.SrcSys
																		AND	rmd.PreCare_ID = merged_ref.Src_UID
																		AND	merged_ref.IsConfirmed = 1
																			
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_Referrals'
		AND			rmc.ColumnName IN ('PatientPathwayID','PatientPathwayIdIssuer')

		-- Update any DemographicsActionId values that haven't mapped because the demographic record was changed
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
		INNER JOIN	SCR_Warehouse.SCR_Referrals pre_ref
																		ON	rmd.PreSrcSysID = pre_ref.SrcSysID
																		AND	rmd.PreCare_ID = pre_ref.CARE_ID
		INNER JOIN	CancerReporting_MERGE.SCR_Warehouse.SCR_Referrals post_ref
																		ON	rmd.MerCare_ID = post_ref.CARE_ID
		INNER JOIN	Merge_R_Compare.DedupeChangedDemographics_Work changed_dem
																				ON	pre_ref.SrcSysID = changed_dem.SrcSysID
																				AND	pre_ref.PATIENT_ID = changed_dem.PATIENT_ID
																			
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_Referrals'
		AND			rmc.ColumnName IN ('DemographicsActionId')
		AND			pre_ref.DemographicsActionId = post_ref.DemographicsActionId

		-- Ignore any nhs number status codes that have been changed from NULL to 03 - this is a backstop default value in the merge process
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
																			
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_Referrals'
		AND			rmc.ColumnName IN ('NHSNumberStatusCode')
		AND			rmd.PreValue IS NULL
		AND			rmd.MerValue = '03'

		-- Treat a death status of 0 and NULL as being the same
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
																			
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_Referrals'
		AND			rmc.ColumnName IN ('DeathStatus')
		AND			rmd.PreValue = 0
		AND			rmd.MerValue IS NULL

		-- We're only worried about InappropriateRef when the value changes to or from 1 (this impacts cwtFlag logic
		UPDATE		rmd
		SET			rmd.HasDedupeChangeDiff = 1
		FROM		Merge_R_Compare.ReportingMergeColumns_Work rmc
		INNER JOIN	Merge_R_Compare.ReportingMergeDifferences_Work rmd
																	ON	rmc.ColumnIx = rmd.ColumnIx
																			
		WHERE		rmc.TableName = 'VwSCR_Warehouse_SCR_Referrals'
		AND			rmc.ColumnName IN ('InappropriateRef')
		AND			ISNULL(rmd.PreValue, 0) != 1
		AND			ISNULL(rmd.MerValue, 0) != 1



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

			-- Drop dedupe changed values tables
			IF OBJECT_ID('Merge_R_Compare.DedupeChangedDemographics') IS NOT NULL DROP TABLE Merge_R_Compare.DedupeChangedDemographics
			IF OBJECT_ID('Merge_R_Compare.DedupeChangedRefs') IS NOT NULL DROP TABLE Merge_R_Compare.DedupeChangedRefs
			IF OBJECT_ID('Merge_R_Compare.DedupeDroppedRefs') IS NOT NULL DROP TABLE Merge_R_Compare.DedupeDroppedRefs


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

			-- Rename the dedupe changed values tables
			EXEC sp_rename @objname = 'Merge_R_Compare.DedupeChangedDemographics_work', @newname = 'DedupeChangedDemographics'
			EXEC sp_rename @objname = 'Merge_R_Compare.DedupeChangedRefs_work', @newname = 'DedupeChangedRefs'
			EXEC sp_rename @objname = 'Merge_R_Compare.DedupeDroppedRefs_work', @newname = 'DedupeDroppedRefs'
			

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
