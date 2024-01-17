SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [map].[usp_AspNetUsers_MappingUpdate] AS 

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

Original Work Created Date:	17/01/2024
Original Work Created By:	Perspicacity Ltd (Matthew Bishop) & UHSx (Sian Neville)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk / sian.neville@nhs.net
Description:				Create the data to validate and manage the merging of the SCR AspNetUsers table
**************************************************************************************************************************************************/

/* -- Refresh the manually captured mapping data



UPDATE		map.AspNetUsers
SET			AspNetUsers.MergePrimary = NULL
			,AspNetUsers.MergeUsername = NULL
			,AspNetUsers.LogicalDelete = NULL

*/

/************************************************************************************************************************************************************************/
-- Insert any new usernames from either source system that aren't already in the table
/************************************************************************************************************************************************************************/

		-- Create a table variable to hold the newly inserted records for return as a dataset
		DECLARE @AspNetUsers_Inserted AS TABLE (SrcSysID TINYINT NOT NULL, ID INT NOT NULL, Username NVARCHAR(256) NOT NULL, DateLogged DATETIME2 NOT NULL)

		-- Insert any new WSHT usernames
		INSERT INTO	map.AspNetUsers
					(SrcSysID
					,ID
					,UserName
					)
		OUTPUT Inserted.SrcSysID, Inserted.ID, Inserted.UserName, Inserted.DateLogged INTO @AspNetUsers_Inserted
		SELECT		1
					,WSHT.Id
					,WSHT.UserName
		FROM		CancerRegister_WSHT.dbo.AspNetUsers WSHT
		LEFT JOIN	map.AspNetUsers map
										ON	WSHT.ID = map.ID
										AND	map.SrcSysID = 1
		WHERE		map.ID IS NULL

		-- Insert any new BSUH usernames
		INSERT INTO	map.AspNetUsers
					(SrcSysID
					,ID
					,UserName
					)
		OUTPUT Inserted.SrcSysID, Inserted.ID, Inserted.UserName, Inserted.DateLogged INTO @AspNetUsers_Inserted
		SELECT		2
					,BSUH.Id
					,BSUH.UserName
		FROM		CancerRegister_BSUH.dbo.AspNetUsers BSUH
		LEFT JOIN	map.AspNetUsers map
										ON	BSUH.Id = map.ID
										AND	map.SrcSysID = 2
		WHERE		map.ID IS NULL

		SELECT		'Newly added records' AS OutputData
					,*
		FROM		@AspNetUsers_Inserted


/************************************************************************************************************************************************************************/
-- Create a dataset to help identify potential duplicates / merges
/************************************************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#AspNetUsers_Extended') IS NOT NULL DROP TABLE #AspNetUsers_Extended

		-- Create a dataset of the WSHT data from the mapping table with extended information to be used for matching
		SELECT		users.SrcSysID
					,users.ID
					,users.UserName
					,users.MergePrimary
					,users.MergeUsername
					,users.LogicalDelete
					,users.DateLogged
					,WSHT.Email
					,WSHT.IsApproved
					,WSHT.CreatedDate
					,WSHT.LastLoginDate
					,WSHT.LastPasswordChangeDate
					,WSHT.OrganisationCode
					,WSHT.FullName
					,WSHT.PasswordReset
					,WSHT.AssociatedCNSId
					,WSHT.LastLockoutDate
		INTO		#AspNetUsers_Extended
		FROM		map.AspNetUsers users
		LEFT JOIN	CancerRegister_WSHT.dbo.AspNetUsers WSHT
															ON	users.ID = WSHT.Id
		WHERE		users.SrcSysID = 1

		-- Add the BSUH data from the mapping table with extended information to be used for matching
		INSERT INTO	#AspNetUsers_Extended
		SELECT		users.SrcSysID
					,users.ID
					,users.UserName
					,users.MergePrimary
					,users.MergeUsername
					,users.LogicalDelete
					,users.DateLogged
					,BSUH.Email
					,BSUH.IsApproved
					,BSUH.CreatedDate
					,BSUH.LastLoginDate
					,BSUH.LastPasswordChangeDate
					,BSUH.OrganisationCode
					,BSUH.FullName
					,BSUH.PasswordReset
					,BSUH.AssociatedCNSId
					,BSUH.LastLockoutDate
		FROM		map.AspNetUsers users
		LEFT JOIN	CancerRegister_BSUH.dbo.AspNetUsers BSUH
															ON	users.ID = BSUH.Id
		WHERE		users.SrcSysID = 2


		IF OBJECT_ID('map.AspNetUsers_CouldBeMatch_01') IS NOT NULL DROP TABLE map.AspNetUsers_CouldBeMatch_01

		-- Create a dataset identifying any combination of matches from key fields
		SELECT		A.SrcSysID AS SrcSysID_A
					,A.Id AS Id_A
					,B.SrcSysID AS SrcSysID_B
					,B.Id AS Id_B
					,A.SrcSysID AS SrcSysID_Master
					,A.Id AS ID_Master

					,CASE WHEN A.UserName = B.UserName THEN 1 ELSE 0 END +
					CASE WHEN A.Email = B.Email THEN 1 ELSE 0 END +
					CASE WHEN A.FullName = B.FullName THEN 1 ELSE 0 END +
					CASE WHEN A.OrganisationCode = B.OrganisationCode THEN 1 ELSE 0 END AS MatchScore
			
					,CASE WHEN A.UserName = B.UserName THEN 1 ELSE 0 END AS MatchUsername
					,CASE WHEN A.Email = B.Email THEN 1 ELSE 0 END AS MatchEmail
					,CASE WHEN A.FullName = B.FullName THEN 1 ELSE 0 END AS MatchFullName
					,CASE WHEN A.OrganisationCode = B.OrganisationCode THEN 1 ELSE 0 END AS MatchOrgCode
					,A.Email AS Email_A
					,B.Email AS Email_B
					,A.FullName AS FullName_A
					,B.FullName AS FullName_B
					,A.OrganisationCode AS OrganisationCode_A
					,B.OrganisationCode AS OrganisationCode_B
					,A.IsApproved AS IsApproved_A
					,B.IsApproved AS IsApproved_B
			
					,A.CreatedDate AS CreatedDate_A
					,A.LastLoginDate AS LastLoginDate_A
					,A.LastPasswordChangeDate AS LastPasswordChangeDate_A
					,A.PasswordReset AS PasswordReset_A
					,A.AssociatedCNSId AS AssociatedCNSId_A
					,A.LastLockoutDate AS LastLockoutDate_A
					,B.CreatedDate AS CreatedDate_B
					,B.LastLoginDate AS LastLoginDate_B
					,B.LastPasswordChangeDate AS LastPasswordChangeDate_B
					,B.PasswordReset AS PasswordReset_B
					,B.AssociatedCNSId AS AssociatedCNSId_B
					,B.LastLockoutDate AS LastLockoutDate_B
		INTO		map.AspNetUsers_CouldBeMatch_01
		FROM		#AspNetUsers_Extended A
		INNER JOIN	#AspNetUsers_Extended B
												ON	(A.SrcSysID * 1000000) + A.ID < (B.SrcSysID * 1000000) + B.ID
		WHERE		CASE WHEN A.UserName = B.UserName THEN 1 ELSE 0 END +
					CASE WHEN A.Email = B.Email THEN 1 ELSE 0 END +
					CASE WHEN A.FullName = B.FullName THEN 1 ELSE 0 END > 0

			
		DECLARE @IterativeMaster_01 INT = 1

		-- Loop through the matches to trace all of them back to a common parent record (for when there are multiple records that could all be the same user)
		WHILE @IterativeMaster_01 > 0
		BEGIN

				-- Find any parent (SrcSysID A / ID A) of the current master SrcSysID / ID and repoint the master to the parent
				UPDATE		cbm_01_child
				SET			cbm_01_child.SrcSysID_Master = cbm_01_parent.SrcSysID_Master
							,cbm_01_child.ID_Master = cbm_01_parent.ID_Master
				FROM		map.AspNetUsers_CouldBeMatch_01 cbm_01_child
				INNER JOIN	map.AspNetUsers_CouldBeMatch_01 cbm_01_parent
																	ON	cbm_01_child.SrcSysID_Master = cbm_01_parent.SrcSysID_B
																	AND	cbm_01_child.ID_Master = cbm_01_parent.ID_B

				-- Reset @IterativeMaster to the number of rows affected in the last update
				SET @IterativeMaster_01 = @@ROWCOUNT

		END



		IF OBJECT_ID('map.AspNetUsers_ValidateMatch_01') IS NOT NULL DROP TABLE map.AspNetUsers_ValidateMatch_01

		-- Collate the unique master record ID's and identify the maximum match score within the master record
		SELECT			cbm_01.SrcSysID_Master
						,cbm_01.ID_Master
						,cbm_01.SrcSysID_Master AS SrcSysID
						,cbm_01.ID_Master AS ID
						,MAX(cbm_01.MatchScore) AS BestMatchScore
						,COUNT(*) AS MatchCount
		INTO			map.AspNetUsers_ValidateMatch_01
		FROM			map.AspNetUsers_CouldBeMatch_01 cbm_01
		GROUP BY		cbm_01.SrcSysID_Master
						,cbm_01.ID_Master

		-- Collate the child records related to the unique master record ID's and populate the maximum match score within the master record
		INSERT INTO		map.AspNetUsers_ValidateMatch_01
						(SrcSysID_Master
						,ID_Master
						,SrcSysID
						,ID
						,BestMatchScore
						,MatchCount
						)
		SELECT			cbm_01.SrcSysID_Master
						,cbm_01.ID_Master
						,cbm_01.SrcSysID_B
						,cbm_01.ID_B
						,v_01.BestMatchScore
						,v_01.MatchCount
		FROM			(SELECT		cbm_01_inner.SrcSysID_Master
									,cbm_01_inner.ID_Master
									,cbm_01_inner.SrcSysID_B
									,cbm_01_inner.Id_B
						FROM		map.AspNetUsers_CouldBeMatch_01 cbm_01_inner
						GROUP BY	cbm_01_inner.SrcSysID_Master
									,cbm_01_inner.ID_Master
									,cbm_01_inner.SrcSysID_B
									,cbm_01_inner.Id_B) cbm_01
		INNER JOIN		map.AspNetUsers_ValidateMatch_01 v_01
													ON	cbm_01.SrcSysID_Master = v_01.SrcSysID
													AND	cbm_01.ID_Master = v_01.ID

GO
