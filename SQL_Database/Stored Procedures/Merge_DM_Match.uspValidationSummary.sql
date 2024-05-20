SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_Match].[uspValidationSummary]
		(@StoreSnapshot BIT = 0
		)

AS

-- Test me
-- EXEC Merge_DM_Match.uspValidationSummary
-- EXEC Merge_DM_Match.uspValidationSummary @StoreSnapshot = 1

/*********************************************************************************************************************************************************************************************************/
-- Procedure setup
/*********************************************************************************************************************************************************************************************************/

	-- Set NOCOUNT on if we are storing the data (in case we execute it from Excel to refresh the data)
	SET NOCOUNT ON
	
	-- Create a temp table to store the output
	IF OBJECT_ID('tempdb..#ValidationSummary') IS NOT NULL DROP TABLE #ValidationSummary
	CREATE TABLE #ValidationSummary	(TableBeingValidated VARCHAR(255), ConfirmedSoFar INT, AutoConfirmedSoFar INT, TotalToBeConfirmed INT, ManuallyConfirmedSoFar INT
									, StillToBeManuallyConfirmed INT, TotalToBeManuallyConfirmed INT, PercentComplete REAL)

/*********************************************************************************************************************************************************************************************************/
-- tblDEMOGRAPHICS
/*********************************************************************************************************************************************************************************************************/

-- Validation Summary
INSERT INTO #ValidationSummary (TableBeingValidated,ConfirmedSoFar,AutoConfirmedSoFar,TotalToBeConfirmed,ManuallyConfirmedSoFar,StillToBeManuallyConfirmed,TotalToBeManuallyConfirmed,PercentComplete)
SELECT		'tblDEMOGRAPHICS' AS TableBeingValidated
			,SUM(A.Confirmed) AS ConfirmedSoFar
			,SUM(A.AutoConfirmed) AS AutoConfirmedSoFar
			,COUNT(*) AS TotalToBeConfirmed
			,SUM(A.Confirmed) - SUM(A.AutoConfirmed) AS ManuallyConfirmedSoFar
			,COUNT(*) - SUM(A.Confirmed) AS StillToBeManuallyConfirmed
			,COUNT(*) - SUM(A.AutoConfirmed) AS TotalToBeManuallyConfirmed
			,ROUND(CAST(SUM(A.Confirmed) - SUM(A.AutoConfirmed) AS REAL) * CAST(100 AS REAL) / CAST(COUNT(*) - SUM(A.AutoConfirmed) AS REAL), 1) AS PercentComplete
FROM		(SELECT		mc.SrcSys_Major
						,mc.Src_UID_Major
						,COUNT(*) AS MinorsCount
						,MAX(CASE WHEN mmv.SrcSys_Major IS NOT NULL THEN 1 ELSE 0 END) AS Confirmed
						,MAX(CASE WHEN mmv.SrcSys_Major IS NOT NULL AND mmv.LastValidatedBy = 'tblDEMOGRAPHICS_uspMatchEntityPairs' THEN 1 ELSE 0 END) AS AutoConfirmed
			FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
			LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv
																				ON	mc.SrcSys_Major = mmv.SrcSys_Major
																				AND	mc.Src_UID_Major = mmv.Src_UID_Major
																				AND	mmv.ValidationStatus IN ('Confirmed','Dont Merge')
			GROUP BY	mc.SrcSys_Major
						,mc.Src_UID_Major
			HAVING		COUNT(*) > 1) A

/*********************************************************************************************************************************************************************************************************/
-- tblMAIN_REFERRALS
/*********************************************************************************************************************************************************************************************************/

-- Validation Summary
INSERT INTO #ValidationSummary (TableBeingValidated,ConfirmedSoFar,AutoConfirmedSoFar,TotalToBeConfirmed,ManuallyConfirmedSoFar,StillToBeManuallyConfirmed,TotalToBeManuallyConfirmed,PercentComplete)
SELECT		'tblMAIN_REFERRALS' AS TableBeingValidated
			,SUM(A.Confirmed) AS ConfirmedSoFar
			,SUM(A.AutoConfirmed) AS AutoConfirmedSoFar
			,COUNT(*) AS TotalToBeConfirmed
			,SUM(A.Confirmed) - SUM(A.AutoConfirmed) AS ManuallyConfirmedSoFar
			,COUNT(*) - SUM(A.Confirmed) AS StillToBeManuallyConfirmed
			,COUNT(*) - SUM(A.AutoConfirmed) AS TotalToBeManuallyConfirmed
			,ROUND(CAST(SUM(A.Confirmed) - SUM(A.AutoConfirmed) AS REAL) * CAST(100 AS REAL) / CAST(COUNT(*) - SUM(A.AutoConfirmed) AS REAL), 1) AS PercentComplete
FROM		(SELECT		mc.SrcSys_Major
						,mc.Src_UID_Major
						,COUNT(*) AS MinorsCount
						,MAX(CASE WHEN mmv.SrcSys_Major IS NOT NULL THEN 1 ELSE 0 END) AS Confirmed
						,MAX(CASE WHEN mmv.SrcSys_Major IS NOT NULL AND mmv.LastValidatedBy = 'tblMAIN_REFERRALS_uspMatchEntityPairs' THEN 1 ELSE 0 END) AS AutoConfirmed
			FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
			LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv
																				ON	mc.SrcSys_Major = mmv.SrcSys_Major
																				AND	mc.Src_UID_Major = mmv.Src_UID_Major
																				AND	mmv.ValidationStatus IN ('Confirmed','Dont Merge')
			GROUP BY	mc.SrcSys_Major
						,mc.Src_UID_Major
			HAVING		COUNT(*) > 1) A


/*********************************************************************************************************************************************************************************************************/
-- Return the output
/*********************************************************************************************************************************************************************************************************/

		-- Store the snapshot
		IF @StoreSnapshot = 1
		BEGIN

				INSERT INTO	Merge_DM_Match.ValidationSummary
							(SnapshotDate
							,TableBeingValidated
							,ConfirmedSoFar
							,AutoConfirmedSoFar
							,TotalToBeConfirmed
							,ManuallyConfirmedSoFar
							,StillToBeManuallyConfirmed
							,TotalToBeManuallyConfirmed
							,PercentComplete
							)
				SELECT		GETDATE()
							,TableBeingValidated
							,ConfirmedSoFar
							,AutoConfirmedSoFar
							,TotalToBeConfirmed
							,ManuallyConfirmedSoFar
							,StillToBeManuallyConfirmed
							,TotalToBeManuallyConfirmed
							,PercentComplete
				FROM		#ValidationSummary				

		END

		-- Return the output
		ELSE
		BEGIN

				SELECT * FROM #ValidationSummary
				ORDER BY TableBeingValidated

		END

GO
