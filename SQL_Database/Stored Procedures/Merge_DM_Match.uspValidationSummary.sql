SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_Match].[uspValidationSummary]
		(@StoreSnapshot BIT = 0
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
Description:				A stored procedure to monitor the progress of the deduplication / validation
**************************************************************************************************************************************************/

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
			FROM		Merge_DM_MatchViews.tblMAIN_REFERRALS_vw_SCOPE(NULL,NULL) ref_scope
			INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
																				ON	ref_scope.SrcSys_Major = mc.SrcSys_Major
																				AND	ref_scope.Src_UID_Major = mc.Src_UID_Major
			LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv
																				ON	mc.SrcSys_Major = mmv.SrcSys_Major
																				AND	mc.Src_UID_Major = mmv.Src_UID_Major
																				AND	mmv.ValidationStatus IN ('Confirmed','Dont Merge')
			GROUP BY	mc.SrcSys_Major
						,mc.Src_UID_Major
			HAVING		COUNT(*) > 1) A


/*********************************************************************************************************************************************************************************************************/
-- Treatments
/*********************************************************************************************************************************************************************************************************/

-- Validation Summary
INSERT INTO #ValidationSummary (TableBeingValidated,ConfirmedSoFar,AutoConfirmedSoFar,TotalToBeConfirmed,ManuallyConfirmedSoFar,StillToBeManuallyConfirmed,TotalToBeManuallyConfirmed,PercentComplete)
SELECT		'Treatments' AS TableBeingValidated
			,SUM(CASE WHEN A.Confirmed = A.MinorsCount THEN 1 ELSE 0 END) AS ConfirmedSoFar
			,SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS AutoConfirmedSoFar
			,COUNT(*) AS TotalToBeConfirmed
			,SUM(CASE WHEN A.Confirmed = A.MinorsCount THEN 1 ELSE 0 END) - SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS ManuallyConfirmedSoFar
			,COUNT(*) - SUM(CASE WHEN A.Confirmed = A.MinorsCount THEN 1 ELSE 0 END) AS StillToBeManuallyConfirmed
			,COUNT(*) - SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS TotalToBeManuallyConfirmed
			,ROUND(CAST(SUM(CASE WHEN A.Confirmed = A.MinorsCount THEN 1 ELSE 0 END) - SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS REAL) * CAST(100 AS REAL) / CAST(COUNT(*) - SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS REAL), 1) AS PercentComplete
FROM		(SELECT		tx_vw.Ref_SrcSys_Major
						,tx_vw.Ref_Src_UID_Major
						,tx_vw.TreatmentDate
						,COUNT(*) AS MinorsCount
						,SUM(CASE WHEN tx_vw.Migrate IS NOT NULL THEN 1 ELSE 0 END) AS Confirmed
						,SUM(CASE WHEN tx_vw.Migrate IS NOT NULL AND tx_vw.LastValidatedBy = 'Treatments_uspMatchControlUpdateAndMatch' THEN 1 ELSE 0 END) AS AutoConfirmed
			FROM		Merge_DM_MatchViews.Treatments_vw_SCOPE (NULL, NULL) tx_vw
			WHERE		tx_vw.InScope = 1
			GROUP BY	tx_vw.Ref_SrcSys_Major
						,tx_vw.Ref_Src_UID_Major
						,tx_vw.TreatmentDate) A


/*********************************************************************************************************************************************************************************************************/
-- MDT
/*********************************************************************************************************************************************************************************************************/

-- Validation Summary
INSERT INTO #ValidationSummary (TableBeingValidated,ConfirmedSoFar,AutoConfirmedSoFar,TotalToBeConfirmed,ManuallyConfirmedSoFar,StillToBeManuallyConfirmed,TotalToBeManuallyConfirmed,PercentComplete)
SELECT		'MDT' AS TableBeingValidated
			,SUM(CASE WHEN A.Confirmed = A.MinorsCount THEN 1 ELSE 0 END) AS ConfirmedSoFar
			,SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS AutoConfirmedSoFar
			,COUNT(*) AS TotalToBeConfirmed
			,SUM(CASE WHEN A.Confirmed = A.MinorsCount THEN 1 ELSE 0 END) - SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS ManuallyConfirmedSoFar
			,COUNT(*) - SUM(CASE WHEN A.Confirmed = A.MinorsCount THEN 1 ELSE 0 END) AS StillToBeManuallyConfirmed
			,COUNT(*) - SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS TotalToBeManuallyConfirmed
			,ROUND(CAST(SUM(CASE WHEN A.Confirmed = A.MinorsCount THEN 1 ELSE 0 END) - SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS REAL) * CAST(100 AS REAL) / CAST(COUNT(*) - SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS REAL), 1) AS PercentComplete
FROM		(SELECT		MDT_vw.Ref_SrcSys_Major
						,MDT_vw.Ref_Src_UID_Major
						,MDT_vw.MDT_DATE
						,COUNT(*) AS MinorsCount
						,SUM(CASE WHEN MDT_vw.Migrate IS NOT NULL THEN 1 ELSE 0 END) AS Confirmed
						,SUM(CASE WHEN MDT_vw.Migrate IS NOT NULL AND MDT_vw.LastValidatedBy = 'MDT_uspMatchControlUpdateAndMatch' THEN 1 ELSE 0 END) AS AutoConfirmed
			FROM		Merge_DM_MatchViews.MDT_vw_SCOPE (NULL, NULL) MDT_vw
			WHERE		MDT_vw.InScope = 1
			GROUP BY	MDT_vw.Ref_SrcSys_Major
						,MDT_vw.Ref_Src_UID_Major
						,MDT_vw.MDT_DATE) A


/*********************************************************************************************************************************************************************************************************/
-- tblMAIN_REFERRALS & Children
/*********************************************************************************************************************************************************************************************************/

-- Validation Summary
INSERT INTO #ValidationSummary (TableBeingValidated,ConfirmedSoFar,AutoConfirmedSoFar,TotalToBeConfirmed,ManuallyConfirmedSoFar,StillToBeManuallyConfirmed,TotalToBeManuallyConfirmed,PercentComplete)
SELECT		'Referrals and/or children' AS TableBeingValidated
			,SUM(ISNULL(Ref.ConfirmedSoFar, 1) & ISNULL(Tx.ConfirmedSoFar, 1) & ISNULL(MDT.ConfirmedSoFar, 1)) AS ConfirmedSoFar
			,SUM(ISNULL(Ref.AutoConfirmedSoFar, 1) & ISNULL(Tx.AutoConfirmedSoFar, 1) & ISNULL(MDT.AutoConfirmedSoFar, 1)) AS AutoConfirmedSoFar
			,SUM(ISNULL(Ref.TotalToBeConfirmed, 0) | ISNULL(Tx.TotalToBeConfirmed, 0) | ISNULL(MDT.TotalToBeConfirmed, 0)) AS TotalToBeConfirmed
			,SUM(ISNULL(Ref.ManuallyConfirmedSoFar, 1) & ISNULL(Tx.ConfirmedSoFar, 1) & ISNULL(MDT.ConfirmedSoFar, 1)) AS ManuallyConfirmedSoFar
			,SUM(ISNULL(Ref.StillToBeManuallyConfirmed, 0) | ISNULL(Tx.StillToBeManuallyConfirmed, 0) | ISNULL(MDT.StillToBeManuallyConfirmed, 0)) AS StillToBeManuallyConfirmed
			,SUM(ISNULL(Ref.TotalToBeManuallyConfirmed, 0) | ISNULL(Tx.TotalToBeManuallyConfirmed, 0) | ISNULL(MDT.TotalToBeManuallyConfirmed, 0)) AS TotalToBeManuallyConfirmed
			,ROUND(CAST(SUM(ISNULL(Ref.ManuallyConfirmedSoFar, 1) & ISNULL(Tx.ConfirmedSoFar, 1) & ISNULL(MDT.ConfirmedSoFar, 1)) AS REAL) * CAST(100 AS REAL) / CAST(SUM(ISNULL(Ref.TotalToBeManuallyConfirmed, 0) | ISNULL(Tx.TotalToBeManuallyConfirmed, 0) | ISNULL(MDT.TotalToBeManuallyConfirmed, 0)) AS REAL), 1) AS PercentComplete
FROM		(SELECT		A.SrcSys_Major
						,A.Src_UID_Major
						,'tblMAIN_REFERRALS' AS TableBeingValidated
						,SUM(A.Confirmed) AS ConfirmedSoFar
						,SUM(A.AutoConfirmed) AS AutoConfirmedSoFar
						,COUNT(*) AS TotalToBeConfirmed
						,SUM(A.Confirmed) - SUM(A.AutoConfirmed) AS ManuallyConfirmedSoFar
						,COUNT(*) - SUM(A.Confirmed) AS StillToBeManuallyConfirmed
						,COUNT(*) - SUM(A.AutoConfirmed) AS TotalToBeManuallyConfirmed
			FROM		(SELECT		mc.SrcSys_Major
									,mc.Src_UID_Major
									,COUNT(*) AS MinorsCount
									,MAX(CASE WHEN mmv.SrcSys_Major IS NOT NULL THEN 1 ELSE 0 END) AS Confirmed
									,MAX(CASE WHEN mmv.SrcSys_Major IS NOT NULL AND mmv.LastValidatedBy = 'tblMAIN_REFERRALS_uspMatchEntityPairs' THEN 1 ELSE 0 END) AS AutoConfirmed
						FROM		Merge_DM_MatchViews.tblMAIN_REFERRALS_vw_SCOPE(NULL,NULL) ref_scope
						INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
																							ON	ref_scope.SrcSys_Major = mc.SrcSys_Major
																							AND	ref_scope.Src_UID_Major = mc.Src_UID_Major
						LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation mmv
																							ON	mc.SrcSys_Major = mmv.SrcSys_Major
																							AND	mc.Src_UID_Major = mmv.Src_UID_Major
																							AND	mmv.ValidationStatus IN ('Confirmed','Dont Merge')
						GROUP BY	mc.SrcSys_Major
									,mc.Src_UID_Major
						HAVING		COUNT(*) > 1) A
			GROUP BY	A.SrcSys_Major
						,A.Src_UID_Major
						) Ref
FULL JOIN	(SELECT		A.Ref_SrcSys_Major AS SrcSys_Major
						,A.Ref_Src_UID_Major AS Src_UID_Major
						,'Treatments' AS TableBeingValidated
						,CAST(SUM(CASE WHEN A.Confirmed = A.MinorsCount THEN 1 ELSE 0 END) AS BIT) AS ConfirmedSoFar
						,CAST(SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS BIT) AS AutoConfirmedSoFar
						,CAST(COUNT(*) AS BIT) AS TotalToBeConfirmed
						,CAST(SUM(CASE WHEN A.Confirmed = A.MinorsCount THEN 1 ELSE 0 END) - SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS BIT) AS ManuallyConfirmedSoFar
						,CAST(COUNT(*) - SUM(CASE WHEN A.Confirmed = A.MinorsCount THEN 1 ELSE 0 END) AS BIT) AS StillToBeManuallyConfirmed
						,CAST(COUNT(*) - SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS BIT) AS TotalToBeManuallyConfirmed
			FROM		(SELECT		tx_vw.Ref_SrcSys_Major
									,tx_vw.Ref_Src_UID_Major
									,tx_vw.TreatmentDate
									,COUNT(*) AS MinorsCount
									,SUM(CASE WHEN tx_vw.Migrate IS NOT NULL THEN 1 ELSE 0 END) AS Confirmed
									,SUM(CASE WHEN tx_vw.Migrate IS NOT NULL AND tx_vw.LastValidatedBy = 'Treatments_uspMatchControlUpdateAndMatch' THEN 1 ELSE 0 END) AS AutoConfirmed
						FROM		Merge_DM_MatchViews.Treatments_vw_SCOPE (NULL, NULL) tx_vw
						WHERE		tx_vw.InScope = 1
						GROUP BY	tx_vw.Ref_SrcSys_Major
									,tx_vw.Ref_Src_UID_Major
									,tx_vw.TreatmentDate) A
			GROUP BY	A.Ref_SrcSys_Major
						,A.Ref_Src_UID_Major
						 ) Tx
							ON	Ref.SrcSys_Major = Tx.SrcSys_Major
							AND	Ref.Src_UID_Major = Tx.Src_UID_Major
FULL JOIN	(SELECT		A.Ref_SrcSys_Major AS SrcSys_Major
						,A.Ref_Src_UID_Major AS Src_UID_Major
						,'MDT' AS TableBeingValidated
						,CAST(SUM(CASE WHEN A.Confirmed = A.MinorsCount THEN 1 ELSE 0 END) AS BIT) AS ConfirmedSoFar
						,CAST(SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS BIT) AS AutoConfirmedSoFar
						,CAST(COUNT(*) AS BIT) AS TotalToBeConfirmed
						,CAST(SUM(CASE WHEN A.Confirmed = A.MinorsCount THEN 1 ELSE 0 END) - SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS BIT) AS ManuallyConfirmedSoFar
						,CAST(COUNT(*) - SUM(CASE WHEN A.Confirmed = A.MinorsCount THEN 1 ELSE 0 END) AS BIT) AS StillToBeManuallyConfirmed
						,CAST(COUNT(*) - SUM(CASE WHEN A.AutoConfirmed = A.MinorsCount THEN 1 ELSE 0 END) AS BIT) AS TotalToBeManuallyConfirmed
			FROM		(SELECT		MDT_vw.Ref_SrcSys_Major
									,MDT_vw.Ref_Src_UID_Major
									,MDT_vw.MDT_DATE
									,COUNT(*) AS MinorsCount
									,SUM(CASE WHEN MDT_vw.Migrate IS NOT NULL THEN 1 ELSE 0 END) AS Confirmed
									,SUM(CASE WHEN MDT_vw.Migrate IS NOT NULL AND MDT_vw.LastValidatedBy = 'MDT_uspMatchControlUpdateAndMatch' THEN 1 ELSE 0 END) AS AutoConfirmed
						FROM		Merge_DM_MatchViews.MDT_vw_SCOPE (NULL, NULL) MDT_vw
						WHERE		MDT_vw.InScope = 1
						GROUP BY	MDT_vw.Ref_SrcSys_Major
									,MDT_vw.Ref_Src_UID_Major
									,MDT_vw.MDT_DATE) A
			GROUP BY	A.Ref_SrcSys_Major
						,A.Ref_Src_UID_Major
						 ) MDT
							ON	Ref.SrcSys_Major = MDT.SrcSys_Major
							AND	Ref.Src_UID_Major = MDT.Src_UID_Major


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
				ORDER BY	CASE TableBeingValidated
							WHEN 'tblDEMOGRAPHICS' THEN 1
							WHEN 'tblMAIN_REFERRALS' THEN 2
							WHEN 'Treatments' THEN 3
							WHEN 'MDT' THEN 4
							WHEN 'Referrals and/or children' THEN 5
							ELSE 99
							END

		END

		-- Return the output
		ELSE
		BEGIN

				SELECT * FROM #ValidationSummary	
				ORDER BY	CASE TableBeingValidated
							WHEN 'tblDEMOGRAPHICS' THEN 1
							WHEN 'tblMAIN_REFERRALS' THEN 2
							WHEN 'Treatments' THEN 3
							WHEN 'MDT' THEN 4
							WHEN 'Referrals and/or children' THEN 5
							ELSE 99
							END

		END

GO
