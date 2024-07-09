SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_Match].[uspUnlinkMatch]

		(@tableName VARCHAR(255)
		,@SrcSys_Major TINYINT
		,@Src_UID_Major VARCHAR(255)
		,@SrcSys TINYINT
		,@Src_UID VARCHAR(255)
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
Description:				A stored procedure to unlink incorrect matches between an entity and the major entity
**************************************************************************************************************************************************/

-- Test me
-- EXEC Merge_DM_Match.uspUnlinkMatch @tableName = 'tblDEMOGRAPHICS', @SrcSys_Major = 3, @Src_UID_Major = '57E87725-70BE-4B51-A8EE-F6FB9ADB653D', @SrcSys = 2, @Src_UID = '58282', @UserId = 'BSUH\Matthew.Bishop'

		/*****************************************************************************************************************************************/
		-- Prepare for the updates
		/*****************************************************************************************************************************************/
		
		DECLARE @SQL VARCHAR(MAX)

		-- Create a control table we will use to manage the dynamic SQL
		IF OBJECT_ID('tempdb..#DynamicSqlControl') IS NOT NULL DROP TABLE #DynamicSqlControl
		CREATE TABLE #DynamicSqlControl (ControlType VARCHAR(255), ControlValue SQL_VARIANT)

		-- Test whether the new major record is within the group of the current major record 
		SET @SQL =	'INSERT INTO #DynamicSqlControl (ControlType, ControlValue) ' + CHAR(13) +
					'SELECT ''ValidityTest'', COUNT(*) ' + CHAR(13) +
					'FROM Merge_DM_Match.' + @tableName + '_Match_Control ' + CHAR(13) +
					'WHERE SrcSys_Major = ' + CAST(@SrcSys_Major AS VARCHAR(255)) + ' ' + CHAR(13) +
					'AND Src_UID_Major = ''' + @Src_UID_Major + ''' ' + CHAR(13) +
					'AND SrcSys = ' + CAST(@SrcSys AS VARCHAR(255)) + ' ' + CHAR(13) +
					'AND Src_UID = ''' + @Src_UID + ''' ' + CHAR(13) /*+
					'AND IsScr = 1'*/
		EXEC (@SQL)

		-- Test whether the UID has been unlinked already and we want to try a harder unlink 
		SET @SQL =	'INSERT INTO #DynamicSqlControl (ControlType) ' + CHAR(13) +
					'SELECT ''HardUnlink'' ' + CHAR(13) +
					'FROM Merge_DM_Match.' + @tableName + '_Match_EntityPairs_Unique ' + CHAR(13) +
					'WHERE ((SrcSys_A = ' + CAST(@SrcSys AS VARCHAR(255)) + ' ' + CHAR(13) +
					'AND Src_UID_A = ''' + @Src_UID + ''') ' + CHAR(13) +
					'OR (SrcSys_B = ' + CAST(@SrcSys AS VARCHAR(255)) + ' ' + CHAR(13) +
					'AND Src_UID_B = ''' + @Src_UID + ''')) ' + CHAR(13) +
					'AND UnlinkProcessed = 1 '
		EXEC (@SQL)

		-- Create an populate a hard unlink flag
		DECLARE @HardUnlink BIT
		SET @HardUnlink = (SELECT COUNT(*) FROM #DynamicSqlControl WHERE ControlType = 'HardUnlink')

		-- Create the distance table
		IF OBJECT_ID('tempdb..#Distance') IS NOT NULL DROP TABLE #Distance
		CREATE TABLE #Distance
				(SrcSys_Major TINYINT NOT NULL
				,Src_UID_Major VARCHAR(255) NOT NULL
				,SrcSys TINYINT NOT NULL
				,Src_UID VARCHAR(255) NOT NULL
				,Distance SMALLINT NULL
				)

		-- Create the entity pairs unique table with the distance to the major included
		IF OBJECT_ID('tempdb..#EntityPairs_Unique_Distance') IS NOT NULL DROP TABLE #EntityPairs_Unique_Distance
		CREATE TABLE #EntityPairs_Unique_Distance
				(SrcSys_A TINYINT NOT NULL
				,Src_UID_A VARCHAR(255) NOT NULL
				,Distance_A SMALLINT NOT NULL
				,Distance_B SMALLINT NOT NULL
				,SrcSys_B TINYINT NOT NULL
				,Src_UID_B VARCHAR(255) NOT NULL
				)

		-- Create the multi-parent table
		IF OBJECT_ID('tempdb..#MultiParent') IS NOT NULL DROP TABLE #MultiParent
		CREATE TABLE #MultiParent
				(SrcSys_MultiParent TINYINT NOT NULL
				,Src_UID_MultiParent VARCHAR(255) NOT NULL
				)

		-- Create the downward chain table
		IF OBJECT_ID('tempdb..#DownwardChain') IS NOT NULL DROP TABLE #DownwardChain
		CREATE TABLE #DownwardChain
				(SrcSys_OneDeeper TINYINT NOT NULL
				,Src_UID_OneDeeper VARCHAR(255) NOT NULL
				,SrcSys_From TINYINT NOT NULL
				,Src_UID_From VARCHAR(255) NOT NULL
				,Distance_From SMALLINT NOT NULL
				,SrcSys_To TINYINT NOT NULL
				,Src_UID_To VARCHAR(255) NOT NULL
				,Distance_To SMALLINT NOT NULL
				,HasMultiParent BIT NOT NULL DEFAULT 0
				,Processed BIT NULL
				)

		-- Create the unlinking table
		IF OBJECT_ID('tempdb..#Unlink') IS NOT NULL DROP TABLE #Unlink
		CREATE TABLE #Unlink
				(SrcSys_Unlink_A TINYINT NOT NULL
				,Src_UID_Unlink_A VARCHAR(255) NOT NULL
				,SrcSys_Unlink_B TINYINT NOT NULL
				,Src_UID_Unlink_B VARCHAR(255) NOT NULL
				)

		-- Create the clear unlinks table
		IF OBJECT_ID('tempdb..#ClearUnlinks') IS NOT NULL DROP TABLE #ClearUnlinks
		CREATE TABLE #ClearUnlinks
				(SrcSys_ClearUnlink_A TINYINT NOT NULL
				,Src_UID_ClearUnlink_A VARCHAR(255) NOT NULL
				,SrcSys_ClearUnlink_B TINYINT NOT NULL
				,Src_UID_ClearUnlink_B VARCHAR(255) NOT NULL
				)
		
		-- Find all minors under the same major and assign the major to distance 1
		SET @SQL =	'INSERT INTO	#Distance ' + CHAR(13) +
					'			(SrcSys_Major ' + CHAR(13) +
					'			,Src_UID_Major ' + CHAR(13) +
					'			,SrcSys ' + CHAR(13) +
					'			,Src_UID ' + CHAR(13) +
					'			,Distance ' + CHAR(13) +
					'			) ' + CHAR(13) +
					'SELECT		mc_major.SrcSys_Major ' + CHAR(13) +
					'			,mc_major.Src_UID_Major ' + CHAR(13) +
					'			,mc_minor.SrcSys ' + CHAR(13) +
					'			,mc_minor.Src_UID ' + CHAR(13) +
					'			,CASE WHEN mc_minor.SrcSys = mc_minor.SrcSys_Major AND mc_minor.Src_UID = mc_minor.Src_UID_Major THEN 1 END ' + CHAR(13) +
					'FROM		Merge_DM_Match.' + @tableName + '_Match_Control mc_major ' + CHAR(13) +
					'INNER JOIN	Merge_DM_Match.' + @tableName + '_Match_Control mc_minor ' + CHAR(13) +
					'														ON	mc_major.SrcSys_Major = mc_minor.SrcSys_Major ' + CHAR(13) +
					'														AND	mc_major.Src_UID_Major = mc_minor.Src_UID_Major ' + CHAR(13) +
					'WHERE		mc_major.SrcSys = ' + CAST(@SrcSys AS VARCHAR(255)) + ' ' + CHAR(13) +
					'AND		mc_major.Src_UID = ''' + @Src_UID + ''' ' 
		PRINT @SQL
		EXEC (@SQL)


		-- Loop through the dataset to find any other records that need to be in the chain
		SET @SQL =	'DECLARE @NoMoreUpdates SMALLINT = 0 ' + CHAR(13) +
					'WHILE @NoMoreUpdates = 0 ' + CHAR(13) +
					'BEGIN ' + CHAR(13) +
					' ' + CHAR(13) +
					'		INSERT INTO	#Distance ' + CHAR(13) +
					'			(SrcSys_Major ' + CHAR(13) +
					'			,Src_UID_Major ' + CHAR(13) +
					'			,SrcSys ' + CHAR(13) +
					'			,Src_UID ' + CHAR(13) +
					'			) ' + CHAR(13) +
					'		SELECT		mc.SrcSys_Major ' + CHAR(13) +
					'					,mc.Src_UID_Major ' + CHAR(13) +
					'					,IterateNext.SrcSys_Iterative ' + CHAR(13) +
					'					,IterateNext.Src_UID_Iterative ' + CHAR(13) +
					'		FROM		#Distance dist ' + CHAR(13) +
					'		INNER JOIN	(SELECT		SrcSys_A AS SrcSys_Link ' + CHAR(13) +
					'								,Src_UID_A AS Src_UID_Link ' + CHAR(13) +
					'								,SrcSys_B AS SrcSys_Iterative ' + CHAR(13) +
					'								,Src_UID_B AS Src_UID_Iterative ' + CHAR(13) +
					'					FROM		Merge_DM_Match.' + @tableName + '_Match_EntityPairs_Unique ep_u ' + CHAR(13) +
					'		 ' + CHAR(13) +
					'					UNION ' + CHAR(13) +
					'		 ' + CHAR(13) +
					'					SELECT		SrcSys_B AS SrcSys_Link ' + CHAR(13) +
					'								,Src_UID_B AS Src_UID_Link ' + CHAR(13) +
					'								,SrcSys_A AS SrcSys_Iterative ' + CHAR(13) +
					'								,Src_UID_A AS Src_UID_Iterative ' + CHAR(13) +
					'					FROM		Merge_DM_Match.' + @tableName + '_Match_EntityPairs_Unique ep_u ' + CHAR(13) +
					'								) IterateNext ' + CHAR(13) +
					'												ON	dist.SrcSys = IterateNext.SrcSys_Link ' + CHAR(13) +
					'												AND	dist.Src_UID = IterateNext.Src_UID_Link ' + CHAR(13) +
					'		INNER JOIN	Merge_DM_Match.' + @tableName + '_Match_Control mc ' + CHAR(13) +
					'															ON	IterateNext.SrcSys_Iterative = mc.SrcSys ' + CHAR(13) +
					'															AND	IterateNext.Src_UID_Iterative = mc.Src_UID ' + CHAR(13) +
					'		LEFT JOIN	#Distance dist_notPresent ' + CHAR(13) +
					'											ON	IterateNext.SrcSys_Iterative = dist_notPresent.SrcSys ' + CHAR(13) +
					'											AND	IterateNext.Src_UID_Iterative = dist_notPresent.Src_UID ' + CHAR(13) +
					'		WHERE		dist_notPresent.SrcSys IS NULL ' + CHAR(13) +
					'		GROUP BY	mc.SrcSys_Major ' + CHAR(13) +
					'					,mc.Src_UID_Major ' + CHAR(13) +
					'					,IterateNext.SrcSys_Iterative ' + CHAR(13) +
					'					,IterateNext.Src_UID_Iterative ' + CHAR(13) +
					' ' + CHAR(13) +
					'		-- Exit the loop if there were no more distances to find ' + CHAR(13) +
					'		IF @@ROWCOUNT = 0 ' + CHAR(13) +
					'		SET @NoMoreUpdates = 1 ' + CHAR(13) +
					' ' + CHAR(13) +
					'END '
		PRINT @SQL
		EXEC (@SQL)


		-- Loop through the dataset to find the distance for all records
		SET @SQL =	'DECLARE @NoMoreUpdates SMALLINT = 0 ' + CHAR(13) +
					'WHILE @NoMoreUpdates = 0 ' + CHAR(13) +
					'BEGIN ' + CHAR(13) +
					' ' + CHAR(13) +
					'		-- Find the next minors under the last set of distanced minors and assign the next distance ' + CHAR(13) +
					'		UPDATE		dist_update ' + CHAR(13) +
					'		SET			Distance = (SELECT MAX(Distance) FROM #Distance) + 1 ' + CHAR(13) +
					'		FROM		#Distance dist ' + CHAR(13) +
					'		INNER JOIN	Merge_DM_Match.' + @tableName + '_Match_EntityPairs_Unique ep_u  ' + CHAR(13) +
					'														ON	(dist.SrcSys = ep_u.SrcSys_A ' + CHAR(13) +
					'														AND	dist.Src_UID = ep_u.Src_UID_A)  ' + CHAR(13) +
					'														OR	(dist.SrcSys = ep_u.SrcSys_B ' + CHAR(13) +
					'														AND	dist.Src_UID = ep_u.Src_UID_B)  ' + CHAR(13) +
					'		INNER JOIN	#Distance dist_update ' + CHAR(13) +
					'										ON	CASE WHEN dist.SrcSys = ep_u.SrcSys_A AND dist.Src_UID = ep_u.Src_UID_A THEN ep_u.SrcSys_B ELSE SrcSys_A END = dist_update.SrcSys ' + CHAR(13) +
					'										AND	CASE WHEN dist.SrcSys = ep_u.SrcSys_A AND dist.Src_UID = ep_u.Src_UID_A THEN ep_u.Src_UID_B ELSE Src_UID_A END = dist_update.Src_UID ' + CHAR(13) +
					'		WHERE		dist.Distance = (SELECT MAX(Distance) FROM #Distance) ' + CHAR(13) +
					'		AND			dist_update.Distance IS NULL ' + CHAR(13) +
					' ' + CHAR(13) +
					'		-- Exit the loop if there were no more distances to find ' + CHAR(13) +
					'		IF @@ROWCOUNT = 0 ' + CHAR(13) +
					'		SET @NoMoreUpdates = 1 ' + CHAR(13) +
					' ' + CHAR(13) +
					'END '
		PRINT @SQL
		EXEC (@SQL)

		-- Create the Entity Pairs Unique table with the distance included
		SET @SQL =	'INSERT INTO	#EntityPairs_Unique_Distance ' + CHAR(13) +
					'			(SrcSys_A ' + CHAR(13) +
					'			,Src_UID_A ' + CHAR(13) +
					'			,Distance_A ' + CHAR(13) +
					'			,Distance_B ' + CHAR(13) +
					'			,SrcSys_B ' + CHAR(13) +
					'			,Src_UID_B ' + CHAR(13) +
					'			) ' + CHAR(13) +
					'SELECT		ep_u.SrcSys_A ' + CHAR(13) +
					'			,ep_u.Src_UID_A ' + CHAR(13) +
					'			,dist_A.Distance AS Distance_A ' + CHAR(13) +
					'			,dist_B.Distance AS Distance_B ' + CHAR(13) +
					'			,ep_u.SrcSys_B ' + CHAR(13) +
					'			,ep_u.Src_UID_B ' + CHAR(13) +
					'FROM		Merge_DM_Match.' + @tableName + '_Match_EntityPairs_Unique ep_u ' + CHAR(13) +
					'INNER JOIN	#Distance dist_A ' + CHAR(13) +
					'							ON	ep_u.SrcSys_A = dist_A.SrcSys ' + CHAR(13) +
					'							AND	ep_u.Src_UID_A = dist_A.Src_UID ' + CHAR(13) +
					'INNER JOIN	#Distance dist_B ' + CHAR(13) +
					'							ON	ep_u.SrcSys_B = dist_B.SrcSys ' + CHAR(13) +
					'							AND	ep_u.Src_UID_B = dist_B.Src_UID '
		PRINT @SQL
		EXEC (@SQL)

		-- Find the target distance (to look for upwards and downwards connections separately
		DECLARE @TargetDistance SMALLINT

		SELECT		@TargetDistance = Distance 
		FROM		#Distance
		WHERE		SrcSys = @SrcSys
		AND			Src_UID = @Src_UID

		-- Find all entity nodes that have 2 or more "upwards" connections - connections where the entity is one node closer to the major
		INSERT INTO	#MultiParent
					(SrcSys_MultiParent
					,Src_UID_MultiParent
					)
		SELECT		SrcSys_MultiParent
					,Src_UID_MultiParent
		FROM		(SELECT		SrcSys_A AS SrcSys_MultiParent
								,Src_UID_A AS Src_UID_MultiParent
					FROM		#EntityPairs_Unique_Distance ep_u_dist
					WHERE		Distance_A > @TargetDistance
					AND			Distance_A > Distance_B

					UNION ALL

					SELECT		SrcSys_B
								,Src_UID_B
					FROM		#EntityPairs_Unique_Distance ep_u_dist
					WHERE		Distance_B > @TargetDistance
					AND			Distance_B > Distance_A
								) MultiParent
		GROUP BY	SrcSys_MultiParent
					,Src_UID_MultiParent
		HAVING		COUNT(*) > 1

		-- Find the "downwards" chain(s) from the target entity going further from the major
			-- Initialise the table with the first downward link
			INSERT INTO	#DownwardChain
						(SrcSys_OneDeeper
						,Src_UID_OneDeeper
						,SrcSys_From
						,Src_UID_From
						,Distance_From
						,SrcSys_To
						,Src_UID_To
						,Distance_To
						,HasMultiParent
						,Processed
						)
			SELECT		SrcSys_B AS SrcSys_OneDeeper
						,Src_UID_B AS Src_UID_OneDeeper
						,@SrcSys AS SrcSys_From
						,@Src_UID AS Src_UID_From
						,@TargetDistance AS Distance_From
						,SrcSys_B AS SrcSys_To
						,Src_UID_B AS Src_UID_To
						,Distance_B AS Distance_To
						,CASE WHEN mp.SrcSys_MultiParent IS NOT NULL THEN 1 ELSE 0 END AS HasMultiParent
						,0 AS Processed
			FROM		#EntityPairs_Unique_Distance ep_u_dist
			LEFT JOIN	#MultiParent mp
										ON	ep_u_dist.SrcSys_B = mp.SrcSys_MultiParent
										AND	ep_u_dist.Src_UID_B = mp.Src_UID_MultiParent
			WHERE		ep_u_dist.SrcSys_A = @SrcSys
			AND			ep_u_dist.Src_UID_A = @Src_UID
			AND			Distance_A < Distance_B

			UNION

			SELECT		SrcSys_A AS SrcSys_OneDeeper
						,Src_UID_A AS Src_UID_OneDeeper
						,@SrcSys AS SrcSys_From
						,@Src_UID AS Src_UID_From
						,@TargetDistance AS Distance_From
						,SrcSys_A AS SrcSys_To
						,Src_UID_A AS Src_UID_To
						,Distance_A AS Distance_To
						,CASE WHEN mp.SrcSys_MultiParent IS NOT NULL THEN 1 ELSE 0 END AS HasMultiParent
						,0 AS Processed
			FROM		#EntityPairs_Unique_Distance ep_u_dist
			LEFT JOIN	#MultiParent mp
										ON	ep_u_dist.SrcSys_A = mp.SrcSys_MultiParent
										AND	ep_u_dist.Src_UID_A = mp.Src_UID_MultiParent
			WHERE		ep_u_dist.SrcSys_B = @SrcSys
			AND			ep_u_dist.Src_UID_B = @Src_UID
			AND			Distance_B < Distance_A
	
			-- Iterate over further connections down the chain
			DECLARE @NoMoreUpdates SMALLINT = 0 
			WHILE @NoMoreUpdates = 0
			BEGIN
					PRINT 'Downward chain loop'
					-- Iterate over further connections down the chain
					INSERT INTO	#DownwardChain
								(SrcSys_OneDeeper
								,Src_UID_OneDeeper
								,SrcSys_From
								,Src_UID_From
								,Distance_From
								,SrcSys_To
								,Src_UID_To
								,Distance_To
								,HasMultiParent
								)
					SELECT		SrcSys_OneDeeper	= dc.SrcSys_OneDeeper
								,Src_UID_OneDeeper	= dc.Src_UID_OneDeeper
								,SrcSys_From		= dc.SrcSys_To
								,Src_UID_From		= dc.Src_UID_To
								,Distance_From		= dc.Distance_To
								,SrcSys_To			= IterateNext.SrcSys_To
								,Src_UID_To			= IterateNext.Src_UID_To
								,Distance_To		= IterateNext.Distance_To
								,HasMultiParent		= IterateNext.HasMultiParent
					FROM		#DownwardChain dc
					INNER JOIN	(SELECT		SrcSys_A AS SrcSys_From
											,Src_UID_A AS Src_UID_From
											,SrcSys_B AS SrcSys_To
											,Src_UID_B AS Src_UID_To
											,Distance_B AS Distance_To
											,CASE WHEN mp.SrcSys_MultiParent IS NOT NULL THEN 1 ELSE 0 END AS HasMultiParent
								FROM		#EntityPairs_Unique_Distance ep_u_dist
								LEFT JOIN	#MultiParent mp
															ON	ep_u_dist.SrcSys_B = mp.SrcSys_MultiParent
															AND	ep_u_dist.Src_UID_B = mp.Src_UID_MultiParent

								UNION

								SELECT		SrcSys_B AS SrcSys_From
											,Src_UID_B AS Src_UID_From
											,SrcSys_A AS SrcSys_To
											,Src_UID_A AS Src_UID_To
											,Distance_A AS Distance_To
											,CASE WHEN mp.SrcSys_MultiParent IS NOT NULL THEN 1 ELSE 0 END AS HasMultiParent
								FROM		#EntityPairs_Unique_Distance ep_u_dist
								LEFT JOIN	#MultiParent mp
															ON	ep_u_dist.SrcSys_A = mp.SrcSys_MultiParent
															AND	ep_u_dist.Src_UID_A = mp.Src_UID_MultiParent
											) IterateNext
															ON	dc.SrcSys_To = IterateNext.SrcSys_From
															AND	dc.Src_UID_To = IterateNext.Src_UID_From
					LEFT JOIN	#DownwardChain dc_notPresent
															ON	IterateNext.SrcSys_To	= dc_notPresent.SrcSys_To
															AND	IterateNext.Src_UID_To	= dc_notPresent.Src_UID_To
					WHERE		dc.Processed = 0
					AND			dc_notPresent.SrcSys_To IS NULL
					AND			dc.HasMultiParent = 0

					-- Exit the loop if there were no more distances to find
					IF @@ROWCOUNT = 0
					SET @NoMoreUpdates = 1

					UPDATE #DownwardChain SET Processed = 1 WHERE Processed = 0

					UPDATE #DownwardChain SET Processed = 0 WHERE Processed = NULL
	
			END

		-- Sever all links from the target entity to those as the same level or higher
		INSERT INTO	#Unlink
					(SrcSys_Unlink_A
					,Src_UID_Unlink_A
					,SrcSys_Unlink_B
					,Src_UID_Unlink_B
					)
		SELECT		SrcSys_B AS SrcSys_Unlink_A
					,Src_UID_B AS Src_UID_Unlink_A
					,SrcSys_A AS SrcSys_Unlink_B
					,Src_UID_A AS Src_UID_Unlink_B
		FROM		#EntityPairs_Unique_Distance ep_u_dist
		WHERE		ep_u_dist.SrcSys_A = @SrcSys
		AND			ep_u_dist.Src_UID_A = @Src_UID
		AND			Distance_B < Distance_A + CAST(ISNULL(@HardUnlink, 0) AS INT)

		UNION

		SELECT		SrcSys_A AS SrcSys_Unlink_A
					,Src_UID_A AS Src_UID_Unlink_A
					,SrcSys_B AS SrcSys_Unlink_B
					,Src_UID_B AS Src_UID_Unlink_B
		FROM		#EntityPairs_Unique_Distance ep_u_dist
		WHERE		ep_u_dist.SrcSys_B = @SrcSys
		AND			ep_u_dist.Src_UID_B = @Src_UID
		AND			Distance_A < Distance_B + CAST(ISNULL(@HardUnlink, 0) AS INT)

		-- Sever all links along any "downwards" chain(s) until you reach a node with 2 or more upward connections - this stops there being routes back round to the current major via another set of entity nodes
		INSERT INTO	#Unlink
					(SrcSys_Unlink_A
					,Src_UID_Unlink_A
					,SrcSys_Unlink_B
					,Src_UID_Unlink_B
					)
		SELECT		dc.SrcSys_From
					,dc.Src_UID_From
					,dc.SrcSys_To
					,dc.Src_UID_To
		FROM		#DownwardChain dc
		LEFT JOIN	#Unlink unlink_notPresent_A
											ON	dc.SrcSys_From	= unlink_notPresent_A.SrcSys_Unlink_A
											AND	dc.Src_UID_From	= unlink_notPresent_A.Src_UID_Unlink_A
											AND	dc.SrcSys_To	= unlink_notPresent_A.SrcSys_Unlink_B
											AND	dc.Src_UID_To	= unlink_notPresent_A.Src_UID_Unlink_B
		LEFT JOIN	#Unlink unlink_notPresent_B
											ON	dc.SrcSys_From	= unlink_notPresent_A.SrcSys_Unlink_B
											AND	dc.Src_UID_From	= unlink_notPresent_A.Src_UID_Unlink_B
											AND	dc.SrcSys_To	= unlink_notPresent_A.SrcSys_Unlink_A
											AND	dc.Src_UID_To	= unlink_notPresent_A.Src_UID_Unlink_B
		WHERE		HasMultiParent = 1
		AND			unlink_notPresent_A.SrcSys_Unlink_A IS NULL
		AND			unlink_notPresent_B.SrcSys_Unlink_B IS NULL
		GROUP BY	dc.SrcSys_From
					,dc.Src_UID_From
					,dc.SrcSys_To
					,dc.Src_UID_To

		-- Re-instate links along any "downwards" chain(s) that have a node with 2 or more upward connections - this stops there being links back round to the current major via another set of entity nodes
		-- This re-instates any unlinks made in this session as well as links made in previous sessions
		INSERT INTO	#ClearUnlinks
					(SrcSys_ClearUnlink_A
					,Src_UID_ClearUnlink_A
					,SrcSys_ClearUnlink_B
					,Src_UID_ClearUnlink_B
					)
		SELECT		*
		FROM		(SELECT		SrcSys_B AS SrcSys_Unlink_A
								,Src_UID_B AS Src_UID_Unlink_A
								,SrcSys_A AS SrcSys_Unlink_B
								,Src_UID_A AS Src_UID_Unlink_B
								--,ep_u_dist.*
								--,dist_a.SrcSys_Major	AS SrcSys_Major_A
								--,dist_a.Src_UID_Major	AS Src_UID_Major_A
								--,dist_b.SrcSys_Major	AS SrcSys_Major_B
								--,dist_b.Src_UID_Major	AS Src_UID_Major_B
					FROM		#EntityPairs_Unique_Distance ep_u_dist
					INNER JOIN	#Distance dist_a
											ON	ep_u_dist.SrcSys_A = dist_a.SrcSys
											AND	ep_u_dist.Src_UID_A = dist_a.Src_UID
					INNER JOIN	#Distance dist_b
											ON	ep_u_dist.SrcSys_B = dist_b.SrcSys
											AND	ep_u_dist.Src_UID_B = dist_b.Src_UID
					WHERE		ep_u_dist.SrcSys_A = @SrcSys
					AND			ep_u_dist.Src_UID_A = @Src_UID
					AND			Distance_B < Distance_A
					AND			CONCAT(dist_a.SrcSys_Major, '|', dist_a.Src_UID_Major) != CONCAT(dist_b.SrcSys_Major, '|', dist_b.Src_UID_Major)

					UNION

					SELECT		SrcSys_A AS SrcSys_Unlink_A
								,Src_UID_A AS Src_UID_Unlink_A
								,SrcSys_B AS SrcSys_Unlink_B
								,Src_UID_B AS Src_UID_Unlink_B
								--,ep_u_dist.*
								--,dist_a.SrcSys_Major	AS SrcSys_Major_A
								--,dist_a.Src_UID_Major	AS Src_UID_Major_A
								--,dist_b.SrcSys_Major	AS SrcSys_Major_B
								--,dist_b.Src_UID_Major	AS Src_UID_Major_B
					FROM		#EntityPairs_Unique_Distance ep_u_dist
					INNER JOIN	#Distance dist_a
											ON	ep_u_dist.SrcSys_A = dist_a.SrcSys
											AND	ep_u_dist.Src_UID_A = dist_a.Src_UID
					INNER JOIN	#Distance dist_b
											ON	ep_u_dist.SrcSys_B = dist_b.SrcSys
											AND	ep_u_dist.Src_UID_B = dist_b.Src_UID
					WHERE		ep_u_dist.SrcSys_B = @SrcSys
					AND			ep_u_dist.Src_UID_B = @Src_UID
					AND			Distance_A < Distance_B
					AND			CONCAT(dist_a.SrcSys_Major, '|', dist_a.Src_UID_Major) != CONCAT(dist_b.SrcSys_Major, '|', dist_b.Src_UID_Major)
								) ep_u_dist

		-- Re-instate any links that move towards the major of the node being updated - this stops there being links back round to the current major via another set of entity nodes
		-- This re-instates any unlinks made in this session as well as links made in previous sessions
		INSERT INTO	#ClearUnlinks
					(SrcSys_ClearUnlink_A
					,Src_UID_ClearUnlink_A
					,SrcSys_ClearUnlink_B
					,Src_UID_ClearUnlink_B
					)
		SELECT		dc.SrcSys_From
					,dc.Src_UID_From
					,dc.SrcSys_To
					,dc.Src_UID_To
		FROM		#DownwardChain dc
		INNER JOIN	#Distance dist_a
								ON	dc.SrcSys_From = dist_a.SrcSys
								AND	dc.Src_UID_From = dist_a.Src_UID
		INNER JOIN	#Distance dist_b
								ON	dc.SrcSys_To = dist_b.SrcSys
								AND	dc.Src_UID_To = dist_b.Src_UID
		WHERE		/*HasMultiParent = 1
		AND			*/CONCAT(dist_a.SrcSys_Major, '|', dist_a.Src_UID_Major) != CONCAT(dist_b.SrcSys_Major, '|', dist_b.Src_UID_Major)
		


		---- debug
		--SELECT * FROM #Distance
		--SELECT * FROM #EntityPairs_Unique_Distance
		--SELECT * FROM #MultiParent
		--SELECT * FROM #DownwardChain
		--SELECT * FROM #Unlink
		--SELECT * FROM #ClearUnlinks

		/*****************************************************************************************************************************************/
		-- Make the updates
		/*****************************************************************************************************************************************/

		-- Record a consistent getdate in the dynamic sql control table
		INSERT INTO #DynamicSqlControl (ControlType, ControlValue) SELECT 'GETDATE', GETDATE()
		
		IF (SELECT COUNT(*) FROM #DynamicSqlControl WHERE ControlType = 'ValidityTest' AND ControlValue = 1) = 1
		BEGIN TRY

			BEGIN TRANSACTION
		
				---- Update unlinking columns in EntityPairs_Unique to clear the unlinks already applied for the entity
				--SET @SQL =	'UPDATE		ep_u ' + CHAR(13) +
				--			'SET		ep_u.UnlinkDttm = NULL ' + CHAR(13) +
				--			'			,ep_u.LastUnlinkedBy = NULL ' + CHAR(13) +
				--			'			,ep_u.UnlinkProcessed = NULL ' + CHAR(13) +
				--			'FROM		Merge_DM_Match.' + @tableName + '_Match_EntityPairs_Unique ep_u ' + CHAR(13) +
				--			'WHERE		(ep_u.SrcSys_A = ' + CAST(@SrcSys AS VARCHAR(255)) + ' ' + CHAR(13) +
				--			'AND		ep_u.Src_UID_A = ''' + @Src_UID + ''') ' + CHAR(13) +
				--			'OR			(ep_u.SrcSys_B = ' + CAST(@SrcSys AS VARCHAR(255)) + ' ' + CHAR(13) +
				--			'AND		ep_u.Src_UID_B = ''' + @Src_UID + ''') ' + CHAR(13) +
				--			'; INSERT INTO #DynamicSqlControl (ControlType, ControlValue) SELECT ''@@ROWCOUNT'', @@ROWCOUNT '

				--PRINT @SQL
				--EXEC (@SQL)
		
				-- Update UnlinkDttm in EntityPairs_Unique for pairs to be unlinked
				SET @SQL =	'DECLARE @GetDate DATETIME2; SELECT @GetDate = CONVERT(DATETIME2, ControlValue) FROM #DynamicSqlControl WHERE ControlType = ''GETDATE''; ' + CHAR(13) +
							'UPDATE		ep_u ' + CHAR(13) +
							'SET		ep_u.UnlinkDttm = @GetDate ' + CHAR(13) +
							'			,ep_u.LastUnlinkedBy = ''' + @UserID + ''' ' + CHAR(13) +
							'			,ep_u.UnlinkProcessed = NULL ' + CHAR(13) +
							'FROM		Merge_DM_Match.' + @tableName + '_Match_EntityPairs_Unique ep_u ' + CHAR(13) +
							'INNER JOIN	#Unlink unlink ' + CHAR(13) +
							'							ON	(ep_u.SrcSys_A = unlink.SrcSys_Unlink_A ' + CHAR(13) +
							'							AND	ep_u.Src_UID_A = unlink.Src_UID_Unlink_A ' + CHAR(13) +
							'							AND	ep_u.SrcSys_B = unlink.SrcSys_Unlink_B ' + CHAR(13) +
							'							AND	ep_u.Src_UID_B = unlink.Src_UID_Unlink_B ) ' + CHAR(13) +
							'							OR	(ep_u.SrcSys_A = unlink.SrcSys_Unlink_B ' + CHAR(13) +
							'							AND	ep_u.Src_UID_A = unlink.Src_UID_Unlink_B ' + CHAR(13) +
							'							AND	ep_u.SrcSys_B = unlink.SrcSys_Unlink_A ' + CHAR(13) +
							'							AND	ep_u.Src_UID_B = unlink.Src_UID_Unlink_A ) ' + CHAR(13) +
							--'WHERE		(ep_u.SrcSys_A = ' + CAST(@SrcSys AS VARCHAR(255)) + ' ' + CHAR(13) +
							--'AND		ep_u.Src_UID_A = ''' + @Src_UID + ''') ' + CHAR(13) +
							--'OR			(ep_u.SrcSys_B = ' + CAST(@SrcSys AS VARCHAR(255)) + ' ' + CHAR(13) +
							--'AND		ep_u.Src_UID_B = ''' + @Src_UID + ''') ' + CHAR(13) +
							'; INSERT INTO #DynamicSqlControl (ControlType, ControlValue) SELECT ''@@ROWCOUNT'', @@ROWCOUNT '

				PRINT @SQL
				EXEC (@SQL)
		
				-- Update unlinking columns in EntityPairs_Unique to clear the unlinks for any entities in a chain that starts to lead back to the major
				SET @SQL =	'UPDATE		ep_u ' + CHAR(13) +
							'SET		ep_u.UnlinkDttm = NULL ' + CHAR(13) +
							'			,ep_u.LastUnlinkedBy = NULL ' + CHAR(13) +
							'			,ep_u.UnlinkProcessed = NULL ' + CHAR(13) +
							'FROM		Merge_DM_Match.' + @tableName + '_Match_EntityPairs_Unique ep_u ' + CHAR(13) +
							'INNER JOIN	#ClearUnlinks cu ' + CHAR(13) +
							'							ON	(ep_u.SrcSys_A = cu.SrcSys_ClearUnlink_A ' + CHAR(13) +
							'							AND	ep_u.Src_UID_A = cu.Src_UID_ClearUnlink_A ' + CHAR(13) +
							'							AND	ep_u.SrcSys_B = cu.SrcSys_ClearUnlink_B ' + CHAR(13) +
							'							AND	ep_u.Src_UID_B = cu.Src_UID_ClearUnlink_B) ' + CHAR(13) +
							'							OR	(ep_u.SrcSys_A = cu.SrcSys_ClearUnlink_B ' + CHAR(13) +
							'							AND	ep_u.Src_UID_A = cu.Src_UID_ClearUnlink_B ' + CHAR(13) +
							'							AND	ep_u.SrcSys_B = cu.SrcSys_ClearUnlink_A ' + CHAR(13) +
							'							AND	ep_u.Src_UID_B = cu.Src_UID_ClearUnlink_A) ' + CHAR(13) +
							'; INSERT INTO #DynamicSqlControl (ControlType, ControlValue) SELECT ''@@ROWCOUNT'', @@ROWCOUNT '

				PRINT @SQL
				EXEC (@SQL)

				---- Update the ChangeLastDetected on the match control record
				--IF (SELECT COUNT(*) FROM #DynamicSqlControl WHERE ControlType = '@@ROWCOUNT' AND ControlValue > 0) = 1
				--BEGIN
				--SET @SQL =	'DECLARE @GetDate DATETIME2; SELECT @GetDate = CONVERT(DATETIME2, ControlValue) FROM #DynamicSqlControl WHERE ControlType = ''GETDATE''; ' + CHAR(13) +
				--			'UPDATE		Merge_DM_Match.tbl_XXX_Match_Control ' + CHAR(13) +
				--			'SET		ChangeLastDetected = @GetDate ' + CHAR(13) +
				--			'WHERE		SrcSys = ' + CAST(@SrcSys AS VARCHAR(255)) + ' ' + CHAR(13) +
				--			'AND		Src_UID = ''' + @Src_UID + ''' ' + CHAR(13)

				--EXEC (@SQL)
				--END
		
			COMMIT TRANSACTION

			EXEC Merge_DM_MatchAudit.uspUnlinkMatch 1, NULL, @UserID, @tableName, @SrcSys_Major, @Src_UID_Major, @SrcSys, @Src_UID

		END TRY

		BEGIN CATCH
 
			DECLARE @ErrorMessage VARCHAR(MAX)
			SELECT @ErrorMessage = ERROR_MESSAGE()
			
			SELECT ERROR_NUMBER() AS ErrorNumber
			SELECT @ErrorMessage AS ErrorMessage
 
			PRINT ERROR_NUMBER()
			PRINT @ErrorMessage

			IF @@TRANCOUNT > 0 -- SELECT @@TRANCOUNT
					PRINT 'Rolling back because of error in Incremental Transaction'
				ROLLBACK TRANSACTION

			EXEC Merge_DM_MatchAudit.uspUnlinkMatch 0, @ErrorMessage, @UserID, @tableName, @SrcSys_Major, @Src_UID_Major, @SrcSys, @Src_UID

			RAISERROR (@ErrorMessage, -- Message text.  
										15, -- Severity.  
										1 -- State.  
										);
 
		END CATCH

		/*****************************************************************************************************************************************/
		-- Refresh the major pathway matching using existing matches to push the unlinking through to the match control table
		/*****************************************************************************************************************************************/
		
		SET @SQL =	'EXEC Merge_DM_Match.' + @tableName + '_uspMatchEntityPairs @MajorID_SrcSys = ' + CAST(@SrcSys_Major AS VARCHAR(255)) + ', @MajorID_Src_UID = ''' + @Src_UID_Major + ''', @UseExistingMatches = 1'
		--EXEC (@SQL)


GO
